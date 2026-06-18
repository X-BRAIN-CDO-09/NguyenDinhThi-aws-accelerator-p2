# W10 Lab — Security GitOps: Payments Tenant Deployment

Tài liệu này giải thích thiết kế cô lập an toàn cho **Tenant `payments`** (Team B) khi đưa vào hệ thống platform.

---

## 1. Giải thích thiết kế bảo mật & cô lập

### Câu hỏi 1: Vì sao các chính sách bảo mật (guardrails) cũ tự động áp dụng cho Team B mà không cần viết luật mới?
* **Cơ chế hoạt động:** Các chính sách bảo mật của **Gatekeeper (Constraints)** và **Sigstore (ClusterImagePolicy)** được định nghĩa ở cấp độ **Cluster-wide** (quy mô toàn cụm).
* **Áp dụng tự động:** 
  * Các Constraint của Gatekeeper (như cấm chạy root, cấm tag latest, yêu cầu resource limits) được cấu hình áp dụng cho mọi namespace ngoại trừ một số namespace hệ thống được loại trừ cụ thể (như `kube-system`, `argocd`).
  * Sigstore `ClusterImagePolicy` quét tất cả các Pod dựa trên namespace được đánh nhãn `policy.sigstore.dev/include: "true"`.
  * Do đó, khi tạo mới namespace `payments` và triển khai ứng dụng của Team B, các luật này sẽ **tự động chặn và kiểm tra** mà không cần lập trình hay viết thêm bất kỳ luật bảo mật nào mới.

### Câu hỏi 2: Role/RoleBinding khác biệt thế nào so với ClusterRoleBinding để giữ tính cô lập?
* **Role & RoleBinding (Namespace-scoped):**
  * Quyền hạn được giới hạn nghiêm ngặt bên trong **duy nhất một Namespace** (ở đây là namespace `payments`).
  * Tài khoản `payments-dev` được liên kết với `payments-dev-role` thông qua `RoleBinding` tại namespace `payments`. Điều này đảm bảo họ có toàn quyền quản lý ứng dụng của mình nhưng **hoàn toàn không thể** xem, sửa hoặc xóa bất kỳ tài nguyên nào ở namespace khác (như `demo` hay `kube-system`).
* **ClusterRoleBinding (Cluster-scoped):**
  * Liên kết quyền hạn trên **toàn bộ Cluster** (tất cả namespaces).
  * Nếu sử dụng `ClusterRoleBinding` cho `payments-dev`, họ sẽ có quyền hạn xuyên suốt mọi namespace, phá vỡ nguyên lý cô lập đa người dùng (Multi-tenancy) và vi phạm nguyên tắc đặc quyền tối thiểu (Least Privilege).

---

## 2. Các thành phần đã triển khai (GitOps)

Toàn bộ hạ tầng và ứng dụng của team `payments` được quản lý qua GitOps:
* **Hạ tầng (`tenants/payments/`):**
  * [ns.yaml](ns.yaml): Tạo namespace `payments` có đánh nhãn quét chữ ký số.
  * [rbac.yaml](rbac.yaml): Phân quyền hạn chế cho `payments-dev` (chỉ thao tác workload, không được xem secrets/rolebindings).
  * [quota.yaml](quota.yaml): Giới hạn tài nguyên tối đa (CPU/Memory) của namespace `payments`.
  * [limitrange.yaml](limitrange.yaml): Thiết lập cấu hình CPU/Memory mặc định cho các Pod không khai báo limit.
  * [netpol.yaml](netpol.yaml): Cấu hình NetworkPolicy cách ly mạng (chặn tất cả Ingress từ ngoài vào và chỉ cho phép Egress nội bộ + DNS).
* **Ứng dụng (`apps/payments/`):**
  * [app.yaml](app.yaml): Deploy ứng dụng `payments-api` sử dụng Docker image đã được ký số hợp lệ của bạn.
* **ArgoCD Apps (`argocd/apps/`):**
  * [payments.yaml](../../argocd/apps/payments.yaml): Ứng dụng ArgoCD quản lý hạ tầng tenant.
  * [payments-app.yaml](../../argocd/apps/payments-app.yaml): Ứng dụng ArgoCD quản lý deploy workload.
