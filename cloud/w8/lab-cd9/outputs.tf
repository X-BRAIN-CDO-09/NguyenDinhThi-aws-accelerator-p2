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
