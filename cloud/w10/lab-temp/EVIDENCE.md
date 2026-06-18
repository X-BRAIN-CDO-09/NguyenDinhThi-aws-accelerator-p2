# BÁO CÁO NGHIỆM THU (EVIDENCE REPORT)
## ĐỀ BÀI: W10 Lab — Security GitOps & Namespace Isolation (Payments)

* **Học viên:** Nguyễn Đình Thi
* **Mã học viên:** XB-DN26-103
* **Chương trình:** X-BRAIN CDO-09 | Tuần W10
* **Repo:** [X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2](https://github.com/X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2)
* **Cluster:** EC2 Instance (t3.large) + Minikube profile `minikube`
* **Ngày nộp:** 19/06/2026

---

## I. SƠ ĐỒ KIẾN TRÚC TỔNG QUAN

```
                         ┌───────────────────────────┐
                         │      GitHub Repository    │
                         └─────────────┬─────────────┘
                                       │
                              ArgoCD App-of-Apps
                                       │
              ┌────────────────────────┼────────────────────────┐
              ▼                        ▼                        ▼
       [eso-system]              [gatekeeper]           [cosign-system]
       - ESO Operator            - OPA Templates        - Sigstore Controller
              │                        │                        │
              ▼                        ▼                        ▼
     ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
     │  SecretStore &   │    │    Admission     │    │  ClusterImage    │
     │  ExternalSecret  │    │   Constraints    │    │     Policy       │
     └────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘
              │                        │                        │
              └────────────────────────┼────────────────────────┘
                                       ▼
                       ┌───────────────────────────────┐
                       │  Kubernetes Target namespaces  │
                       │ ┌───────────────────────────┐ │
                       │ │   demo (API Rollout)      │ │
                       │ ├───────────────────────────┤ │
                       │ │   payments (Cô lập hoàn toà│ │
                       │ ├───────────────────────────┤ │
                       │ │   monitoring (Alerts stack│ │
                       │ └───────────────────────────┘ │
                       └───────────────────────────────┘
                                       ▲
                                       │
                            AWS Secrets Manager
                            (prod/db/password)
                            (prod/alertmanager/email)
```

> Hệ thống tích hợp 4 trụ cột bảo mật GitOps nâng cao: **K8s Security Hardening (RBAC + Gatekeeper OPA)** + **Secrets Management (External Secrets Operator + AWS Secrets Manager)** + **Container Supply Chain (Trivy Scan + Cosign Verification)** + **Multitenancy Namespace Isolation (Payments)**.

---

## II. BẢNG ĐỐI CHIẾU TIÊU CHÍ ĐẠT (ACCEPTANCE CHECKLIST)

Dưới đây là bảng đối chiếu các yêu cầu bắt buộc của đề bài so với kết quả thực tế:

| STT | Yêu cầu bắt buộc của Đề bài | Trạng thái | Giải pháp kỹ thuật thực tế |
| :--- | :--- | :---: | :--- |
| **1** | **Mọi cấu hình qua Git → ArgoCD** | **ĐẠT** | Toàn bộ tài nguyên quản lý bằng GitOps thông qua App-of-Apps (root app quản lý 16 child apps). |
| **2** | **Lab 1.1: Phân quyền RBAC tối thiểu** | **ĐẠT** | Thiết lập Role `developer` trong namespace `demo` cho User `alice`, giới hạn nghiêm ngặt phạm vi truy cập (không xem secrets, không xem nodes). |
| **3** | **Lab 1.2: Áp dụng Gatekeeper Guardrails** | **ĐẠT** | Ràng buộc chặt chẽ 4 quy tắc cơ bản: không chạy `latest` tag, không chạy dưới quyền `root`, bắt buộc có CPU/Memory limits, cấm `hostNetwork`. |
| **4** | **Lab 1.3: Custom Policy (allowed-registry)** | **ĐẠT** | Tạo constraint template và constraint chỉ cho phép các container images có nguồn từ `ghcr.io/x-brain-cdo-09/*`. |
| **5** | **Lab 2.1: Đồng bộ Secret từ AWS qua ESO** | **ĐẠT** | Tích hợp ESO kết nối tới AWS Secrets Manager ở region `ap-southeast-1` thông qua `aws-creds`. Tránh việc lưu trữ mật khẩu plaintext lên Git. |
| **6** | **Lab 2.2: Quét Trivy & Ký ảnh Cosign** | **ĐẠT** | CI pipeline tự động quét lỗ hổng Trivy (chỉ cho phép merge khi không có lỗi Critical/High), sau đó dùng Cosign ký ảnh số hóa. Enforce bằng `ClusterImagePolicy`. |
| **7** | **Lab 2.3: SMTP Alertmanager tích hợp ESO** | **ĐẠT** | Lấy mật khẩu Gmail App Password từ AWS Secrets Manager, đồng bộ bảo mật qua ESO để cung cấp cho SMTP Alertmanager gửi cảnh báo qua Email. |
| **8** | **Challenge: Tách biệt hoàn toàn Payments** | **ĐẠT** | Tạo namespace `payments`. Sử dụng `ResourceQuota`, `LimitRange`, và `NetworkPolicy` để đảm bảo cô lập hoàn toàn tài nguyên và mạng lưới. |

---

## III. GIẢI THÍCH KIẾN TRÚC & QUYẾT ĐỊNH THIẾT KẾ

### 1. Phân quyền RBAC tối thiểu (Least Privilege)
RBAC được thiết kế đảm bảo các nhà phát triển (ví dụ: `alice`) chỉ có quyền quản lý các tài nguyên workload cơ bản (Deployments, Pods, Services, Rollouts) trong namespace được giao (`demo`). Quyền truy cập các thông tin nhạy cảm như Kubernetes Secrets hay tài nguyên cấp cụm (Nodes, ClusterRoles) hoàn toàn bị chặn.

### 2. Tự động kiểm soát chính sách (Admission Guardrails)
Sử dụng **OPA Gatekeeper** hoạt động như một Admission Webhook. Mọi yêu cầu tạo mới hoặc chỉnh sửa workload không thỏa mãn 5 luật bảo mật đều bị chặn ngay ở cấp API Server. Điều này ngăn ngừa hoàn toàn các lỗi vô tình của con người trong quá trình vận hành.

### 3. Tích hợp SecOps qua AWS Secrets Manager và ESO
Thay vì lưu trữ thông tin nhạy cảm (như mật khẩu DB hay Gmail SMTP) trực tiếp trên Git hay tạo thủ công, chúng ta lưu tập trung trên **AWS Secrets Manager**. 
*   **ESO (External Secrets Operator)** đóng vai trò cầu nối, tự động định kỳ kéo (pull) secrets về cụm và khởi tạo Kubernetes Secret.
*   Thông tin xác thực AWS của ESO được cấu hình tách biệt qua Kubernetes Secret `aws-creds` sử dụng IAM Credentials, đảm bảo tính bảo mật và dễ quản lý.

### 4. Supply Chain Security (Trivy + Cosign)
Bảo đảm không chạy mã độc hoặc image không rõ nguồn gốc trong cụm. Pipeline GitHub Actions kiểm tra tính an toàn của mã nguồn trước khi xuất bản, và ký số lên container image. Controller `cosign-policy-controller` trên Kubernetes sẽ từ chối chạy bất kỳ container nào có chữ ký không khớp với khóa công khai chỉ định trong `ClusterImagePolicy`.

### 5. Multi-tenancy Isolation (Payments Tenant)
Để tách biệt hoàn toàn ứng dụng `payments` khỏi namespace `demo`:
*   **ResourceQuota** giới hạn tổng lượng tài nguyên tối đa để ngăn "Noisy Neighbor" (một ứng dụng chiếm hết tài nguyên của cụm).
*   **LimitRange** áp đặt các ngưỡng CPU/Memory mặc định cho từng container.
*   **NetworkPolicy** ngăn chặn mọi kết nối vào (ingress) từ bên ngoài namespace `payments`, chỉ cho phép DNS lookup và kết nối nội bộ.

---

## IV. BẰNG CHỨNG THỰC THI (DELIVERABLES & SCREENSHOTS)

### PHẦN 1 — GitOps & ArgoCD App-of-Apps

#### 1.1 Trạng thái đồng bộ của ArgoCD Dashboard
Toàn bộ các ứng dụng được phân phối và tự động đồng bộ theo đúng sync-wave, đảm bảo không xảy ra race condition.

![SS-01: Giao diện ArgoCD Dashboard hiển thị 16 applications - tất cả Synced và Healthy](assets/SS-01_argocd_dashboard_all_apps.png)

#### 1.2 Trạng thái của các child application trên cluster
```bash
$ kubectl get applications -n argocd
NAME                     SYNC STATUS   HEALTH STATUS
alert                    Synced        Healthy
analysis                 Synced        Healthy
api                      Synced        Healthy
argo-rollouts            Synced        Healthy
common                   Synced        Healthy
eso                      Synced        Healthy
eso-config               Synced        Healthy
gatekeeper               Synced        Healthy
gatekeeper-constraints   Synced        Healthy
gatekeeper-templates     Synced        Healthy
kube-prometheus-stack    Synced        Healthy
payments                 Synced        Healthy
payments-app             Synced        Healthy
policies                 Synced        Healthy
policy-controller        Synced        Healthy
rbac                     Synced        Healthy
root                     Synced        Healthy
```

---

### PHẦN 2 — Kubernetes Workloads & RBAC Hardening

#### 2.1 Kiểm tra phân quyền truy cập của User `alice`
```bash
# 1. Xác nhận Alice có quyền quản trị Deployments trong demo namespace
$ kubectl auth can-i create deployments --as=alice -n demo
yes

# 2. Xác nhận Alice BỊ CHẶN truy cập vào Secrets
$ kubectl auth can-i get secrets --as=alice -n demo
no

# 3. Xác nhận Alice BỊ CHẶN truy cập tài nguyên Cluster (Nodes)
$ kubectl auth can-i get nodes --as=alice
Warning: resource 'nodes' is not namespace scoped
no
```

#### 2.2 Kiểm tra hoạt động của OPA Gatekeeper Admission Control
Thử nghiệm chạy một Pod thiếu cấu hình giới hạn tài nguyên và sử dụng image từ Docker Hub không được phép:
```bash
$ kubectl run test-unsigned --image=nginx:1.25 -n demo
```
**Kết quả bị từ chối trực tiếp từ API Server:**
```text
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: 
[require-limits] Container 'test-unsigned' missing resources.limits.cpu
[require-limits] Container 'test-unsigned' missing resources.limits.memory
[allowed-registry] Image 'index.docker.io/library/nginx@sha256:a484819eb60211f5299034ac80f6a681b06f89e65866ce91f356ed7c72af059c' is not from allowed registry 'ghcr.io/x-brain-cdo-09/'
```

---

### PHẦN 3 — Secrets Management (ESO) & Alerting Stack

#### 3.1 Trạng thái của External Secrets Operator (ESO)
Hệ thống kết nối và đồng bộ bí mật từ AWS Secrets Manager một cách tự động và ổn định:
```bash
$ kubectl get secretstores,externalsecrets --all-namespaces
NAMESPACE    NAME                                                   AGE     STATUS   CAPABILITIES   READY
demo         secretstore.external-secrets.io/aws-store              113m    Valid    ReadWrite      True
monitoring   secretstore.external-secrets.io/aws-store-monitoring   6m40s   Valid    ReadWrite      True

NAMESPACE    NAME                                                        STORE                  REFRESH INTERVAL   STATUS         READY
demo         externalsecret.external-secrets.io/db-creds                 aws-store              10s                SecretSynced   True
monitoring   externalsecret.external-secrets.io/alertmanager-email-eso   aws-store-monitoring   1m                 SecretSynced   True
```

#### 3.2 Kubernetes Secrets được tạo tự động bởi ESO
*   Secret mật khẩu Database (`db-secret` trong namespace `demo`):
```bash
$ kubectl get secret db-secret -n demo -o yaml | grep "password:"
  password: eyJwYXNzd29yZCI6IlRoaXRoaXRoaUAwMzA1MDQifQ==
```
*   Secret mật khẩu Gmail SMTP (`alertmanager-email` trong namespace `monitoring`):
```bash
$ kubectl get secret alertmanager-email -n monitoring -o yaml | grep "password:"
  password: ZnpweGRnZmVydWhyYWxmdw==
```

#### 3.3 Alertmanager SMTP Email Notification
Alertmanager nhận diện cấu hình SMTP Gmail được lấy từ AWS Secrets Manager, gửi thông báo trực tiếp tới địa chỉ `thihtktk@gmail.com`.

![SS-02: Email cảnh báo thực tế gửi từ Alertmanager đến hộp thư Gmail của học viên](assets/SS-02_gmail_alertmanager_received.png)

---

### PHẦN 4 — Container Supply Chain (Cosign Verification)

Chính sách xác minh chữ ký được khai báo dưới dạng `ClusterImagePolicy` với cấu hình bắt buộc xác minh bằng khóa công khai (`mode: enforce`).
```bash
$ kubectl get clusterimagepolicy image-signature-policy -o yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: image-signature-policy
spec:
  authorities:
  - key:
      data: |
        -----BEGIN PUBLIC KEY-----
        MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE95AAuTY83Nrf/FI+Yti+3xOp3cNl
        JyklSH+0Cy6yC0V+f+cdBnXeDXaGqPn5XbavMpq1eedEd0FUV+xjSW1V5Q==
        -----END PUBLIC KEY-----
    name: authority-0
  images:
  - glob: ghcr.io/x-brain-cdo-09/nguyendinhthi-aws-accelerator-p2/*
  mode: enforce
```

---

### PHẦN 5 — Challenge: Namespace Isolation (Payments Tenant)

#### 5.1 Workloads chạy độc lập trong namespace `payments`
```bash
$ kubectl get pods -n payments -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP            NODE
payments-api-7ffff4757c-kkg7m   1/1     Running   0          52m   10.244.0.35   minikube
payments-api-7ffff4757c-kl2f5   1/1     Running   0          52m   10.244.0.36   minikube
```

#### 5.2 Network Policies cô lập mạng lưới
```bash
$ kubectl get networkpolicies -n payments
NAME                           POD-SELECTOR   AGE
allow-same-ns-egress-and-dns   <none>         60m
deny-all-ingress               <none>         60m
```

#### 5.3 Cấu hình giới hạn tài nguyên đa người dùng (ResourceQuota & LimitRange)
```bash
# 1. ResourceQuota khống chế tổng tài nguyên
$ kubectl get resourcequota payments-quota -n payments
NAME                           REQUEST                                                LIMIT
resourcequota/payments-quota   requests.cpu: 100m/200m, requests.memory: 64Mi/128Mi   limits.cpu: 200m/500m, limits.memory: 128Mi/256Mi

# 2. LimitRange áp đặt giới hạn CPU/Memory mặc định cho container
$ kubectl describe limitrange payments-limitrange -n payments
Name:       payments-limitrange
Namespace:  payments
Type        Resource  Min   Max      Default Request  Default Limit  Max Limit/Request Ratio
----        --------  ---   ---      ---------------  -------------  -----------------------
Container   cpu       10m   200m     50m              100m           -
Container   memory    16Mi  128Mi    32Mi             64Mi           -
```
