<p align="center">
  <img src="https://img.icons8.com/color/96/000000/kubernetes.png" alt="Kubernetes Logo" width="80"/>
</p>

# <p align="center">🚀 LAB CD9 — 1-Click Automation Platform</p>

### <p align="center">Terraform ➔ Custom VPC ➔ EC2 (Kind) ➔ K8s Provider ➔ ALB</p>

<p align="center">
  <a href="https://terraform.io"><img src="https://img.shields.io/badge/TERRAFORM-1.5+-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"/></a>
  <a href="https://kubernetes.io"><img src="https://img.shields.io/badge/KUBERNETES-KIND-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"/></a>
  <a href="https://aws.amazon.com"><img src="https://img.shields.io/badge/AWS-ALB-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS ALB"/></a>
  <a href="https://docker.com"><img src="https://img.shields.io/badge/DOCKER-KIND-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker Engine"/></a>
</p>

<p align="center">
  <a href="evidence.md"><img src="https://img.shields.io/badge/EVIDENCE%20PACK-VIEW%20NOW-4CAF50?style=for-the-badge&logo=google-docs&logoColor=white" alt="Evidence Pack"/></a>
  <a href="study_guide.md"><img src="https://img.shields.io/badge/STUDY%20GUIDE-OPEN-00bcd4?style=for-the-badge&logo=read-the-docs&logoColor=white" alt="Study Guide"/></a>
</p>

> An automated, single-command deployment pipeline that provisions a full AWS network infrastructure, boots a Kubernetes Kind cluster inside EC2, and deploys a secure Nginx application using the Kubernetes HCL provider.

---

<p align="center">
  <b>Nguyễn Đình Thi</b> · <code>XB-DN26-103</code> · <b>W8 Submission</b> · Deadline: 05/06/2026
</p>

---

## 🏗️ Sơ đồ kiến trúc (Architecture Diagram)

Dưới đây là sơ đồ chi tiết biểu diễn luồng hoạt động, cấu hình định tuyến bảo mật và cơ chế triển khai của bài Lab:

![Sơ đồ kiến trúc](image.png)

### Các thành phần chính trong kiến trúc:
1. **Mạng & Định tuyến (VPC & Subnets):** 
   - VPC (`10.0.0.0/16`) được chia thành 2 Public Subnet thuộc 2 Availability Zone khác nhau: Subnet A (`10.0.1.0/24` - `ap-southeast-1a`) và Subnet B (`10.0.2.0/24` - `ap-southeast-1b`).
   - Cả hai Subnet đều liên kết với Internet Gateway (IGW) thông qua Route Table để cho phép đi ra Internet.
2. **Bộ cân bằng tải (ALB):** 
   - AWS ALB lắng nghe trên cổng `80` công cộng (mở cho `0.0.0.0/0`).
   - ALB bắt buộc phải liên kết với cả 2 Subnet A và B để đạt tính sẵn sàng cao (High Availability).
   - ALB forward traffic từ cổng `80` vào cổng `30080` (NodePort) trên máy chủ EC2.
3. **Máy chủ ứng dụng (EC2 & Kind):**
   - Máy ảo EC2 (chạy Ubuntu 22.04, `t3.medium`) nằm tại Subnet A.
   - EC2 chạy script `user_data.sh` cài đặt Docker, Kind, kubectl và khởi tạo cụm Kubernetes Kind Cluster.
   - Ứng dụng Nginx được đóng gói chạy dưới dạng Pod trong namespace `lab-cd9` và được expose ra ngoài qua Service NodePort `30080`.
   - Lệnh `kubectl proxy --port=8081` chạy nền giúp mở cổng kết nối API Kubernetes cho Terraform.

---

## 🔗 Giải thích cơ chế "Wire" các Provider với nhau

Dự án này thể hiện sự phối hợp nhịp nhàng giữa 4 Providers trong cùng 1 cấu hình:
1. **AWS Provider**: Tạo toàn bộ hạ tầng cơ bản (VPC, Subnet, Route Table, Security Group, EC2, ALB).
2. **TLS Provider**: Tạo SSH Key động và truyền sang AWS Key Pair.
3. **Local Provider**: Ghi file private key `lab-cd9-key.pem` xuống máy local để phục vụ việc SSH.
4. **Kubernetes Provider**: Kết nối trực tiếp vào API Server của cụm Kind Cluster và deploy các tài nguyên K8s dưới dạng code HCL.

### Thách thức Bootstrapping và Giải pháp Proxy (`providers.tf` & `kubernetes.tf`):
Một vấn đề kinh điển của Terraform khi deploy ứng dụng vào cụm K8s mới tinh trong 1 lần apply: **Làm sao để Kubernetes Provider kết nối và xác thực khi cụm K8s vừa mới được dựng và nằm trong mạng cô lập?**
* **Bẫy lỗi**: Nếu copy file kubeconfig hay Certificate về máy local để xác thực, Terraform sẽ bị lỗi ngay từ bước `plan` vì file chưa tồn tại hoặc bị lỗi nạp cấu hình (provider reload) giữa chừng.
* **Giải pháp đột phá**:
  1. Trong script `user_data.sh`, ta chạy ngầm lệnh `kubectl proxy --port=8081 --address='0.0.0.0'` trên EC2 để biến API Server thành HTTP không cần xác thực (chỉ cho phép IP của bạn truy cập qua Security Group để bảo mật).
  2. Cấu hình Kubernetes Provider trỏ động vào IP Public của EC2 qua port 8081:
     ```hcl
     provider "kubernetes" {
       host = "http://${aws_instance.minikube.public_ip}:8081"
     }
     ```
  3. Sử dụng `depends_on = [null_resource.wait_for_minikube]` trên các tài nguyên K8s để bắt Terraform phải đợi máy chủ EC2 hoàn tất cài đặt Kind Cluster và Proxy khởi động hoàn chỉnh rồi mới thực hiện kết nối.

### Tại sao lại chọn Kind thay vì Minikube `--driver=none`?
* **Minikube `--driver=none`** chạy trực tiếp các tiến trình K8s lên hệ điều hành của EC2 mà không có lớp ảo hóa cách ly. Việc này yêu cầu quyền root tối cao, dễ gây rác hệ thống và đặc biệt là cực kỳ bất ổn định trên Ubuntu 22.04 (lỗi cgroups v2/systemd).
* **Kind (Kubernetes in Docker)** chạy cụm Kubernetes dưới dạng các Docker Container nhẹ, sạch sẽ, khởi động nhanh hơn và cực kỳ ổn định trên môi trường EC2.

---

## 📖 Hướng dẫn chạy (Execution Steps - 1-Click)

### Bước 1: Cấu hình Credentials AWS
Đảm bảo bạn đã cấu hình AWS Credentials trên máy của bạn:
```bash
aws configure
# Nhập Access Key, Secret Key, Region: ap-southeast-1
```

### Bước 2: Khởi tạo và tải Providers
Di chuyển vào thư mục dự án và chạy init:
```bash
cd NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9
terraform init
```

### Bước 3: Xem kế hoạch (Plan)
```bash
terraform plan
```

### Bước 4: Triển khai 1-Click (Apply)
```bash
terraform apply -auto-approve
```
*(Quá trình này mất khoảng 3 - 5 phút vì Terraform phải đợi máy ảo EC2 khởi tạo, cài Docker, dựng cụm Kind K8s, khởi động proxy, rồi mới bắt đầu tạo các tài nguyên Kubernetes).*

### Bước 5: Dọn dẹp sạch hạ tầng (Destroy)
Sau khi kiểm tra xong, bạn chạy lệnh sau để xóa sạch tài nguyên tránh phát sinh chi phí:
```bash
terraform destroy -auto-approve
```

---

## 🔍 Bằng chứng nghiệm thu (Acceptance & Screenshots)

Dưới đây là hình ảnh minh chứng thực tế cho từng bước chạy của dự án:

### 1. Khởi tạo thành công (`terraform init`)
Tải thành công cả 4 providers (`aws`, `tls`, `local`, `kubernetes`).

![Init](assets/tf_init.png)

### 2. Kế hoạch triệt để (`terraform plan`)
Xây dựng thành công đồ thị phụ thuộc để tạo mới 22 tài nguyên.

![Plan](assets/tf_plan.png)

### 3. Apply hoàn thành (`terraform apply`)
Terraform chạy xong và xuất ra các thông số Outputs quan trọng.

![Apply](assets/tf_apply.png)

### 4. Trạng thái hạ tầng hoạt động trên AWS
* **Máy chủ EC2 Instance:**
![EC2 Console](assets/ec2.png)
* **Application Load Balancer (ALB):**
![ALB Console](assets/alb.png)

### 5. Xác minh ứng dụng chạy trong cụm K8s (Không cài thẳng EC2)
SSH vào máy EC2, kiểm tra trạng thái Pods và Services trong namespace `lab-cd9`. Ứng dụng chạy an toàn bên trong Container Pod.

![K8s Verify](assets/k8s_verify.png)

### 6. Truy cập thành công qua Load Balancer trên Trình duyệt
Dán URL của `alb_dns_name` vào trình duyệt và nhận về trang web tùy chỉnh chạy từ Kind Cluster.

![Browser](assets/brower.png)

### 7. Dọn dẹp sạch sẽ tài nguyên (`terraform destroy`)
Hủy bỏ toàn bộ 22 tài nguyên trên AWS thành công.

![Destroy](assets/tf_destroy.png)
