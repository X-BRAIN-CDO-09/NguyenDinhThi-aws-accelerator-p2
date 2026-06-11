# Báo cáo thu hoạch tuần W9: Deliver Smartly

Tuần này tập trung nâng cấp hệ thống W8 từ việc triển khai thủ công lên triển khai tự động hóa bằng GitOps (ArgoCD), đo lường mức độ tin cậy dịch vụ qua Observability (SLO/SLI, OTel, Prometheus, Grafana) và quản trị rủi ro deploy bằng Progressive Delivery (Canary Deploy + Auto-abort với Argo Rollouts).

---

## 1. Day A: GitOps & CI/CD
### Kiến thức cốt lõi:
- **GitOps:** Mô hình quản lý hạ tầng và ứng dụng trong đó Git đóng vai trò là "Single Source of Truth". Trạng thái mong muốn (Desired State) của hệ thống được khai báo trong Git và tự động đồng bộ xuống Cluster.
- **ArgoCD:** Công cụ GitOps hoạt động theo cơ chế Pull Model. Nó liên tục so sánh trạng thái trên Git và Cluster, tự động áp dụng các thay đổi (Auto-Sync) và sửa chữa các sai lệch thủ công ngoài ý muốn (Self-Healing).
- **CI/CD Pipeline (GitHub Actions):** Tách biệt CI (kiểm thử, lint manifest trên Pull Request) và CD (ArgoCD tự động kéo manifest mới sau khi PR được merge vào nhánh chính).

### Các cấu hình đã làm:
- [argocd-app.yaml](file:///e:/x-brain/w9/day-a/argocd-app.yaml): Định nghĩa ArgoCD Application theo dõi thư mục chứa manifests của ứng dụng.
- [k8s-manifests.yaml](file:///e:/x-brain/w9/day-a/k8s-manifests.yaml): Manifests chuẩn hóa của ứng dụng gồm Namespace, ConfigMap (chứa file HTML hỗ trợ giao diện Dark/Light mode), Deployment và Service.
- [gitops-pipeline.yaml](file:///e:/x-brain/w9/day-a/gitops-pipeline.yaml): GitHub Actions pipeline để kiểm định chất lượng tệp tin cấu hình (kube-linter & dry-run apply) trước khi merge.

---

## 2. Day B: Observability
### Kiến thức cốt lõi:
- **SLI (Service Level Indicator) & SLO (Service Level Objective):**
  - **Availability SLI:** Tỷ lệ số request thành công (2xx) chia cho tổng số request.
  - **SLO:** Mục tiêu độ tin cậy mong muốn, ví dụ: 99.0% availability trong vòng 30 ngày.
- **Error Budget & Burn Rate Alert:**
  - **Error Budget:** Lượng sai số cho phép (100% - SLO). Với SLO 99%, ngân sách lỗi là 1%.
  - **Burn Rate:** Tốc độ tiêu thụ Error Budget. Cảnh báo đa cửa sổ (Multi-window burn rate alert) giúp phát hiện nhanh các sự cố nghiêm trọng (Fast burn) và các lỗi rò rỉ âm thầm kéo dài (Slow burn).
- **OpenTelemetry Collector:** Cầu nối nhận dữ liệu telemetry (metrics, traces, logs) từ ứng dụng, xử lý (batching, filtering) và export sang Prometheus / Loki.

### Các cấu hình đã làm:
- [otel-collector.yaml](file:///e:/x-brain/w9/day-b/otel-collector.yaml): Cấu hình OpenTelemetry Collector nhận data OTLP và cào metric ứng dụng đưa về Prometheus.
- [alerts-burn-rate.yaml](file:///e:/x-brain/w9/day-b/alerts-burn-rate.yaml): Cấu hình luật cảnh báo PrometheusRule cho Fast Burn (1h/5m) và Slow Burn (6h/30m).
- [grafana-slo-dashboard.json](file:///e:/x-brain/w9/day-b/grafana-slo-dashboard.json): File JSON dashboard hiển thị trực quan SLI/SLO trạng thái và biểu đồ lỗi.

---

## 3. Day C: Progressive Delivery (Canary)
### Kiến thức cốt lõi:
- **Argo Rollouts:** Bộ điều khiển thay thế Kubernetes Deployment mặc định để hỗ trợ các chiến lược deploy nâng cao như Canary và Blue-Green.
- **Canary Steps:** Chia nhỏ tỷ lệ traffic tiếp cận phiên bản mới (ví dụ: 20% -> pause -> 50% -> pause -> 100%).
- **Automated Rollback (Auto-abort):** Sử dụng `AnalysisTemplate` để liên tục truy vấn Prometheus. Nếu tỉ lệ lỗi tăng cao (success rate < 95%), đợt rollout sẽ lập tức bị hủy bỏ (Abort) và tự động khôi phục lại phiên bản cũ an toàn mà không cần con người can thiệp.

### Các cấu hình đã làm:
- [rollout.yaml](file:///e:/x-brain/w9/day-c/rollout.yaml): Cấu hình tiến trình Canary thay cho Deployment truyền thống.
- [analysis-template.yaml](file:///e:/x-brain/w9/day-c/analysis-template.yaml): Template định nghĩa điều kiện kiểm tra tỉ lệ thành công dựa trên PromQL query.

---

## 4. Hướng dẫn thực hành Lab tích hợp
Tất cả mã nguồn và script tự động hóa được đặt trong thư mục [lab/](file:///e:/x-brain/w9/lab/).

1. **Khởi chạy hạ tầng:** Chạy script [setup-all.sh](file:///e:/x-brain/w9/lab/setup-all.sh) để cài đặt ArgoCD, Argo Rollouts, Prometheus, Grafana và deploy ứng dụng qua GitOps:
   ```bash
   cd e:/x-brain/w9/lab
   chmod +x setup-all.sh
   ./setup-all.sh
   ```
2. **Kiểm thử tải & Giả lập lỗi:** Sử dụng script [k6-load-test.js](file:///e:/x-brain/w9/lab/k6-load-test.js) để gửi traffic. k6 sẽ chủ động gửi ~15% request lỗi (truy cập đường dẫn sai) để kiểm thử cơ chế tự động Abort của Canary:
   ```bash
   # Cài đặt k6 nếu chưa có
   # Chạy test tải
   TARGET_URL=http://<IP_MINIKUBE>:30080 k6 run k6-load-test.js
   ```
3. **Quan sát:** Theo dõi tiến trình Rollout rollback tự động bằng cách chạy:
   ```bash
   kubectl argo rollouts get rollout simple-app -n app --watch
   ```
   Hoặc truy cập Grafana và ArgoCD theo hướng dẫn hiển thị khi chạy xong `setup-all.sh`.
