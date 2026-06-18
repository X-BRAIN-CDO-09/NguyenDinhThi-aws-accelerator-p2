output "ec2_public_ip" {
  value       = aws_instance.security_lab_node.public_ip
  description = "Public IP address của EC2 instance"
}

output "ssh_command" {
  value       = "ssh -i \"${path.module}/${var.key_name}.pem\" ubuntu@${aws_instance.security_lab_node.public_ip}"
  description = "Lệnh SSH vào EC2 (file .pem được tạo tự động trong thư mục terraform/)"
}

output "argocd_url" {
  value       = "https://${aws_instance.security_lab_node.public_ip}:8443"
  description = "URL truy cập ArgoCD Web UI (sau khi chạy setup-ec2.sh)"
}

output "app_api_url" {
  value       = "http://${aws_instance.security_lab_node.public_ip}:8080"
  description = "URL truy cập Demo App API"
}

output "private_key_path" {
  value       = "${path.module}/${var.key_name}.pem"
  description = "Đường dẫn file private key .pem (tự động tạo bởi Terraform)"
}
