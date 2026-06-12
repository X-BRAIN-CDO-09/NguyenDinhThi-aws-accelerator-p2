# Ghi Chú Học Tập — W9 Session 03: AWS Monitoring

## 1. SNS (Simple Notification Service) là gì?

### Khái niệm cốt lõi

```
SNS = Pub/Sub Messaging Service
      (Publisher → Topic → Subscriber)

Publisher (CloudWatch Alarm)
    │
    ▼
Topic (w9-cpu-alarm-lab-cpu-alerts)
    │
    ├──► Email Subscription
    ├──► SMS Subscription
    ├──► SQS Subscription
    ├──► Lambda Subscription
    └──► HTTP/HTTPS Webhook
```

### So sánh SNS Standard vs FIFO

| Đặc điểm | Standard | FIFO |
|-----------|---------|------|
| Throughput | Không giới hạn | 300 msg/s |
| Thứ tự | Không đảm bảo | Đảm bảo |
| Deduplication | Có thể duplicate | Không duplicate |
| Use case | Notifications, alerts | Giao dịch tài chính |
| Giá | Rẻ hơn | Đắt hơn |

### Subscription Protocols

| Protocol | Ví dụ |
|----------|-------|
| email | your@gmail.com |
| email-json | Nhận raw JSON |
| sms | +84901234567 |
| sqs | SQS queue ARN |
| lambda | Lambda function ARN |
| http/https | API endpoint |
| application | Mobile push (iOS/Android) |
| firehose | Kinesis Firehose |

---

## 2. CloudWatch là gì?

### Các thành phần chính

```
CloudWatch
├── Metrics      → Dữ liệu số theo thời gian (CPU, Memory, Disk...)
├── Alarms       → Đánh giá metric → trigger action
├── Logs         → Thu thập log từ EC2, Lambda, etc.
├── Dashboards   → Visualize metrics
├── Events       → Phản ứng sự kiện AWS (EventBridge)
└── Insights     → Phân tích log thông minh
```

### EC2 Metrics trong CloudWatch

| Metric | Namespace | Mô tả |
|--------|-----------|-------|
| CPUUtilization | AWS/EC2 | % CPU đang dùng |
| NetworkIn | AWS/EC2 | Bytes nhận vào |
| NetworkOut | AWS/EC2 | Bytes gửi ra |
| DiskReadOps | AWS/EC2 | Số lần đọc disk |
| DiskWriteOps | AWS/EC2 | Số lần ghi disk |
| StatusCheckFailed | AWS/EC2 | EC2 health check |

> **Lưu ý:** Memory, Disk Usage KHÔNG có sẵn trong AWS/EC2 namespace  
> → Cần cài CloudWatch Agent để push custom metrics

### Basic vs Detailed Monitoring

```
Basic Monitoring (miễn phí):
  T+0    T+5    T+10   T+15   (mỗi 5 phút)
  ●      ●      ●      ●

Detailed Monitoring ($0.01/metric/tháng):
  T+0 T+1 T+2 T+3 T+4 T+5  (mỗi 1 phút)
  ●   ●   ●   ●   ●   ●
```

---

## 3. CloudWatch Alarm

### 3 States của Alarm

```
┌─────────────────────────────────────────────────────────┐
│                                                          │
│   INSUFFICIENT_DATA                                      │
│   (Chưa đủ dữ liệu để đánh giá — vừa tạo alarm)        │
│            │                                             │
│            ▼ (sau vài phút có metric)                    │
│           OK  ←──────────────────────── ALARM            │
│            │   (CPU về dưới ngưỡng)         ▲            │
│            │                                │            │
│            └── (CPU > 80% × 5 phút) ────────┘            │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Alarm Conditions (từ slide)

```
Condition: Greater than 80%
    → comparison_operator = "GreaterThanThreshold"
    → threshold = 80

Period: 5 minutes
    → period = 300  (giây)

Evaluation: 1 out of 1 datapoints
    → evaluation_periods = 1
    → datapoints_to_alarm = 1 (default)
```

### Cách tính Evaluation

```
evaluation_periods = 3, datapoints_to_alarm = 2

Ví dụ:
  Period 1: CPU = 85% ✓ (breaching)
  Period 2: CPU = 70% ✗ (ok)
  Period 3: CPU = 90% ✓ (breaching)
  → 2/3 periods breaching = ALARM! ✅

  Period 1: CPU = 85% ✓
  Period 2: CPU = 60% ✗
  Period 3: CPU = 65% ✗
  → 1/3 periods breaching = OK ✅
```

---

## 4. Terraform Resources Dùng Trong Bài

### aws_sns_topic

```hcl
resource "aws_sns_topic" "example" {
  name         = "my-alerts"     # Tên topic
  display_name = "My Alerts"     # Hiển thị trong email
}
```

### aws_sns_topic_subscription

```hcl
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = "user@gmail.com"
  # ⚠️ Phải confirm email thủ công!
}
```

### aws_cloudwatch_metric_alarm

```hcl
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "cpu-high-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300    # 5 phút
  statistic           = "Average"
  threshold           = 80     # 80%
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = "i-1234567890abcdef0"
  }

  alarm_actions = [aws_sns_topic.example.arn]
  ok_actions    = [aws_sns_topic.example.arn]
}
```

---

## 5. So Sánh Monitoring AWS vs Kubernetes (Liên hệ W9 Lab-Final)

| Khía cạnh | AWS CloudWatch (Session 03) | Prometheus/Grafana (Lab-Final) |
|-----------|----------------------------|-------------------------------|
| **Nguồn metric** | EC2 tự gửi lên CloudWatch | App expose `/metrics` endpoint |
| **Alert** | CloudWatch Alarm → SNS → Email | PrometheusRule → AlertManager → Email |
| **Dashboard** | CloudWatch Dashboard | Grafana Dashboard |
| **SLO** | Không native | PrometheusRule + Burn Rate |
| **Tự động hóa** | Terraform | ArgoCD + Terraform |
| **Chi phí** | Trả theo metric/alarm | Self-hosted (miễn phí) |

> **Insight:** CloudWatch là managed service của AWS — dễ dùng nhưng vendor lock-in.  
> Prometheus/Grafana là open-source — flexible hơn nhưng tự quản lý.

---

## 6. Burn Rate (Liên Hệ W9)

Trong Lab-Final W9, ta học **Burn Rate** cho SLO. Ở Session 03, CloudWatch Alarm là phiên bản đơn giản hơn:

```
Session 03 (Simple):
  CPU > 80% → ALARM
  (Binary: có/không)

W9 Lab-Final (Advanced):
  Error Budget Burn Rate > 14.4× → CRITICAL
  (Tính tốc độ tiêu thụ ngân sách lỗi theo thời gian)
```

Cả hai đều có cùng mục đích: **phát hiện vấn đề sớm và thông báo tự động**.

---

## 7. Chi Phí Ước Tính

| Resource | Giá (ap-southeast-1) |
|----------|---------------------|
| EC2 t3.micro | $0.0104/giờ ≈ $0.25/ngày |
| CloudWatch Alarm | $0.10/alarm/tháng |
| SNS Email (1000 emails đầu) | Miễn phí |
| Detailed EC2 Monitoring | $3.50/tháng |
| CloudWatch Dashboard | $3.00/dashboard/tháng |

> **Tổng lab ~2 giờ:** ~$0.02 — Nhớ `terraform destroy` ngay sau khi xong!
