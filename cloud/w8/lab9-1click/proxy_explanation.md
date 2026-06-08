# GIẢI THÍCH CƠ CHẾ K8S API PROXY TRONG DỰ ÁN (LAB CD9)

Tài liệu này giải thích chi tiết lý do tại sao dự án của **Nguyễn Đình Thi** sử dụng cơ chế **Kubernetes API Proxy (`kubectl proxy`)** để liên kết (wire) giữa Terraform và cụm Kind Cluster trên EC2, cùng với các ưu điểm và nhược điểm của giải pháp này.

---

## I. LÝ DO SỬ DỤNG K8S API PROXY TRONG DỰ ÁN

Trong một kịch bản triển khai **1-Click Automation** bằng Terraform, chúng ta gặp phải bài toán **phụ thuộc vòng lặp (Bootstrapping Dependency)**:
1. Terraform cần khởi tạo hạ tầng AWS (VPC, EC2) trước.
2. Sau khi EC2 khởi động, cụm Kubernetes (Kind) mới được tạo ra thông qua script `user_data.sh`.
3. Khi cụm K8s sẵn sàng, Terraform Kubernetes Provider cần kết nối vào cụm để tạo Namespace, Deployment, Service và HPA.

### Thử thách:
Thông thường, để kết nối vào cụm K8s, ta cần file cấu hình xác thực (`kubeconfig`), chứng chỉ TLS (`client-certificate`, `client-key`) hoặc Token. Tuy nhiên, các file này nằm trên máy ảo EC2 vừa tạo và **không tồn tại ở máy local** chạy lệnh Terraform lúc bắt đầu.

### Giải pháp:
Trong script [user_data.sh](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/scripts/user_data.sh#L69-L76), ta chạy một tiến trình ngầm (background process) để mở cổng Proxy:
```bash
nohup kubectl proxy --port=8081 --address='0.0.0.0' --accept-hosts='^.*$' > /var/log/kubectl-proxy.log 2>&1 &
```
Lệnh này chuyển đổi cổng API Server bảo mật của Kubernetes (yêu cầu chứng chỉ phức tạp) thành một cổng HTTP không cần xác thực ở cổng `8081`. Nhờ vậy, ở file [providers.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/providers.tf#L33-L35), Terraform chỉ cần kết nối qua giao thức HTTP đơn giản:
```terraform
provider "kubernetes" {
  host = "http://${aws_instance.minikube.public_ip}:8081"
}
```

---

## II. PHÂN TÍCH ƯU ĐIỂM & NHƯỢC ĐIỂM

### 1. Ưu điểm (Advantages)

* **Quản lý Trạng thái Tập trung (Terraform State Management) — Điểm vượt trội nhất**:
  * **Sự khác biệt**: Các thành viên khác chọn giải pháp "Ủy quyền hoàn toàn" cho EC2 tự cài và tự deploy (Terraform local tạo xong EC2 là ngắt kết nối). Còn bạn chọn cách **"Quản lý tập trung"** (Terraform local vừa tạo hạ tầng AWS vừa trực tiếp kết nối qua API Proxy để điều khiển và giám sát cụm K8s).
  * **Lợi ích**: Khi sử dụng Kubernetes Provider trong Terraform, toàn bộ tài nguyên K8s (Namespace, Deployment, ConfigMap, Service, HPA) đều được theo dõi chặt chẽ trong file **`terraform.tfstate`**.
  * **Phát hiện sai lệch (Drift Detection)**: Nếu có ai đó vô tình hoặc cố ý vào cụm K8s xóa đi một Pod hoặc thay đổi cấu hình Service, lệnh `terraform plan/apply` tiếp theo ở máy local của bạn sẽ lập tức phát hiện ra sự sai lệch (drift) này và tự động khôi phục (re-create/update) tài nguyên về đúng trạng thái mong muốn. Ở giải pháp chạy script của các bạn khác, Terraform hoàn toàn "mù" trước các tài nguyên K8s này và không thể kiểm soát hay sửa chữa khi có lỗi xảy ra.
  * **Vòng đời nhất quán (Unified Lifecycle)**: Khi bạn chạy `terraform destroy`, Terraform sẽ dọn sạch sẽ từ ứng dụng K8s cho đến mạng lưới AWS theo đúng thứ tự ưu tiên. Giải pháp dùng shell script của các bạn khác sẽ để lại các tài nguyên K8s "mồ côi" trong container của EC2, và chúng chỉ bị triệt tiêu khi máy ảo EC2 bị tắt hoàn toàn.
* **Hiện thực hóa 1-Click Deployment**: Cho phép hoàn thành toàn bộ tiến trình từ tạo hạ tầng Cloud đến deploy ứng dụng K8s chỉ trong duy nhất một lệnh `terraform apply` mà không cần ngắt quãng giữa chừng để cấu hình thủ công hoặc lấy file chứng chỉ.
* **Đơn giản hóa cấu hình cấu trúc mã nguồn (HCL)**: Loại bỏ sự phức tạp khi phải viết code Terraform để download file `kubeconfig` từ EC2 về máy local bằng SSH, rồi nạp Certificate động vào Provider.
* **Không phụ thuộc vào cấu hình client local**: Lập trình viên chạy lệnh ở bất kỳ máy tính nào cũng có thể deploy được, không cần có sẵn các công cụ giải mã hoặc phân quyền file trên hệ điều hành local.

### 2. Nhược điểm & Rủi ro (Disadvantages & Risks)

* **Rủi ro bảo mật cực kỳ lớn (Security Risk)**: 
  * Cổng proxy `8081` chấp nhận mọi kết nối không cần xác thực (`--accept-hosts='^.*$'`) và có toàn quyền tối cao (`cluster-admin`) trên cụm K8s.
  * Nếu hacker quét thấy cổng này đang mở công khai trên Internet, họ có thể chiếm quyền điều khiển hoàn toàn cụm Kubernetes của bạn.
* **Truyền tin không mã hóa (Plaintext Traffic)**: Dữ liệu giao tiếp giữa máy local (chạy Terraform) và EC2 truyền qua HTTP thay vì HTTPS, dẫn đến nguy cơ bị tấn công nghe lén (Man-in-the-Middle) để đánh cắp thông tin nhạy cảm.
* **Rủi ro sập tiến trình nền (Dependency on Background Process)**: Nếu tiến trình chạy nền `kubectl proxy` trên EC2 bị sập (do thiếu tài nguyên, crash...), Terraform ở local sẽ lập tức mất quyền quản lý K8s dù cụm K8s bên trong vẫn đang hoạt động bình thường.

---

## III. CÁCH KHẮC PHỤC RỦI RO TRONG DỰ ÁN NÀY

Để sử dụng cơ chế này một cách an toàn cho bài Lab, dự án đã triển khai giải pháp bảo mật nhiều lớp:

1. **Giới hạn IP nghiêm ngặt tại Security Group (EC2-SG)**: 
   Tại file [security_groups.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/security_groups.tf#L55-L61), cổng `8081` chỉ được mở Inbound duy nhất cho IP cá nhân của Developer (`var.my_ip`). Tất cả các IP khác trên thế giới quét cổng này đều bị AWS drop traffic ngay lập tức.
2. **Khuyến nghị môi trường thực tế (Production)**:
   * Không sử dụng `kubectl proxy` public.
   * Sử dụng cơ chế xác thực **OIDC (OpenID Connect)** hoặc dùng **VPN/Bastion Host** để kết nối an toàn bằng HTTPS thông qua file kubeconfig được mã hóa bảo mật.
