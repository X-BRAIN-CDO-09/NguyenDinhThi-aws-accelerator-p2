# ☸️ Cẩm Nang Ôn Tập & Thực Hành Kubernetes - W8 Foundation (Day B)

Tài liệu này hệ thống lại toàn bộ kiến thức nền tảng về Kubernetes (K8s) phục vụ cho các buổi Onsite Lab và bài kiểm tra lý thuyết sắp tới. Đồng thời, tài liệu cung cấp các file YAML mẫu thực tế đã được chuẩn hóa để bạn thực hành local trên **Minikube**.

---

## 🎯 Phần 1: Lý Thuyết Cốt Lõi K8s Container Orchestration

### 1. Kiến trúc tổng quan & Cơ chế hoạt động của K8s
*   **Kubernetes (K8s)** là nền tảng nguồn mở dùng để tự động hóa việc đóng gói (container orchestration), triển khai, scale và quản lý các ứng dụng container hóa.
*   **Kiến trúc Control Plane (Master Node) vs Worker Node:**
    *   **Control Plane:** Điều phối toàn bộ cluster, bao gồm:
        *   `kube-apiserver`: Cổng giao tiếp chính tiếp nhận mọi yêu cầu API (là "bộ não" giao tiếp).
        *   `etcd`: Cơ sở dữ liệu key-value phân tán lưu trữ toàn bộ trạng thái của cluster.
        *   `kube-scheduler`: Lựa chọn node tối ưu để chạy các Pod mới được tạo.
        *   `kube-controller-manager`: Chạy các bộ điều khiển giám sát trạng thái hệ thống (Node, Deployment, Namespace,...).
    *   **Worker Node:** Nơi thực sự chạy các ứng dụng container, bao gồm:
        *   `kubelet`: Agent chạy trên mỗi Node để đảm bảo các container chạy đúng như mô tả trong PodSpec.
        *   `kube-proxy`: Quản lý mạng nội bộ và các quy tắc iptables/IPVS để định tuyến traffic đến Pod.
        *   `Container Runtime` (e.g., Docker, containerd): Môi trường thực thi container.

---

### 2. Pod - Đơn vị tính toán nhỏ nhất của K8s
*   **Định nghĩa:** Pod là đối tượng nhỏ nhất có thể triển khai và quản lý trong K8s. Một Pod chứa một hoặc nhiều container (thường là 1 container chính và có thể kèm sidecar container) chia sẻ chung không gian mạng (Network Namespace), địa chỉ IP, và các volume lưu trữ (Storage).
*   **Vòng đời (Lifecycle) của Pod:**
    *   `Pending`: Yêu cầu tạo Pod được API chấp nhận, nhưng container chưa được khởi chạy (đang tải image hoặc chờ scheduler phân bổ Node).
    *   `Running`: Pod đã được gán vào Node, tất cả container đã được tạo và ít nhất một container đang chạy/khởi động.
    *   `Succeeded`: Tất cả container trong Pod đã kết thúc thành công (exit code 0) và không tự khởi động lại (thường dùng cho Job/CronJob).
    *   `Failed`: Tất cả container đã dừng, và ít nhất một container dừng với lỗi (exit code khác 0).
    *   `Unknown`: Không thể giao tiếp với Pod (thường do lỗi kết nối giữa Control Plane và Kubelet của Worker Node).

---

### 3. Probes - Cơ chế giám sát sức khỏe Container
Để đảm bảo ứng dụng hoạt động tin cậy, K8s sử dụng 3 loại Probe chính do Kubelet thực hiện định kỳ:

1.  **Liveness Probe (Giám sát sự sống):**
    *   *Nhiệm vụ:* Kiểm tra xem container còn hoạt động bình thường không.
    *   *Hành vi:* Nếu thất bại, Kubelet sẽ **kill container và khởi động lại** nó dựa trên chính sách `restartPolicy`.
    *   *Ứng dụng:* Phát hiện và tự phục hồi khi ứng dụng bị treo (deadlock), rò rỉ bộ nhớ dẫn tới không phản hồi.
2.  **Readiness Probe (Giám sát tính sẵn sàng):**
    *   *Nhiệm vụ:* Kiểm tra xem ứng dụng đã sẵn sàng tiếp nhận lượng traffic yêu cầu từ bên ngoài chưa (ví dụ: đã load xong database, cache).
    *   *Hành vi:* Nếu thất bại, K8s sẽ **ngắt Pod khỏi danh sách Endpoint của Service** (không có traffic gửi đến Pod này) nhưng **không** restart container.
    *   *Ứng dụng:* Đảm bảo người dùng không nhận lỗi 502/503 trong quá trình khởi động hoặc khi app quá tải.
3.  **Startup Probe (Giám sát khởi động):**
    *   *Nhiệm vụ:* Kiểm tra xem container đã khởi động hoàn tất chưa.
    *   *Hành vi:* Khi Startup Probe đang chạy, Liveness và Readiness Probes sẽ bị **tắt**. Nếu thất bại, container sẽ bị restart.
    *   *Ứng dụng:* Dành cho các ứng dụng legacy mất nhiều thời gian khởi động ban đầu để tránh bị Liveness Probe kill nhầm.

---

### 4. Service - Định tuyến & Cân bằng tải mạng
Vì Pod có tính chất tạm thời (ephemeral) — có thể bị xóa và cấp phát IP mới bất kỳ lúc nào — K8s sử dụng **Service** để làm cổng giao tiếp ổn định (Static IP & DNS) trước các Pod.

K8s cung cấp 4 loại Service chính:
*   **ClusterIP (Mặc định):**
    *   Chỉ cho phép truy cập từ **bên trong** K8s cluster.
    *   Phù hợp cho các service nội bộ như Database, Cache, backend APIs nội bộ.
*   **NodePort:**
    *   Mở một cổng tĩnh (từ cổng `30000 - 32767`) trên **mọi Node** của cluster. Traffic gửi vào IP của Node ở port này sẽ được chuyển tiếp đến Pod.
    *   Phù hợp cho môi trường test local hoặc demo nhanh.
*   **LoadBalancer:**
    *   Tự động yêu cầu nhà cung cấp Cloud (AWS, GCP, Azure) cấp phát một Load Balancer vật lý (ví dụ AWS ELB/ALB) để tiếp nhận traffic từ internet và cân bằng tải tới các Pod.
    *   Phù hợp cho các dịch vụ Production hướng ra ngoài internet.
*   **ExternalName:**
    *   Ánh xạ Service tới một DNS bên ngoài (ví dụ: `my-database.amazonaws.com`) thông qua bản ghi CNAME.

---

### 5. ConfigMap & Secret - Tách biệt cấu hình khỏi Source Code
Nhằm tuân thủ nguyên lý *12-Factor App*, cấu hình và dữ liệu nhạy cảm phải được tách biệt hoàn toàn khỏi container image:

*   **ConfigMap:** Lưu trữ các cấu hình không bảo mật dạng key-value (như file config, biến môi trường, domain).
*   **Secret:** Lưu trữ các dữ liệu nhạy cảm cần mã hóa (mật khẩu, khóa API, SSH key, SSL certificate). Trong K8s, Secret được mã hóa dạng **Base64** mặc định và lưu trong bộ nhớ tạm (tmpfs) trên RAM của Node để tăng tính bảo mật.
*   **Cách sử dụng:** Cả ConfigMap và Secret đều có thể được truyền vào Container thông qua:
    1.  Biến môi trường (`env` hoặc `envFrom`).
    2.  Gắn dưới dạng tệp tin thông qua Volume mount (`volumeMounts`).

---

### 6. NetworkPolicy - Bảo mật mạng ở mức Pod
*   Theo mặc định trong K8s, **tất cả các Pod đều có thể giao tiếp với nhau không giới hạn** (non-isolated).
*   **NetworkPolicy** cho phép cấu hình tường lửa ở mức Layer 3/4 cho Pod, định nghĩa rõ ràng:
    *   `Ingress`: Nguồn traffic nào được phép **truy cập vào** Pod (từ Namespace nào, Pod nào, hoặc IP block nào).
    *   `Egress`: Pod được phép **gửi traffic đi** đâu.
*   Để NetworkPolicy hoạt động, cluster bắt buộc phải cài đặt một **Network Plugin (CNI)** hỗ trợ NetworkPolicy như Calico, Cilium, Weave Net (Minikube cần được start với flag `--cni=calico` để thực thi chính sách này).

---

## 💻 Phần 2: Các File YAML Thực Hành Đã Tạo (Day B)

Tại thư mục [cloud/w8/day-b/](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/day-b), các file manifest mẫu chuẩn chỉnh sau đã được tạo lập:

1.  [pod-demo.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/day-b/pod-demo.yaml): Khai báo Pod chạy Nginx, cấu hình CPU/RAM Requests & Limits, cấu hình 3 loại Probe giám sát sức khỏe.
2.  [service-demo.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/day-b/service-demo.yaml): Tạo Service loại `ClusterIP` và `NodePort` để định tuyến traffic vào Pod.
3.  [configmap-secret-demo.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/day-b/configmap-secret-demo.yaml): Khai báo ConfigMap, Secret (mã hóa Base64) và gắn chúng vào Pod thông qua biến môi trường cùng Volume.
4.  [network-policy-demo.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/day-b/network-policy-demo.yaml): Thiết lập chính sách bảo mật mạng mặc định từ chối tất cả traffic, chỉ cho phép traffic từ các Pod có nhãn cụ thể.

---

## 🚀 Hướng Dẫn Chạy Lab Trên Máy Cá Nhân (Minikube)

Bạn hãy khởi động Minikube trên máy của mình để thực thi thử các file cấu hình này:

```bash
# 1. Khởi động Minikube (kèm CNI Calico để chạy được NetworkPolicy)
minikube start --cni=calico

# 2. Di chuyển tới thư mục Day B
cd cloud/w8/day-b/

# 3. Deploy ConfigMap và Secret trước tiên
kubectl apply -f configmap-secret-demo.yaml

# 4. Deploy Pod Demo (sử dụng ConfigMap và Secret)
kubectl apply -f pod-demo.yaml

# 5. Deploy Service Demo
kubectl apply -f service-demo.yaml

# 6. Triển khai Network Policy để bảo mật
kubectl apply -f network-policy-demo.yaml

# 7. Kiểm tra trạng thái hệ thống
kubectl get pods -o wide
kubectl get services
kubectl describe pod nginx-pod-demo
```

---

## 💾 Hướng Dẫn Commit & Push Cho Cả Day A & Day B

Để hoàn tất, hãy thực hiện đẩy toàn bộ bài học và thực hành của cả **Day A (Terraform)** và **Day B (K8s)** lên repository Github cá nhân của bạn với format commit chuẩn chỉnh.

```bash
# 1. Thêm toàn bộ các thay đổi của Day A và Day B
git add cloud/w8/day-a/ cloud/w8/day-b/ cloud/w8/reflection.md

# 2. Commit với message mô tả cả 2 ngày
git commit -m "[W8-D2] Complete Terraform basics and Kubernetes core resource manifests"

# 3. Push lên branch chính
git push origin main
```
