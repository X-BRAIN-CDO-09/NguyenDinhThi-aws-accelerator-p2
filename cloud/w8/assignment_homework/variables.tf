# =============================================================================
# ROOT - VARIABLES
# Định nghĩa các biến đầu vào cho cấu hình Terraform chính
# =============================================================================

# TODO 1: Khai báo biến vùng AWS (Region)
variable "aws_region" {
  type        = string
  description = "Vùng AWS để deploy hạ tầng"
  default     = "ap-southeast-1"
}

# TODO 2: Khai báo biến dải CIDR block cho VPC
variable "vpc_cidr" {
  type        = string
  description = "Dải CIDR block cho VPC"
  default     = "10.0.0.0/16"
}

# TODO 3: Khai báo biến dải CIDR block cho Public Subnet
variable "public_subnet_cidr" {
  type        = string
  description = "Dải CIDR block cho Public Subnet"
  default     = "10.0.1.0/24"
}

# TODO 4: Khai báo biến dải CIDR block cho danh sách Private Subnets
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Danh sách CIDR blocks cho Private Subnets"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# TODO 5: Khai báo biến danh sách Availability Zones
variable "availability_zones" {
  type        = list(string)
  description = "Danh sách Availability Zones"
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

# TODO 6: Khai báo biến cấu hình EC2 Instance Type cho Web Server
#   Syntax:
#     variable "instance_type" {
#       type    = string
#       default = "t2.micro"
#     }
variable "instance_type" {
  type        = string
  description = "Cấu hình loại EC2 Instance"
  default     = "t2.micro"
}

# TODO 7: Khai báo biến cấu hình tên Database MySQL
variable "db_name" {
  type        = string
  description = "Tên Database khởi tạo trong RDS MySQL"
  default     = "webappdb"
}

# TODO 8: Khai báo biến cấu hình Database Username
variable "db_username" {
  type        = string
  description = "Tài khoản quản trị Database"
  default     = "admin"
}

# TODO 9: Khai báo biến cấu hình Database Password (nhạy cảm)
#   Yêu cầu: Đặt thuộc tính sensitive = true để ẩn giá trị password trên logs
#   Syntax:
#     variable "db_password" {
#       type      = string
#       sensitive = true
#     }
variable "db_password" {
  type        = string
  description = "Mật khẩu truy cập Database (nhập khi chạy hoặc cấu hình tfvars)"
  sensitive   = true
  default     = "SuperSecurePassword123" # Bạn có thể thay đổi hoặc nhập khi apply
}

# TODO 10: Khai báo biến cấu hình tên S3 Bucket chứa Static Assets
variable "s3_bucket_static_name" {
  type        = string
  description = "Tên S3 Bucket lưu trữ static assets (phải độc nhất toàn cầu)"
  default     = "assignment-homework-static-assets-unique"
}
