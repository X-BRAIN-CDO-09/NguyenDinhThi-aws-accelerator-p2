<p align="center">
  <img src="https://img.icons8.com/color/96/000000/google-docs.png" alt="Evidence Logo" width="80"/>
</p>

# <p align="center">📄 BÁO CÁO NGHIỆM THU — W9 SESSION 03</p>

### <p align="center">CPU Alarm to Email Alert via SNS</p>

<p align="center">
  <img src="https://img.shields.io/badge/STATUS-PASSED-4CAF50?style=for-the-badge" alt="Status Passed"/>
  <img src="https://img.shields.io/badge/AWS-884244642114-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS Account"/>
  <img src="https://img.shields.io/badge/REGION-ap--southeast--1-blue?style=for-the-badge" alt="AWS Region"/>
</p>

---

## 📋 Thông Tin Tổng Quan

* **Bài thực hành:** Hands-On: CPU Alarm ➔ Email Alert via SNS
* **Session:** 03 — Mastering AWS System Monitoring
* **Mục tiêu:** Tự động gửi email cảnh báo khi chỉ số CPU của EC2 vượt quá 80% liên tục trong 5 phút.
* **Công nghệ sử dụng:** AWS EC2 (t3.micro) + CloudWatch Alarm + SNS + Terraform IaC.
* **AWS Account:** `884244642114` | **Region:** `ap-southeast-1` (Singapore).
* **SNS Topic ARN:** `arn:aws:sns:ap-southeast-1:884244642114:w9-cpu-alarm-lab-cpu-alerts`
* **Alarm ARN:** `arn:aws:cloudwatch:ap-southeast-1:884244642114:alarm:w9-cpu-alarm-lab-cpu-high`

---

## 📐 Sơ Đồ Kiến Trúc Hoạt Động (Architecture Flow)

```mermaid
graph TD
    subgraph "AWS Cloud Infrastructure"
        EC2[EC2 t3.micro stressed] -->|Detailed Monitoring: 1m| CloudWatch[CloudWatch Alarm]
        CloudWatch -->|If CPU > 80% for 5m| SNS[SNS Topic: cpu-alerts]
    end
    
    SNS -->|Publish Alert| Email[📧 thihtktk@gmail.com]

    classDef aws fill:#FF9900,stroke:#333,stroke-width:1px,color:#fff;
    class EC2,CloudWatch,SNS aws;
```

---

## 📊 Bảng Đối Chiếu Tiêu Chí Nghiệm Thu

| STT | Tiêu chí kỹ thuật từ Slide | Trạng thái | Bằng chứng thực tế xác minh |
| :---: | :--- | :---: | :--- |
| **1** | **Create SNS Topic (Standard)** | **✅ ĐẠT** | Topic ARN: `arn:aws:sns:ap-southeast-1:884244642114:w9-cpu-alarm-lab-cpu-alerts` — xem **SS-01**. |
| **2** | **Add Email Subscription** | **✅ ĐẠT** | Đã đăng ký email `thihtktk@gmail.com` nhận cảnh báo — xem **SS-02**. |
| **3** | **Confirm subscription via email link** | **✅ ĐẠT** | Nhận email xác nhận ➔ Trạng thái chuyển sang **Confirmed** — xem **SS-03**. |
| **4** | **Create CloudWatch Alarm** | **✅ ĐẠT** | Alarm `w9-cpu-alarm-lab-cpu-high` được tạo gắn trực tiếp vào máy chủ EC2 — xem **SS-04**. |
| **5** | **Select Metric: CPUUtilization** | **✅ ĐẠT** | Giám sát chỉ số `CPUUtilization` trong namespace `AWS/EC2`. |
| **6** | **Condition: Greater than 80%** | **✅ ĐẠT** | Thiết lập Threshold = 80% — xem **SS-05**. |
| **7** | **Period: 5 minutes, Eval: 1 out of 1** | **✅ ĐẠT** | Cấu hình chu kỳ đánh giá 5 phút, 1 điểm dữ liệu vi phạm là báo động. |
| **8** | **In Alarm state ➔ SNS Notification** | **✅ ĐẠT** | **ALARM Fired** ➔ Nhận email cảnh báo đỏ từ AWS — xem **SS-09, SS-11**. |
| **9** | **OK state notification (Recovery alert)** | **✅ ĐẠT** | Khi CPU giảm, hệ thống tự động gửi Email báo phục hồi **OK** — xem **SS-12**. |

---

## 🔍 Giải Thích Kỹ Thuật & Quyết Định Thiết Kế

### 1. Tại sao dùng SNS Standard thay vì FIFO?
* **Standard Topic:** Cung cấp throughput cực cao, hỗ trợ gửi thông báo đồng thời qua nhiều kênh (Email, SMS, Lambda). Đối với cảnh báo hệ thống, việc có thể bị trùng lặp nhẹ hoặc thứ tự đến lệch nhau vài mili giây không ảnh hưởng tới tiến trình xử lý sự cố của quản trị viên.
* **FIFO Topic:** Giới hạn throughput và chỉ hỗ trợ giao thức SQS làm subscription, không hỗ trợ gửi trực tiếp Email/SMS cho người dùng.

### 2. Tại sao cần bật Detailed Monitoring (1 phút)?
Mặc định (Basic Monitoring) chỉ đẩy metric 5 phút một lần. Nếu dùng cấu hình này, CloudWatch Alarm phải mất ít nhất 5-10 phút để nhận đủ dữ liệu và đưa ra phán quyết, làm tăng thời gian phản ứng với sự cố. Bằng cách kích hoạt Detailed Monitoring, dữ liệu được gửi mỗi phút giúp Alarm đánh giá nhanh và đưa ra quyết định báo động chính xác sau đúng 5 phút CPU vượt ngưỡng.

### 3. Tại sao cấu hình `treat_missing_data = "breaching"`?
Nếu máy ảo EC2 bị treo cứng hoàn toàn (crash) đến mức không thể gửi dữ liệu metric CPU lên CloudWatch Logs, hệ thống sẽ rơi vào trạng thái thiếu dữ liệu (missing data). 
Bằng cách cấu hình `breaching`, CloudWatch Alarm sẽ coi việc mất kết nối dữ liệu này là một hành vi nguy hiểm (vi phạm ngưỡng) và lập tức kích hoạt báo động gửi email cho quản trị viên đến kiểm tra.

---

## 📸 Hình Ảnh Bằng Chứng Thực Tế (Screenshots)

### PHẦN 1 — SNS Topic & Subscription

#### 1.1 SNS Topic Được Khởi Tạo Thành Công
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-01_sns_topic_created_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-01_sns_topic_created_light.png">
  <img src="assets/SS-01_sns_topic_created.png" alt="SS-01: SNS Topic đã tạo">
</picture>

---

#### 1.2 Trạng Thái Email Subscription Đã Confirmed
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-02_sns_subscription_confirmed_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-02_sns_subscription_confirmed_light.png">
  <img src="assets/SS-02_sns_subscription_confirmed.png" alt="SS-02: Subscription status confirmed">
</picture>

---

#### 1.3 Thư Xác Nhận Đăng Ký Gửi Từ AWS Trong Gmail
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-03_confirmation_email_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-03_confirmation_email_light.png">
  <img src="assets/SS-03_confirmation_email.png" alt="SS-03: Thư confirm của AWS">
</picture>

---

### PHẦN 2 — CloudWatch Alarm

#### 2.1 CloudWatch Alarm Được Khởi Tạo (Trạng Thái: OK)
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-04_alarm_created_ok_state_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-04_alarm_created_ok_state_light.png">
  <img src="assets/SS-04_alarm_created_ok_state.png" alt="SS-04: Alarm ở trạng thái ban đầu OK">
</picture>

---

#### 2.2 Chi Tiết Cấu Hình Alarm Trên Console
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-05_alarm_configuration_detail_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-05_alarm_configuration_detail_light.png">
  <img src="assets/SS-05_alarm_configuration_detail.png" alt="SS-05: Cấu hình Alarm trên console">
</picture>

---

### PHẦN 3 — EC2 Instance & CPU Metric

#### 3.1 Trạng Thái EC2 Instance Đang Chạy Với Detailed Monitoring
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-06_ec2_instance_running_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-06_ec2_instance_running_light.png">
  <img src="assets/SS-06_ec2_instance_running.png" alt="SS-06: EC2 running với Detailed Monitoring bật">
</picture>

---

#### 3.2 CloudWatch Dashboard Giám Sát Khi CPU Bình Thường
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-07_dashboard_cpu_normal_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-07_dashboard_cpu_normal_light.png">
  <img src="assets/SS-07_dashboard_cpu_normal.png" alt="SS-07: Đồ thị CPU bình thường ở mức thấp">
</picture>

---

### PHẦN 4 — Kiểm Thử Đổi Trạng Thái Báo Động (Stress Test)

#### 4.1 Chạy Script stress-ng Chiếm Dụng 100% CPU Máy Chủ
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-08_stress_test_running_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-08_stress_test_running_light.png">
  <img src="assets/SS-08_stress_test_running.png" alt="SS-08: stress-ng chạy 100% CPU trên EC2">
</picture>

---

#### 4.2 CloudWatch Alarm Chuyển Sang Trạng Thái Báo Động (ALARM State) 🚨
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-09_alarm_state_firing_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-09_alarm_state_firing_light.png">
  <img src="assets/SS-09_alarm_state_firing.png" alt="SS-09: Alarm chuyển sang trạng thái cảnh báo đỏ">
</picture>

---

#### 4.3 Đỉnh Nhọn CPU Đột Biến Spike Vượt Ngưỡng 80% Trên Dashboard
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-10_dashboard_cpu_spike_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-10_dashboard_cpu_spike_light.png">
  <img src="assets/SS-10_dashboard_cpu_spike.png" alt="SS-10: Spike vượt đường kẻ đỏ 80% trên dashboard">
</picture>

---

### PHẦN 5 — Xác Nhận Nhận Email Cảnh Báo & Phục Hồi

#### 5.1 Nhận Thư Cảnh Báo Báo Động (ALARM Notification) Trong Gmail
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-11_email_alarm_received_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-11_email_alarm_received_light.png">
  <img src="assets/SS-11_email_alarm_received.png" alt="SS-11: Email cảnh báo sự cố gửi tới Gmail">
</picture>

---

#### 5.2 Nhận Thư Phục Hồi Hệ Thống (OK Recovery Notification)
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/SS-12_email_ok_recovery_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/SS-12_email_ok_recovery_light.png">
  <img src="assets/SS-12_email_ok_recovery.png" alt="SS-12: Email báo phục hồi hệ thống khi CPU hạ nhiệt">
</picture>

---

## 🏆 KẾT LUẬN

Bài thực hành W9 Session 03 đã triển khai thành công quy trình cảnh báo lỗi tự động:
* **Độ Nhạy Cao:** Bật Detailed Monitoring giúp phát hiện sự cố nhanh gấp 5 lần so với mặc định.
* **Luồng Khép Kín:** Quy trình tự động hóa hoạt động chính xác từ lúc phát sinh quá tải ➔ Phát cảnh báo lỗi qua email ➔ Phát email báo an toàn khi hệ thống tự nguội.
* **Tính Tiện Ích:** Cung cấp giải pháp giám sát an toàn, giảm tải công sức túc trực giám sát thủ công cho kỹ sư vận hành.
