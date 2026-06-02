terraform {
  required_version = ">= 1.0.0"
  
  # Cấu hình providers cần thiết (dùng local provider để thực hành ngoại tuyến)
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "local" {
  # Không cần cấu hình gì thêm đối với local provider
}

# 1. Minh họa gọi Module tự định nghĩa kèm theo meta-argument 'for_each'
# module này sẽ lặp qua danh sách các server đang active và tạo cấu hình ảo
module "servers" {
  source   = "./modules/local_server"
  for_each = local.active_servers # Sử dụng for_each để tạo động các server từ Map

  server_name = each.key
  server_role = each.value.role
  environment = var.env
  cpu_cores   = each.value.cpu
  ram_gb      = each.value.ram
  allowed_ips = ["127.0.0.1", "192.168.1.10"]
}

# 2. Minh họa tạo một tài nguyên đơn lẻ ở root module
resource "local_file" "environment_manifest" {
  filename = "${path.module}/env_${var.env}_manifest.txt"
  
  content = <<EOF
==================================================
🌍 ENVIRONMENT MANIFEST
==================================================
Workspace Prefix : ${local.workspace_prefix}
Global Severity  : ${local.severity}
Common Tags      :
${jsonencode(local.common_tags)}

Active Servers   :
${join("\n", [for name, config in local.active_servers : "- ${name} (${config.role}): ${config.cpu} Cores, ${config.ram} GB RAM"])}
==================================================
EOF

  # 3. Minh họa meta-argument 'depends_on'
  # Bắt buộc manifest này chỉ được tạo sau khi TẤT CẢ các module server đã chạy xong
  depends_on = [
    module.servers
  ]

  # 4. Minh họa block 'lifecycle' của Resource
  lifecycle {
    # Ngăn chặn việc xóa manifest này nếu có chạy destroy (hãy bỏ comment để test thử)
    # prevent_destroy = true
    
    # Bỏ qua thay đổi nếu file này bị chỉnh sửa thủ công tags bên ngoài (nếu có hỗ trợ tag)
    ignore_changes = []
  }
}
