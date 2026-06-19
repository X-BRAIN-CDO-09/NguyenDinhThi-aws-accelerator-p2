# LAB — Detect Sensitive Data in Amazon S3 & Send Notifications using Amazon Macie

[![AWS Macie](https://img.shields.io/badge/AWS-Amazon%20Macie-FF9900?logo=amazon-aws&style=flat-square)](#)
[![S3](https://img.shields.io/badge/AWS-S3%20Bucket-569A31?logo=amazon-s3&style=flat-square)](#)
[![SNS](https://img.shields.io/badge/AWS-SNS%20Notification-FF9900?logo=amazon-aws&style=flat-square)](#)
[![EventBridge](https://img.shields.io/badge/AWS-EventBridge-FF9900?logo=amazon-aws&style=flat-square)](#)

---

## Mô tả bài Lab

Bài lab này hướng dẫn cách sử dụng **Amazon Macie** để tự động phát hiện dữ liệu nhạy cảm (Sensitive Data như số thẻ tín dụng, thông tin cá nhân, mật khẩu,...) trong các S3 bucket, sau đó tự động gửi thông báo qua **Amazon SNS → Email** bằng cách sử dụng **Amazon EventBridge** làm cầu nối rule.

## Kiến trúc

```
User (Login AWS Console)
    │
    ▼ Create & Configure Resources
    ┌──────────────────────────────────────────┐
    │               AWS Cloud                  │
    │                                          │
    │  ┌──────────┐    Upload files            │
    │  │ Sample   │───────────────────────►    │
    │  │  Files   │         ┌──────────────┐  │
    │  └──────────┘         │   S3 Bucket  │  │
    │                       └──────┬───────┘  │
    │                              │           │
    │                    Amazon Macie Job      │
    │                              │           │
    │                       ┌──────▼───────┐  │
    │                       │    Amazon    │  │
    │                       │    Macie     │  │
    │                       └──────┬───────┘  │
    │                              │ Findings  │
    │               ┌──────────────▼────────┐ │
    │               │   EventBridge Rule    │ │
    │               │  (Rule created for    │ │
    │               │      alerts)          │ │
    │               └──────────────┬────────┘ │
    │                              │           │
    │                       ┌──────▼───────┐  │
    │                       │     SNS      │  │
    │                       └──────┬───────┘  │
    │                              │           │
    │                   Alerts on Email 📧     │
    └──────────────────────────────────────────┘
```

## Mục tiêu Lab

1. **Tạo S3 bucket** chứa các file dữ liệu mẫu có chứa thông tin nhạy cảm.
2. **Upload sample files** có chứa dữ liệu nhạy cảm (số CMND, số thẻ tín dụng,...).
3. **Bật Amazon Macie** và tạo Macie Classification Job để quét S3 bucket.
4. **Xem Macie Findings** (kết quả phát hiện dữ liệu nhạy cảm).
5. **Tạo EventBridge Rule** lắng nghe các Macie Findings và gửi đến SNS.
6. **Cấu hình SNS Topic + Email Subscription** để nhận thông báo qua email.

## Cấu trúc thư mục

```
lab-macie-s3-sensitive-alert/
├── README.md               # Tài liệu hướng dẫn (file này)
├── EVIDENCE.md             # Báo cáo nghiệm thu
├── terraform/              # (Tuỳ chọn) Infrastructure as Code
│   └── main.tf
├── scripts/                # Các script hỗ trợ
│   └── upload-sample-data.sh
├── sample-data/            # Dữ liệu mẫu dùng để test Macie
│   ├── fake-credentials.txt
│   ├── fake-credit-cards.txt
│   └── fake-personal-info.csv
└── assets/                 # Screenshots nghiệm thu
    ├── SS-01-macie-job.png
    ├── SS-02-findings.png
    └── SS-03-email-alert.png
```

## Các dịch vụ AWS sử dụng

| Dịch vụ | Vai trò |
|:---|:---|
| **Amazon S3** | Lưu trữ các file dữ liệu mẫu cần được quét |
| **Amazon Macie** | Tự động phát hiện và phân loại dữ liệu nhạy cảm trong S3 |
| **Amazon EventBridge** | Tạo Rule lắng nghe sự kiện Macie Findings và kích hoạt cảnh báo |
| **Amazon SNS** | Gửi thông báo (Email) khi phát hiện dữ liệu nhạy cảm |

## Thông tin học viên

* **Học viên:** Nguyễn Đình Thi
* **Mã học viên:** XB-DN26-103
* **Chương trình:** X-BRAIN CDO-09 | Tuần W10
