# ☸️ Cẩm Nang Nâng Cao: K8s Scaling + Advanced Networking - W8 Foundation (Day C)

Tài liệu này hệ thống lại các khái niệm nâng cao của Kubernetes về **Scaling (Co giãn ứng dụng)** và **Advanced Networking (Định tuyến nâng cao với Ingress)** để chuẩn bị cho buổi học Onsite Đà Nẵng với Mentor Nghĩa và buổi làm Lab.

---

## 🎯 Phần 1: Lý Thuyết Nâng Cao (Day C)

### 1. ReplicaSet & Deployment - Quản lý trạng thái và tự phục hồi
*   **ReplicaSet:**
    *   *Nhiệm vụ:* Đảm bảo luôn luôn có một số lượng Pod xác định (số bản sao - replicas) đang chạy ổn định tại bất kỳ thời điểm nào.
    *   *Cơ chế:* Sử dụng `selector` (nhãn - labels) để giám sát các Pod. Nếu một Pod bị chết, ReplicaSet sẽ lập tức tạo Pod mới thay thế.
*   **Deployment:**
    *   *Nhiệm vụ:* Là đối tượng cấp cao hơn, bao bọc (wrap) xung quanh ReplicaSet để quản lý việc **triển khai ứng dụng (Deploy)** và **cập nhật phiên bản (Rolling Update)** không gây gián đoạn dịch vụ.
    *   *Chiến lược cập nhật (Deployment Strategies):*
        1.  **RollingUpdate (Mặc định):** K8s sẽ thay thế dần dần từng Pod cũ bằng Pod mới (tạo Pod mới -> kiểm tra health check -> xóa Pod cũ). Đảm bảo không có downtime. Các tham số cấu hình:
            *   `maxSurge`: Số lượng Pod tối đa có thể tạo vượt mức quy định trong quá trình deploy (ví dụ: `25%` hoặc `1`).
            *   `maxUnavailable`: Số lượng Pod tối đa có thể tạm thời không hoạt động trong quá trình deploy.
        2.  **Recreate:** Xóa toàn bộ các Pod cũ trước, sau đó mới tạo các Pod mới. Có downtime nhưng giải quyết được vấn đề không tương thích phiên bản database/schema giữa phiên bản cũ và mới.

---

### 2. Auto Scaling - Tự động co giãn trong K8s
K8s hỗ trợ co giãn tự động ở cả mức ứng dụng (Pod) và mức hạ tầng (Node):

*   **HPA (Horizontal Pod Autoscaler - Co giãn ngang):**
    *   *Cơ chế:* Tự động tăng hoặc giảm **số lượng Pod (replicas)** của một Deployment/ReplicaSet dựa trên các chỉ số tài nguyên thu thập được (như tỷ lệ sử dụng CPU, RAM) hoặc custom metrics.
    *   *Hoạt động:* HPA kiểm tra các chỉ số thông qua dịch vụ **Metrics Server** của cluster định kỳ (mặc định là 15 giây).
*   **VPA (Vertical Pod Autoscaler - Co giãn dọc):**
    *   *Cơ chế:* Tự động tăng hoặc giảm **kích cỡ tài nguyên (CPU/RAM requests & limits)** của từng Pod thay vì tăng số lượng Pod. (HPA và VPA thường không chạy đồng thời trên cùng một chỉ số tài nguyên).
*   **Cluster Autoscaler (Co giãn hạ tầng node):**
    *   *Cơ chế:* Tự động thêm Node vật lý/VM mới vào cluster khi có Pod rơi vào trạng thái `Pending` do thiếu tài nguyên, hoặc xóa bớt Node trống để tiết kiệm chi phí.

---

### 3. K8s Advanced Networking - Ingress & Ingress Controller
Mặc dù `NodePort` và `LoadBalancer` giúp mở cổng dịch vụ ra ngoài, nhưng chúng có nhược điểm:
*   Mỗi dịch vụ `LoadBalancer` yêu cầu một Public IP riêng từ Cloud Provider, rất tốn chi phí.
*   `NodePort` mở các port phi chuẩn (30000+), không thân thiện với người dùng và khó quản lý chứng chỉ SSL bảo mật.

👉 **Ingress** ra đời để giải quyết triệt để vấn đề này.

*   **Ingress (Tài nguyên cấu hình):**
    *   Là một API Object định nghĩa tập hợp các **quy tắc định tuyến (routing rules)** dựa trên HTTP/HTTPS.
    *   Ví dụ:
        *   `http://my-app.com/api` -> chuyển tiếp tới `backend-service:8080`
        *   `http://my-app.com/` -> chuyển tiếp tới `frontend-service:80`
*   **Ingress Controller (Trình thực thi):**
    *   Ingress chỉ là "bản thiết kế" (tập tin cấu hình). Để các quy tắc hoạt động, cluster cần một **Ingress Controller** làm nhiệm vụ tiếp nhận traffic thực tế và định tuyến (phổ biến nhất là **NGINX Ingress Controller**, Traefik, HAProxy, Kong).
    *   Ingress Controller hoạt động như một Reverse Proxy / API Gateway thông minh đứng ở rìa (edge) của cluster.

---

## 💻 Phần 2: Các File Cấu Hình Đã Tạo Cho Day C

Để bạn thực hành trực quan và nộp bằng chứng self-study chất lượng cho Mentor, tôi đã tạo các file manifest mẫu tại thư mục [cloud/w8/day-c/](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/day-c/):

1.  [deployment-demo.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/day-c/deployment-demo.yaml): Khai báo Deployment chạy ứng dụng Web với 3 bản sao, cấu hình chiến lược `RollingUpdate` tối ưu.
2.  [hpa-demo.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/day-c/hpa-demo.yaml): Định nghĩa cấu hình tự động co giãn HPA từ 2 đến 10 Pod khi CPU trung bình vượt mức 50%.
3.  [ingress-demo.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/day-c/ingress-demo.yaml): Định nghĩa Ingress routing traffic từ domain giả lập `http://xbrain.local` vào đúng các service frontend/backend tương ứng.

---

## 🚀 Hướng Dẫn Thực Hành Cụ Thể (Từng bước chi tiết)

### Bước 1: Khởi động Minikube kèm Metrics Server và Ingress
Để thực hành được HPA (cần đo CPU) và Ingress (cần Reverse Proxy), bạn phải kích hoạt các addons này trên Minikube:

```bash
# 1. Khởi động Minikube
minikube start

# 2. Bật addon Metrics Server (phục vụ cho HPA đo đạc CPU)
minikube addons enable metrics-server

# 3. Bật addon Ingress Controller (tự động cài NGINX Ingress Controller cục bộ)
minikube addons enable ingress
```

### Bước 2: Deploy ứng dụng (Deployment + Service)
```bash
# Di chuyển tới thư mục Day C
cd cloud/w8/day-c/

# Deploy ứng dụng web và Service đi kèm
kubectl apply -f deployment-demo.yaml
```

### Bước 3: Deploy HPA & Kiểm tra tự động co giãn
```bash
# Deploy HPA
kubectl apply -f hpa-demo.yaml

# Theo dõi trạng thái HPA (có thể mất 1-2 phút để Metrics Server lấy đủ thông số CPU ban đầu)
kubectl get hpa -w
```
*(Bạn sẽ thấy cột TARGETS hiển thị dạng `<chỉ_số_hiện_tại>/50%`).*

### Bước 4: Cấu hình Ingress và ánh xạ Host
```bash
# 1. Deploy Ingress Routing
kubectl apply -f ingress-demo.yaml

# 2. Lấy IP của Minikube
minikube ip
```
*(Giả sử kết quả trả ra IP là `192.168.49.2`).*

*   **Để truy cập qua domain giả lập:** Bạn cần trỏ file `hosts` trên máy tính của mình (đường dẫn Windows: `C:\Windows\System32\drivers\etc\hosts`) thêm dòng sau:
    ```text
    192.168.49.2 xbrain.local
    ```
*   Bây giờ bạn mở trình duyệt và gõ `http://xbrain.local` hoặc `http://xbrain.local/api` để trải nghiệm khả năng định tuyến thông minh của Ingress!
