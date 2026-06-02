output "server_id" {
  value       = local_file.server_config.id
  description = "ID (đường dẫn tuyệt đối) của file cấu hình server được tạo ra"
}

output "server_details" {
  value = {
    name = var.server_name
    role = var.server_role
    ip   = "192.168.1.${var.cpu_cores}" # Giả lập địa chỉ IP dựa trên số nhân CPU
  }
  description = "Thông tin chi tiết của server ảo được tạo"
}
