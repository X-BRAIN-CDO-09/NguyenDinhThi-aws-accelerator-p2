# README.md — W9 Session 05
## Hands-On: Alert on AWS Root Account Login

---

## 🎯 Mục tiêu Lab

Thiết lập hệ thống cảnh báo tự động khi **root account** đăng nhập vào AWS Console — một trong những Security Best Practices quan trọng nhất của AWS.

> **Security Best Practice:** "The root account should almost never be used. Alert immediately if it is!"

---

## 📐 Kiến trúc

```
Root Login
    │
    ▼
┌─────────────────────┐
│ AWS CloudTrail      │ ← Ghi lại ALL API calls (Management Events)
│ Trail: w9-root-...  │
└──────────┬──────────┘
           │ real-time stream
           ▼
┌─────────────────────┐
│ CloudWatch Logs     │ ← Log Group: /aws/cloudtrail/root-login-alert
└──────────┬──────────┘
           │ Metric Filter
           │ Pattern: { $.userIdentity.type = "Root" && ...}
           ▼
┌─────────────────────┐
│ Custom Metric       │ ← Namespace: Security
│ RootAccountLoginCount│   Value: 1 mỗi khi root login
└──────────┬──────────┘
           │ >= 1 trong 5 phút
           ▼
┌─────────────────────┐
│ CloudWatch Alarm    │ ← Trigger ngay khi có 1 root login
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ SNS Topic           │ → 📧 Email Alert tới Security Team
└─────────────────────┘
```

---

## 📋 Tài nguyên được tạo (Terraform)

| # | Resource | Tên | Mục đích |
|---|----------|-----|---------|
| 1 | `aws_s3_bucket` | `...-cloudtrail-logs-{accountId}` | Lưu CloudTrail log files |
| 2 | `aws_s3_bucket_policy` | — | Cho phép CloudTrail ghi vào S3 |
| 3 | `aws_cloudwatch_log_group` | `/aws/cloudtrail/root-login-alert` | CloudWatch Logs nhận CloudTrail events |
| 4 | `aws_iam_role` | `...-cloudtrail-cw-role` | IAM Role cho CloudTrail → CW Logs |
| 5 | `aws_iam_role_policy` | — | Policy: PutLogEvents |
| 6 | `aws_cloudtrail` | `w9-root-alert-lab-trail` | Trail theo dõi management events |
| 7 | `aws_cloudwatch_log_metric_filter` | `...-root-login-filter` | Metric Filter: lọc Root login events |
| 8 | `aws_sns_topic` | `...-root-account-alerts` | SNS Topic nhận alarm |
| 9 | `aws_sns_topic_subscription` | Email subscription | Gửi email khi alarm |
| 10 | `aws_cloudwatch_metric_alarm` | `...-root-login-detected` | Alarm khi có root login |
| 11 | `aws_cloudwatch_dashboard` | `...-security-dashboard` | Dashboard bảo mật tổng quan |

---

## 🚀 Cách chạy Lab

### Bước 1: Chuẩn bị

```bash
# Di chuyển vào thư mục terraform
cd assignments/root-account-alert/terraform

# Copy file config mẫu
cp terraform.tfvars.example terraform.tfvars

# Chỉnh sửa terraform.tfvars — điền email thật
notepad terraform.tfvars  # hoặc dùng VS Code
```

### Bước 2: Triển khai

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

### Bước 3: Xác nhận email

```
⚠️ Sau khi apply xong, kiểm tra email ngay!
→ AWS gửi "AWS Notification - Subscription Confirmation"
→ Click "Confirm subscription" để kích hoạt alert
```

### Bước 4: Verify

```bash
bash scripts/verify-alert.sh w9-root-alert-lab ap-southeast-1
```

### Bước 5: Test Alarm (an toàn — không cần login root)

```bash
# Tạo giả metric để trigger alarm (không cần login root!)
aws cloudwatch put-metric-data \
  --namespace "Security" \
  --metric-name "RootAccountLoginCount" \
  --value 1 \
  --region ap-southeast-1

# Sau 5 phút → Email alert sẽ đến!
```

### Bước 6: Dọn dẹp

```bash
terraform destroy -auto-approve
```

---

## 📸 Evidence Screenshots cần chụp

| SS | Tên file | Nội dung |
|----|---------|---------|
| SS-01 | `SS-01_cloudtrail_trail_created.png` | CloudTrail Trail đang logging |
| SS-02 | `SS-02_cloudwatch_log_group.png` | CW Logs Group nhận CloudTrail events |
| SS-03 | `SS-03_metric_filter_created.png` | Metric Filter với Root login pattern |
| SS-04 | `SS-04_alarm_created_ok_state.png` | Alarm ở state OK |
| SS-05 | `SS-05_alarm_configuration_detail.png` | Chi tiết cấu hình alarm |
| SS-06 | `SS-06_sns_topic_and_subscription.png` | SNS Topic + Subscription Confirmed |
| SS-07 | `SS-07_confirmation_email.png` | Email xác nhận subscription |
| SS-08 | `SS-08_root_login_simulation.png` | Bằng chứng put-metric-data (test) |
| SS-09 | `SS-09_alarm_state_firing.png` | Alarm → ALARM state |
| SS-10 | `SS-10_email_alert_received.png` | Email alert trong Gmail |
| SS-11 | `SS-11_cloudtrail_event_detail.png` | CloudTrail Event (ConsoleLogin/put-metric) |
| SS-12 | `SS-12_dashboard_overview.png` | Security Dashboard |
| SS-13 | `SS-13_terraform_apply_success.png` | terraform apply thành công |
| SS-14 | `SS-14_terraform_destroy_success.png` | terraform destroy thành công |

---

## 💡 Lưu ý quan trọng

- **KHÔNG login root thật** để test nếu không cần — dùng `put-metric-data` thay thế
- CloudTrail có thể mất **5-15 phút** để bắt đầu stream log vào CloudWatch Logs
- Alarm sẽ ở `INSUFFICIENT_DATA` cho đến khi có data point đầu tiên — đây là **bình thường**
- File `terraform.tfvars` chứa email thật — **không commit** lên Git
