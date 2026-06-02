output "environment" {
  value       = var.env
  description = "Môi trường hiện tại"
}

output "manifest_file" {
  value       = local_file.environment_manifest.filename
  description = "Đường dẫn của file manifest được tạo ra"
}

output "created_servers" {
  value = {
    for name, s in module.servers : name => s.server_details
  }
  description = "Danh sách chi tiết các server ảo đã được tạo ra từ module"
}
