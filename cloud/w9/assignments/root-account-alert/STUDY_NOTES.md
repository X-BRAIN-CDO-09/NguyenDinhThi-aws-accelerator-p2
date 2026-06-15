# STUDY_NOTES.md — W9 Session 05
## Alert on AWS Root Account Login

---

## 1. Tại sao root account CỰC KỲ NGUY HIỂM?

```
Root Account = Superuser tuyệt đối của AWS Account
  ✗ Không thể bị giới hạn bởi IAM Policy
  ✗ Có thể xóa toàn bộ tài nguyên
  ✗ Có thể đóng AWS Account
  ✗ Có thể thay đổi billing, MFA, credentials
  ✓ Chỉ nên dùng cho: thay đổi AWS Support plan, đóng account, recover IAM lock
```

**AWS Best Practice:** "Root account should almost never be used. Alert immediately if it is!"

---

## 2. Kiến trúc 4-bước từ Slide

```
1. CloudTrail Trail
   ↓ ghi mọi API call
2. CloudWatch Logs (Log Group)
   ↓ CloudTrail gửi log events vào đây
3. Metric Filter
   ↓ lọc event Root login → tạo metric RootAccountLoginCount
4. CloudWatch Alarm
   ↓ nếu RootAccountLoginCount >= 1 trong 5 phút
5. SNS → Email alert tới Security Team
```

---

## 3. Filter Pattern — Giải thích chi tiết

```
{ $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }
```

| Phần | Ý nghĩa |
|------|---------|
| `$.userIdentity.type = "Root"` | Chỉ khớp events từ root account |
| `$.eventType != "AwsServiceEvent"` | Bỏ qua các event từ AWS Service nội bộ (không phải người dùng) |

**Tại sao cần loại bỏ `AwsServiceEvent`?**
→ AWS đôi khi tự động thực hiện một số hành động dưới danh nghĩa root (ví dụ: S3 bucket ownership events). Loại bỏ chúng để giảm false positives.

---

## 4. CloudTrail → CloudWatch Logs — Cơ chế hoạt động

```
Root Login ──► CloudTrail API ──► S3 (raw log, encrypted)
                                        │
                                        ▼ (real-time stream)
                                 CloudWatch Logs
                                        │
                                        ▼ Metric Filter tự động scan
                                 Metric: RootAccountLoginCount += 1
                                        │
                                        ▼ (nếu >= 1 trong 5 phút)
                                 CloudWatch Alarm → ALARM
                                        │
                                        ▼
                                 SNS → Email 📧
```

**Độ trễ thực tế:**
- CloudTrail → CloudWatch Logs: ~2-5 phút
- Alarm evaluation: mỗi 5 phút
- Tổng cộng: ~7-15 phút từ lúc login đến lúc nhận email

---

## 5. IAM Role cho CloudTrail — Tại sao cần?

CloudTrail cần quyền ghi vào CloudWatch Logs (PutLogEvents). Đây là một cross-service integration → bắt buộc phải có IAM Role với Trust Policy cho `cloudtrail.amazonaws.com`:

```json
{
  "Effect": "Allow",
  "Action": ["logs:CreateLogStream", "logs:PutLogEvents"],
  "Resource": "arn:aws:logs:*:*:log-group:/aws/cloudtrail/*:*"
}
```

---

## 6. `treat_missing_data` — Sự lựa chọn quan trọng

Với bài này, chọn **`notBreaching`** (khác với bài CPU alarm chọn `breaching`):

| Giá trị | Ý nghĩa | Phù hợp khi |
|---------|---------|------------|
| `notBreaching` | No data = OK (không có login) | ✅ Root login alert — không có login = an toàn |
| `breaching` | No data = ALARM (giả định vi phạm) | CPU alarm — mất metric = có thể bị crash |
| `missing` | No data → INSUFFICIENT_DATA | Không muốn false positive |
| `ignore` | Giữ nguyên state cũ | |

→ **Root login alert:** Không có metric data = không có root login = BÌNH THƯỜNG → dùng `notBreaching`

---

## 7. CloudTrail Concepts

| Khái niệm | Giải thích |
|----------|-----------|
| **Trail** | Cấu hình ghi lại API calls |
| **Event** | Một API call đơn lẻ (ví dụ: ConsoleLogin, CreateBucket) |
| **Management Events** | Các thao tác quản lý tài nguyên (không phải data) |
| **Data Events** | Read/Write vào S3, Lambda (tốn thêm tiền) |
| **Global Service Events** | IAM, STS, Route53 — cần bật riêng |
| **Multi-region Trail** | Ghi event ở tất cả regions |

---

## 8. Security Namespace — Best Practice

Dùng namespace `Security` (custom) thay vì `AWS/CloudTrail`:
- Tách biệt metrics bảo mật với metrics AWS mặc định
- Dễ tạo IAM Policy giới hạn theo namespace
- Dễ tìm trong CloudWatch Console

---

## 9. So sánh các bài lab Monitoring W9

| | Session 03 | Session 05 |
|--|-----------|-----------|
| **Metric nguồn** | Built-in (CPUUtilization) | Custom (từ Metric Filter trên CloudTrail) |
| **Trigger** | CPU > 80% trong 5 phút | Root login >= 1 lần |
| **Mức độ khẩn cấp** | Hiệu năng | Bảo mật |
| `treat_missing_data` | `breaching` | `notBreaching` |
| **Cần CloudTrail?** | Không | Bắt buộc |
| **Cần Metric Filter?** | Không | Bắt buộc |

---

## 10. Các lưu ý thực hành

⚠️ **KHÔNG test bằng cách login root thật nếu không cần thiết!**
→ Thay vào đó, tạo giả metric bằng CLI:
```bash
aws cloudwatch put-metric-data \
  --namespace "Security" \
  --metric-name "RootAccountLoginCount" \
  --value 1 \
  --region ap-southeast-1
```
→ Sau 5 phút → Alarm sẽ trigger và email được gửi đi!

---

## 11. Chi phí

| Dịch vụ | Chi phí |
|---------|---------|
| CloudTrail (Management Events, 1 region) | Free tier: 1 trail miễn phí |
| CloudWatch Logs Ingestion | $0.50/GB |
| CloudWatch Custom Metrics | $0.30/metric/tháng (10 đầu miễn phí) |
| CloudWatch Alarms | $0.10/alarm/tháng |
| SNS Email | Free tier: 1000 email/tháng |
| S3 (log storage) | $0.023/GB |

**Tổng ước tính cho lab ngắn ngày:** < $0.01
