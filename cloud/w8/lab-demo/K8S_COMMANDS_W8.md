# 📖 Tài liệu Tổng hợp Toàn bộ Câu lệnh Kubernetes & Minikube (W8 Cheat Sheet)

Tài liệu này tổng hợp toàn bộ các câu lệnh Kubernetes (`kubectl`) và `minikube` đã học trong phần thực hành **W8**, sắp xếp theo các chủ đề từ cơ bản đến nâng cao để hỗ trợ bạn ôn tập và thực hành nhanh.

---

## 🚀 1. Quản lý Minikube (Cluster Management)
Minikube là công cụ chạy K8s cục bộ (local). Đây là nhóm lệnh cấu hình và điều khiển cluster.

| Lệnh | Mô tả |
| :--- | :--- |
| `minikube start --cni=calico --memory=4096 --cpus=2` | Khởi động cluster với CNI là Calico (bắt buộc để chạy Lab NetworkPolicy), RAM 4GB và 2 CPU. |
| `minikube status` | Kiểm tra trạng thái hoạt động của Minikube. |
| `minikube stop` | Tạm dừng cluster (giữ nguyên dữ liệu). |
| `minikube delete` | Xóa sạch toàn bộ cluster (khuyên dùng khi muốn reset làm lại từ đầu). |
| `minikube ip` | Lấy địa chỉ IP của Node Minikube. |
| `minikube dashboard` | Mở giao diện đồ họa (Web UI) trực quan của Kubernetes. |
| `minikube addons list` | Liệt kê các plugin (addons) đi kèm của Minikube. |
| `minikube addons enable ingress` | Kích hoạt Ingress Controller (Nginx) trên cluster. |
| `minikube addons enable metrics-server` | Bật Metrics Server (để xem tài nguyên CPU/RAM và chạy Auto Scaling). |

---

## 📂 2. Áp dụng & Xóa Tài nguyên (Apply & Delete)
Kubernetes hỗ trợ hai phương pháp: **Imperative** (ra lệnh trực tiếp) và **Declarative** (khai báo qua file YAML).

| Lệnh | Phân loại | Mô tả |
| :--- | :--- | :--- |
| `kubectl apply -f <file.yaml>` | **Declarative** | Tạo hoặc cập nhật tài nguyên được khai báo trong file YAML. |
| `kubectl apply -f <thư_mục>/` | **Declarative** | Áp dụng toàn bộ file YAML nằm trong một thư mục cụ thể. |
| `kubectl delete -f <file.yaml>` | **Declarative** | Xóa toàn bộ các tài nguyên đã được định nghĩa trong file YAML. |
| `kubectl run <tên_pod> --image=<image>` | **Imperative** | Tạo nhanh một Pod trần (Bare Pod) từ image trên registry. |
| `kubectl create deployment <tên> --image=<image>` | **Imperative** | Tạo nhanh một deployment từ dòng lệnh (chưa có file cấu hình). |
| `kubectl delete pod <tên_pod>` | **Imperative** | Xóa một Pod cụ thể. |
| `kubectl delete pods -l <key>=<value>` | **Imperative** | Xóa các Pods hàng loạt dựa theo Label Selector (ví dụ: `app=web`). |
| `kubectl delete all --all` | **Imperative** | ⚠️ Xóa sạch mọi tài nguyên trong namespace hiện hành (Deploy, RS, Pod, SVC). |

---

## 🔍 3. Kiểm tra trạng thái tài nguyên (Get & Watch)
Nhóm lệnh giúp xem thông tin tổng quan, trạng thái hoạt động của các đối tượng trong K8s.

```bash
# Xem tất cả tài nguyên (Pods, Services, Deployments, ReplicaSets)
kubectl get all

# Kiểm tra danh sách Pods
kubectl get pods

# Xem chi tiết IP và Node của các Pods
kubectl get pods -o wide

# Watch Pods - Tự động cập nhật trạng thái thời gian thực (nhấn Ctrl+C để thoát)
kubectl get pods -w

# Lọc Pods theo Label (ví dụ: app=web)
kubectl get pods -l app=web

# Xem danh sách Pod kèm theo cột labels của chúng
kubectl get pods --show-labels

# Xem các tài nguyên khác
kubectl get services          # Services (SVC)
kubectl get deployments       # Deployments (Deploy)
kubectl get replicasets       # ReplicaSets (RS)
kubectl get ingress           # Ingress Routes
kubectl get networkpolicies   # NetworkPolicies (NetPol)
kubectl get configmaps        # ConfigMaps (CM)
kubectl get secrets           # Secrets (Mật khẩu, Key)
kubectl get pv                # PersistentVolumes (Bộ nhớ vật lý)
kubectl get pvc               # PersistentVolumeClaims (Yêu cầu cấp bộ nhớ)
```

---

## 🔎 4. Tra cứu chi tiết & Log (Describe & Logs)
Khi tài nguyên bị lỗi (ví dụ: Pod không chạy), đây là các lệnh quan trọng nhất để tìm nguyên nhân.

```bash
# Xem thông tin chi tiết cấu hình và lịch sử sự kiện (Events) của 1 đối tượng
kubectl describe pod <tên_pod>
kubectl describe deployment <tên_deployment>
kubectl describe service <tên_service>
kubectl describe ingress <tên_ingress>
kubectl describe pvc <tên_pvc>

# Xem Logs của ứng dụng chạy trong Pod
kubectl logs <tên_pod>

# Xem Logs trực tiếp (real-time stream, giống tail -f)
kubectl logs <tên_pod> -f

# Xem logs của container chạy trước đó nếu Pod vừa bị khởi động lại (restart)
kubectl logs <tên_pod> --previous

# Xem logs của tất cả các Pods có nhãn app=web, chỉ lấy 3 dòng cuối cùng
kubectl logs -l app=web --tail=3
```

---

## 🐚 5. Tương tác trực tiếp & Kiểm thử (Exec & Debug)
Dùng để truy cập vào môi trường chạy của Pod nhằm chạy thử lệnh hoặc ping mạng.

```bash
# Truy cập vào shell bên trong container (tương tự như SSH)
kubectl exec -it <tên_pod> -- /bin/sh
kubectl exec -it <tên_pod> -- /bin/bash     # Dùng nếu container có cài bash

# Chạy một lệnh cụ thể bên trong Pod mà không cần truy cập shell
kubectl exec deploy/web -- env              # Xem danh sách biến môi trường của Pod thuộc deploy/web
kubectl exec deploy/web -- ls -la /usr/share/nginx/html

# Tạo một Pod tạm để test ping/curl, tự động xóa sau khi thoát (exit)
kubectl run test-pod --image=busybox --rm -it -- sh
# (Trong shell của test-pod, gõ: wget -qO- http://web-service:80)

kubectl run curl-test --image=curlimages/curl --rm -it -- sh
# (Trong shell của curl-test, gõ: curl http://backend-service:80)
```

---

## 🔁 6. Co giãn & Cập nhật ứng dụng (Scaling & Updates)
Quản lý việc tăng giảm số lượng Pod (Replicas) và cập nhật phiên bản ứng dụng (Rolling Update).

```bash
# Thay đổi số lượng bản sao (Replicas) của Deployment
kubectl scale deployment web --replicas=5

# Cập nhật phiên bản image mới cho Deployment (kích hoạt Rolling Update)
kubectl set image deployment/web web-container=nginx:1.21.0

# Kiểm tra tiến trình cập nhật ứng dụng
kubectl rollout status deployment/web

# Xem lịch sử các lần deploy (các phiên bản revision)
kubectl rollout history deployment/web

# Rollback (quay lại) phiên bản ứng dụng trước đó nếu bản mới bị lỗi
kubectl rollout undo deployment/web

# Khởi động lại toàn bộ các Pods của Deployment (thường dùng để Pod ăn ConfigMap/Secret mới)
kubectl rollout restart deployment/web
```

---

## 🔒 7. Cấu hình ConfigMap & Secret
Nơi lưu trữ biến môi trường (ConfigMap) và dữ liệu nhạy cảm (Secret) tách biệt khỏi Source Code/Docker Image.

```bash
# Tạo ConfigMap từ dòng lệnh (Imperative)
kubectl create configmap app-cfg --from-literal=APP_ENV=production

# Tạo Secret dạng Generic từ dòng lệnh (mã hóa tự động)
kubectl create secret generic app-sec --from-literal=DB_PASSWORD=s3cr3t

# Gắn toàn bộ key-value trong ConfigMap vào môi trường của Deployment
kubectl set env deploy/web --from=configmap/app-cfg

# Gắn toàn bộ key-value trong Secret vào môi trường của Deployment
kubectl set env deploy/web --from=secret/app-sec

# Xem chi tiết cấu hình đã lưu
kubectl describe configmap app-cfg
kubectl get secret app-sec -o yaml              # Hiển thị Secret (value bị mã hóa Base64)

# Giải mã Base64 của Secret để đọc trực tiếp giá trị gốc (trên terminal)
# Linux / macOS:
kubectl get secret app-sec -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
# Windows (PowerShell):
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((kubectl get secret app-sec -o jsonpath='{.data.DB_PASSWORD}')))
```

---

## 📊 8. Giám sát & Quản lý Tài nguyên (Metrics & Autoscaling)
Theo dõi lượng CPU, RAM đang sử dụng của Node và Pod.

```bash
# Xem dung lượng CPU/RAM tiêu thụ của các Node
kubectl top nodes

# Xem dung lượng CPU/RAM tiêu thụ của tất cả các Pods
kubectl top pods

# Sắp xếp danh sách Pods theo lượng RAM tiêu thụ nhiều nhất
kubectl top pods --sort-by=memory

# Kiểm tra trạng thái bộ tự động co giãn Pod (Horizontal Pod Autoscaler)
kubectl get hpa
kubectl describe hpa web-hpa
```

---

## ⚡ 9. Sổ tay xử lý lỗi K8s (Troubleshooting Guide)

Khi gặp lỗi, hãy làm theo quy trình sau:
```
Trạng thái Pod bất thường?
│
├── 1. Pending (Đang chờ cấp tài nguyên)
│   └── Cách xử lý: Gõ `kubectl describe pod <tên_pod>` -> xem mục "Events" cuối cùng.
│       - Nếu báo "Insufficient cpu" hoặc "Insufficient memory": Tăng RAM/CPU cho Minikube.
│       - Nếu báo "No nodes available": Kiểm tra node có bị tắt hoặc quá tải không (`kubectl get nodes`).
│
├── 2. ImagePullBackOff (Không kéo được Docker Image)
│   └── Cách xử lý: Gõ `kubectl describe pod <tên_pod>` -> kiểm tra tên image và tag có viết đúng chính tả không.
│       - Nếu dùng image private: Kiểm tra xem đã tạo và config `imagePullSecrets` chưa.
│       - Kiểm tra kết nối mạng của máy ảo Minikube có ra được Internet không.
│
├── 3. CrashLoopBackOff (Ứng dụng khởi động xong tự crash liên tục)
│   └── Cách xử lý: Gõ `kubectl logs <tên_pod> --previous`.
│       - Xem log lỗi từ bản thân code/ứng dụng xuất ra (ví dụ: thiếu file config, kết nối database thất bại, sai cổng port).
│       - Đảm bảo các biến môi trường (Env) truyền vào đầy đủ và chính xác.
│
├── 4. OOMKilled (Out Of Memory - Bị hủy vì ngốn quá RAM quy định)
│   └── Cách xử lý: Sửa file YAML, tăng giá trị `resources.limits.memory` cho Container lên.
│
└── 5. Terminating (Pod bị kẹt ở trạng thái đang xóa)
    └── Cách xử lý: Nếu xóa thông thường không phản hồi, chạy lệnh cưỡng bức (Force Delete):
        `kubectl delete pod <tên_pod> --force --grace-period=0`
```

---

## 🧹 10. Dọn dẹp Tài nguyên (Clean up)
Sau khi thực hành xong, dùng các lệnh sau để giải phóng tài nguyên cho máy tính của bạn:

```bash
# Cách 1: Xóa theo từng file YAML theo thứ tự
kubectl delete -f step5-network-policies.yaml
kubectl delete -f step4-ingress-routing.yaml
kubectl delete -f step3-frontend-tier.yaml
kubectl delete -f step2-backend-tier.yaml
kubectl delete -f step1-db-tier.yaml

# Cách 2: Xóa tất cả các YAML nằm trong thư mục hiện tại
kubectl delete -f .

# Dừng Minikube (để tắt máy ảo giải phóng RAM/CPU của máy host)
minikube stop
```
