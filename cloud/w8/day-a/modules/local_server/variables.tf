variable "server_name" {
  type        = string
  description = "Tên của server cần tạo"
}

variable "server_role" {
  type        = string
  description = "Vai trò của server (web, db, cache)"
  default     = "web"
}

variable "environment" {
  type        = string
  description = "Môi trường triển khai (dev, staging, prod)"
}

variable "cpu_cores" {
  type        = number
  description = "Số lượng nhân CPU"
  default     = 2
}

variable "ram_gb" {
  type        = number
  description = "Dung lượng RAM tính bằng GB"
  default     = 4
}

variable "allowed_ips" {
  type        = list(string)
  description = "Danh sách các IP được phép truy cập"
  default     = ["127.0.0.1"]
}
