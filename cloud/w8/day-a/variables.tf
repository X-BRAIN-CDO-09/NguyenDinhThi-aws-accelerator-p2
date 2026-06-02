variable "env" {
  type        = string
  description = "Môi trường triển khai chính (dev, staging, prod)"
  default     = "dev"
}

variable "project" {
  type        = string
  description = "Tên dự án"
  default     = "xbrain-accelerator"
}

variable "servers" {
  type = map(object({
    role   = string
    cpu    = number
    ram    = number
    active = bool
  }))
  description = "Danh sách các server cần tạo và thông số chi tiết"
  default = {
    "web-01" = { role = "web", cpu = 2, ram = 4, active = true }
    "db-01"  = { role = "db", cpu = 4, ram = 8, active = true }
    "cache"  = { role = "cache", cpu = 1, ram = 2, active = false }
  }
}
