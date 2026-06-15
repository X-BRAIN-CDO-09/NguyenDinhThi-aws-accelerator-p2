# assets directory — chứa screenshots evidence

Đặt ảnh chụp màn hình vào đây khi chạy lab thật.

## Danh sách ảnh cần chụp:

| File | Nội dung |
|------|---------|
| SS-01_cloudtrail_trail_created.png | CloudTrail Trail đã tạo, gửi log tới CloudWatch Logs |
| SS-02_cloudwatch_log_group.png | CloudWatch Logs Group `/aws/cloudtrail/root-login-alert` |
| SS-03_metric_filter_created.png | Metric Filter với pattern Root login đã được tạo |
| SS-04_alarm_created_ok_state.png | CloudWatch Alarm `RootAccountLoginCount >= 1` ở trạng thái OK |
| SS-05_alarm_configuration_detail.png | Chi tiết cấu hình alarm (threshold, period, evaluation) |
| SS-06_sns_topic_and_subscription.png | SNS Topic + Subscription đã xác nhận (Confirmed) |
| SS-07_confirmation_email.png | Email xác nhận subscription từ AWS trong Gmail |
| SS-08_root_login_simulation.png | Bằng chứng root account login (CloudTrail event hoặc terminal) |
| SS-09_alarm_state_firing.png | Alarm chuyển sang ALARM state sau root login |
| SS-10_email_alert_received.png | Email ALARM nhận được tại Gmail |
| SS-11_cloudtrail_event_detail.png | CloudTrail event detail — Root login event |
| SS-12_dashboard_overview.png | CloudWatch Dashboard tổng quan |
| SS-13_terraform_apply_success.png | terraform apply — Apply complete! N resources added |
| SS-14_terraform_destroy_success.png | terraform destroy — Destroy complete! N resources destroyed |
