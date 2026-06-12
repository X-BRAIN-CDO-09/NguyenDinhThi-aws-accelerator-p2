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

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = var.key_pair_name != "" ? "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.lab_ec2.public_ip}" : "No key pair configured — use SSM Session Manager"
}

output "ssm_session_command" {
  description = "AWS SSM Session Manager command (no SSH key needed)"
  value       = "aws ssm start-session --target ${aws_instance.lab_ec2.id} --region ${var.aws_region}"
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch Dashboard visualizing custom metrics"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.lab_dashboard.dashboard_name}"
}

output "custom_metrics_console_url" {
  description = "CloudWatch Metrics console — Custom Namespace"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#metricsV2:graph=~();namespace=${replace(var.custom_metrics_namespace, "/", "~2F")}"
}

output "ssm_parameter_name" {
  description = "SSM Parameter Store name holding the CloudWatch Agent config"
  value       = aws_ssm_parameter.cw_agent_config.name
}

output "iam_role_arn" {
  description = "IAM Role ARN attached to EC2 (has CloudWatchAgentServerPolicy)"
  value       = aws_iam_role.ec2_cw_agent_role.arn
}

output "next_steps" {
  description = "Next steps after apply"
  value       = <<-EOT
    =====================================================
    ✅ Infrastructure deployed! Next steps:
    =====================================================

    1. 🖥️  Kết nối EC2 (SSM Session Manager — không cần key):
       ${var.key_pair_name != "" ? "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.lab_ec2.public_ip}" : "aws ssm start-session --target ${aws_instance.lab_ec2.id} --region ${var.aws_region}"}

    2. ⏳  Đợi ~3 phút để user_data setup xong, sau đó verify:
       ~/verify-agent.sh

    3. 📊  Kiểm tra Custom Metrics trên CloudWatch Console:
       https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#metricsV2

    4. 📈  Xem Dashboard (Memory + Disk + CPU + Network):
       https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.lab_dashboard.dashboard_name}

    5. 💾  Test Memory metric:
       ~/generate-memory-load.sh
       # Sau đó xem Dashboard → mem_used_percent tăng lên

    6. 💸  SAU KHI XONG LAB: terraform destroy -auto-approve
    =====================================================
  EOT
}
