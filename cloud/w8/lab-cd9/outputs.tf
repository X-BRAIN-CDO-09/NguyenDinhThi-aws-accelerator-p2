# ==============================================================================
# LAB CD9 - Outputs Configuration
# Xuat ra cac thong tin huong dan su dung ngay sau khi apply xong
# ==============================================================================

output "alb_dns_name" {
  description = "URL truy cap ung dung cua ban qua Internet"
  value       = "http://${aws_lb.app.dns_name}"
}

output "instance_public_ip" {
  description = "IP Public cua EC2 Instance"
  value       = aws_instance.minikube.public_ip
}

output "ssh_command" {
  description = "Lenh SSH vao EC2 nhanh chong ma khong can go nhieu"
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.minikube.public_ip}"
}

output "kube_api_proxy" {
  description = "API Endpoint cua K8s mo qua proxy (chi accessible tu IP của ban)"
  value       = "http://${aws_instance.minikube.public_ip}:${var.proxy_port}"
}

# ===== RDS MySQL Outputs =====
output "rds_endpoint" {
  description = "Endpoint cua RDS MySQL (chi truy cap duoc tu EC2 trong VPC)"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_database_name" {
  description = "Ten database tren RDS"
  value       = aws_db_instance.mysql.db_name
}

output "rds_password" {
  description = "Password cua RDS MySQL (tu dong sinh boi random_password)"
  value       = random_password.db_password.result
  sensitive   = true
}

# ===== S3 Outputs =====
output "s3_bucket_name" {
  description = "Ten S3 Bucket chua static assets"
  value       = aws_s3_bucket.static_assets.id
}

output "s3_bucket_arn" {
  description = "ARN cua S3 Bucket"
  value       = aws_s3_bucket.static_assets.arn
}

output "s3_website_url" {
  description = "URL truy cap trang HTML duoc host truc tiep tren S3"
  value       = "http://${aws_s3_bucket_website_configuration.static_assets.website_endpoint}"
}



