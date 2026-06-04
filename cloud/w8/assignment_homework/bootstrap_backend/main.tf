# =============================================================================
# BOOTSTRAP BACKEND
# Tạo S3 Bucket và DynamoDB Table để lưu trữ State File của Terraform
# =============================================================================
# Mục tiêu:
#   Chạy thư mục này TRƯỚC để tạo các tài nguyên lưu trữ trạng thái (State).
#   Sau khi chạy xong, lấy tên Bucket và Table điền vào file `backend.tf`
#   của thư mục chính để migrate dữ liệu state lên đám mây AWS.
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # TODO 1: Điền vùng (region) bạn muốn chạy AWS. Gợi ý: "ap-southeast-1" (Singapore)
  # Syntax: region = "<region_name>"
  region = "ap-southeast-1"
}

# TODO 2: Khai báo tài nguyên aws_s3_bucket để làm nơi chứa state file
#   Yêu cầu: Tên bucket phải là duy nhất trên toàn cầu (Globally Unique).
#   Syntax:
#     resource "aws_s3_bucket" "<tên_logical>" {
#       bucket = "<tên_s3_bucket_chọn_tùy_ý>"
#     }
#
resource "aws_s3_bucket" "terraform_state" {
  # Cần sửa tên bucket này cho độc nhất (ví dụ: `<tên_của_bạn>-k8s-tf-state-bucket`)
  bucket = "assignment-homework-tf-state-bucket-unique"
  
  # Đảm bảo không bị xóa nhầm bucket chứa state quan trọng
  lifecycle {
    prevent_destroy = false
  }
}

# TODO 3: Bật tính năng Versioning cho S3 Bucket để giữ lịch sử các phiên bản State
#   Syntax:
#     resource "aws_s3_bucket_versioning" "<tên_logical>" {
#       bucket = aws_s3_bucket.<tên_logical_bucket>.id
#       versioning_configuration {
#         status = "Enabled"
#       }
#     }
#
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# TODO 4: Cấu hình mã hóa Server-side Encryption cho S3 Bucket để bảo mật thông tin nhạy cảm
#   Syntax:
#     resource "aws_s3_bucket_server_side_encryption_configuration" "<tên_logical>" {
#       bucket = aws_s3_bucket.<tên_logical_bucket>.id
#       rule {
#         apply_server_side_encryption_by_default {
#           sse_algorithm = "AES256"
#         }
#       }
#     }
#
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# TODO 5: Tạo bảng DynamoDB để quản lý cơ chế khóa trạng thái (State Locking)
#   Yêu cầu: Bảng phải có một khóa chính (Hash Key) tên chính xác là "LockID" (kiểu chuỗi - S)
#   Syntax:
#     resource "aws_dynamodb_table" "<tên_logical>" {
#       name         = "<tên_bảng_chọn_tùy_ý>"
#       billing_mode = "PAY_PER_REQUEST"
#       hash_key     = "LockID"
#       attribute {
#         name = "LockID"
#         type = "S"
#       }
#     }
#
resource "aws_dynamodb_table" "state_locks" {
  name         = "assignment-homework-tf-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# =============================================================================
# OUTPUTS
# In ra terminal tên Bucket và Table sau khi tạo xong
# =============================================================================
output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "Tên S3 Bucket cần điền vào backend.tf"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.state_locks.name
  description = "Tên DynamoDB Table cần điền vào backend.tf"
}
