# ☸️ TODO — Mini K8s Platform Lab Demo (Tự Làm)

> **Mục tiêu:** Tự tay build 1 hệ thống 3-tier chạy trên Minikube gồm:
> Frontend (Nginx) → Backend (Node.js API) → Database (PostgreSQL)
> Có Ingress routing, PersistentVolume, Secret, NetworkPolicy Zero-Trust.

---

## 🗂️ Cấu trúc folder này

```
lab-demo/
├── TODO.md                      ← File này — danh sách việc cần làm
├── COMMANDS_CHEATSHEET.md       ← Bảng lệnh kubectl hay dùng
├── step1-db-tier.yaml           ← TODO: viết config Database (PostgreSQL)
├── step2-backend-tier.yaml      ← TODO: viết config Backend API
├── step3-frontend-tier.yaml     ← TODO: viết config Frontend (Nginx)
├── step4-ingress-routing.yaml   ← TODO: viết Ingress routing rules
└── step5-network-policies.yaml  ← TODO: viết NetworkPolicy Zero-Trust
```

---

## ✅ CHECKLIST — Đánh dấu khi hoàn thành từng bước

### 🔧 BƯỚC 0 — Chuẩn bị môi trường

- [ ] **0.1** Cài Docker Desktop và đảm bảo Docker Engine đang chạy
  - Download: https://docs.docker.com/get-docker/
  - Kiểm tra: `docker --version`

- [ ] **0.2** Cài kubectl
  - Hướng dẫn: https://kubernetes.io/docs/tasks/tools/
  - Kiểm tra: `kubectl version --client`

- [ ] **0.3** Cài minikube
  - Hướng dẫn: https://minikube.sigs.k8s.io/docs/start/
  - Kiểm tra: `minikube version`

- [ ] **0.4** Khởi động Minikube với CNI Calico (bắt buộc để NetworkPolicy hoạt động)
  ```bash
  minikube start --cni=calico --memory=4096 --cpus=2
  ```
  > ⚠️ Lần đầu chạy sẽ mất 3–5 phút để pull image

- [ ] **0.5** Bật các addon cần thiết
  ```bash
  minikube addons enable ingress
  minikube addons enable metrics-server
  ```

- [ ] **0.6** Kiểm tra cluster đã sẵn sàng
  ```bash
  kubectl get nodes
  kubectl get pods -n kube-system
  ```
  > ✅ Mong đợi: Node `minikube` ở trạng thái `Ready`

---

### 📦 BƯỚC 1 — Database Tier (PostgreSQL)

> File cần hoàn thành: `step1-db-tier.yaml`

- [ ] **1.1** Mở file `step1-db-tier.yaml` và đọc hết các comment TODO
- [ ] **1.2** Điền đúng `apiVersion` và `kind` cho từng resource
- [ ] **1.3** Viết phần `Secret` chứa POSTGRES_PASSWORD (mã hóa base64)
  - Hint: `echo -n "mypassword" | base64` → dùng kết quả làm value
- [ ] **1.4** Viết phần `PersistentVolume` (loại hostPath, dung lượng 1Gi)
- [ ] **1.5** Viết phần `PersistentVolumeClaim` claim đúng storage từ PV trên
- [ ] **1.6** Viết phần `Deployment` chạy image `postgres:15`
  - Nhớ nạp Secret vào env `POSTGRES_PASSWORD`
  - Mount PVC vào `/var/lib/postgresql/data`
- [ ] **1.7** Viết phần `Service` loại ClusterIP, expose port 5432
- [ ] **1.8** Apply và kiểm tra
  ```bash
  kubectl apply -f step1-db-tier.yaml
  kubectl get pods -l tier=database -w
  kubectl get pvc
  ```
  > ✅ Mong đợi: Pod `postgres-*` ở trạng thái `Running`, PVC `Bound`

---

### ⚙️ BƯỚC 2 — Backend Tier (API App)

> File cần hoàn thành: `step2-backend-tier.yaml`

- [ ] **2.1** Mở file `step2-backend-tier.yaml` và đọc hết các comment TODO
- [ ] **2.2** Viết `Deployment` chạy image `hashicorp/http-echo` (API giả lập đơn giản)
  - Truyền arg: `-text="Hello from Backend! DB connected."`
  - Port: 5678
- [ ] **2.3** Cấu hình env lấy POSTGRES_PASSWORD từ Secret đã tạo ở Bước 1
- [ ] **2.4** Cấu hình `Liveness Probe` kiểm tra HTTP GET `/` port 5678
- [ ] **2.5** Cấu hình `Readiness Probe` kiểm tra HTTP GET `/health` port 5678
- [ ] **2.6** Viết `Service` loại ClusterIP, expose port 80 → targetPort 5678
- [ ] **2.7** Apply và kiểm tra
  ```bash
  kubectl apply -f step2-backend-tier.yaml
  kubectl get pods -l tier=backend
  kubectl logs -l tier=backend
  ```
  > ✅ Mong đợi: Pod backend Running, log hiển thị server đang lắng nghe

---

### 🌐 BƯỚC 3 — Frontend Tier (Nginx Web)

> File cần hoàn thành: `step3-frontend-tier.yaml`

- [ ] **3.1** Mở file `step3-frontend-tier.yaml` và đọc hết comment TODO
- [ ] **3.2** Viết `ConfigMap` chứa nội dung trang HTML đơn giản (index.html)
- [ ] **3.3** Viết `Deployment` chạy image `nginx:alpine`
  - Mount ConfigMap vào `/usr/share/nginx/html/index.html`
  - Port: 80
- [ ] **3.4** Cấu hình `Readiness Probe` kiểm tra HTTP GET `/` port 80
- [ ] **3.5** Viết `Service` loại ClusterIP, expose port 80
- [ ] **3.6** Apply và kiểm tra
  ```bash
  kubectl apply -f step3-frontend-tier.yaml
  kubectl get pods -l tier=frontend
  ```
  > ✅ Mong đợi: Pod frontend Running

---

### 🔀 BƯỚC 4 — Ingress Routing

> File cần hoàn thành: `step4-ingress-routing.yaml`

- [ ] **4.1** Mở file `step4-ingress-routing.yaml` và đọc hết comment TODO
- [ ] **4.2** Viết `Ingress` resource với 2 routing rules:
  - `/api` → forward đến `backend-service` port 80
  - `/` → forward đến `frontend-service` port 80
- [ ] **4.3** Đặt `ingressClassName: nginx`
- [ ] **4.4** Apply Ingress
  ```bash
  kubectl apply -f step4-ingress-routing.yaml
  kubectl get ingress
  ```
- [ ] **4.5** Lấy IP của minikube và trỏ hosts file
  ```bash
  minikube ip
  # Giả sử output là: 192.168.49.2
  ```
  Mở file `C:\Windows\System32\drivers\etc\hosts` (chạy Notepad as Admin) và thêm:
  ```
  192.168.49.2  mini-platform.local
  ```
- [ ] **4.6** Kiểm tra truy cập qua trình duyệt
  - `http://mini-platform.local` → phải thấy trang Frontend
  - `http://mini-platform.local/api` → phải thấy response từ Backend

---

### 🔒 BƯỚC 5 — Network Policy (Zero-Trust Security)

> File cần hoàn thành: `step5-network-policies.yaml`

- [ ] **5.1** Mở file `step5-network-policies.yaml` và đọc hết comment TODO
- [ ] **5.2** Viết NetworkPolicy `deny-all` cho namespace `default`
  - Chặn toàn bộ Ingress và Egress mặc định
- [ ] **5.3** Viết NetworkPolicy `allow-frontend-ingress`
  - Frontend chỉ nhận traffic từ Ingress Controller (namespace `ingress-nginx`)
- [ ] **5.4** Viết NetworkPolicy `allow-backend-from-frontend`
  - Backend chỉ nhận traffic từ Pod có label `tier: frontend`
- [ ] **5.5** Viết NetworkPolicy `allow-db-from-backend`
  - Database chỉ nhận traffic từ Pod có label `tier: backend`
- [ ] **5.6** Apply Network Policies
  ```bash
  kubectl apply -f step5-network-policies.yaml
  kubectl get networkpolicies
  ```
- [ ] **5.7** ⭐ Kiểm tra nghiệm thu Zero-Trust
  ```bash
  # Mở một Pod tạm để test
  kubectl run test-pod --image=busybox --rm -it -- sh

  # Bên trong Pod, thử ping thẳng vào database (phải BỊ CHẶN)
  wget -qO- http://postgres-service:5432
  # Kết quả mong đợi: connection refused / timeout → PASS ✅

  # Thử ping frontend (cũng phải bị chặn từ pod không có label)
  wget -qO- http://frontend-service:80
  # Kết quả mong đợi: connection refused / timeout → PASS ✅
  ```
- [ ] **5.8** Kiểm tra Backend vẫn hoạt động bình thường qua Ingress
  - `http://mini-platform.local/api` vẫn phải trả về response → PASS ✅

---

### 📝 BƯỚC 6 — Reflection & Commit

- [ ] **6.1** Cập nhật file `../reflection.md` phần Lab:
  - Ghi lại những lỗi gặp phải và cách fix
  - Điền điểm Test 2 khi có kết quả
- [ ] **6.2** Commit toàn bộ lên GitHub
  ```bash
  git add cloud/w8/lab-demo/
  git commit -m "[W8-Lab] Complete Mini K8s Platform lab demo with Zero-Trust NetworkPolicy"
  git push origin main
  ```

---

## 🚨 Các lỗi thường gặp & Cách fix

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| Pod ở trạng thái `Pending` | Không đủ CPU/RAM | `minikube start --memory=4096 --cpus=2` |
| `ImagePullBackOff` | Sai tên image hoặc không có internet | Kiểm tra lại tên image, `docker pull <image>` thử |
| NetworkPolicy không có tác dụng | Không có CNI hỗ trợ | `minikube start --cni=calico` |
| Ingress trả về 404 | Sai `serviceName` hoặc `port` trong routing | `kubectl describe ingress` để debug |
| PVC ở trạng thái `Pending` | Không có PV match | Kiểm tra `storageClassName` phải khớp |

---

## 📞 Khi cần giúp đỡ

- Kênh Slack: `#phase2-cloud-help` (kèm screenshot + log)
- DM Mentor Nghĩa hoặc Mentor Minh
