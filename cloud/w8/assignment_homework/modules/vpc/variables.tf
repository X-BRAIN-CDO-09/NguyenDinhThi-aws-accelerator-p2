# =============================================================================
# MODULE VPC - VARIABLES
# Định nghĩa các biến đầu vào cho Module VPC
# =============================================================================

# TODO 1: Khai báo biến dải CIDR block cho VPC
#   Syntax:
#     variable "vpc_cidr" {
#       type        = string
#       description = "Mô tả biến"
#       default     = "10.0.0.0/16"
#     }
variable "vpc_cidr" {
  type        = string
  description = "CIDR block cho VPC chính"
  default     = "10.0.0.0/16"
}

# TODO 2: Khai báo biến dải CIDR block cho Public Subnet (nơi chứa Web Server)
variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block cho Public Subnet"
  default     = "10.0.1.0/24"
}

# TODO 3: Khai báo biến dải CIDR block cho danh sách các Private Subnets (nơi chứa RDS)
#   Chú ý: RDS yêu cầu tối thiểu 2 subnets ở 2 AZs khác nhau.
#   Syntax:
#     variable "private_subnet_cidrs" {
#       type        = list(string)
#       default     = ["10.0.10.0/24", "10.0.11.0/24"]
#     }
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Danh sách CIDR blocks cho Private Subnets (tối thiểu 2 dải)"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# TODO 4: Khai báo biến danh sách Availability Zones (AZ) để phân chia subnet
#   Syntax:
#     variable "availability_zones" {
#       type        = list(string)
#       default     = ["ap-southeast-1a", "ap-southeast-1b"]
#     }
variable "availability_zones" {
  type        = list(string)
  description = "Danh sách các Availability Zones (AZ)"
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}
