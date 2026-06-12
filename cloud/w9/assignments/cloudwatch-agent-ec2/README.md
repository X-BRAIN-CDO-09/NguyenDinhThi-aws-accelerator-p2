# W9 Session 02 — Installing the CloudWatch Agent on EC2 📊

> **Bài lab hands-on:** Cài đặt CloudWatch Agent lên EC2 để thu thập Custom Metrics (Memory, Disk, CPU chi tiết)  
> **Công nghệ:** AWS EC2 + CloudWatch Agent + SSM Parameter Store + Terraform  
> **Session:** 02 — Mastering AWS System Monitoring

---

## Vấn Đề Bài Lab Giải Quyết

AWS CloudWatch **mặc định** chỉ thu thập được các metric từ **hypervisor** (CPU, Network, Disk I/O ops). Điều này nghĩa là:

| Metric | Built-in? | Cần Agent? |
|--------|:---------:|:---------:|
| `CPUUtilization` | ✅ | - |
| `mem_used_percent` | ❌ | **✅ Bắt buộc** |
| `disk_used_percent` | ❌ | **✅ Bắt buộc** |

→ Bài lab cài CloudWatch Agent để **mở khóa** các custom metrics này.

---

## Kiến Trúc Tổng Quan

```
EC2 t3.micro
│
│  CloudWatch Agent (systemd service)
│  Config từ SSM Parameter Store
│  Thu thập mỗi 60 giây:
│    • mem_used_percent
│    • disk_used_percent (/)
│    • cpu_usage_user / system / idle
│    • bytes_sent / bytes_recv
│    • /var/log/messages
│
└──► PutMetricData API (cần CloudWatchAgentServerPolicy)
         │
         ▼
CloudWatch Metrics
Namespace: W9Lab/CustomMetrics
         │
         ▼
CloudWatch Dashboard
(Memory + Disk + CPU + Network widgets)
```

---

## Cấu Trúc Thư Mục

```
cloudwatch-agent-ec2/
├── README.md                         # File này
├── EVIDENCE.md                       # Báo cáo nghiệm thu + screenshots
├── STUDY_NOTES.md                    # Ghi chú kiến thức CloudWatch Agent
├── assets/                           # Screenshots evidence
│   └── README.md                     # Danh sách SS-01 → SS-14 cần chụp
├── scripts/
│   ├── verify-agent.sh               # Kiểm tra agent status + logs
│   └── generate-memory-load.sh       # Tạo memory load để test metrics
└── terraform/
    ├── main.tf                       # EC2 + IAM + SSM + Dashboard
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars.example      # Template (copy thành .tfvars)
    └── cloudwatch-agent.json         # CloudWatch Agent config
```

---

## Yêu Cầu Trước Khi Chạy

| Công cụ | Kiểm tra |
|---------|---------|
| Terraform ≥ 1.3 | `terraform version` |
| AWS CLI v2 | `aws --version` |
| AWS credentials | `aws sts get-caller-identity` |

---

## Hướng Dẫn Chạy Lab

### Bước 0: Chuẩn Bị

```powershell
# Di chuyển vào thư mục terraform
cd assignments/cloudwatch-agent-ec2/terraform

# Copy template và dùng mặc định (không cần sửa nếu dùng ap-southeast-1)
Copy-Item terraform.tfvars.example terraform.tfvars
```

### Bước 1: Deploy Infrastructure

```bash
terraform init
terraform plan      # Xem 9 resources sẽ tạo
terraform apply -auto-approve
```

**9 resources được tạo:**
1. `data.aws_ami` — Amazon Linux 2023 AMI
2. `data.aws_vpc` — Default VPC
3. `data.aws_subnets` — Subnets
4. `aws_iam_role` — EC2 Role với CloudWatchAgentServerPolicy
5. `aws_iam_role_policy_attachment` × 2 — CW Agent + SSM policies
6. `aws_iam_instance_profile` — Profile gắn role vào EC2
7. `aws_security_group` — Chỉ cho phép outbound
8. `aws_ssm_parameter` — CloudWatch Agent JSON config
9. `aws_instance` — EC2 t3.micro với user_data tự động cài agent
10. `aws_cloudwatch_dashboard` — Dashboard 5 widgets

### Bước 2: Kết Nối EC2 (SSM Session Manager)

```bash
# Lấy instance ID từ terraform output
terraform output ec2_instance_id

# Kết nối qua SSM (không cần SSH key!)
aws ssm start-session --target i-xxxxxxxxx --region ap-southeast-1
```

### Bước 3: Verify Agent (chạy trên EC2)

```bash
~/verify-agent.sh
# → Kỳ vọng: status = "running"
# → Log không có ERROR
```

### Bước 4: Kiểm Tra Custom Metrics

1. Mở CloudWatch Console → **Metrics** → **Custom Namespaces** → `W9Lab/CustomMetrics`
2. Tìm metrics: `mem_used_percent`, `disk_used_percent`
3. Mở Dashboard URL (từ `terraform output cloudwatch_dashboard_url`)

### Bước 5: Test Memory Metric (chạy trên EC2)

```bash
~/generate-memory-load.sh
# → Đợi 2 phút → CloudWatch Dashboard → mem_used_percent tăng
```

### Bước 6: Dọn Dẹp

```bash
terraform destroy -auto-approve
```

---

## Điểm Khác Biệt Quan Trọng So Với Session 03

| | Session 02 (bài này) | Session 03 |
|--|---------------------|-----------|
| **Mục đích** | Thu thập custom metrics | Cảnh báo CPU → Email |
| **Metric nguồn** | Agent (Memory, Disk) | Built-in (CPUUtilization) |
| **Thông báo** | Dashboard chỉ xem | Email qua SNS |
| **SSM** | Lưu agent config | Không dùng |
| **Custom namespace** | `W9Lab/CustomMetrics` | `AWS/EC2` |

---

## Ghi Chú Nhanh

```
Tại sao cần CloudWatch Agent?
→ AWS chỉ đọc được metrics từ hypervisor, không vào được OS
→ Agent chạy BÊN TRONG OS, đọc /proc/* và gửi lên CloudWatch

Prerequisite quan trọng nhất (từ slide):
→ IAM Role phải có CloudWatchAgentServerPolicy

Best practice IaC:
→ Lưu agent config vào SSM Parameter Store
→ user_data dùng "fetch-config -c ssm:/..." thay vì copy file trực tiếp
```
