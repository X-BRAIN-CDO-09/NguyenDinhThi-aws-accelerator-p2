# LAB CD9 — 1-Click Automation: Terraform → Custom VPC → EC2 (Minikube) → K8s Provider → ALB

Dự án này thực hiện tự động hóa hoàn toàn ở mức độ cao nhất (Native IaC) bằng cách kết hợp **AWS Provider** (dựng hạ tầng) và **Kubernetes Provider** (deploy ứng dụng trực tiếp bằng code HCL) trong **một lệnh duy nhất** (`1-click`).

---

## 🏗️ Sơ đồ kiến trúc (Architecture Diagram)

```text
  Developer (terraform init/plan/apply)
       │
       ├─────────────────────────────────────────┐
       ▼ (AWS Infrastructure)                    ▼ (K8s Application)
   AWS Provider                            Kubernetes Provider
   ├── VPC, Subnets, IGW, RTs              ├── Namespace (lab-cd9)
   ├── Security Groups (ALB & EC2)         ├── Deployment (nginx)
   ├── EC2 Instance (Ubuntu 22.04)         └── Service (NodePort: 30080)
   └── ALB & Target Group                      │ (K8s Provider kết nối qua
       │                                       │  cổng 8081 được mở bởi
       │                                       │  kubectl proxy trên EC2)
       ▼                                       ▼
┌────────────────────────────── AWS Cloud ──────────────────────────────┐
│                                                                       │
│  ┌──────────────────────── Custom VPC (10.0.0.0/16) ────────────────┐  │
│  │                                                                 │  │
│  │  ┌── Public Subnet A (AZ-a) ──┐      ┌── Public Subnet B (AZ-b) ──┐ │  │
│  │  │   (CIDR: 10.0.1.0/24)      │      │   (CIDR: 10.0.2.0/24)      │ │  │
│  │  │  ┌──────────────────────┐  │      │  ┌──────────────────────┐  │ │  │
│  │  │  │ ALB (Internet-facing)│◀─┼──────┼──│   Inbound: 80/tcp    │  │ │  │
│  │  │  │     Listener: :80    │  │      │  │    from 0.0.0.0/0    │  │ │  │
│  │  │  └──────────┬───────────┘  │      │  └──────────┬───────────┘  │ │  │
│  │  │             │              │      │             │ (ALB-SG)     │ │  │
│  │  │             │ Forward      │      │             │              │ │  │
│  │  │             ▼ Port 30080   │      │             ▼              │ │  │
│  │  │      Target Group          │      │      Security Group        │ │  │
│  │  │  Port 30080 / Health: /    │      │         (ALB-SG)           │ │  │
│  │  │             │              │      │                            │ │  │
│  │  └─────────────┼──────────────┘      └────────────────────────────┘ │  │
│  │                │                                                    │  │
│  │                ▼ Forward to port 30080                              │  │
│  │  ┌─────────────┼────────────── EC2 Instance ─────────────────────┐  │  │
│  │  │             │                                                 │  │  │
│  │  │             ▼                                                 │  │  │
│  │  │    Security Group (EC2-SG)                                    │  │  │
│  │  │    • Inbound: 30080/tcp from ALB-SG                           │  │  │
│  │  │    • Inbound: 22/tcp from MyIP                                │  │  │
│  │  │    • Inbound: 8081/tcp from MyIP ◄── (K8s API Proxy)          │  │  │
│  │  │                                                               │  │  │
│  │  │    Ubuntu 22.04 (t3.medium)                                   │  │  │
│  │  │    └─ User Data Bootstrap:                                    │  │  │
│  │  │       1. Install Docker, kubectl, Minikube                    │  │  │
│  │  │       2. Start Minikube (--driver=none)                       │  │  │
│  │  │       3. Start kubectl proxy --port=8081 (background)         │  │  │
│  │  │                                                               │  │  │
│  │  │    ┌────────────────── Minikube Cluster ──────────────────┐   │  │  │
│  │  │    │                                                      │   │  │  │
│  │  │    │  [Namespace: lab-cd9]                                │   │  │  │
│  │  │    │  [Deployment: web-app] ──► [Service: web-service]    │   │  │  │
│  │  │    │  (replicas: 1)             (NodePort: 30080)         │   │  │  │
│  │  │    └──────────────────────────────────────────────────────┘   │  │  │
│  │  │                                                               │  │  │
│  │  └───────────────────────────────────────────────────────────────┘  │  │
│  │                                                                     │  │
│  │    Internet Gateway (IGW) ──► Route Table (0.0.0.0/0 trỏ ra IGW)    │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Giải thích cơ chế "Wire" các Provider với nhau

Dự án này thể hiện sự phối hợp nhịp nhàng giữa 4 Providers trong cùng 1 cấu hình:
1. **AWS Provider**: Tạo tài nguyên hạ tầng cơ bản (VPC, Security Group, EC2, ALB).
2. **TLS Provider**: Tạo SSH Key động và truyền sang AWS Key Pair.
3. **Local Provider**: Lưu file private key `.pem` xuống ổ đĩa cục bộ.
4. **Kubernetes Provider**: Kết nối trực tiếp vào API Server của cụm Minikube và deploy các tài nguyên K8s dưới dạng code HCL.

### Thách thức Bootstrapping và Giải pháp Proxy (providers.tf & kubernetes.tf):
Một vấn đề kinh điển của Terraform khi deploy ứng dụng vào cụm K8s mới tinh trong 1 lần apply: **Làm sao để Kubernetes Provider kết nối và xác thực khi Minikube vừa mới được dựng?**
* **Bẫy lỗi**: Nếu copy file kubeconfig hay Certificate về máy local để xác thực, Terraform sẽ bị lỗi ngay từ bước `plan` vì file chưa tồn tại hoặc bị lỗi nạp cấu hình (provider reload) giữa chừng.
* **Giải pháp đột phá**:
  1. Trong `user_data.sh`, ta chạy ngầm lệnh `kubectl proxy --port=8081 --address='0.0.0.0'` trên EC2 để biến API Server thành HTTP không cần xác thực (chỉ cho phép IP của bạn truy cập qua Security Group để bảo mật).
  2. Cấu hình Kubernetes Provider trỏ động vào IP Public của EC2 qua port 8081:
     ```hcl
     provider "kubernetes" {
       host = "http://${aws_instance.minikube.public_ip}:8081"
     }
     ```
  3. Sử dụng `depends_on = [null_resource.wait_for_minikube]` trên các tài nguyên K8s để bắt Terraform phải đợi Minikube và Proxy khởi động hoàn tất trên EC2 rồi mới thực hiện kết nối.

---

## 📖 Hướng dẫn chạy (Execution Steps)

### Bước 1: Cấu hình Credentials AWS
Đảm bảo bạn đã cấu hình AWS Credentials trên máy của bạn:
```bash
aws configure
# Nhap Access Key, Secret Key, Region: ap-southeast-1
```

### Bước 2: Khởi tạo thư mục dự án
Di chuyển vào thư mục `lab-cd9` và khởi tạo Terraform:
```bash
cd NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9
terraform init
```

### Bước 3: Xem kế hoạch (Plan)
Xem danh sách tài nguyên hạ tầng và K8s sẽ được tạo:
```bash
terraform plan
```

### Bước 4: Triển khai (Apply)
Chạy lệnh apply để tự động tạo toàn bộ hệ thống. 
*(Lưu ý: Quá trình này sẽ mất từ 3 - 5 phút vì Terraform phải đợi Minikube cài đặt và sau đó tự động deploy Deployment/Service Nginx).*
```bash
terraform apply -auto-approve
```

---

## 🔍 Xác minh kết quả (Verification)

Sau khi chạy xong, terminal sẽ xuất ra các giá trị đầu ra (Outputs):

1. **Truy cập qua Web**: Copy giá trị từ `alb_dns_name` dán vào trình duyệt (ví dụ: `http://lab-cd9-alb-xxxx.ap-southeast-1.elb.amazonaws.com`). Bạn sẽ thấy trang chào mừng mặc định của **Nginx** (chạy bên trong Namespace `lab-cd9`).
2. **SSH kiểm tra cụm K8s**: Copy câu lệnh từ `ssh_command` để SSH vào EC2 và kiểm tra trạng thái:
   ```bash
   # Lenh SSH mau:
   ssh -i lab-cd9-key.pem ubuntu@<IP-Public>
   
   # Xem trang thai cac Pod và Service K8s
   kubectl get pods -n lab-cd9
   kubectl get svc -n lab-cd9
   ```

### Dọn dẹp tài nguyên (Hủy bỏ tránh tốn chi phí)
Sau khi thực hành xong, chạy lệnh hủy để xóa sạch cả app K8s lẫn hạ tầng AWS:
```bash
terraform destroy -auto-approve
```

---

## 💡 Câu hỏi nghiên cứu (Phần tự học cho Trainer hỏi)

### Q1: Tại sao cách làm này (dùng Kubernetes Provider) lại hay hơn việc chạy `kubectl apply` trong User Data?
* **Trả lời**: Vì cách này biến các tài nguyên K8s thành các đối tượng được quản lý trực tiếp bởi Terraform State (IaC thực sự). Khi ta cập nhật cấu hình Pod hoặc Service bằng Terraform, nó sẽ tự thực hiện rolling update. Khi ta chạy `terraform destroy`, Terraform sẽ tự động dọn dẹp sạch sẽ các tài nguyên K8s trước, sau đó mới hủy hạ tầng AWS. Nếu dùng User Data, Terraform sẽ không quản lý được ứng dụng K8s đó.

### Q2: Cơ chế hoạt động của `kubectl proxy` trong bài lab này là gì?
* **Trả lời**: Mặc định, Kubernetes API Server yêu cầu chứng chỉ TLS phức tạp để kết nối. Lệnh `kubectl proxy` chạy trên EC2 hoạt động như một reverse proxy cục bộ, lắng nghe ở port `8081` và chuyển tiếp các yêu cầu HTTP không cần xác thực vào API Server cục bộ. Chúng ta chỉ mở port `8081` cho IP của Dev nên vẫn đảm bảo an toàn bảo mật.

### Q3: Tại sao bản triển khai này lại cần Internet Gateway (IGW) và Route Table?
* **Trả lời**: Vì chúng ta đang tự dựng một **Custom VPC** mới hoàn toàn từ đầu. Một VPC mới tạo sẽ hoàn toàn cô lập với Internet. Để EC2 instance có thể tải Docker, Minikube và kéo image Nginx về, nó cần đi ra ngoài Internet. Chúng ta tạo **Internet Gateway (IGW)** để mở cổng kết nối, và tạo **Route Table** định tuyến dải `0.0.0.0/0` qua IGW đó, biến Subnet chứa EC2 thành Public Subnet.

### Q4: Tại sao lại cần tới 2 Subnet ở 2 Availability Zone khác nhau?
* **Trả lời**: AWS bắt buộc một Application Load Balancer (ALB) phải chạy trên ít nhất **2 Availability Zones (AZ)** khác nhau để đảm bảo tính sẵn sàng cao (High Availability). Nếu một trung tâm dữ liệu (AZ) của AWS gặp sự cố, ALB vẫn hoạt động ở AZ còn lại. Do đó, ta phải khai báo 2 Subnets thuộc 2 AZ khác nhau (ví dụ: `ap-southeast-1a` và `ap-southeast-1b`) và gán cả hai vào ALB.
