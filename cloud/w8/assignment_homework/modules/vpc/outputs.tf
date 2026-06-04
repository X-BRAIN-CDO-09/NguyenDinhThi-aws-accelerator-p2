# =============================================================================
# MODULE VPC - OUTPUTS
# Trích xuất các giá trị đầu ra từ Module VPC để sử dụng ở cấu hình chính (Root)
# =============================================================================

# TODO 1: Khai báo Output vpc_id để truyền cho các Security Groups
#   Syntax:
#     output "vpc_id" {
#       value       = aws_vpc.<tên_logical_vpc>.id
#       description = "Mô tả giá trị đầu ra"
#     }
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID của VPC mới tạo"
}

# TODO 2: Khai báo Output public_subnet_id để truyền vào EC2 Web Server
#   Syntax:
#     output "public_subnet_id" {
#       value       = aws_subnet.<tên_logical_public_subnet>.id
#     }
output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "ID của Public Subnet để deploy Web Server"
}

# TODO 3: Khai báo Output private_subnet_ids để truyền vào RDS Subnet Group
#   Syntax:
#     output "private_subnet_ids" {
#       value       = [aws_subnet.<private_1>.id, aws_subnet.<private_2>.id]
#       # Hoặc dùng splat operator nếu dùng count/for_each:
#       # value     = aws_subnet.<private_logical>[*].id
#     }
output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Danh sách IDs của các Private Subnets để deploy RDS Database"
}
