# KỊCH BẢN THUYẾT TRÌNH BẢO VỆ TUẦN W10
## Chủ đề: Security GitOps & Multitenancy Isolation (Payments)
*Học viên: Nguyễn Đình Thi*

---

## 📌 PHẦN MỞ ĐẦU: ĐẶT VẤN ĐỀ & TRIẾT LÝ THIẾT KẾ (Thời gian: 1 phút)

*   **Slide/Tài liệu trình chiếu**: [EVIDENCE.md](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/EVIDENCE.md) - Mục **I. SƠ ĐỒ KIẾN TRÚC TỔNG QUAN**.
*   **Hành động**: Chỉ vào sơ đồ kiến trúc tổng quan.
*   **Lời thoại nói**:
    > *"Em chào Mentor, hôm nay em xin phép trình bày báo cáo nghiệm thu bài Lab Tuần 10 về **Security GitOps & Multitenancy Isolation**.*
    > 
    > *Triết lý cốt lõi của bài lab này là **'Hệ thống tự động từ chối mọi cấu hình vi phạm ngay từ đầu, thay vì dựa vào lời hứa của nhà phát triển'**. Để đạt được mục tiêu đó, em thiết lập mô hình bảo mật nhiều lớp (Defense-in-Depth) bao gồm: Kiểm soát phân quyền tối thiểu (RBAC), Chính sách kiểm duyệt đầu vào (Gatekeeper), Tự động hóa SecOps (ESO + AWS Secrets Manager), Chuỗi cung ứng an toàn (Trivy + Cosign) và Cô lập đa người dùng (Payments Tenant)."*

---

## 🔒 BƯỚC 1: LAB 1 — PHÂN QUYỀN RBAC & GATEKEEPER GUARDRAILS (Thời gian: 2.5 phút)

### Ý 1. Phân quyền tối thiểu với RBAC
*   **Tài liệu trình chiếu**: File [roles.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/rbac/roles.yaml) (dòng 6-20) và [rolebindings.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/rbac/rolebindings.yaml) (dòng 2-14).
*   **Hành động**: Chỉ vào phần định nghĩa `Role` của `developer` và cách bind nó vào user `alice`.
*   **Lời thoại nói**:
    > *"Đầu tiên là lớp phân quyền. Em định nghĩa một Role tên là `developer` đặt trong namespace `demo`.*
    > 
    > *Role này chỉ cho phép User **alice** (qua RoleBinding `alice-developer`) được thao tác với Deployments, Pods, Services. Alice bị cấm hoàn toàn quyền xem K8s Secrets hay thực hiện các thao tác cấp cụm như xem thông tin Nodes.*
    > 
    > *Để chứng minh, em chạy lệnh kiểm tra trên cluster: `kubectl auth can-i create deployments --as=alice -n demo` kết quả trả về là **yes**, nhưng khi kiểm tra quyền xem secrets `kubectl auth can-i get secrets --as=alice -n demo` kết quả trả về là **no**."*

### Ý 2. Kiểm duyệt cấu hình với OPA Gatekeeper
*   **Tài liệu trình chiếu**: File [c-allowed-registry.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/argocd/gatekeeper/constraints/c-allowed-registry.yaml).
*   **Hành động**: Chỉ vào dòng `allowedRegistry: "ghcr.io/x-brain-cdo-09/"` và `enforcementAction: deny`.
*   **Lời thoại nói**:
    > *"Lớp tiếp theo là kiểm duyệt cấu hình thông qua **OPA Gatekeeper**.*
    > 
    > *Để kiểm soát an toàn, em áp dụng luật kiểm tra registry (`K8sAllowedRegistry`). Cấu hình chỉ cho phép chạy các pod sử dụng image từ registry `ghcr.io/x-brain-cdo-09/` trong namespace `demo`.*
    > 
    > *Minh chứng là khi chạy thử pod `nginx:1.25` công cộng từ Docker Hub, Admission Webhook của Gatekeeper lập tức chặn đứng yêu cầu và trả về lỗi: image không hợp lệ và thiếu cấu hình giới hạn tài nguyên CPU/Memory."*

---

## 🔑 BƯỚC 2: LAB 2 — SECRETS MANAGEMENT & SUPPLY CHAIN (Thời gian: 2.5 phút)

### Ý 1. Quản lý bí mật an toàn với ESO & AWS Secrets Manager
*   **Tài liệu trình chiếu**: File [secret-store.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/k8s-eso/secret-store.yaml) và [external-secret.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/k8s-eso/external-secret.yaml).
*   **Hành động**: Chỉ vào phần `auth.secretRef` trong SecretStore và `remoteRef.key: prod/db/password` trong ExternalSecret.
*   **Lời thoại nói**:
    > *"Về phần quản lý Secrets, để tránh lộ mật khẩu, em lưu trữ tập trung trên **AWS Secrets Manager**.*
    > 
    > *Trong cụm, em dùng **External Secrets Operator (ESO)**. SecretStore có tên `aws-store` sẽ xác thực với AWS thông qua K8s secret `aws-creds`. *
    > 
    > *Sau đó, ExternalSecret `db-creds` định kỳ kéo mật khẩu `prod/db/password` từ AWS Secrets Manager về cụm để tự động sinh ra K8s Secret `db-secret` mà không cần con người can thiệp thủ công."*

### Ý 2. SMTP Alertmanager tích hợp ESO
*   **Tài liệu trình chiếu**: File [external-secret.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/app-alert/external-secret.yaml) và [k8s-prometheus.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/argocd/apps/k8s-prometheus.yaml#L43).
*   **Hành động**: Chỉ vào dòng cấu hình file password của Alertmanager.
*   **Lời thoại nói**:
    > *"Tương tự như vậy, mật khẩu ứng dụng Gmail SMTP được lưu trữ trên AWS Secrets Manager (`prod/alertmanager/email`) và đồng bộ an toàn qua ESO vào namespace `monitoring` thành secret `alertmanager-email`.*
    > 
    > *Trong cấu hình Helm Chart của Prometheus, Alertmanager được khai báo đọc mật khẩu từ file `/etc/alertmanager/secrets/alertmanager-email/password` và tự động gửi email cảnh báo về hòm thư `thihtktk@gmail.com` khi có sự cố."*

### Ý 3. Supply Chain Security (Cosign Verification)
*   **Tài liệu trình chiếu**: File [cluster-image-policy.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/policies/cluster-image-policy.yaml).
*   **Hành động**: Chỉ vào dòng khai báo Public Key của Cosign trong file chính sách.
*   **Lời thoại nói**:
    > *"Cuối cùng trong Lab 2 là bảo vệ chuỗi cung ứng. Em chạy Trivy quét lỗ hổng trong CI pipeline, sau đó ký số vào image bằng Cosign.*
    > 
    > *Tại cụm Kubernetes, em cấu hình chính sách `ClusterImagePolicy` với khóa công khai tương ứng ở chế độ bắt buộc `mode: enforce`. Bất kỳ container image nào thuộc repository của em khi deploy lên mà chưa được ký bằng khóa riêng tương ứng sẽ bị controller từ chối chạy ngay lập tức."*

---

## 🛡️ BƯỚC 3: CHALLENGE — CO LẬP NAMESPACE PAYMENTS (Thời gian: 2 phút)

*   **Tài liệu trình chiếu**: File [netpol.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/tenants/payments/netpol.yaml) và [quota.yaml](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/tenants/payments/quota.yaml).
*   **Hành động**: Chỉ vào khối NetworkPolicy chiều đi ra (`Egress`) và các thông số ResourceQuota.
*   **Lời thoại nói**:
    > *"Cuối cùng là phần Challenge: **Cô lập hoàn toàn namespace payments** chứa ứng dụng giao dịch tài chính nhạy cảm.*
    > 
    > *Để tránh việc các namespace khác gây ảnh hưởng hoặc truy cập trái phép vào `payments`, em triển khai 3 lớp cô lập:*
    > *   *Thứ nhất: **ResourceQuota** giới hạn tổng lượng tài nguyên tối đa để tránh ứng dụng khác chiếm dụng (Noisy Neighbor).*
    > *   *Thứ hai: **LimitRange** thiết lập cấu hình CPU/Memory mặc định cho các pod.*
    > *   *Thứ ba: **NetworkPolicy** cô lập mạng lưới. Em cấu hình luật Ingress mặc định chặn toàn bộ kết nối đi vào (`deny-all-ingress`), và Egress chỉ cho phép gọi nội bộ trong cùng namespace cùng DNS tới `kube-system`.*
    > 
    > *Do không khai báo quyền truy cập tới namespace `demo`, mọi nỗ lực kết nối từ Pod của `payments` sang api của `demo` đều bị NetworkPolicy chặn đứng và báo lỗi Connection Timeout."*

---

## 🏁 PHẦN KẾT LUẬN (Thời gian: 1 phút)

*   **Tài liệu trình chiếu**: Giao diện ArgoCD UI [SS-01.png](file:///E:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/assets/SS-01.png).
*   **Hành động**: Chỉ vào hình ảnh Dashboard ArgoCD xanh mướt toàn bộ.
*   **Lời thoại nói**:
    > *"Tóm lại, toàn bộ cấu hình bài Lab 1, Lab 2 và phần Challenge đã được em triển khai đồng bộ hoàn toàn qua GitOps. Như trên màn hình, ArgoCD Dashboard hiển thị toàn bộ 16 ứng dụng con đã ở trạng thái **Synced** và **Healthy**.*
    > 
    > *Em xin cảm ơn Mentor đã theo dõi, em rất mong nhận được câu hỏi và đóng góp ý kiến từ Mentor để bài lab hoàn thiện hơn ạ!"*
