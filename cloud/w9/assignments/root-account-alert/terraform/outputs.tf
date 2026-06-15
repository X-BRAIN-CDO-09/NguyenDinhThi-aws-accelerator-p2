output "cloudtrail_trail_arn" {
  description = "CloudTrail Trail ARN"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_trail_name" {
  description = "CloudTrail Trail Name"
  value       = aws_cloudtrail.main.name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Logs Group receiving CloudTrail events"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Logs Group ARN"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}

output "metric_filter_name" {
  description = "CloudWatch Log Metric Filter name"
  value       = aws_cloudwatch_log_metric_filter.root_login.name
}

output "metric_namespace" {
  description = "CloudWatch Metric Namespace"
  value       = var.metric_namespace
}

output "metric_name" {
  description = "CloudWatch Metric Name"
  value       = var.metric_name
}

output "alarm_name" {
  description = "CloudWatch Alarm Name"
  value       = aws_cloudwatch_metric_alarm.root_login_alarm.alarm_name
}

output "alarm_arn" {
  description = "CloudWatch Alarm ARN"
  value       = aws_cloudwatch_metric_alarm.root_login_alarm.arn
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for root login alerts"
  value       = aws_sns_topic.root_alerts.arn
}

output "sns_subscription_arn" {
  description = "SNS Email Subscription ARN (pending confirmation)"
  value       = aws_sns_topic_subscription.email_subscription.arn
}

output "s3_bucket_name" {
  description = "S3 bucket storing CloudTrail log files"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "dashboard_url" {
  description = "CloudWatch Security Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.security_dashboard.dashboard_name}"
}

output "cloudtrail_console_url" {
  description = "CloudTrail Console URL to view events"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudtrail/home?region=${var.aws_region}#/events"
}

output "next_steps" {
  description = "Next steps after apply"
  value       = <<-EOT
    =====================================================
    ✅ Infrastructure deployed! Next steps:
    =====================================================

    1. ⚠️  CHECK EMAIL: Confirm SNS subscription
       → AWS gửi email "AWS Notification - Subscription Confirmation"
       → Click link "Confirm subscription" trong email

    2. ⏳  Đợi ~5-10 phút để CloudTrail bắt đầu gửi logs
       → CloudTrail có độ trễ khi mới tạo trail

    3. 🔍  Xem logs tại CloudWatch Logs:
       Log Group: ${var.log_group_name}

    4. 🔒  Test bằng cách login root account (rất CẨN THẬN!):
       → Truy cập AWS Console bằng root account
       → Sau 5 phút → Email alert sẽ đến

    5. 📊  Xem CloudWatch Security Dashboard:
       https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.security_dashboard.dashboard_name}

    6. 📋  Xem CloudTrail events:
       https://${var.aws_region}.console.aws.amazon.com/cloudtrail/home?region=${var.aws_region}#/events

    7. 💸  SAU KHI XONG LAB: terraform destroy -auto-approve
    =====================================================
  EOT
}
