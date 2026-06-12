output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.lab_ec2.id
}

output "ec2_public_ip" {
  description = "EC2 Public IP address"
  value       = aws_instance.lab_ec2.public_ip
}

output "ec2_public_dns" {
  description = "EC2 Public DNS"
  value       = aws_instance.lab_ec2.public_dns
}

output "ec2_ami_used" {
  description = "Amazon Linux 2023 AMI used"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.cpu_alerts.arn
}

output "sns_subscription_arn" {
  description = "SNS Email Subscription ARN (pending confirmation)"
  value       = aws_sns_topic_subscription.email_subscription.arn
}

output "cloudwatch_alarm_name" {
  description = "CloudWatch Alarm name"
  value       = aws_cloudwatch_metric_alarm.cpu_high_alarm.alarm_name
}

output "cloudwatch_alarm_arn" {
  description = "CloudWatch Alarm ARN"
  value       = aws_cloudwatch_metric_alarm.cpu_high_alarm.arn
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch Dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.lab_dashboard.dashboard_name}"
}

output "ssh_command" {
  description = "SSH command to connect to EC2 (only if key_pair_name is set)"
  value       = var.key_pair_name != "" ? "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.lab_ec2.public_ip}" : "No key pair configured"
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

    2. 🖥️  SSH vào EC2 (nếu có key pair):
       ${var.key_pair_name != "" ? "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.lab_ec2.public_ip}" : "No key pair — skip SSH"}

    3. 💥  Trigger CPU alarm:
       ${var.key_pair_name != "" ? "# Trên EC2: ~/stress-cpu.sh" : "# Dùng AWS Systems Manager Session Manager hoặc EC2 Connect"}

    4. 📊  Xem CloudWatch Dashboard:
       https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.lab_dashboard.dashboard_name}

    5. 🔔  Đợi ~5 phút → Email alert đến!

    6. 💸  SAU KHI XONG LAB: terraform destroy -auto-approve
    =====================================================
  EOT
}
