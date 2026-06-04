# 🛠️ AWS Web App Infrastructure Deployment Guide (Terraform - Final Project)

Tài liệu hướng dẫn chi tiết các bước thiết lập và triển khai hạ tầng 3 lớp (Multi-tier Architecture) trên AWS bằng Terraform cho dự án cuối khóa.

---

## 📐 Sơ đồ kiến trúc hạ tầng
```text
                     [AWS Cloud (ap-southeast-1)]
                                 │
                         ┌───────┴────────────────────────┐
                         │              VPC               │
                         │          (10.0.0.0/16)         │
                         │                                │
        Internet         │  ┌──────────────────────────┐  │
     ──────(HTTP)───────>│  │      Public Subnet       │  │
                         │  │      (10.0.1.0/24)       │  │
                         │  │                          │  │
                         │  │     ┌──────────────┐     │  │
                         │  │     │  EC2 Server  │     │  │
                         │  │     │ (Web Server) │     │  │
                         │  │     └──────┬───────┘     │  │
                         │  └────────────┼─────────────┘  │
                         │               │                │
                         │               │ (Port 3306)    │
                         │               v                │
                         │  ┌──────────────────────────┐  │
                         │  │  Private Subnets (2 AZs) │  │
                         │  │ (10.0.10.0 / 10.0.11.0)  │  │
                         │  │                          │  │
                         │  │    ┌────────────────┐    │  │
                         │  │    │   RDS MySQL    │    │  │
                         │  │    └────────────────┘    │  │
                         │  └──────────────────────────┘  │
                         └────────────────────────────────┘
                                         │
                                         ▼
                               [S3 Bucket - Assets]
```

---

## 🗂️ Cấu trúc thư mục dự án

```text
assignment_homework/
├── bootstrap_backend/          # Bước 0: Tạo S3 Bucket & DynamoDB Table lưu State
│   └── main.tf                 # Khai báo S3 và DynamoDB
├── modules/
│   └── vpc/                    # Module tạo mạng ảo VPC
│       ├── main.tf             # Khai báo VPC, Subnets, IGW, Route Tables
│       ├── variables.tf        # Biến đầu vào của VPC Module
│       └── outputs.tf          # Trích xuất VPC ID, Subnet IDs
├── providers.tf                # Khai báo Provider AWS
├── variables.tf                # Khai báo Biến đầu vào toàn cục
├── outputs.tf                  # In ra IP EC2, URL S3, Endpoint Database
├── backend.tf                  # Lưu cấu hình State trên AWS
└── main.tf                     # Lắp ghép Security Groups, EC2, RDS, S3
```

---

## 🏃‍♂️ Quy trình triển khai từng bước (Step-by-Step)

### 🅢🅣🅔🅟 0 — Khởi tạo lưu trữ State (Bootstrap Backend)
Trước khi lưu trữ cấu hình hạ tầng chính thức lên AWS S3, ta cần tạo S3 Bucket và DynamoDB khóa trước.

1. Di chuyển vào thư mục `bootstrap_backend`:
   ```bash
   cd bootstrap_backend
   ```
2. Khởi tạo Terraform và áp dụng để tạo tài nguyên:
   ```bash
   terraform init
   terraform apply
   ```
3. Sau khi chạy thành công, terminal sẽ in ra:
   - `s3_bucket_name` (ví dụ: `assignment-homework-tf-state-bucket-unique`)
   - `dynamodb_table_name` (ví dụ: `assignment-homework-tf-state-locks`)
4. Quay lại thư mục cha:
   ```bash
   cd ..
   ```

---

### 🅢🅣🅔🅟 1 — Bật cấu hình Backend Remote
1. Mở file [backend.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/assignment_homework/backend.tf).
2. Sửa giá trị `bucket` và `dynamodb_table` khớp với kết quả vừa nhận được ở **Step 0**.
3. Bỏ các dấu comment `#` ở phần `terraform` block trong `backend.tf`.

---

### 🅢🅣🅔🅟 2 — Viết code hoàn thiện các TODOs
Hãy đọc kỹ các hướng dẫn và cú pháp (`Syntax`) mẫu ở các file sau để tự điền code:
1. [modules/vpc/main.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/assignment_homework/modules/vpc/main.tf) - Khởi tạo hạ tầng mạng.
2. [main.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/assignment_homework/main.tf) - Lắp ghép EC2, RDS Database, Security Group bảo mật, và S3 Static.

---

### 🅢🅣🅔🅟 3 — Kiểm tra cấu hình và Triển khai
Tại thư mục chính (`assignment_homework/`):

1. Khởi tạo Terraform để tải providers và tự động **Migrate State** lên S3 Bucket:
   ```bash
   terraform init
   ```
   *(Hệ thống sẽ hỏi bạn có muốn sao chép local state lên S3 từ xa không -> Nhập `yes`)*

2. Kiểm tra lỗi cú pháp và xem trước các tài nguyên sẽ được tạo trên AWS:
   ```bash
   terraform plan
   ```
   *Hãy đảm bảo không có thông báo lỗi đỏ nào xuất hiện.*

3. Tiến hành triển khai hạ tầng thực tế lên AWS:
   ```bash
   terraform apply
   ```
   *(Nhập `yes` khi hệ thống yêu cầu xác nhận)*

---

### 🅢🅣🅔🅟 4 — Kiểm thử và Xác thực (Verification)
Sau khi `terraform apply` thành công, terminal sẽ trả ra thông tin Outputs:

1. **Kiểm tra Web Server**:
   - Lấy giá trị IP công cộng của EC2 từ output `web_server_public_ip`.
   - Mở trình duyệt web truy cập địa chỉ: `http://<IP_EC2>`. Bạn sẽ thấy thông báo:
     `Welcome to AWS Web Server (Deployed by Terraform)`.
2. **Kiểm tra kết nối SSH**:
   - Truy cập thử vào Web Server qua SSH:
     `ssh -i <keypath> ec2-user@<IP_EC2>`.
3. **Kiểm tra liên kết Database**:
   - Log vào EC2 và ping thử RDS MySQL: `mysql -h <rds_endpoint> -u admin -p` (cần cài đặt client mysql trên EC2).

---

### 🅢🅣🅔🅟 5 — Xóa tài nguyên tránh mất phí (Destroy)
Sau khi thực hành xong và chụp ảnh kết quả, hãy chạy lệnh xóa ngay để tránh bị AWS tính phí duy trì:

1. Xóa hạ tầng chính thức:
   ```bash
   terraform destroy
   ```
   *(Nhập `yes` để xác nhận)*

2. Xóa tài nguyên bootstrap state (nếu không cần dùng nữa):
   ```bash
   cd bootstrap_backend
   terraform destroy
   cd ..
   ```

---

## 📚 Sổ tay Syntax Terraform hay dùng

### 1. Gọi Module (Module Block)
```hcl
module "tên_logical" {
  source     = "đường_dẫn_thư_mục_module"
  biến_1     = giá_trị_1
  biến_2     = giá_trị_2
}
```

### 2. Định nghĩa Security Group Rule
```hcl
resource "aws_security_group" "tên_sg" {
  vpc_id = <vpc_id>

  # Chiều đi vào
  ingress {
    description     = "Ghi chú"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"] # Mở cho toàn bộ internet
    # security_groups = [aws_security_group.tên_sg_khác.id] # Chỉ mở cho SG khác
  }

  # Chiều đi ra ngoài
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Mọi giao thức
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### 3. Vòng lặp count tạo nhiều Subnet
```hcl
resource "aws_subnet" "subnets" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.az_list[count.index]
}
# Truy cập ID subnet thứ nhất: aws_subnet.subnets[0].id
# Truy cập ID subnet thứ hai: aws_subnet.subnets[1].id
# Lấy danh sách IDs: aws_subnet.subnets[*].id
```
