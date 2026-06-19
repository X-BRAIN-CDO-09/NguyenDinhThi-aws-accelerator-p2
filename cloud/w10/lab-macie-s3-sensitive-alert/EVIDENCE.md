# BÁO CÁO NGHIỆM THU (EVIDENCE REPORT)
## LAB: Detect Sensitive Data in Amazon S3 & Send Notifications using Amazon Macie

[![AWS Macie](https://img.shields.io/badge/AWS-Amazon%20Macie-FF9900?logo=amazon-aws&style=flat-square)](#)
[![S3](https://img.shields.io/badge/AWS-S3%20Bucket-569A31?logo=amazon-s3&style=flat-square)](#)
[![SNS](https://img.shields.io/badge/AWS-SNS%20Notification-FF9900?logo=amazon-aws&style=flat-square)](#)
[![EventBridge](https://img.shields.io/badge/AWS-EventBridge-FF9900?logo=amazon-aws&style=flat-square)](#)

---

### THÔNG TIN HỌC VIÊN
* **Học viên:** Nguyễn Đình Thi
* **Mã học viên:** XB-DN26-103
* **Chương trình:** X-BRAIN CDO-09 | Tuần W10
* **Ngày nộp:** ___/06/2026

---

## I. BẢNG ĐỐI CHIẾU TIÊU CHÍ ĐẠT

| STT | Yêu cầu | Trạng thái | Ghi chú |
| :--- | :--- | :---: | :--- |
| 1 | Tạo S3 bucket và upload sample data | ⬜ ĐẠT | |
| 2 | Bật Amazon Macie và tạo Classification Job | ⬜ ĐẠT | |
| 3 | Xem Macie Findings phát hiện dữ liệu nhạy cảm | ⬜ ĐẠT | |
| 4 | Tạo EventBridge Rule từ Macie Findings | ⬜ ĐẠT | |
| 5 | Tạo SNS Topic + Email Subscription | ⬜ ĐẠT | |
| 6 | Nhận email cảnh báo thực tế | ⬜ ĐẠT | |

---

## II. CÁC BƯỚC THỰC HIỆN (TERMINAL OUTPUTS)

### Bước 1: Tạo S3 Bucket và Upload Sample Data
```bash
# TODO: Thêm output terminal sau khi thực hiện
```

### Bước 2: Bật Amazon Macie
```bash
# TODO: Thêm output terminal sau khi thực hiện
```

### Bước 3: Tạo Macie Classification Job
```bash
# TODO: Thêm output terminal sau khi thực hiện
```

### Bước 4: Xem Macie Findings
```bash
# TODO: Thêm output terminal sau khi thực hiện
```

### Bước 5: Tạo EventBridge Rule
```bash
# TODO: Thêm output terminal sau khi thực hiện
```

### Bước 6: Tạo SNS Topic + Subscription
```bash
# TODO: Thêm output terminal sau khi thực hiện
```

---

## III. BẰNG CHỨNG THỰC THI (SCREENSHOTS)

### Screenshot 1 — Macie Classification Job
![SS-01: Macie Classification Job đang chạy](assets/SS-01-macie-job.png)

### Screenshot 2 — Macie Findings (Phát hiện dữ liệu nhạy cảm)
![SS-02: Macie Findings hiển thị dữ liệu nhạy cảm](assets/SS-02-findings.png)

### Screenshot 3 — Email Alert nhận được
![SS-03: Email thông báo nhận được qua SNS](assets/SS-03-email-alert.png)
