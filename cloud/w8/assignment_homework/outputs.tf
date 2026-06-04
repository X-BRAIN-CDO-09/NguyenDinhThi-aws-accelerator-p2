# =============================================================================
# ROOT - OUTPUTS
# Khai báo các kết quả đầu ra sau khi hạ tầng hoàn thành triển khai
# =============================================================================

# TODO 1: Khai báo Output in ra IP công cộng của Web Server EC2
#   Syntax:
#     output "web_server_public_ip" {
#       value       = aws_instance.<logical_name>.public_ip
#       description = "Mô tả"
#     }
output "web_server_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Địa chỉ IP công cộng của Web Server (truy cập SSH hoặc duyệt web)"
}

# TODO 2: Khai báo Output in ra endpoint (đường dẫn kết nối) của RDS MySQL
#   Syntax:
#     output "rds_endpoint" {
#       value       = aws_db_instance.<logical_name>.endpoint
#     }
output "rds_endpoint" {
  value       = aws_db_instance.db.endpoint
  description = "Đường dẫn kết nối (Endpoint) đến RDS Database"
}

# TODO 3: Khai báo Output in ra tên miền của S3 Static Assets Bucket
#   Syntax:
#     output "s3_bucket_domain_name" {
#       value       = aws_s3_bucket.<logical_name>.bucket_regional_domain_name
#     }
output "s3_bucket_domain_name" {
  value       = aws_s3_bucket.static_assets.bucket_regional_domain_name
  description = "Tên miền khu vực của S3 Bucket lưu static assets"
}
