# Lab CD9 — 1-Click: Terraform → EC2 (Minikube driver=none) → ALB

## ✅ Checklist đối chiếu đề bài & Sơ đồ

| # | Ràng buộc / Yêu cầu trong sơ đồ | Cách đáp ứng trong plan | Trạng thái |
|---|---|---|:---:|
| 1 | Hạ tầng dựng bằng **Terraform** | EC2, ALB, SG, Target Group, Key Pair — viết trong các file `.tf` | ✅ |
| 2 | Cụm K8s chạy bằng **Minikube** trên EC2 | Cài Docker + Minikube với `--driver=none` qua `user_data.sh` | ✅ |
| 3 | App chạy **trong K8s** (Nginx) | Deploy `nginx:alpine` (replicas: 1) và NodePort Service | ✅ |
| 4 | App truy cập từ **Internet qua ALB** | ALB :80 → Target Group → EC2:30080 (NodePort) → Pod | ✅ |
| 5 | **Một lệnh** dựng tất cả (1-click) | `terraform apply` tự tạo key, EC2, ALB, tự cấu hình K8s app | ✅ |
| 6 | Dùng **≥2 provider** (wire provider khác) | Provider 1: **`aws`** (hạ tầng) + Provider 2: **`tls`** (gen SSH Key để truyền vào `aws_key_pair`) | ✅ |

---

## So sánh: Sơ đồ của bạn vs Bản kế hoạch cũ

Sơ đồ của bạn đề xuất một kiến trúc rất thực tế và ổn định hơn bản kế hoạch cũ. Dưới đây là phân tích chi tiết:

| Tiêu chí | Trong Sơ đồ của bạn | Bản kế hoạch cũ | Ưu điểm của sơ đồ |
| :--- | :--- | :--- | :--- |
| **Minikube Driver** | `--driver=none` | `--driver=docker` | **`--driver=none` đơn giản hơn**: Minikube chạy trực tiếp trên host, tự động bind port `30080` ra IP của EC2. Không cần cài `socat` hay chạy port-forward ngầm cực kỳ dễ lỗi. |
| **Cách Deploy App K8s** | Dùng **User Data** (`kubectl apply` các file manifest) | Dùng **Kubernetes Provider** viết bằng code HCL (`kubernetes.tf`) | **Ổn định hơn nhiều**: Tránh lỗi vòng lặp phụ thuộc (dependency cycle) trong Terraform khi cố gắng kết nối K8s Provider vào cụm Minikube chưa khởi tạo xong. |
| **Hệ điều hành EC2** | `Ubuntu 22.04` | `Amazon Linux 2` | Ubuntu là môi trường chuẩn và ổn định nhất để chạy Minikube `--driver=none`. |
| **Providers sử dụng** | `aws` + `tls` | `aws` + `kubernetes` + `tls` | Giảm bớt sự phức tạp của Kubernetes Provider, vẫn đáp ứng yêu cầu "wire 2 providers" bằng cách dùng `tls` để sinh SSH Key rồi truyền sang `aws`. |

> [!TIP]
> **Quyết định:** Tôi đã cập nhật toàn bộ bản kế hoạch bên dưới theo đúng **Sơ đồ** của bạn để đảm bảo bài lab chạy mượt mà, dễ debug và ổn định nhất.

---

## Sơ đồ kiến trúc (Khớp 100% sơ đồ của bạn)

```text
  Developer (terraform init/plan/apply)
       │
       ▼
   Terraform
   ├── Provider 1: aws (AWS Cloud Infrastructure)
   └── Provider 2: tls (Generate Private Key) ──► Wired to aws_key_pair
       │
       ▼
┌────────────────────────────── AWS Cloud ──────────────────────────────┐
│                                                                       │
│  ┌─────────────────────── Default VPC ─────────────────────────────┐  │
│  │                                                                 │  │
│  │  ┌── Public Subnet A (AZ-a) ──┐      ┌── Public Subnet B (AZ-b) ──┐ │  │
│  │  │                            │      │                            │ │  │
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
│  │  │                                                               │  │  │
│  │  │    Ubuntu 22.04 (t3.medium)                                   │  │  │
│  │  │    └─ User Data Bootstrap:                                    │  │  │
│  │  │       1. Install Docker                                       │  │  │
│  │  │       2. Install kubectl                                      │  │  │
│  │  │       3. Install Minikube                                     │  │  │
│  │  │       4. Start Minikube (--driver=none)                       │  │  │
│  │  │       5. Apply deployment.yaml (nginx:alpine, replica: 1)     │  │  │
│  │  │       6. Apply service-nodeport.yaml (NodePort: 30080)        │  │  │
│  │  │       7. Wait for Service Ready                               │  │  │
│  │  │                                                               │  │  │
│  │  │    ┌────────────────── Minikube Cluster ──────────────────┐   │  │  │
│  │  │    │                                                      │   │  │  │
│  │  │    │  [Deployment: nginx:alpine] ──► [Service: NodePort]  │   │  │  │
│  │  │    │        (replicas: 1)              (Port: 30080)      │   │  │  │
│  │  │    └──────────────────────────────────────────────────────┘   │  │  │
│  │  └───────────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘

Outputs:
  • alb_dns_name = http://<alb-dns-name>  ──► Access from Internet
  • instance_public_ip = <public-ip-for-ssh>
```

---

## Cấu trúc thư mục

Chúng ta sẽ tạo thư mục `lab-cd9` với các file sau:

```text
lab-cd9/
├── README.md                   # Hướng dẫn và sơ đồ (giống như bạn yêu cầu)
├── providers.tf                # Khai báo AWS + TLS + Local providers
├── variables.tf                # aws_region, instance_type, my_ip, app_port
├── locals.tf                   # Tags chung, name_prefix
├── data.tf                     # Data sources: Ubuntu 22.04 AMI, default VPC, Subnets
├── security_groups.tf          # SG cho ALB và SG cho EC2
├── key_pair.tf                 # 🆕 Tạo SSH Key bằng TLS provider và import lên AWS
├── ec2.tf                      # Dựng EC2 và nạp user_data.sh
├── alb.tf                      # ALB, Target Group, Listener & Attachment
├── outputs.tf                  # URL ALB, IP public, câu lệnh SSH debug
└── scripts/
    ├── user_data.sh            # Script cài Docker, Minikube và deploy app
    ├── deployment.yaml         # Manifest Deployment nginx
    └── service-nodeport.yaml   # Manifest Service NodePort 30080
```

---

## Chi tiết các thay đổi (Proposed Changes)

### 1. [NEW] [providers.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/providers.tf)
Khai báo các providers cần thiết. Ở đây ta wire 3 provider: `aws`, `tls` (tạo key), `local` (lưu file key).

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### 2. [NEW] [variables.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/variables.tf)
Các biến để dễ tùy biến cấu hình:
- `aws_region`: Mặc định `"ap-southeast-1"`.
- `instance_type`: Mặc định `"t3.medium"` (Minikube bắt buộc ≥ 2 vCPUs).
- `my_ip`: IP của bạn để giới hạn quyền SSH bảo mật.
- `app_port`: Mặc định `30080` (NodePort).

### 3. [NEW] [locals.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/locals.tf)
Khai báo các tags chung và tiền tố tên resource.
```hcl
locals {
  name_prefix = "lab-cd9"
  common_tags = {
    Project     = "CD9-Automation"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}
```

### 4. [NEW] [data.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/data.tf)
Lấy thông tin động từ AWS. **Quan trọng là dùng Ubuntu 22.04 LTS**.
```hcl
# Tìm Ubuntu 22.04 AMI mới nhất
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Lấy VPC mặc định
data "aws_vpc" "default" {
  default = true
}

# Lấy các Subnet trong VPC mặc định (để ALB span qua nhiều AZ)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```

### 5. [NEW] [key_pair.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/key_pair.tf)
**Minh chứng wiring 2 providers (`tls` và `aws`)**: 
1. Sinh private key RSA bằng `tls`.
2. Truyền public key sang `aws_key_pair` để tạo SSH key trên AWS.
3. Dùng `local_file` để lưu private key xuống máy local của dev để SSH.

```hcl
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh
  tags       = local.common_tags
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/${local.name_prefix}-key.pem"
  file_permission = "0400"
}
```

### 6. [NEW] [security_groups.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/security_groups.tf)
Khai báo Security Group:
- `alb_sg`: Mở port 80 cho toàn bộ Internet (`0.0.0.0/0`).
- `ec2_sg`:
  - Mở port 30080 **chỉ từ ALB SG** (Target Group forward qua đây).
  - Mở port 22 (SSH) từ `var.my_ip`.
  - Outbound: Allow All (để EC2 tải Docker/Minikube từ Internet).

### 7. [NEW] [scripts/deployment.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/scripts/deployment.yaml)
Manifest K8s Deployment chạy app nginx đơn giản.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "500m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
```

### 8. [NEW] [scripts/service-nodeport.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/scripts/service-nodeport.yaml)
Manifest K8s Service expose app qua NodePort 30080.
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

### 9. [NEW] [scripts/user_data.sh](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/scripts/user_data.sh)
Script tự động chạy khi EC2 khởi tạo. Script này sẽ:
1. Cài đặt các thư viện cần thiết, Docker, kubectl và Minikube.
2. Khởi động Minikube với `--driver=none`.
3. Tạo trực tiếp các file manifest K8s (hoặc copy từ file) và chạy `kubectl apply`.
4. Đợi cho Service K8s và Pod sẵn sàng để phục vụ.

```bash
#!/bin/bash
set -euxo pipefail

# Redirect logs để dễ debug
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== 1. Cap nhat he thong & Cai dat Docker ==="
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release conntrack socat

# Cài Docker Engine
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Đảm bảo docker group và permissions
systemctl enable docker
systemctl start docker

echo "=== 2. Cai dat kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

echo "=== 3. Cai dat Minikube ==="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

echo "=== 4. Khoi dong Minikube voi driver=none ==="
# Minikube driver=none yeu cau chay duoi quyen root va su dung Docker co san tren host
export CHANGE_MINIKUBE_NONE_USER=true
minikube start --driver=none --kubernetes-version=v1.28.3

echo "=== 5. Tao va Apply K8s Manifests ==="
# Ghi de file manifest từ template/heredoc (de phong viec file copy bi loi)
cat <<'EOF' > /tmp/deployment.yaml
${deployment_yaml}
EOF

cat <<'EOF' > /tmp/service-nodeport.yaml
${service_yaml}
EOF

kubectl apply -f /tmp/deployment.yaml
kubectl apply -f /tmp/service-nodeport.yaml

echo "=== 6. Doi Service san sang ==="
kubectl rollout status deployment/web-app --timeout=300s

echo "=== BOOTSTRAP HOAN TAT ==="
touch /var/log/bootstrap_done
```

### 10. [NEW] [ec2.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/ec2.tf)
Tạo EC2 Instance Ubuntu 22.04, truyền variables vào `user_data.sh` thông qua hàm `templatefile()` của Terraform.
Có sử dụng `remote-exec` để đợi `user_data.sh` chạy hoàn thành, tránh trường hợp Terraform báo apply xong nhưng Web app thực tế chưa chạy.

```hcl
resource "aws_instance" "minikube" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = tolist(data.aws_subnets.default.ids)[0]
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Truyền manifest vào user_data thông qua templatefile
  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    deployment_yaml = file("${path.module}/scripts/deployment.yaml")
    service_yaml    = file("${path.module}/scripts/service-nodeport.yaml")
  })

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-minikube"
  })
}

# Đợi cho user_data script chạy xong hoàn toàn
resource "null_resource" "wait_for_minikube" {
  depends_on = [aws_instance.minikube]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    host        = aws_instance.minikube.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init (user_data) to complete...'",
      "sudo cloud-init status --wait",
      "echo '=== Kubernetes Pods ==='",
      "sudo kubectl get pods -A",
      "echo '=== Kubernetes Services ==='",
      "sudo kubectl get svc"
    ]
  }
}
```

### 11. [NEW] [alb.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/alb.tf)
Cấu hình ALB phân phối lưu lượng:
- ALB nhận cổng `:80` từ Internet, chuyển tiếp vào Target Group cổng `:30080`.
- Target Group định nghĩa cổng `:30080` (NodePort) của EC2 và có Health Check path `/`.
- Đính kèm EC2 Instance vào Target Group.

### 12. [NEW] [outputs.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/outputs.tf)
Các output giúp bạn nhanh chóng sử dụng:
```hcl
output "alb_dns_name" {
  description = "URL truy cap ung dung qua Internet"
  value       = "http://${aws_lb.app.dns_name}"
}

output "instance_public_ip" {
  description = "IP Public cua EC2 instance"
  value       = aws_instance.minikube.public_ip
}

output "ssh_command" {
  description = "Lenh SSH vao EC2 nhanh chong"
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.minikube.public_ip}"
}
```

---

## 🔗 Chuỗi phụ thuộc & Thứ tự dựng (Dependency Chain)

Cập nhật lại sơ đồ thứ tự dựng vì không còn dùng Kubernetes Provider từ local:

```text
  data.aws_ami ──┐
  data.aws_vpc ──┼─► [Tự động truy vấn thông tin]
  data.aws_subnets┘
        │
        ▼
  tls_private_key (Tạo SSH key ngẫu nhiên trên máy local)
        │
        ├─────────────────────────────────────────┐
        ▼ (Public Key)                            ▼ (Private Key)
  aws_key_pair (Đăng ký key lên AWS)         local_file (Ghi key.pem xuống máy local)
        │                                         │
        ├─────────────────────────────────────────┘
        ▼
  aws_security_group (alb_sg & ec2_sg)
        │
        ├─────────────────────────────────────────┐
        ▼                                         ▼
  aws_instance.minikube                       aws_lb.app (ALB)
  (Nạp user_data.sh & bắt đầu chạy ngầm)       (Span qua 2 Subnet công cộng)
        │                                         │
        ▼                                         ▼
  null_resource.wait_for_minikube            aws_lb_target_group (Port 30080)
  (SSH remote-exec: đợi cloud-init hoàn tất)  aws_lb_listener (Port 80 -> Target Group)
        │                                         │
        │                                         ▼
        │                              aws_lb_target_group_attachment
        │                              (Gắn EC2 vào Target Group)
        ▼                                         │
  [K8s App Running] (Port 30080 mở trên host)     │
        │                                         │
        └───────────────────┬─────────────────────┘
                            ▼
                     [ALB Health Check Pass]
                            │
                            ▼
              Truy cập: http://<alb-dns-name>
```

---

## ⚠️ Vấn đề kỹ thuật & Cách giải quyết (Mới)

### Vấn đề 1: Lỗi gián đoạn do Minikube driver=none dùng chung Docker với host
- **Mô tả**: Khi chạy `--driver=none`, Minikube chia sẻ Docker daemon trực tiếp với hệ điều hành Ubuntu. Đôi khi có sự xung đột về systemd/cgroup hoặc service Docker bị khởi động lại giữa chừng khiến Minikube bị lỗi "kubelet not healthy".
- **Giải pháp**: Thiết lập `export CHANGE_MINIKUBE_NONE_USER=true` trước khi chạy `minikube start`. Sử dụng phiên bản Kubernetes và Minikube tương thích ổn định nhất (như `v1.28.3`) và đảm bảo Docker được bật sẵn sàng trước khi chạy.

### Vấn đề 2: Đồng bộ hóa quá trình bootstrap
- **Mô tả**: Terraform tạo EC2 chỉ mất 30 giây và sẽ báo hoàn thành, nhưng tiến trình cài đặt Docker + Minikube ngầm trong `user_data.sh` mất 3–5 phút. Nếu người dùng truy cập ngay hoặc Terraform kết thúc ngay, ALB sẽ trả về `502 Bad Gateway` vì Target Group chưa thấy cổng 30080 mở.
- **Giải pháp**: Sử dụng `null_resource` kèm provisioner `remote-exec` chạy câu lệnh `sudo cloud-init status --wait`. Lệnh này sẽ **chặn (block)** tiến trình Terraform cho tới khi script `user_data.sh` chạy xong 100%. Người dùng sẽ thấy trạng thái chạy cụ thể ngay trên terminal.

---

## Verification Plan

### Manual Verification
1. Chạy lệnh:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```
2. Đợi cho đến khi quá trình `apply` hoàn tất (nó sẽ đứng đợi khoảng 3-4 phút ở bước `null_resource.wait_for_minikube`).
3. Sau khi hoàn thành, copy URL từ `alb_dns_name` dán vào trình duyệt → Nhận được trang chào mừng của Nginx.
4. Chạy câu lệnh `ssh_command` được xuất ra để SSH vào EC2 kiểm tra logs nếu cần:
   ```bash
   sudo cat /var/log/user-data.log  # Xem logs qua trinh bootstrap
   kubectl get pods -A              # Xem trang thai cac Pod
   ```
5. Chạy `terraform destroy` để thu hồi toàn bộ tài nguyên tránh phát sinh chi phí.
