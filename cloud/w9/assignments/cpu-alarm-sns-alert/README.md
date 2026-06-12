# W9 Session 03 — CPU Alarm → Email Alert via SNS 🚨

> **Bài lab hands-on:** Gửi email cảnh báo khi EC2 CPU > 80% liên tiếp 5 phút  
> **Công nghệ:** AWS EC2 + CloudWatch + SNS + Terraform  
> **Session:** 03 — Mastering AWS System Monitoring

---

## Kiến Trúc Tổng Quan

```
EC2 (t3.micro)
    │
    │ CPUUtilization metric (mỗi 1 phút)
    ▼
CloudWatch Alarm
    │
    │ Condition: CPU > 80% trong 5 phút liên tiếp
    │ (1 out of 1 datapoints × 300s period)
    ▼
SNS Topic: w9-cpu-alarm-lab-cpu-alerts
    │
    ├──► Email Subscription → 📧 Your Gmail
    │
    └──► (Optional) OK state → 📧 Recovery alert
```

---

## Cấu Trúc Thư Mục

```
cpu-alarm-sns-alert/
├── README.md                       # File này
├── EVIDENCE.md                     # Báo cáo nghiệm thu + screenshots
├── STUDY_NOTES.md                  # Ghi chú kiến thức
├── assets/                         # Screenshots evidence
│   └── .gitkeep
├── terraform/
│   ├── main.tf                     # EC2 + SNS + CloudWatch Alarm + Dashboard
│   ├── variables.tf                # Biến cấu hình
│   ├── outputs.tf                  # Kết quả sau khi apply
│   └── terraform.tfvars.example   # Template điền thông tin
└── scripts/
    ├── stress-cpu.sh               # Giả lập CPU cao → trigger alarm
    └── verify-alarm.sh             # Kiểm tra trạng thái tất cả resources
```

---

## Yêu Cầu Trước Khi Chạy

| Công cụ | Kiểm tra |
|---------|---------|
| Terraform ≥ 1.3 | `terraform version` |
| AWS CLI v2 | `aws --version` |
| AWS credentials | `aws sts get-caller-identity` |
| Email hợp lệ | Để nhận confirmation link |

---

## Hướng Dẫn Chạy Lab

### Bước 0: Chuẩn Bị

```bash
# Clone/navigate vào folder lab
cd cpu-alarm-sns-alert/terraform

# Copy file example → file thật
cp terraform.tfvars.example terraform.tfvars

# Mở file và điền thông tin
notepad terraform.tfvars   # Windows
# hoặc
nano terraform.tfvars      # Linux/Mac
```

Điền vào `terraform.tfvars`:
```hcl
alert_email   = "your-email@gmail.com"   # Email nhận cảnh báo
aws_region    = "ap-southeast-1"          # Singapore (hoặc region khác)
key_pair_name = "my-key-pair"            # Tên key pair trong AWS (optional)
```

---

### Bước 1: Create SNS Topic & Subscription

> **Manual trên Console:** SNS → Create Topic (Standard) → Add Email Subscription → Confirm via email

**Bằng Terraform** (tự động):
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

**⚠️ QUAN TRỌNG:** Sau khi `apply` xong, kiểm tra email và click **"Confirm subscription"**!

```
Subject: AWS Notification - Subscription Confirmation
→ Click link "Confirm subscription"
→ Status: PendingConfirmation → Confirmed
```

---

### Bước 2: Create CloudWatch Alarm

> **Manual trên Console:** CloudWatch → Alarms → Create Alarm → Select Metric → EC2 → Per-Instance → CPUUtilization

**Terraform đã tạo tự động** với cấu hình:
```hcl
metric_name        = "CPUUtilization"
namespace          = "AWS/EC2"
period             = 300       # 5 phút
evaluation_periods = 1
threshold          = 80        # 80%
comparison_operator = "GreaterThanThreshold"
```

---

### Bước 3: Configure Alarm Conditions

| Thông số | Giá trị |
|----------|---------|
| Condition | Greater than 80% |
| Period | 5 minutes (300s) |
| Evaluation | 1 out of 1 datapoints |
| Statistic | Average |
| Missing data | Treated as breaching |

---

### Bước 4: Set SNS Notification Action

| State | Action |
|-------|--------|
| **ALARM** | Gửi SNS → Email alert 🔥 |
| **OK** | Gửi SNS → Recovery email ✅ |
| INSUFFICIENT_DATA | Không notify |

---

### Bước 5: Trigger Alarm (Test)

```bash
# SSH vào EC2
ssh -i your-key.pem ec2-user@<EC2_PUBLIC_IP>

# Chạy stress test (6 phút)
bash ~/stress-cpu.sh
```

Hoặc dùng **AWS Systems Manager Session Manager** (không cần SSH):
```
AWS Console → EC2 → Instance → Connect → Session Manager
$ bash ~/stress-cpu.sh
```

**Timeline:**
```
T+0:00  → stress-ng bắt đầu, CPU = ~100%
T+1:00  → CloudWatch nhận metric đầu tiên (monitoring = detailed)
T+5:00  → Alarm evaluation: 1/1 periods > 80% → ALARM!
T+5:30  → SNS gửi email
T+6:00  → Bạn nhận email 📧
T+6:30  → stress-ng kết thúc, CPU về 0%
T+11:30 → CloudWatch: ALARM → OK → Recovery email 📧
```

---

### Bước 6: Kiểm Tra Trạng Thái

```bash
# Kiểm tra bằng script
chmod +x scripts/verify-alarm.sh
./scripts/verify-alarm.sh

# Hoặc AWS CLI thủ công
aws cloudwatch describe-alarms \
  --alarm-names "w9-cpu-alarm-lab-cpu-high" \
  --query "MetricAlarms[0].{State:StateValue,Threshold:Threshold}"
```

---

### Bước 7: Cleanup (Quan Trọng!)

```bash
cd terraform/
terraform destroy -auto-approve
```

> 💸 EC2 t3.micro: ~$0.0104/giờ. **Nhớ destroy sau khi xong lab!**

---

## Xem Kết Quả Trực Quan

| Resource | URL |
|----------|-----|
| CloudWatch Dashboard | AWS Console → CloudWatch → Dashboards → w9-cpu-alarm-lab-dashboard |
| Alarm Status | AWS Console → CloudWatch → Alarms |
| SNS Topics | AWS Console → SNS → Topics |
| EC2 Instance | AWS Console → EC2 → Instances |

---

## Troubleshooting

| Vấn đề | Nguyên nhân | Giải pháp |
|--------|-------------|-----------|
| Email không đến | Chưa confirm subscription | Kiểm tra spam, click confirm link |
| Alarm ở INSUFFICIENT_DATA | EC2 mới tạo, chưa có metric | Đợi 5-10 phút |
| CPU không lên cao | stress-ng chưa cài | `sudo dnf install stress-ng -y` |
| Terraform init lỗi | Chưa cấu hình AWS credentials | `aws configure` |

---

## Tài Liệu Tham Khảo

- [AWS CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [AWS SNS Email Notifications](https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html)
- [Terraform aws_cloudwatch_metric_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)
- [EC2 Detailed Monitoring](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-cloudwatch-new.html)
