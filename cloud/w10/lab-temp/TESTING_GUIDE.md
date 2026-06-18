# HƯỚNG DẪN KIỂM THỬ CHI TIẾT — LAB 2

Tài liệu này hướng dẫn từng bước để thực hiện kiểm thử toàn bộ **Lab 2 (bao gồm cả Lab 2.1 và Lab 2.2)** từ khâu đổi cấu hình, chạy lệnh test cho tới khâu khôi phục lại cấu hình gốc.

---

## PHẦN 1: Kiểm thử Lab 2.1 — External Secrets Operator (ESO)

Mục tiêu là kiểm tra xem Cluster có tự động kéo và đồng bộ mật khẩu từ AWS Secrets Manager về Kubernetes mỗi 10 giây hay không.

### Bước 1: Kiểm tra trạng thái đồng bộ ban đầu (Trên EC2)
Chạy các lệnh sau trên terminal EC2:
```bash
# 1. Kiểm tra kết nối AWS
kubectl get secretstore aws-store -n demo
# Kết quả mong đợi: STATUS = Valid, READY = True

# 2. Kiểm tra yêu cầu kéo Secret
kubectl get externalsecret db-creds -n demo
# Kết quả mong đợi: STATUS = SecretSynced, READY = True

# 3. Kiểm tra xem Secret Kubernetes đã được sinh ra chưa
kubectl get secret db-secret -n demo -o yaml
```

### Bước 2: Test tính năng tự động cập nhật (Rotation)
1. **Lên AWS Console (Secrets Manager):** Tìm secret `prod/db/password` -> Nhấp **Retrieve secret value** -> Chọn **Edit** -> Đổi giá trị mật khẩu thành một chuỗi mới (Ví dụ: `Thithithi@2026`) -> Nhấn **Save**.
2. **Theo dõi trên EC2 terminal:** Chạy lệnh sau để giải mã mật khẩu liên tục mỗi 1 giây:
   ```bash
   watch -n 1 "kubectl get secret db-secret -n demo -o jsonpath='{.data.password}' | base64 --decode"
   ```
3. **Kết quả mong đợi:** Sau khoảng 10 - 15 giây, mật khẩu hiển thị trên terminal sẽ tự động chuyển thành giá trị mới bạn vừa đổi trên AWS Console.
*(Nhấn `Ctrl + C` để thoát màn hình watch).*

---

## PHẦN 2: Kiểm thử Lab 2.2 — Trivy Scan & Ký số Cosign

Mục tiêu là kiểm tra xem hệ thống có tự động chặn các ảnh Docker chưa được ký số hay không.

### Bước A: Xác minh chữ ký số của ảnh app (Trên EC2)
Chạy lệnh sau trên EC2 để kiểm tra xem ảnh ứng dụng của bạn đã được ký số hợp lệ chưa:
```bash
cosign verify --key ~/NguyenDinhThi-aws-accelerator-p2/cloud/w10/lab-temp/signing/cosign.pub ghcr.io/x-brain-cdo-09/nguyendinhthi-aws-accelerator-p2/w10-api:0.0.5
```
* **Kết quả mong đợi:** Trả về chuỗi JSON thông tin chữ ký và hiển thị dòng chữ: `Cosign image signature successfully verified`.

---

### Bước B: Test cơ chế Chặn ảnh chưa ký số (Signature Enforcement)

Do chính sách mặc định chỉ chặn các ảnh thuộc repo của bạn, để test tính năng chặn với ảnh công cộng chưa ký (như `nginx` từ Docker Hub) ta làm theo các bước sau:

#### Bước 1: Sửa cấu hình Policy trên máy Local
Mở file `cloud/w10/lab-temp/policies/cluster-image-policy.yaml` trên máy **local** và sửa lại phần `spec` như sau:
```yaml
spec:
  mode: enforce  # Chế độ chặn nghiêm ngặt
  images:
  - glob: "index.docker.io/library/nginx*"  # Chuyển hướng kiểm tra sang ảnh nginx công cộng
  authorities:
  - name: authority-0
    key:
      data: |
        -----BEGIN PUBLIC KEY-----
        MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE95AAuTY83Nrf/FI+Yti+3xOp3cNl
        JyklSH+0Cy6yC0V+f+cdBnXeDXaGqPn5XbavMpq1eedEd0FUV+xjSW1V5Q==
        -----END PUBLIC KEY-----
```

#### Bước 2: Commit và Push code lên GitHub (Tại máy Local)
Chạy các lệnh sau tại thư mục dự án trên máy **local**:
```powershell
git add cloud/w10/lab-temp/policies/cluster-image-policy.yaml
git commit -m "test: enforce signature policy on nginx image"
git push
```

#### Bước 3: Đồng bộ và kích hoạt quét chữ ký (Trên EC2)
Chạy các lệnh sau trên terminal của **EC2** để bắt ArgoCD đồng bộ ngay cấu hình mới và kích hoạt quét chữ ký trên namespace `default`:
```bash
# 1. Bắt ArgoCD đồng bộ policy mới ngay lập tức
kubectl annotate app policies -n argocd argocd.argoproj.io/refresh=normal --overwrite

# 2. Gắn nhãn kích hoạt kiểm tra chữ ký cho namespace default (để tránh bị Gatekeeper chặn registry)
kubectl label namespace default policy.sigstore.dev/include=true --overwrite
```

#### Bước 4: Chạy lệnh kiểm thử (Trên EC2)
Cố gắng tạo một Pod sử dụng ảnh `nginx:1.25` chưa ký số (kèm khai báo CPU/RAM để vượt qua Gatekeeper):
```bash
# Tạo file manifest tạm thời
cat <<EOF > test-sig.yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-sig
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    resources:
      limits:
        cpu: 100m
        memory: 64Mi
EOF

# Chạy thử nghiệm tạo Pod
kubectl apply -f test-sig.yaml --dry-run=server

# Xóa file tạm sau khi test xong
rm test-sig.yaml
```
* **Kết quả mong đợi:** Webhook của Sigstore chặn đứng và báo lỗi:
  > `Error from server (BadRequest): ... admission webhook "policy.sigstore.dev" denied the request: ... signature key validation failed ... no signatures found`

---

#### Bước 5: Khôi phục cấu hình ban đầu
Sau khi kiểm tra hệ thống chặn thành công, chúng ta cần đưa cấu hình trở lại bình thường.

1. **Sửa lại file ở máy Local:** Mở lại file `cloud/w10/lab-temp/policies/cluster-image-policy.yaml` và sửa lại `glob` về ảnh repo của bạn:
   ```yaml
   spec:
     mode: enforce  # Giữ nguyên chế độ chặn để bảo vệ cụm
     images:
     - glob: "ghcr.io/x-brain-cdo-09/nguyendinhthi-aws-accelerator-p2*"  # Khôi phục về ảnh của bạn
   ```
2. **Commit và Push lên Git (Tại máy Local):**
   ```powershell
   git add cloud/w10/lab-temp/policies/cluster-image-policy.yaml
   git commit -m "restore: original image glob for lab completion"
   git push
   ```
3. **Đồng bộ lại trên EC2:**
   ```bash
   kubectl annotate app policies -n argocd argocd.argoproj.io/refresh=normal --overwrite
   ```
