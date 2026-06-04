# 📋 kubectl Cheat Sheet — W8 Lab Demo

Bảng lệnh hay dùng nhất trong lab. Bookmark lại để dùng!

---

## 🚀 Quản lý Minikube

| Lệnh | Mô tả |
|------|--------|
| `minikube start --cni=calico --memory=4096 --cpus=2` | Khởi động với Calico CNI (bắt buộc cho NetworkPolicy) |
| `minikube stop` | Dừng cluster |
| `minikube delete` | Xóa toàn bộ cluster (reset sạch) |
| `minikube status` | Kiểm tra trạng thái cluster |
| `minikube ip` | Lấy IP của minikube node |
| `minikube dashboard` | Mở Kubernetes Dashboard trên trình duyệt |
| `minikube addons enable ingress` | Bật NGINX Ingress Controller |
| `minikube addons enable metrics-server` | Bật Metrics Server (cần cho HPA) |
| `minikube addons list` | Xem tất cả addons và trạng thái |

---

## 📦 Apply & Xóa Resource

| Lệnh | Mô tả |
|------|--------|
| `kubectl apply -f <file.yaml>` | Tạo hoặc cập nhật resource từ file |
| `kubectl apply -f <thư_mục>/` | Apply tất cả YAML trong thư mục |
| `kubectl delete -f <file.yaml>` | Xóa resource từ file |
| `kubectl delete pod <tên_pod>` | Xóa 1 Pod cụ thể (sẽ được tạo lại nếu có Deployment) |
| `kubectl delete all --all` | **⚠️ Xóa tất cả resource trong namespace hiện tại** |

---

## 🔍 Kiểm tra trạng thái (GET)

```bash
# Xem tất cả resource cùng lúc
kubectl get all

# Xem theo từng loại
kubectl get pods                     # Danh sách Pods
kubectl get pods -o wide             # Kèm IP và Node
kubectl get pods -w                  # Watch — tự động refresh khi có thay đổi
kubectl get pods -l tier=backend     # Lọc theo label

kubectl get services                 # Danh sách Services
kubectl get deployments              # Danh sách Deployments
kubectl get replicasets              # Danh sách ReplicaSets
kubectl get ingress                  # Danh sách Ingress
kubectl get networkpolicies          # Danh sách NetworkPolicies
kubectl get pv                       # PersistentVolumes
kubectl get pvc                      # PersistentVolumeClaims
kubectl get secrets                  # Secrets
kubectl get configmaps               # ConfigMaps
kubectl get hpa                      # Horizontal Pod Autoscalers
```

---

## 🔎 Debug chi tiết (DESCRIBE & LOGS)

```bash
# Xem chi tiết đầy đủ của 1 resource (rất hữu ích khi debug)
kubectl describe pod <tên_pod>
kubectl describe deployment <tên_deployment>
kubectl describe service <tên_service>
kubectl describe ingress <tên_ingress>
kubectl describe networkpolicy <tên_policy>
kubectl describe pvc <tên_pvc>

# Xem logs của container
kubectl logs <tên_pod>                    # Log của pod
kubectl logs <tên_pod> -f                 # Follow log (như tail -f)
kubectl logs <tên_pod> --previous         # Log của container trước khi restart
kubectl logs -l tier=backend              # Log của tất cả pod có label này
kubectl logs -l tier=backend --all-pods   # Kèm tên pod

# Xem events (thường chứa lỗi quan trọng)
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n kube-system
```

---

## 🐚 Exec vào trong Container

```bash
# Mở shell bên trong container (như SSH vào)
kubectl exec -it <tên_pod> -- /bin/sh     # Dùng sh (phổ biến hơn)
kubectl exec -it <tên_pod> -- /bin/bash   # Dùng bash nếu có

# Chạy 1 lệnh cụ thể không cần vào shell
kubectl exec <tên_pod> -- ls /var/lib/postgresql/data
kubectl exec <tên_pod> -- env             # Xem biến môi trường

# Tạo pod tạm để test (tự xóa sau khi exit)
kubectl run test-pod --image=busybox --rm -it -- sh
kubectl run test-pod --image=curlimages/curl --rm -it -- sh
```

---

## 🔁 Scaling & Rolling Update

```bash
# Scale thủ công
kubectl scale deployment frontend-deployment --replicas=3

# Xem quá trình rolling update
kubectl rollout status deployment/frontend-deployment

# Rollback về phiên bản trước
kubectl rollout undo deployment/frontend-deployment

# Xem lịch sử deploy
kubectl rollout history deployment/frontend-deployment

# Cập nhật image (trigger rolling update)
kubectl set image deployment/backend-deployment backend-api=hashicorp/http-echo:latest
```

---

## 🔒 Debug NetworkPolicy

```bash
# Kiểm tra NetworkPolicy có được apply chưa
kubectl get networkpolicies
kubectl describe networkpolicy deny-all-default

# Test kết nối từ pod tạm (không có label → bị chặn)
kubectl run test --image=busybox --rm -it -- sh
# Bên trong pod:
# wget -qO- --timeout=5 http://postgres-service:5432
# wget -qO- --timeout=5 http://backend-service:80
# wget -qO- --timeout=5 http://frontend-service:80

# Kiểm tra xem pod có labels gì
kubectl get pod <tên_pod> --show-labels
```

---

## 💾 Debug Storage (PV & PVC)

```bash
# Kiểm tra PV và PVC đã bind chưa
kubectl get pv
kubectl get pvc
# → Status phải là "Bound", nếu "Pending" thì check lại accessModes và storage size

# Xem chi tiết PVC
kubectl describe pvc postgres-pvc
```

---

## 🔐 Debug Secrets & ConfigMaps

```bash
# Xem danh sách (không hiện value)
kubectl get secrets
kubectl get configmaps

# Xem nội dung Secret (value dạng base64)
kubectl get secret postgres-secret -o yaml

# Decode base64 để xem giá trị thật
kubectl get secret postgres-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d

# Xem nội dung ConfigMap
kubectl get configmap frontend-config -o yaml
```

---

## 🌐 Debug Ingress & Network

```bash
# Kiểm tra Ingress đã có IP chưa
kubectl get ingress
# → Cột ADDRESS phải có IP (ví dụ: 192.168.49.2)
# → Nếu trống thì Ingress Controller chưa ready

# Kiểm tra Ingress Controller pod
kubectl get pods -n ingress-nginx

# Test kết nối HTTP trực tiếp
curl http://mini-platform.local
curl http://mini-platform.local/api

# Nếu không có curl, dùng wget
wget -qO- http://mini-platform.local
```

---

## ⚡ Luồng Debug Khi Pod Lỗi

```
Pod ở trạng thái lạ?
│
├── Pending → kubectl describe pod <tên> → Xem phần "Events"
│   - "Insufficient cpu/memory" → Tăng resource của minikube
│   - "No nodes available"      → kubectl get nodes xem có Node không
│
├── ImagePullBackOff → Tên image sai hoặc không có internet
│   → kubectl describe pod → Xem section "Image"
│   → docker pull <image> để test kéo image thủ công
│
├── CrashLoopBackOff → Container khởi động rồi crash liên tục
│   → kubectl logs <pod> --previous để xem log lần crash trước
│   → Thường do sai config, thiếu env var, sai command/args
│
├── OOMKilled → Pod bị kill vì hết memory
│   → Tăng limits.memory trong YAML
│
└── Terminating mãi không xong → kubectl delete pod <tên> --force --grace-period=0
```

---

## 📊 Kiểm tra Resource Usage

```bash
# Xem CPU/RAM của các node
kubectl top nodes

# Xem CPU/RAM của từng pod
kubectl top pods
kubectl top pods --sort-by=memory    # Sắp xếp theo RAM
kubectl top pods -l tier=backend     # Lọc theo label

# Xem trạng thái HPA
kubectl get hpa
kubectl describe hpa backend-hpa
```

---

## 🧹 Dọn dẹp Lab

```bash
# Xóa từng bước theo thứ tự ngược lại
kubectl delete -f step5-network-policies.yaml
kubectl delete -f step4-ingress-routing.yaml
kubectl delete -f step3-frontend-tier.yaml
kubectl delete -f step2-backend-tier.yaml
kubectl delete -f step1-db-tier.yaml

# Hoặc xóa tất cả 1 lệnh
kubectl delete -f .

# Dừng minikube
minikube stop

# Xóa toàn bộ cluster (nếu muốn bắt đầu lại từ đầu)
minikube delete
```
