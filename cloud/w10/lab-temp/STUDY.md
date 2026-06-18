# CẨM NANG THUYẾT TRÌNH BẢO VỆ BÀI LAB TUẦN 10
## Dành cho học viên: Nguyễn Đình Thi — Lớp X-BRAIN CDO-09

Tài liệu này hướng dẫn bạn cấu trúc bài thuyết trình cho Mentor theo trình tự logic, giải thích chi tiết ý nghĩa từng thuật ngữ, và đính kèm các đoạn mã nguồn (code snippets) cụ thể để giải thích sự liên kết giữa các file.

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
*   **File nói đến đầu tiên**: [rbac/roles.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/rbac/roles.yaml) (Dòng 6-39) và [rbac/rolebindings.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/rbac/rolebindings.yaml) (Dòng 2-14).
*   **Mối liên kết trong code**:
    *   Trong `roles.yaml` định nghĩa `Role` tên là `developer` trong namespace `demo` để hạn chế quyền của nhà phát triển:
    ```yaml
    # roles.yaml (Dòng 6-20)
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: developer
      namespace: demo # Scoped chỉ trong namespace demo
    rules:
      - apiGroups: ["", "apps"]
        resources:
          - deployments
          - pods
          - services
          - replicasets
          - statefulsets
          - daemonsets
        verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]
    ```
    *   Trong `rolebindings.yaml` liên kết Role này với user `alice`:
    ```yaml
    # rolebindings.yaml (Dòng 2-14)
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: alice-developer
      namespace: demo
    subjects:
      - kind: User
        name: alice # Liên kết với user alice
        apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: Role
      name: developer # Chỉ định phân quyền từ Role developer ở trên
      apiGroup: rbac.authorization.k8s.io
    ```
    *   **Ý nghĩa**: Alice chỉ được làm việc trong phòng `demo` và chỉ được thao tác các tài nguyên được khai báo trong `roles.yaml` (không có quyền đọc `secrets` hay xem `nodes`).

#### 2. Kiểm duyệt cấu hình đầu vào: OPA Gatekeeper
*   **Cơ chế liên kết**:
    *   **ConstraintTemplate** (Định nghĩa logic Rego): ví dụ [ct-allowed-registry.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/argocd/gatekeeper/templates/ct-allowed-registry.yaml) quy định loại tài nguyên kiểm tra là `K8sAllowedRegistry`.
    *   **Constraint** (Truyền tham số cấu hình): [c-allowed-registry.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/argocd/gatekeeper/constraints/c-allowed-registry.yaml).
    ```yaml
    # c-allowed-registry.yaml (Toàn bộ file)
    apiVersion: constraints.gatekeeper.sh/v1beta1
    kind: K8sAllowedRegistry # Trùng khớp với tên kind khai báo trong ConstraintTemplate
    metadata:
      name: allowed-registry
      annotations:
        argocd.argoproj.io/sync-wave: "2"
    spec:
      enforcementAction: deny # Từ chối yêu cầu nếu vi phạm
      match:
        kinds:
          - apiGroups: [""]
            kinds: ["Pod"]
        namespaces:
          - demo # Chỉ áp đặt luật này lên namespace demo
      parameters:
        allowedRegistry: "ghcr.io/x-brain-cdo-09/" # Truyền registry cho phép sang Rego
    ```

---

### PHẦN 2: LAB 2 — SECRETS MANAGEMENT, SUPPLY CHAIN & ALERTS

> **Ý tưởng mở đầu**: *"Lớp phòng thủ thứ hai là tự động hóa SecOps: Bảo mật mật khẩu qua AWS Secrets Manager và bảo vệ chuỗi cung ứng bằng chữ ký số."*

#### 1. Quản lý bí mật: ESO + AWS Secrets Manager
*   **Các file**: [secret-store.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/k8s-eso/secret-store.yaml) và [external-secret.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/k8s-eso/external-secret.yaml).
*   **Mối liên kết trong code**:
    1.  SecretStore kết nối tới AWS Secrets Manager bằng `aws-creds` Kubernetes Secret:
    ```yaml
    # secret-store.yaml (Dòng 8-20)
    spec:
      provider:
        aws:
          service: SecretsManager
          region: ap-southeast-1
          auth:
            secretRef:
              accessKeyIDSecretRef:
                name: aws-creds # Trỏ tới K8s Secret chứa AWS Access Key
                key: access-key
              secretAccessKeySecretRef:
                name: aws-creds
                key: secret-key
    ```
    2.  ExternalSecret sử dụng SecretStore đó để đồng bộ mật khẩu DB về K8s Secret:
    ```yaml
    # external-secret.yaml (Dòng 11-23)
    spec:
      refreshInterval: 10s # Đồng bộ định kỳ 10s một lần
      secretStoreRef:
        name: aws-store # Gọi tên SecretStore đã định nghĩa ở trên
        kind: SecretStore
      target:
        name: db-secret # Tên Kubernetes Secret tự động tạo ra trên cụm
        creationPolicy: Owner
      data:
      - secretKey: password # Key ghi vào K8s secret
        remoteRef:
          key: prod/db/password # Key thực tế nằm trên AWS Secrets Manager
    ```

#### 2. Kênh cảnh báo SMTP Alertmanager an toàn
*   **Cơ chế liên kết**:
    *   ExternalSecret [external-secret.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/app-alert/external-secret.yaml) đồng bộ `prod/alertmanager/email` từ AWS vào Kubernetes Secret `alertmanager-email` trong namespace `monitoring`.
    *   Trong cấu hình Helm Chart của Prometheus [k8s-prometheus.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/argocd/apps/k8s-prometheus.yaml):
    ```yaml
    # k8s-prometheus.yaml (Trích xuất các dòng liên quan)
    # 1. Chỉ định file đọc password của Alertmanager SMTP
    auth_password_file: /etc/alertmanager/secrets/alertmanager-email/password
    
    # 2. Mount secret chứa password vào container Alertmanager
    alertmanagerSpec:
      secrets:
      - alertmanager-email
    ```

#### 3. Chuỗi cung ứng an toàn: Cosign Verification
*   **Các file**: [.github/workflows/build-push.yml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/.github/workflows/build-push.yml) (CI/CD pipeline) và [cluster-image-policy.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/policies/cluster-image-policy.yaml).
*   **Mối liên kết trong code**:
    1.  CI/CD pipeline ký số lên image: `cosign sign --yes --key env://COSIGN_PRIVATE_KEY ghcr.io/x-brain-cdo-09/nguyendinhthi-aws-accelerator-p2/w10-api:0.0.5`.
    2.  `ClusterImagePolicy` cấu hình xác minh bằng khóa công khai (Public Key) và khóa cứng cụm:
    ```yaml
    # cluster-image-policy.yaml (Trích xuất)
    spec:
      authorities:
      - key:
          data: | # Khóa công khai dùng để xác minh chữ ký của image
            -----BEGIN PUBLIC KEY-----
            MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE95AAuTY83Nrf/FI+Yti+3xOp3cNl
            JyklSH+0Cy6yC0V+f+cdBnXeDXaGqPn5XbavMpq1eedEd0FUV+xjSW1V5Q==
            -----END PUBLIC KEY-----
      images:
      - glob: ghcr.io/x-brain-cdo-09/nguyendinhthi-aws-accelerator-p2/* # Áp dụng cho mọi image trong repo này
      mode: enforce # Chế độ bắt buộc (từ chối chạy nếu image chưa được ký)
    ```

---

### PHẦN 3: CHALLENGE — MULTITENANCY NAMESPACE ISOLATION (PAYMENTS)

> **Ý tưởng mở đầu**: *"Cuối cùng là phần Challenge, em đã cấu hình cô lập hoàn toàn một namespace nhạy cảm có tên là payments để tránh lây nhiễm chéo hoặc ảnh hưởng tài nguyên giữa các tenant trên cùng một cụm."*

*   **File cách ly mạng lưới**: [netpol.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/tenants/payments/netpol.yaml) (Toàn bộ file).
*   **Cấu hình chi tiết NetworkPolicy**:
    ```yaml
    # netpol.yaml (Trích xuất luật cho phép đi ra - Egress)
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-same-ns-egress-and-dns
      namespace: payments
    spec:
      podSelector: {}
      policyTypes:
      - Egress
      egress:
      - to:
        - podSelector: {} # Chỉ cho phép gửi gói tin tới các Pod trong cùng namespace payments
      - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system # Chỉ cho phép truy cập DNS qua kube-system
        ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    ```
*   **Giải thích kết quả**: Do không khai báo bất kỳ đường truyền nào tới namespace `demo`, bất kỳ nỗ lực kết nối nào từ pod của `payments` sang `demo` đều bị NetworkPolicy chặn đứng, gây ra lỗi **Connection Timeout**.
