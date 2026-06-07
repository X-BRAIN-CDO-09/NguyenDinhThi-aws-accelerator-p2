# ==============================================================================
# LAB CD9 - Variables Configuration
# Khai bao cac bien dau vao giup de dang tuy bien he thong
# ==============================================================================

variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "Region AWS se trien khai ha tang"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium" # t3.medium: 2 vCPU, 4GB RAM - chay Minikube on dinh nhat
  description = "Loai instance cho may chu EC2"
}

variable "my_ip" {
  type        = string
  default     = "0.0.0.0/0" # Mac dinh allow all de thuan tien cho lab, nen doi thanh IP/32 cua ban trong thuc te
  description = "Dai IP cua ban duoc phep ket noi SSH vao EC2"
}

variable "app_port" {
  type        = number
  default     = 30080
  description = "Port NodePort cua K8s Service se duoc expose ra ngoai host"
}

variable "proxy_port" {
  type        = number
  default     = 8081
  description = "Port proxy dung de Terraform ket noi vao K8s API server tren EC2"
}

# ===== RDS MySQL Variables =====
variable "db_name" {
  type        = string
  default     = "webapp_db"
  description = "Ten database MySQL tren RDS"
}

variable "db_username" {
  type        = string
  default     = "admin"
  description = "Username cho MySQL RDS"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "Loai instance cho RDS (db.t3.micro thuoc Free Tier)"
}
