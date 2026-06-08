# 📚 Tài Liệu Ôn Tập: LAB CD9 — 1-Click Automation

Tài liệu này tổng hợp toàn bộ kiến thức bạn cần nắm vững để tự tin thuyết trình và trả lời mọi câu hỏi về bài Lab CD9.

---

## Phần 1: Terraform — Công Cụ Tự Động Hóa Hạ Tầng

### 1.1. Terraform là gì?
- Là công cụ **Infrastructure as Code (IaC)** của HashiCorp.
- Cho phép bạn viết code (ngôn ngữ HCL) để mô tả hạ tầng, sau đó Terraform tự động dựng/xóa hạ tầng cho bạn.
- **Declarative (Khai báo):** Bạn chỉ cần mô tả trạng thái mong muốn, Terraform tự tìm cách thực hiện.

### 1.2. Các lệnh cơ bản (Phải thuộc!)
| Lệnh | Mục đích |
|---|---|
| `terraform init` | Tải các Provider cần thiết, khởi tạo thư mục `.terraform` |
| `terraform plan` | Xem trước những gì Terraform sẽ tạo/sửa/xóa (dry-run) |
| `terraform apply` | Thực thi kế hoạch, dựng hạ tầng thật trên cloud |
| `terraform destroy` | Xóa sạch toàn bộ hạ tầng đã tạo |
| `terraform state list` | Liệt kê tất cả tài nguyên đang được Terraform quản lý |
| `terraform state rm <resource>` | Loại bỏ 1 tài nguyên khỏi state (không xóa trên cloud) |

### 1.3. Terraform State (`terraform.tfstate`) là gì?
- Là file JSON lưu trữ **trạng thái hiện tại** của toàn bộ hạ tầng mà Terraform đang quản lý.
- Mỗi lần chạy `plan` hoặc `apply`, Terraform so sánh **code mới** với **state cũ** để tìm ra sự khác biệt cần thực hiện.
- **Quan trọng:** Nếu xóa file này, Terraform sẽ "quên" hết tất cả tài nguyên và tạo mới lại từ đầu (tài nguyên cũ vẫn chạy trên AWS nhưng Terraform không biết).

### 1.4. Provider là gì? Bài lab dùng bao nhiêu Provider?
- Provider là **plugin kết nối** giúp Terraform giao tiếp với các nền tảng bên ngoài (AWS, Kubernetes, v.v.).
- Bài lab sử dụng **5 Provider**:

| Provider | Vai trò | File khai báo |
|---|---|---|
| **aws** | Tạo/quản lý tài nguyên trên AWS (VPC, EC2, ALB...) | `providers.tf` |
| **tls** | Sinh cặp khóa SSH Private/Public key tự động | `key_pair.tf` |
| **kubernetes** | Kết nối qua proxy 8081 để tạo Namespace, Deployment, Service | `kubernetes.tf` |
| **local** | Ghi file private key `.pem` xuống máy tính của bạn | `key_pair.tf` |
| **null** | Chạy script SSH kiểm tra EC2 đã sẵn sàng chưa (`null_resource`) | `ec2.tf` |

### 1.5. Các khái niệm HCL quan trọng
| Khái niệm | Giải thích | Ví dụ trong lab |
|---|---|---|
| `resource` | Khai báo 1 tài nguyên cần tạo | `resource "aws_vpc" "main" { ... }` |
| `data` | Truy vấn dữ liệu có sẵn (không tạo mới) | `data "aws_ami" "ubuntu" { ... }` — Tìm AMI Ubuntu mới nhất |
| `variable` | Biến đầu vào để tùy chỉnh | `var.aws_region`, `var.app_port` |
| `locals` | Giá trị tính toán nội bộ, dùng lại nhiều lần | `local.name_prefix = "lab-cd9"` |
| `output` | Xuất kết quả sau khi apply xong | `output "alb_dns_name"` |
| `depends_on` | Ràng buộc thứ tự tạo/xóa tài nguyên | Namespace phụ thuộc vào IGW và Route Table |
| `templatefile()` | Đọc file và thay thế biến bên trong | `templatefile("scripts/user_data.sh", { proxy_port = 8081 })` |

---

## Phần 2: AWS — Hạ Tầng Cloud

### 2.1. VPC (Virtual Private Cloud)
- Là **mạng ảo riêng** của bạn trên AWS, hoàn toàn cách ly với các tài khoản khác.
- CIDR trong lab: `10.0.0.0/16` — nghĩa là có tổng cộng 65,536 địa chỉ IP khả dụng.
- File cấu hình: `vpc.tf`

### 2.2. Subnet (Mạng con)
- Là **phân vùng nhỏ hơn** bên trong VPC.
- Lab sử dụng **2 Public Subnet** ở 2 vùng khả dụng (AZ) khác nhau:
  - **Subnet A** (`10.0.1.0/24`) — AZ `ap-southeast-1a` — Chạy EC2 và ALB.
  - **Subnet B** (`10.0.2.0/24`) — AZ `ap-southeast-1b` — Chạy ALB (đảm bảo High Availability).
- **Tại sao cần 2 Subnet?** AWS yêu cầu ALB phải gắn vào **ít nhất 2 Subnet thuộc 2 AZ khác nhau** để đảm bảo tính sẵn sàng cao (HA).

### 2.3. Internet Gateway (IGW)
- Là **cổng kết nối** giữa VPC và Internet bên ngoài.
- Nếu không có IGW, các máy chủ bên trong VPC sẽ **không thể** truy cập hoặc bị truy cập từ Internet.

### 2.4. Route Table (Bảng định tuyến)
- Chứa các **quy tắc điều hướng traffic** trong VPC.
- Trong lab: Mọi traffic đi ra ngoài (`0.0.0.0/0`) sẽ được chuyển qua Internet Gateway.
- Route Table được **liên kết (associate)** với cả 2 Subnet A và B.

### 2.5. Security Group (Nhóm bảo mật)
- Hoạt động như **tường lửa ảo** kiểm soát traffic vào/ra cho từng tài nguyên.
- Lab có **2 Security Group**:

| Security Group | Inbound (Vào) | Outbound (Ra) |
|---|---|---|
| **ALB-SG** | Port 80 (HTTP) từ `0.0.0.0/0` (toàn bộ Internet) | Tất cả |
| **EC2-SG** | Port 30080 (NodePort) chỉ từ ALB-SG | Tất cả |
| | Port 22 (SSH) chỉ từ `var.my_ip` | |
| | Port 8081 (K8s Proxy) chỉ từ `var.my_ip` | |

- **Câu hỏi hay gặp:** *Tại sao EC2 không mở port 30080 cho `0.0.0.0/0`?*
  - Vì người dùng không truy cập trực tiếp vào EC2. Họ truy cập qua ALB (port 80), ALB sẽ forward tới EC2 (port 30080). Nên chỉ cần cho phép ALB-SG kết nối tới port 30080 là đủ.

### 2.6. EC2 Instance (Máy chủ ảo)
- Loại instance: **t3.medium** (2 vCPU, 4GB RAM) — đủ sức chạy Kind Cluster.
- AMI: **Ubuntu 22.04 LTS** (tìm tự động bằng `data "aws_ami"`).
- **User Data (`user_data.sh`):** Script tự động chạy khi EC2 khởi động lần đầu:
  1. Cài Docker Engine
  2. Cài kubectl
  3. Cài Kind
  4. Tạo Kind Cluster với cấu hình NodePort 30080
  5. Khởi động `kubectl proxy` trên port 8081

### 2.7. Application Load Balancer (ALB)
- Là bộ **cân bằng tải tầng ứng dụng** (Layer 7 — HTTP/HTTPS).
- Nhận request từ Internet (port 80) và phân phối tới Target Group.
- **Target Group:** Nhóm các máy chủ đích. Trong lab, Target Group chỉ chứa 1 EC2, trỏ vào port 30080.
- **Health Check:** ALB định kỳ gửi request tới `/` trên port 30080 để kiểm tra xem ứng dụng còn sống không.

### 2.8. Key Pair (Cặp khóa SSH)
- **TLS Provider** sinh ra cặp khóa RSA 4096-bit.
- **Public key** được đăng ký lên AWS (`aws_key_pair`) và gắn vào EC2.
- **Private key** được ghi xuống file `lab-cd9-key.pem` trên máy local (bằng `local_file`).
- Khi SSH vào EC2, bạn dùng file `.pem` này để xác thực.

---

## Phần 3: Kubernetes — Điều Phối Container

### 3.1. Kubernetes (K8s) là gì?
- Là hệ thống **điều phối container** mã nguồn mở, giúp tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng chạy trong container.

### 3.2. Kind là gì? Tại sao dùng Kind thay Minikube?
- **Kind (Kubernetes in Docker):** Chạy cụm Kubernetes bên trong Docker container.
- **Minikube:** Chạy Kubernetes bằng VM hoặc trực tiếp trên host (`--driver=none`).
- **Lý do chọn Kind:**
  - Minikube với `--driver=none` thường gặp lỗi phân quyền Docker và Systemd trên Ubuntu 22.04.
  - Kind nhẹ hơn, khởi động nhanh hơn và ổn định hơn trên môi trường EC2.
  - Về mặt chức năng, cả hai đều cung cấp một cụm K8s chuẩn.

### 3.3. Các khái niệm K8s trong bài lab (Phải thuộc!)

| Khái niệm | Giải thích | Trong bài lab |
|---|---|---|
| **Node** | Máy chủ chạy Kubernetes (phần cứng/VM) | EC2 Instance chính là Node |
| **Pod** | Đơn vị nhỏ nhất chạy ứng dụng, bọc 1 hoặc nhiều Container | Pod chứa container Nginx |
| **Namespace** | "Phòng làm việc riêng" để gom nhóm tài nguyên, tránh xung đột tên | `lab-cd9` |
| **ConfigMap** | Lưu trữ dữ liệu cấu hình/file tĩnh bên ngoài container | `web-html` chứa file `index.html` |
| **Deployment** | Quản lý vòng đời Pod (tạo, cập nhật, rollback, scale) | `web-app` với `replicas: 1` |
| **Service** | Expose ứng dụng ra ngoài, cung cấp IP/Port ổn định | `web-service` kiểu NodePort trên port `30080` |

### 3.4. Service NodePort là gì?
- **NodePort** là một loại Service trong K8s cho phép truy cập ứng dụng từ bên ngoài cluster thông qua một port cố định trên Node.
- Dải port NodePort: `30000–32767`.
- Trong lab: Port `30080` trên EC2 (Node) sẽ chuyển tiếp traffic vào Port `80` của Pod Nginx.

### 3.5. kubectl proxy là gì?
- Là lệnh tạo một **cổng kết nối tạm thời** (proxy) từ bên ngoài vào Kubernetes API Server.
- Trong lab: `kubectl proxy --port=8081` mở cổng `8081` trên EC2 để Terraform (từ máy local) có thể gọi K8s API để tạo Deployment, Service, v.v.

---

## Phần 4: Luồng Hoạt Động (Flow) — Phải giải thích được!

### 4.1. Luồng Triển Khai (Apply — Chiều xuôi)
```
terraform apply
    ↓
[1] Tạo VPC + Subnet + IGW + Route Table (Mạng)
    ↓
[2] Tạo Security Groups (Tường lửa)
    ↓
[3] Sinh SSH Key (TLS Provider) + Ghi file .pem (Local Provider)
    ↓
[4] Tạo EC2 Instance → Chạy user_data.sh (Docker → Kind → kubectl proxy)
    ↓
[5] null_resource kiểm tra proxy 8081 sẵn sàng
    ↓
[6] Kubernetes Provider kết nối qua proxy → Tạo Namespace → ConfigMap → Deployment → Service
    ↓
[7] Tạo ALB + Target Group + Listener (song song với bước 4-6)
    ↓
✅ Hoàn tất! Truy cập http://<alb-dns-name>
```

### 4.2. Luồng Request của Người Dùng
```
Trình duyệt → http://<alb-dns-name>:80
    ↓
Internet Gateway (IGW)
    ↓
Application Load Balancer (ALB) — Port 80
    ↓
Target Group → Forward tới EC2:30080
    ↓
EC2 (Node) nhận traffic ở port 30080
    ↓
Kind Cluster → Service (NodePort 30080) → Pod (Nginx:80)
    ↓
Nginx đọc file index.html từ ConfigMap → Trả về trang web
```

### 4.3. Luồng Hủy Bỏ (Destroy — Chiều ngược, nhờ depends_on)
```
terraform destroy
    ↓
[1] Xóa Service → Deployment → ConfigMap → Namespace (K8s)
    ↓  ← Lúc này mạng AWS vẫn sống, proxy 8081 vẫn thông
[2] Xóa null_resource, EC2 Instance
    ↓  ← EC2 tắt → Kind Cluster biến mất
[3] Xóa Route Table Associations
    ↓
[4] Xóa Route Table, Internet Gateway
    ↓
[5] Xóa Subnet, ALB, Security Groups
    ↓
[6] Xóa VPC
    ↓
✅ Dọn sạch! Không bị treo!
```

---

## Phần 5: Vấn Đề `depends_on` — Câu hỏi nâng cao hay gặp

### 5.1. Vấn đề gốc (Deadlock khi Destroy)
- Khi không có `depends_on`, Terraform xóa tài nguyên theo thứ tự tùy ý.
- Nó có thể xóa Internet Gateway và Route Table **trước** khi xóa xong Namespace K8s.
- Hậu quả: Đường mạng bị ngắt → Terraform không thể kết nối proxy 8081 để gọi API xóa Namespace → Bị treo vô hạn.

### 5.2. Giải pháp
```hcl
resource "kubernetes_namespace_v1" "web" {
  depends_on = [
    null_resource.wait_for_minikube,
    aws_route_table_association.public_a,
    aws_route_table_association.public_b,
    aws_route_table.public,
    aws_internet_gateway.gw
  ]
}
```
- `depends_on` ép Terraform **tạo** Namespace **sau** khi mạng sẵn sàng.
- Ngược lại khi destroy, Terraform **xóa** Namespace **trước** khi ngắt mạng.
- Kết quả: Quá trình xóa K8s diễn ra khi proxy vẫn hoạt động → Destroy hoàn tất trong vòng 1 phút.

---

## Phần 6: Câu Hỏi Thường Gặp Khi Thuyết Trình (Q&A)

### Câu hỏi về Terraform
> **Q: Tại sao dùng Terraform mà không dùng AWS Console (giao diện web)?**
> A: Terraform cho phép tự động hóa 100%, có thể tái sử dụng code, version control bằng Git, và đảm bảo tính nhất quán (mỗi lần chạy đều cho ra kết quả giống nhau). Dùng Console thì phải click thủ công từng bước, dễ sai sót và không lặp lại được.

> **Q: `terraform plan` khác `terraform apply` thế nào?**
> A: `plan` chỉ xem trước (dry-run), không thay đổi gì trên cloud. `apply` mới thực sự tạo/sửa/xóa tài nguyên.

> **Q: Nếu xóa file `terraform.tfstate` thì sao?**
> A: Terraform sẽ "mất trí nhớ", không biết hạ tầng nào đang chạy trên AWS. Lần chạy `apply` tiếp theo, nó sẽ cố tạo mới tất cả → Bị lỗi trùng tên tài nguyên trên AWS.

### Câu hỏi về AWS
> **Q: Tại sao cần 2 Subnet?**
> A: AWS yêu cầu ALB phải gắn vào ít nhất 2 Subnet thuộc 2 Availability Zone khác nhau để đảm bảo tính sẵn sàng cao (High Availability). Nếu AZ-a bị sập, ALB vẫn hoạt động ở AZ-b.

> **Q: Security Group khác gì với Firewall truyền thống?**
> A: Security Group là tường lửa ảo hoạt động ở cấp độ instance (gắn trực tiếp vào EC2/ALB). Nó là **stateful** — nghĩa là nếu cho phép traffic vào, response tự động được cho phép đi ra mà không cần khai báo thêm rule outbound.

> **Q: ALB khác gì NLB?**
> A: ALB (Application Load Balancer) hoạt động ở Layer 7 (HTTP/HTTPS), hiểu được URL, header, cookie. NLB (Network Load Balancer) hoạt động ở Layer 4 (TCP/UDP), nhanh hơn nhưng không hiểu nội dung HTTP.

### Câu hỏi về Kubernetes
> **Q: Pod khác gì Container?**
> A: Container là tiến trình chạy ứng dụng (ví dụ: Nginx). Pod là lớp bọc bên ngoài Container, cung cấp IP riêng và quản lý vòng đời. Một Pod có thể chứa nhiều Container chia sẻ cùng network và storage.

> **Q: Tại sao dùng ConfigMap thay vì build HTML vào Docker Image?**
> A: Để tách biệt code và cấu hình. Khi cần sửa giao diện, chỉ cần cập nhật ConfigMap mà không phải build lại Docker Image (tiết kiệm 2-3 phút mỗi lần sửa).

> **Q: NodePort khác gì ClusterIP và LoadBalancer?**
> A: ClusterIP chỉ truy cập được từ bên trong cluster. NodePort mở port trên Node để truy cập từ bên ngoài (dải 30000-32767). LoadBalancer tự động tạo Load Balancer trên cloud provider (nhưng trong lab ta đã dùng ALB riêng nên chọn NodePort).

### Câu hỏi về Bảo mật
> **Q: Hacker lấy được file SSH key .pem thì có vào được EC2 không?**
> A: Nếu bạn đặt biến `my_ip` đúng IP của mình (thay vì `0.0.0.0/0`), thì KHÔNG. Security Group của EC2 sẽ chặn mọi kết nối SSH từ IP không khớp, dù có đúng key cũng không vào được.

> **Q: Tại sao không dùng HTTPS?**
> A: HTTPS cần chứng chỉ SSL từ AWS ACM, mà ACM yêu cầu phải có tên miền riêng (domain). Bài lab dùng URL mặc định của ALB nên không thể cấp SSL. Với mục đích học tập, HTTP là đủ.

---

## Phần 7: Cấu Trúc File Dự Án (Phải nhớ mỗi file làm gì!)

| File | Mục đích |
|---|---|
| `providers.tf` | Khai báo 4 provider (AWS, TLS, Local, Kubernetes) và cấu hình kết nối |
| `variables.tf` | Khai báo các biến đầu vào (region, instance type, IP, port) |
| `locals.tf` | Định nghĩa giá trị tái sử dụng (name prefix, common tags) |
| `data.tf` | Truy vấn AMI Ubuntu 22.04 mới nhất từ AWS |
| `vpc.tf` | Tạo VPC, Subnet A/B, IGW, Route Table và liên kết |
| `security_groups.tf` | Tạo 2 Security Group cho ALB và EC2 |
| `key_pair.tf` | Sinh SSH key, đăng ký lên AWS, ghi file .pem |
| `ec2.tf` | Tạo EC2 Instance và null_resource kiểm tra proxy |
| `alb.tf` | Tạo ALB, Target Group, Listener và gắn EC2 |
| `kubernetes.tf` | Tạo Namespace, ConfigMap, Deployment, Service (có depends_on) |
| `outputs.tf` | Xuất URL ALB, IP EC2, lệnh SSH, link proxy |
| `scripts/user_data.sh` | Script bootstrap cài Docker, Kind, kubectl, tạo cluster, chạy proxy |
| `scripts/index.html` | Trang giao diện web tùy chỉnh của bạn |

---

## Phần 8: Code Thực Tế — Giải Thích Từng Dòng

### 8.1. EC2 Instance (`ec2.tf`)
```hcl
resource "aws_instance" "minikube" {
  ami           = data.aws_ami.ubuntu.id        # AMI Ubuntu 22.04 (truy vấn tự động từ data source)
  instance_type = var.instance_type             # t3.medium (2 vCPU, 4GB RAM)
  key_name      = aws_key_pair.deployer.key_name # Gắn SSH public key vào EC2
  subnet_id     = aws_subnet.public_a.id         # Đặt EC2 trong Subnet A (có public IP)

  vpc_security_group_ids = [aws_security_group.ec2_sg.id] # Gắn tường lửa EC2-SG

  # Đọc file user_data.sh và truyền biến proxy_port = 8081 vào bên trong script
  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    proxy_port = var.proxy_port
  })

  root_block_device {
    volume_size           = 20    # Ổ cứng 20GB
    volume_type           = "gp3" # Loại ổ SSD hiệu suất cao
    delete_on_termination = true  # Tự xóa ổ cứng khi EC2 bị hủy
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-minikube"  # Tên hiển thị: "lab-cd9-minikube"
  })
}
```

**Các điểm cần nắm:**
- `data.aws_ami.ubuntu.id` — Tham chiếu đến kết quả của data source, trả về ID của AMI Ubuntu mới nhất.
- `templatefile()` — Hàm đọc file script và thay thế `${proxy_port}` bên trong bằng giá trị thực (8081).
- `merge()` — Hàm gộp 2 map lại với nhau (gộp common_tags + tag Name riêng).
- `${path.module}` — Biến đặc biệt của Terraform, trả về đường dẫn tới thư mục chứa file `.tf` hiện tại.

### 8.2. null_resource (`ec2.tf`)
```hcl
resource "null_resource" "wait_for_minikube" {
  depends_on = [aws_instance.minikube]  # Chỉ chạy SAU KHI EC2 đã được tạo

  connection {
    type        = "ssh"                              # Kết nối bằng giao thức SSH
    user        = "ubuntu"                           # User mặc định của Ubuntu AMI
    private_key = tls_private_key.ssh.private_key_pem # Dùng key vừa sinh từ TLS provider
    host        = aws_instance.minikube.public_ip    # IP công khai của EC2
  }

  provisioner "remote-exec" {   # Chạy lệnh TRÊN MÁY EC2 (không phải máy local)
    inline = [
      "sudo cloud-init status --wait",   # Đợi user_data.sh chạy xong
      "until curl -s http://localhost:${var.proxy_port}/api/v1/namespaces > /dev/null 2>&1; do sleep 5; done",
      # ↑ Liên tục thử gọi API proxy cho đến khi nó phản hồi thành công
    ]
  }
}
```

### 8.3. Kubernetes Deployment (`kubernetes.tf`)
```hcl
resource "kubernetes_deployment_v1" "web" {
  metadata {
    name      = "web-app"                                      # Tên của Deployment
    namespace = kubernetes_namespace_v1.web.metadata[0].name   # Thuộc namespace lab-cd9
    labels    = { app = "web-app" }                            # Nhãn để liên kết với Service
  }

  spec {
    replicas = 1  # Số lượng Pod cần duy trì (1 bản sao)

    selector {
      match_labels = { app = "web-app" }  # Deployment quản lý các Pod có label app=web-app
    }

    template {      # Khuôn mẫu để tạo Pod
      metadata {
        labels = { app = "web-app" }   # Pod được gắn label này
        annotations = {
          # Hash của file HTML → Khi HTML thay đổi, hash đổi → Terraform phát hiện và redeploy Pod
          "configmap-hash" = sha256(file("${path.module}/scripts/index.html"))
        }
      }

      spec {
        container {
          name  = "nginx"          # Tên container bên trong Pod
          image = "nginx:alpine"   # Docker Image: Nginx phiên bản nhẹ (chỉ ~40MB)

          port {
            container_port = 80    # Container lắng nghe port 80
          }

          volume_mount {
            name       = "html-volume"                 # Tên volume cần mount
            mount_path = "/usr/share/nginx/html"       # Ghi đè thư mục HTML mặc định của Nginx
            read_only  = true                          # Chỉ đọc, không cho phép ghi
          }

          resources {
            limits   = { cpu = "500m", memory = "256Mi" }   # Giới hạn tối đa: 0.5 CPU, 256MB RAM
            requests = { cpu = "100m", memory = "128Mi" }   # Yêu cầu tối thiểu: 0.1 CPU, 128MB RAM
          }
        }

        volume {
          name = "html-volume"
          config_map {
            name = kubernetes_config_map_v1.web_html.metadata[0].name  # Gắn ConfigMap web-html làm volume
          }
        }
      }
    }
  }
}
```

**Mối quan hệ giữa các thành phần:**
```
Deployment (web-app)
    │
    ├── selector: app=web-app     ← Deployment tìm và quản lý Pod theo label này
    │
    └── template (Khuôn mẫu Pod)
         │
         ├── labels: app=web-app  ← Pod được gắn label khớp với selector
         │
         ├── Container: nginx:alpine (port 80)
         │       │
         │       └── volume_mount: /usr/share/nginx/html ← Ghi đè file HTML
         │
         └── Volume: html-volume
                 │
                 └── config_map: web-html ← Nội dung file index.html
```

### 8.4. Service NodePort (`kubernetes.tf`)
```hcl
resource "kubernetes_service_v1" "web" {
  spec {
    type = "NodePort"                # Kiểu Service: mở port trên Node

    selector = { app = "web-app" }   # Forward traffic tới Pod có label app=web-app

    port {
      port        = 80               # Port của Service (bên trong cluster)
      target_port = 80               # Port của Container Nginx
      node_port   = 30080            # Port mở ra trên Node (EC2) để nhận traffic từ bên ngoài
    }
  }
}
```

**Luồng traffic qua Service:**
```
Bên ngoài (ALB) → EC2:30080 (node_port) → Service:80 (port) → Pod/Container:80 (target_port)
```

### 8.5. Security Group (`security_groups.tf`)
```hcl
resource "aws_security_group" "ec2_sg" {
  name   = "${local.name_prefix}-ec2-sg"
  vpc_id = aws_vpc.main.id

  # Inbound: Chỉ cho ALB gửi traffic vào port 30080
  ingress {
    from_port       = var.app_port          # 30080
    to_port         = var.app_port          # 30080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # ← Chỉ cho phép từ ALB-SG (KHÔNG phải IP)
  }

  # Inbound: SSH chỉ từ IP của bạn
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]               # ← "0.0.0.0/0" hoặc "123.45.67.89/32"
  }
}
```

**Lưu ý:** `security_groups = [...]` khác với `cidr_blocks = [...]`:
- `security_groups`: Cho phép traffic từ **tài nguyên thuộc Security Group** khác (không cần biết IP).
- `cidr_blocks`: Cho phép traffic từ **dải IP cụ thể**.

---

## Phần 9: Ingress, Expose và Các Cách Truy Cập Ứng Dụng K8s

### 9.1. "Expose" nghĩa là gì?
- **Expose** = "Phơi bày" ứng dụng ra bên ngoài. Mặc định, Pod chỉ có IP nội bộ trong cluster, không ai từ bên ngoài truy cập được. Muốn người dùng truy cập được, bạn phải **expose** nó thông qua Service.

### 9.2. So sánh 3 loại Service trong K8s

| Loại Service | Phạm vi truy cập | Port | Khi nào dùng? | Trong lab? |
|---|---|---|---|---|
| **ClusterIP** | Chỉ bên trong cluster | Nội bộ | Giao tiếp giữa các ứng dụng trong cùng cluster | ❌ Không dùng |
| **NodePort** | Từ bên ngoài, qua IP của Node | 30000-32767 | Truy cập trực tiếp qua IP máy chủ + port | ✅ **Đang dùng** (port 30080) |
| **LoadBalancer** | Từ Internet, qua Load Balancer của cloud | 80/443 | Tự động tạo Cloud LB (ELB trên AWS) | ❌ Không dùng (ta tự tạo ALB riêng) |

### 9.3. Ingress là gì? Lab có dùng không?
- **Ingress** là tài nguyên K8s dùng để **định tuyến HTTP/HTTPS** từ bên ngoài vào các Service bên trong cluster (giống như một reverse proxy nội bộ).
- **Lab KHÔNG dùng Ingress** vì ta đã có **AWS ALB** đóng vai trò tương tự (nhận HTTP port 80 → forward vào NodePort 30080).
- Ingress thường được dùng khi bạn có **nhiều ứng dụng** trong 1 cluster và muốn phân luồng theo URL path (ví dụ: `/api` → Service A, `/web` → Service B).

### 9.4. Tóm tắt cách truy cập ứng dụng trong Lab
```
Internet → ALB (Port 80) → EC2:30080 (NodePort) → Pod:80 (Nginx)
            ↑                    ↑                      ↑
     AWS ALB thay thế       Service NodePort         Container
     vai trò Ingress        expose ra Node          chạy ứng dụng
```

---

## Phần 10: `null_resource` vs `null` Provider — Phân Biệt Rõ Ràng

### 10.1. `null` Provider là gì?
- Là một **Terraform Provider** (plugin) do HashiCorp phát hành.
- Được khai báo ngầm định khi bạn sử dụng `null_resource` (không cần khai báo tường minh trong `required_providers`).
- Nó cung cấp duy nhất một loại resource: `null_resource`.

### 10.2. `null_resource` là gì?
- Là một **tài nguyên ảo** (không tạo ra thứ gì trên cloud).
- Dùng để **chạy các tác vụ phụ trợ** mà Terraform không hỗ trợ sẵn, ví dụ:
  - SSH vào máy chủ để chạy lệnh (provisioner `remote-exec`)
  - Chạy script trên máy local (provisioner `local-exec`)
  - Đợi một điều kiện nào đó hoàn tất trước khi tiếp tục

### 10.3. Trong Lab, `null_resource` dùng để làm gì?
```hcl
resource "null_resource" "wait_for_minikube" {
  # Mục đích: SSH vào EC2 để kiểm tra xem cloud-init và proxy đã sẵn sàng chưa
  # Nếu không có bước này, Kubernetes Provider sẽ cố kết nối proxy 8081 ngay lập tức
  # trong khi EC2 vẫn đang cài Docker/Kind → Lỗi "connection refused"
}
```

### 10.4. Tóm tắt mối quan hệ
```
null Provider (plugin)
    │
    └── cung cấp → null_resource (tài nguyên ảo)
                        │
                        ├── provisioner "remote-exec"  → Chạy lệnh trên máy xa (EC2)
                        └── provisioner "local-exec"   → Chạy lệnh trên máy local
```

---

## Phần 11: Provisioner — Các Loại Provisioner Trong Terraform

### 11.1. Provisioner là gì?
- Là khối code bên trong `resource` dùng để **thực thi hành động bổ sung** sau khi tài nguyên được tạo.
- Terraform không khuyến khích dùng nhiều provisioner (vì khó quản lý state), nhưng trong một số trường hợp như lab này thì rất cần thiết.

### 11.2. Các loại Provisioner trong Lab

| Provisioner | Chạy ở đâu? | Mục đích trong lab | File |
|---|---|---|---|
| `remote-exec` | Trên máy **EC2** (qua SSH) | Đợi cloud-init chạy xong, kiểm tra proxy 8081 | `ec2.tf` |
| `file` | Copy file từ local lên **EC2** | (Không dùng trong phiên bản hiện tại) | — |
| `local-exec` | Trên máy **local** của bạn | (Không dùng trong lab này) | — |

### 11.3. `connection` block
- Provisioner cần biết **cách kết nối** vào máy chủ đích. Block `connection` cung cấp thông tin này:
```hcl
connection {
  type        = "ssh"                                    # Giao thức: SSH
  user        = "ubuntu"                                 # User trên EC2
  private_key = tls_private_key.ssh.private_key_pem      # Key SSH (từ TLS provider)
  host        = aws_instance.minikube.public_ip          # IP công khai của EC2
}
```

---

## Phần 12: Hàm Terraform Sử Dụng Trong Lab

| Hàm | Giải thích | Ví dụ trong lab |
|---|---|---|
| `merge(map1, map2)` | Gộp 2 map/object lại | `merge(local.common_tags, { Name = "..." })` — Gộp tags chung + tag Name riêng |
| `templatefile(path, vars)` | Đọc file và thay thế biến `${...}` | `templatefile("scripts/user_data.sh", { proxy_port = 8081 })` |
| `file(path)` | Đọc nội dung file thành chuỗi | `file("scripts/index.html")` — Đọc HTML nhúng vào ConfigMap |
| `sha256(string)` | Tính mã hash SHA-256 | `sha256(file("scripts/index.html"))` — Tạo hash để phát hiện thay đổi |

### `templatefile()` vs `file()` — Khác nhau thế nào?
- `file()`: Đọc file nguyên bản, **không** thay thế biến. Dùng khi nội dung file là tĩnh (ví dụ: HTML).
- `templatefile()`: Đọc file và **thay thế** các biến `${...}` bên trong. Dùng khi file cần tham số hóa (ví dụ: script shell cần biết port).

---

## Phần 13: Mạng và CIDR — Giải Thích Dễ Hiểu

### 13.1. CIDR là gì?
- **CIDR** (Classless Inter-Domain Routing) là cách viết tắt để biểu diễn một dải địa chỉ IP.
- Ký hiệu: `IP/số_bit_mạng`. Số sau dấu `/` càng nhỏ thì dải IP càng rộng.

### 13.2. CIDR trong Lab
| CIDR | Ý nghĩa | Số IP khả dụng | Dùng cho |
|---|---|---|---|
| `10.0.0.0/16` | Toàn bộ mạng VPC | 65,536 IP | VPC chính |
| `10.0.1.0/24` | Mạng con nhỏ hơn | 256 IP | Subnet A (AZ-a) |
| `10.0.2.0/24` | Mạng con nhỏ hơn | 256 IP | Subnet B (AZ-b) |
| `0.0.0.0/0` | Tất cả IP trên Internet | Toàn bộ | Route Table (default route), SG inbound |
| `123.45.67.89/32` | Chính xác 1 IP duy nhất | 1 IP | Biến `my_ip` (khóa SSH chặt) |

### 13.3. Tại sao Subnet `/24` nằm trong VPC `/16`?
```
VPC:      10.0. 0.0 /16  → 10.0.x.x  (x có thể là 0-255)
Subnet A: 10.0. 1.0 /24  → 10.0.1.x  (x có thể là 0-255)
Subnet B: 10.0. 2.0 /24  → 10.0.2.x  (x có thể là 0-255)
```
Subnet là **tập con** của VPC. VPC có 65,536 IP, mỗi Subnet chiếm 256 IP.

---

## Phần 14: Bảng Thuật Ngữ Tổng Hợp (Glossary)

| Thuật ngữ | Viết tắt | Giải thích ngắn gọn |
|---|---|---|
| Infrastructure as Code | IaC | Viết code để quản lý hạ tầng thay vì click tay |
| HashiCorp Configuration Language | HCL | Ngôn ngữ viết file `.tf` của Terraform |
| Virtual Private Cloud | VPC | Mạng ảo riêng của bạn trên AWS |
| Availability Zone | AZ | Trung tâm dữ liệu vật lý trong 1 Region |
| Internet Gateway | IGW | Cổng kết nối VPC ra Internet |
| Application Load Balancer | ALB | Bộ cân bằng tải HTTP/HTTPS (Layer 7) |
| Network Load Balancer | NLB | Bộ cân bằng tải TCP/UDP (Layer 4) |
| Security Group | SG | Tường lửa ảo gắn vào tài nguyên AWS |
| Amazon Machine Image | AMI | Bản snapshot hệ điều hành để tạo EC2 |
| Elastic Compute Cloud | EC2 | Dịch vụ máy chủ ảo của AWS |
| Kubernetes | K8s | Hệ thống điều phối container |
| Kubernetes in Docker | Kind | Công cụ chạy cluster K8s bên trong Docker |
| Container | — | Tiến trình ứng dụng chạy cách ly (Docker) |
| Pod | — | Đơn vị nhỏ nhất trong K8s, bọc 1+ container |
| Node | — | Máy chủ chạy Pod (EC2 trong lab) |
| Namespace | NS | Không gian tên để phân tách tài nguyên K8s |
| ConfigMap | CM | Lưu trữ dữ liệu cấu hình dạng key-value |
| Deployment | Deploy | Quản lý Pod: tạo, scale, update, rollback |
| Service | SVC | Expose Pod ra ngoài qua IP/Port ổn định |
| NodePort | — | Loại Service mở port 30000-32767 trên Node |
| ClusterIP | — | Loại Service chỉ truy cập nội bộ cluster |
| Ingress | — | Định tuyến HTTP/HTTPS vào cluster (lab không dùng) |
| Provisioner | — | Chạy script bổ sung sau khi tạo tài nguyên |
| User Data | — | Script shell chạy tự động khi EC2 khởi động lần đầu |
| CIDR | — | Cách biểu diễn dải địa chỉ IP (ví dụ: `10.0.0.0/16`) |
| Health Check | — | Kiểm tra định kỳ xem ứng dụng còn sống không |
| Target Group | TG | Nhóm máy chủ đích mà ALB forward traffic tới |
| High Availability | HA | Khả năng hoạt động liên tục, không gián đoạn |
| Stateful (Security Group) | — | Cho phép response tự động đi ra nếu request đã được cho vào |
| `depends_on` | — | Ràng buộc thứ tự tạo/xóa tài nguyên trong Terraform |
| `terraform.tfstate` | State | File JSON lưu trạng thái hạ tầng hiện tại |

