output "ec2_public_ip" {
  value       = aws_instance.security_lab_node.public_ip
  description = "Public IP address of the EC2 instance (use this for SSH and browser access)"
}

output "ssh_command" {
  value       = "ssh -i \"<PATH_TO_YOUR_KEY_PAIR_PEM_FILE>\" ubuntu@${aws_instance.security_lab_node.public_ip}"
  description = "SSH command to connect to the EC2 instance"
}

output "argocd_url" {
  value       = "https://${aws_instance.security_lab_node.public_ip}:8443"
  description = "URL to access ArgoCD Web UI (after running setup-ec2.sh)"
}

output "app_api_url" {
  value       = "http://${aws_instance.security_lab_node.public_ip}:8080"
  description = "URL to access the Demo App API"
}
