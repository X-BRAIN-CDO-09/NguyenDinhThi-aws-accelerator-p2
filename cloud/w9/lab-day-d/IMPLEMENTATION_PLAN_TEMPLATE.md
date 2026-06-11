# Hướng Dẫn & Mẫu Lên Kế Hoạch Triển Khai (Implementation Plan) Cho Dự Án Frontend & Backend

Để triển khai thành công một hệ thống gồm cả Frontend và Backend bằng bộ công nghệ GitOps (ArgoCD) + Kubernetes + Observability + Progressive Delivery, bạn cần lập một **Bản kế hoạch triển khai (Implementation Plan)** chi tiết. 

Dưới đây là cấu trúc chuẩn và các bước chuẩn bị giúp bạn lên kế hoạch hiệu quả:

---

## PHẦN 1: CÁC TIÊU CHÍ CẦN XÁC ĐỊNH TRƯỚC KHI VIẾT PLAN

Trước khi bắt đầu gõ code, bạn phải trả lời được 4 câu hỏi kiến trúc cốt lõi:

1.  **Mạng (Networking):** Frontend làm thế nào để gọi tới Backend? 
    *   *Giải pháp:* Sử dụng dịch vụ DNS nội bộ của Kubernetes. Ví dụ: Frontend sẽ gọi tới URL `http://backend-service.<namespace>.svc.cluster.local`.
2.  **Lưu trữ bí mật (Secrets):** Các thông tin nhạy cảm của Backend (Password Database, API Key) được lưu trữ ở đâu?
    *   *Giải pháp:* Định nghĩa dưới dạng Kubernetes `Secret`. Tránh tuyệt đối việc push mật khẩu trực tiếp lên mã nguồn GitHub.
3.  **Chiến lược phát hành (Deployment Strategy):** Ứng dụng nào cần Canary Deploy?
    *   *Giải pháp:* Backend hoặc API core thường là nơi chứa nhiều rủi ro lỗi logic nhất $\rightarrow$ Dùng `Argo Rollout` (Canary). Frontend thường có thể dùng Deployment truyền thống hoặc Rollout tùy nhu cầu.
4.  **Chỉ số đo lường độ tin cậy (SLO/SLI):** 
    *   *Giải pháp:* Xác định chỉ số Availability SLO (ví dụ: 99%) và thiết lập OTel Collector cào metric từ cổng ứng dụng để phục vụ tính năng tự động rollback.

---

## PHẦN 2: MẪU BẢN KẾ HOẠCH TRIỂN KHAI (TEMPLATE)

*Bạn có thể copy mẫu dưới đây để viết tài liệu thiết kế dự án của mình:*

```markdown
# Bản Kế Hoạch Triển Khai: Hệ Thống Frontend & Backend Trên Kubernetes Bằng GitOps

## 1. Bối Cảnh & Mục Tiêu (Goal Description)
Triển khai hệ thống ứng dụng 3-Tier (Frontend + Backend + Database) lên cụm Kubernetes. Hệ thống yêu cầu tự động hóa triển khai 100% bằng GitOps (ArgoCD), giám sát sức khỏe dịch vụ (Prometheus/Grafana) và giảm thiểu rủi ro khi phát hành tính năng mới bằng Canary Deployment.

## 2. Kiến Trúc Mạng & Luồng Hoạt Động (Architecture Flow)
*   **Frontend Service:** Expose ra ngoài qua NodePort (hoặc Ingress/LoadBalancer) để người dùng truy cập.
*   **Backend Service:** Chỉ mở kết nối nội bộ trong cluster. Frontend gọi Backend thông qua Kubernetes DNS: `http://backend-service.demo.svc.cluster.local`.
*   **Database:** Triển khai một pod PostgreSQL nội bộ hoặc sử dụng AWS RDS (nếu chạy trên cloud).

---

## 3. Cấu Trúc Thư Mục GitOps (Folder Structure)
Hệ thống quản lý theo mô hình App-of-Apps được cấu trúc như sau:

```text
gitops-repo/
  ├── argocd/
  │    ├── root.yaml           # Root App (Đăng ký 1 lần với ArgoCD)
  │    └── apps/
  │         ├── frontend.yaml  # Chỉ dẫn deploy Frontend
  │         └── backend.yaml   # Chỉ dẫn deploy Backend
  │
  ├── frontend/
  │    └── k8s/
  │         ├── deployment.yaml
  │         ├── service.yaml
  │         └── configmap.yaml
  │
  └── backend/
       └── k8s/
            ├── rollout.yaml   # Sử dụng Rollout thay thế Deployment để chạy Canary
            ├── service.yaml
            ├── secret.yaml    # Chứa DB credentials (mã hóa base64)
            └── analysis.yaml  # Phân tích tự động tỷ lệ thành công của Backend
```

---

## 4. Chi Tiết Các File Cần Xây Dựng (Proposed Changes)

### A. Cấu phần Quản lý (GitOps Bootstrap)
*   **[NEW] `argocd/root.yaml`**: Khởi tạo Root App quét thư mục `argocd/apps/`.
*   **[NEW] `argocd/apps/frontend.yaml`**: Định nghĩa Application K8s trỏ tới `frontend/k8s`.
*   **[NEW] `argocd/apps/backend.yaml`**: Định nghĩa Application K8s trỏ tới `backend/k8s`.

### B. Cấu phần Backend (Canary + Database Connection)
*   **[NEW] `backend/k8s/rollout.yaml`**: 
    *   Sử dụng `kind: Rollout` (API `argoproj.io/v1alpha1`).
    *   Định nghĩa Canary Steps: 10% traffic (đợi 1 phút) -> 50% (đợi 2 phút) -> 100%.
    *   Liên kết với `AnalysisTemplate` để đo đạc lỗi.
    *   Đọc biến môi trường kết nối DB từ Secret.
*   **[NEW] `backend/k8s/secret.yaml`**: Chứa mật khẩu kết nối cơ sở dữ liệu dạng mã hóa Base64.

### C. Cấu phần Frontend (User UI + API Fetching)
*   **[NEW] `frontend/k8s/deployment.yaml`**: Chạy giao diện Web (React/Nginx), có tích hợp giao diện Dark/Light mode.
*   **[NEW] `frontend/k8s/configmap.yaml`**: Cấu hình các biến môi trường cho Frontend (như Endpoint URL của Backend).

---

## 5. Kịch Bản Kiểm Thử & Xác Thực (Verification Plan)

### A. Kiểm thử GitOps & Thứ tự chạy (Sync Waves Verification)
1.  Chạy lệnh đăng ký Root App: `kubectl apply -f argocd/root.yaml`.
2.  Quan sát trên giao diện ArgoCD xem các ứng dụng con `frontend` và `backend` có tự động được sinh ra và chạy đúng thứ tự không.

### B. Kiểm thử Canary & Tự động Rollback (Progressive Delivery Test)
1.  Thực hiện cập nhật phiên bản Backend mới bằng cách sửa tag image trong file `backend/k8s/rollout.yaml` và `git push`.
2.  Chạy công cụ tạo tải giả lập lỗi (ví dụ: k6 hoặc locust) hướng vào Backend.
3.  Quan sát lệnh: `kubectl argo rollouts get rollout backend -n demo --watch`.
4.  Xác nhận: Khi tỷ lệ lỗi vượt ngưỡng, Argo Rollouts lập tức tự động hủy bỏ đợt cập nhật (Abort) và rollback về phiên bản cũ an toàn.
```
