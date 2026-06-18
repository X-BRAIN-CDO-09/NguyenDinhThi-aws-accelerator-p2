# Week 10 Lab Evidence — Security GitOps & Namespace Isolation (Payments)

Tài liệu này tổng hợp toàn bộ kết quả thực hiện các bài Lab 1, Lab 2 và phần Challenge (Tách biệt Namespace Payments) trong tuần 10 của học viên **Nguyễn Đình Thi**.

---

## 📸 Các ảnh cần chụp màn hình (Hạn chế tối đa)

> [!IMPORTANT]
> Bạn chỉ cần chụp **02 ảnh màn hình** sau đây và lưu vào thư mục `assets/` (hoặc chèn trực tiếp):
> 
> *   **SS-01: Giao diện ArgoCD UI**
>     *   **Mô tả:** Chụp toàn cảnh ứng dụng `root` và các ứng dụng con (`alert`, `analysis`, `api`, `eso-config`, `payments`, `payments-app`, v.v.) đang ở trạng thái xanh lá cây (**Synced** và **Healthy**).
>     *   *Vị trí ghi nhận:* `[Chèn ảnh SS-01 tại đây]`
> 
> *   **SS-02: Hòm thư Gmail nhận cảnh báo**
>     *   **Mô tả:** Chụp email cảnh báo gửi từ Alertmanager (SMTP Gmail) đến hòm thư `thihtktk@gmail.com` khi kích hoạt cảnh báo mẫu.
>     *   *Vị trí ghi nhận:* `[Chèn ảnh SS-02 tại đây]`

---

## 🛠️ Kết quả thực tế & Minh chứng từ Cluster (Terminal Outputs)

### Phần 1: LAB 1 — RBAC & Gatekeeper Guardrails

#### 1. Kiểm tra phân quyền RBAC (Role-Based Access Control)
*   User `alice` được cấp quyền thông qua `RoleBinding` [alice-developer](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/rbac/rolebindings.yaml#L1-L9).
*   **Minh chứng kiểm tra quyền truy cập:**

```bash
# 1. Kiểm tra xem Alice có quyền tạo Deployment trong namespace demo không?
$ kubectl auth can-i create deployments --as=alice -n demo
yes

# 2. Kiểm tra xem Alice có quyền đọc Secret trong namespace demo không?
$ kubectl auth can-i get secrets --as=alice -n demo
no

# 3. Kiểm tra xem Alice có quyền xem danh sách Node (Cluster-scope) không?
$ kubectl auth can-i get nodes --as=alice
Warning: resource 'nodes' is not namespace scoped
no
```

#### 2. Kiểm tra các luật Gatekeeper Guardrails
Khi cố tình chạy một Pod không tuân thủ quy tắc bảo mật (không cấu hình resource limit, dùng image ngoài registry cho phép):
```bash
$ kubectl run test-unsigned --image=nginx:1.25 -n demo
```
*   **Kết quả đầu ra thực tế (Bị chặn bởi Admission Webhook):**
```text
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: 
[require-limits] Container 'test-unsigned' missing resources.limits.cpu
[require-limits] Container 'test-unsigned' missing resources.limits.memory
[allowed-registry] Image 'index.docker.io/library/nginx@sha256:a484819eb60211f5299034ac80f6a681b06f89e65866ce91f356ed7c72af059c' is not from allowed registry 'ghcr.io/x-brain-cdo-09/'
```

---

### Phần 2: LAB 2 — ESO & Trivy & Cosign + Alerts

#### 1. Đồng bộ Secrets từ AWS Secrets Manager qua ESO
*   Các cấu hình SecretStore và ExternalSecret đã tự động liên kết và giải mã secret thành công.
*   **Danh sách tài nguyên ESO trên cluster:**
```bash
$ kubectl get secretstores,externalsecrets --all-namespaces
NAMESPACE    NAME                                                   AGE     STATUS   CAPABILITIES   READY
demo         secretstore.external-secrets.io/aws-store              113m    Valid    ReadWrite      True
monitoring   secretstore.external-secrets.io/aws-store-monitoring   6m40s   Valid    ReadWrite      True

NAMESPACE    NAME                                                        STORE                  REFRESH INTERVAL   STATUS         READY
demo         externalsecret.external-secrets.io/db-creds                 aws-store              10s                SecretSynced   True
monitoring   externalsecret.external-secrets.io/alertmanager-email-eso   aws-store-monitoring   1m                 SecretSynced   True
```
*   **Secret của Database (`db-secret`) được giải mã và đồng bộ thành công:**
```bash
$ kubectl get secret db-secret -n demo -o yaml
apiVersion: v1
data:
  password: eyJwYXNzd29yZCI6IlRoaXRoaXRoaUAwMzA1MDQifQ== # -> Giải mã: {"password":"Thithithiti@030504"}
kind: Secret
metadata:
  name: db-secret
  namespace: demo
```

#### 2. Kênh cảnh báo Alertmanager SMTP (ESO Managed)
*   Mật khẩu Gmail App Password (`fzpxdgferuhralfw`) được lấy từ AWS Secrets Manager (`prod/alertmanager/email`) thông qua ExternalSecret `alertmanager-email-eso` trong namespace `monitoring`.
*   Kubernetes Secret `alertmanager-email` được tự động khởi tạo:
```bash
$ kubectl get secret alertmanager-email -n monitoring -o yaml
apiVersion: v1
data:
  password: ZnpweGRnZmVydWhyYWxmdw== # -> Giải mã: fzpxdgferuhralfw
kind: Secret
metadata:
  name: alertmanager-email
  namespace: monitoring
```

#### 3. Chính sách Cosign Signature Verification
*   Chúng ta triển khai [ClusterImagePolicy](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/policies/cluster-image-policy.yaml) ở chế độ `enforce` để bảo đảm chỉ những image được ký bởi public key hợp lệ mới có thể chạy.
*   **Chi tiết ClusterImagePolicy:**
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

### Phần 3: Challenge — Namespace Isolation (Payments)

Thiết lập phân quyền đa người dùng (Multitenancy) để hoàn toàn cô lập namespace `payments` so với các namespace khác trên cluster bằng Resource Quotas, Limit Ranges và Network Policies.

#### 1. Trạng thái hoạt động của các Pod trong Payments Namespace
```bash
$ kubectl get pods -n payments -o wide
NAME                            READY   STATUS    RESTARTS   AGE   IP            NODE
payments-api-7ffff4757c-kkg7m   1/1     Running   0          52m   10.244.0.35   minikube
payments-api-7ffff4757c-kl2f5   1/1     Running   0          52m   10.244.0.36   minikube
```

#### 2. Cấu hình cô lập mạng lưới (Network Policies)
Ngăn chặn toàn bộ kết nối đi vào (ingress) từ các namespace khác, chỉ cho phép kết nối nội bộ trong cùng namespace `payments` và phân giải DNS.
```bash
$ kubectl get networkpolicies -n payments
NAME                           POD-SELECTOR   AGE
allow-same-ns-egress-and-dns   <none>         60m
deny-all-ingress               <none>         60m
```

#### 3. Giới hạn tài nguyên (ResourceQuota & LimitRange)
*   **ResourceQuota**: Khống chế tổng dung lượng CPU/Memory mà namespace này được sử dụng trên cluster:
```bash
$ kubectl get resourcequota payments-quota -n payments
NAME                           REQUEST                                                LIMIT
resourcequota/payments-quota   requests.cpu: 100m/200m, requests.memory: 64Mi/128Mi   limits.cpu: 200m/500m, limits.memory: 128Mi/256Mi
```
*   **LimitRange**: Áp đặt giới hạn CPU/Memory mặc định cho từng container khởi chạy trong namespace `payments`:
```bash
$ kubectl describe limitrange payments-limitrange -n payments
Name:       payments-limitrange
Namespace:  payments
Type        Resource  Min   Max      Default Request  Default Limit  Max Limit/Request Ratio
----        --------  ---   ---      ---------------  -------------  -----------------------
Container   cpu       10m   200m     50m              100m           -
Container   memory    16Mi  128Mi    32Mi             64Mi           -
```
