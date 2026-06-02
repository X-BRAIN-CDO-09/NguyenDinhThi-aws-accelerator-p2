# Sử dụng local_file để mô phỏng một server ảo bằng một tệp văn bản cục bộ
resource "local_file" "server_config" {
  filename = "${path.module}/server_${var.server_name}_config.txt"
  
  content = <<EOF
==================================================
🖥️ LOCAL SERVER CONFIGURATION (SIMULATED)
==================================================
Server Name : ${var.server_name}
Role        : ${upper(var.server_role)}
Environment : ${upper(var.environment)}
Specs       : ${var.cpu_cores} Cores, ${var.ram_gb} GB RAM
Allowed IPs : ${join(", ", var.allowed_ips)}
Status      : ACTIVE
Created By  : Terraform Local Server Module
==================================================
EOF

  # Minh họa block lifecycle bên trong resource
  lifecycle {
    # Tạo cấu hình mới trước khi xóa cấu hình cũ (nếu thay đổi tên file)
    create_before_destroy = true
  }
}
