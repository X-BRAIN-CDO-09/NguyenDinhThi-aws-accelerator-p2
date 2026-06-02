locals {
  # 1. Biến cục bộ đơn giản
  creator = "NguyenDinhThi"

  # 2. Sử dụng String Interpolation
  workspace_prefix = "${var.project}-${var.env}"

  # 3. Sử dụng Conditional Expression (Toán tử 3 ngôi)
  # Nếu là môi trường prod thì gán tag quan trọng, dev thì là bình thường
  severity = var.env == "prod" ? "CRITICAL" : "NORMAL"

  # 4. Sử dụng For Expression để lọc các server đang active
  # Chỉ lấy các server có active = true từ map var.servers
  active_servers = {
    for name, config in var.servers : name => config
    if config.active == true
  }

  # 5. Gom tag chung (Common Tags)
  common_tags = {
    Project     = var.project
    Environment = var.env
    Owner       = local.creator
    Severity    = local.severity
  }
}
