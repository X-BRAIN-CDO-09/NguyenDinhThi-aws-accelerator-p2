# CẨM NANG THUYẾT TRÌNH BẢO VỆ BÀI LAB TUẦN 10
## Dành cho học viên: Nguyễn Đình Thi — Lớp X-BRAIN CDO-09

Tài liệu này hướng dẫn bạn cấu trúc bài thuyết trình cho Mentor theo trình tự logic, giải thích chi tiết ý nghĩa từng thuật ngữ, cách các dòng code liên kết với nhau để đạt hiệu quả cao nhất.

---

## 🗺️ LUỒNG THUYẾT TRÌNH KHUYÊN DÙNG (PRESENTATION FLOW)

Bạn nên dẫn dắt bài thuyết trình theo 4 bước sau:
1.  **Đặt vấn đề & Triết lý**: Trình bày triết lý thiết kế hệ thống bảo mật tuần này.
2.  **Phần 1: LAB 1 (RBAC + Gatekeeper)**: Thiết lập chốt chặn phân quyền và kiểm duyệt cấu hình.
3.  **Phần 2: LAB 2 (Secrets Manager + Supply Chain + Alerts)**: Tích hợp SecOps tự động và bảo vệ chuỗi cung ứng.
4.  **Phần 3: Challenge (Cô lập Payments Namespace)**: Chứng minh khả năng đa người dùng (multitenancy) và cách ly mạng lưới/tài nguyên.

---

## 💡 GIẢI THÍCH THUẬT NGỮ CƠ BẢN (DÀNH CHO NGƯỜI MỚI)

*   **`namespace: demo`**: 
    *   *Ý nghĩa*: Namespace (Không gian tên) giống như một căn phòng riêng biệt trong ngôi nhà lớn (Cluster). 
    *   *Tác dụng*: Việc chỉ định `namespace: demo` đảm bảo các ứng dụng thông thường của nhà phát triển (như API, Database) được gom nhóm lại một nơi để dễ quản lý, tránh việc ảnh hưởng hay xung đột tài nguyên với các phòng ban/dự án khác (như `payments` hay `monitoring`).
*   **`namespace: monitoring`**: Phòng điều khiển trung tâm chứa Prometheus, Grafana, Alertmanager để giám sát toàn bộ cluster.
*   **`namespace: payments`**: Căn phòng bảo mật cao dành riêng cho ứng dụng tài chính nhạy cảm, được cách ly hoàn toàn.
*   **`sync-wave`**: Thứ tự triển khai các ứng dụng của ArgoCD (giá trị nhỏ chạy trước, giá trị lớn chạy sau). Ví dụ: Wave `-1` cài đặt ESO Operator, Wave `3` mới deploy cấu hình SecretStore.

---

## 📘 CHI TIẾT CÁC BÀI THUYẾT TRÌNH & SỰ LIÊN KẾT MÃ NGUỒN

---

### PHẦN 1: LAB 1 — RBAC & GATEKEEPER GUARDRAILS

> **Ý tưởng mở đầu**: *"Thưa mentor, để bảo vệ cluster, lớp phòng thủ đầu tiên là kiểm soát xem ai được quyền làm gì (RBAC) và cấu hình của họ gửi lên có an toàn không (Gatekeeper)."*

#### 1. Chốt chặn phân quyền: RBAC
*   **File nói đến đầu tiên**: [roles.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/rbac/roles.yaml) và [rolebindings.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/rbac/rolebindings.yaml).
*   **Mối liên kết trong code**:
    *   Trong `roles.yaml` (dòng 1-13), định nghĩa `Role` có tên là `developer` trong `namespace: demo`. Role này chỉ cho phép `verbs: ["get", "list", "watch", "create", "update", "patch"]` trên các resources workloads, tuyệt đối không có quyền xem `secrets`.
    *   Trong `rolebindings.yaml` (dòng 1-12), định nghĩa `RoleBinding` kết nối `roleRef.name: developer` với đối tượng người dùng `subjects[0].name: alice`.
    *   **Kết quả**: User `alice` bị giới hạn quyền tối thiểu (Least Privilege), không thể can thiệp vào các tài nguyên hệ thống khác.

#### 2. Kiểm duyệt cấu hình đầu vào: OPA Gatekeeper
*   **Cơ chế liên kết**:
    *   **ConstraintTemplate** (Khuôn mẫu): Nơi chứa logic kiểm tra bằng ngôn ngữ Rego (Ví dụ: [ct-allowed-registry.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/argocd/gatekeeper/templates/ct-allowed-registry.yaml)).
    *   **Constraint** (Áp dụng luật): [c-allowed-registry.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/argocd/gatekeeper/constraints/c-allowed-registry.yaml).
    *   **Dòng code liên kết**:
        Trong file Constraint, khai báo `kind: K8sAllowedRegistry` (dòng 2) trùng khớp với `spec.crd.spec.names.kind: K8sAllowedRegistry` được định nghĩa trong ConstraintTemplate. Phần `spec.parameters.registry` (dòng 9) truyền danh sách registry cho phép là `ghcr.io/x-brain-cdo-09/` sang cho mã Rego kiểm tra.

---

### PHẦN 2: LAB 2 — SECRETS MANAGEMENT, SUPPLY CHAIN & ALERTS

> **Ý tưởng mở đầu**: *"Lớp phòng thủ thứ hai là tự động hóa SecOps: Bảo mật mật khẩu qua AWS Secrets Manager và bảo vệ chuỗi cung ứng bằng chữ ký số."*

#### 1. Quản lý bí mật: ESO + AWS Secrets Manager
*   **File nói đến đầu tiên**: [secret-store.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/k8s-eso/secret-store.yaml) và [external-secret.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/k8s-eso/external-secret.yaml).
*   **Mối liên kết trong code**:
    1.  Trên Kubernetes, ta tạo thủ công Secret `aws-creds` chứa AWS IAM credentials.
    2.  Trong `secret-store.yaml`, ta khai báo `aws-store` SecretStore liên kết tới AWS Secrets Manager ở region `ap-southeast-1` bằng cách tham chiếu tới Secret vừa tạo qua khối `auth.secretRef.accessKeyIDSecretRef.name: aws-creds`.
    3.  Trong `external-secret.yaml`, ta khai báo `ExternalSecret` liên kết với SecretStore qua `spec.secretStoreRef.name: aws-store` (dòng 12), trỏ tới secret trên AWS qua `remoteRef.key: prod/db/password` (dòng 20) và tự động ghi vào Kubernetes Secret có tên là `db-secret` (`spec.target.name: db-secret`, dòng 15).

#### 2. Kênh cảnh báo SMTP Alertmanager an toàn
*   **Cơ chế liên kết tương tự**:
    *   SecretStore [secret-store.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/app-alert/secret-store.yaml) được tạo ở `namespace: monitoring`.
    *   ExternalSecret [external-secret.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/app-alert/external-secret.yaml) đồng bộ `prod/alertmanager/email` từ AWS vào Kubernetes Secret `alertmanager-email` trong namespace `monitoring`.
    *   Trong cấu hình Helm Chart của Prometheus [k8s-prometheus.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/argocd/apps/k8s-prometheus.yaml):
        *   Dòng 43: Chỉ định file đọc password: `auth_password_file: /etc/alertmanager/secrets/alertmanager-email/password`.
        *   Dòng 109-110: Mount secret vào pod Alertmanager qua `alertmanagerSpec.secrets: ["alertmanager-email"]`.

#### 3. Chuỗi cung ứng an toàn: Trivy Scan + Cosign Verification
*   **File nói đến đầu tiên**: [.github/workflows/build-push.yml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/.github/workflows/build-push.yml) (nằm ngoài lab-temp, cấu hình CI/CD) và [cluster-image-policy.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/policies/cluster-image-policy.yaml).
*   **Mối liên kết trong code**:
    1.  Trong CI/CD pipeline, sau khi build image sẽ chạy quét Trivy tìm lỗ hổng. Nếu an toàn, image mới được push lên và ký số bằng khóa riêng (Private Key) thông qua lệnh `cosign sign`.
    2.  Trong `cluster-image-policy.yaml`, ta cấu hình `ClusterImagePolicy` với chế độ `mode: enforce` (dòng 23) và dán khóa công khai (Public Key) tương ứng vào `authorities[0].key.data` (dòng 12-16).
    3.  Khi có Pod API triển khai, Sigstore Policy Controller chặn lại, dùng Public Key này giải mã chữ ký đi kèm image. Nếu chữ ký không khớp hoặc chưa ký, Pod sẽ bị từ chối chạy ngay lập tức.

---

### PHẦN 3: CHALLENGE — MULTITENANCY NAMESPACE ISOLATION (PAYMENTS)

> **Ý tưởng mở đầu**: *"Cuối cùng là phần Challenge, em đã cấu hình cô lập hoàn toàn một namespace nhạy cảm có tên là payments để tránh lây nhiễm chéo hoặc ảnh hưởng tài nguyên giữa các tenant trên cùng một cluster."*

*   **Các file chính**: Nằm trong thư mục [tenants/payments/](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/tenants/payments/).
*   **Ba lớp cô lập cốt lõi**:
    1.  **Cách ly tài nguyên (ResourceQuota)**: File [quota.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/tenants/payments/quota.yaml) khống chế tổng tài nguyên tối đa (CPU/Memory limits) mà các Pods trong namespace `payments` có thể sử dụng (requests.cpu tối đa 200m, requests.memory tối đa 128Mi).
    2.  **Mặc định tài nguyên (LimitRange)**: File [limitrange.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/tenants/payments/limitrange.yaml) chỉ định rõ cấu hình CPU/Memory mặc định cho mọi Container tạo trong payments (nếu nhà phát triển quên cấu hình).
    3.  **Cách ly mạng lưới (NetworkPolicy)**: File [netpol.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/tenants/payments/netpol.yaml).
        *   Mặc định chặn toàn bộ Ingress (kết nối đi vào) bằng `deny-all-ingress`.
        *   Chỉ cho phép Egress (kết nối đi ra) đến các Pod trong cùng namespace `payments` (`podSelector: {}`) và cổng 53 đến `kube-system` để phân giải DNS.
        *   **Giải thích kết quả**: Do không khai báo kết nối tới namespace `demo`, bất kỳ nỗ lực nào từ pod của `payments` gọi sang `demo` đều bị NetworkPolicy chặn đứng, gây ra lỗi **Connection Timeout**.
