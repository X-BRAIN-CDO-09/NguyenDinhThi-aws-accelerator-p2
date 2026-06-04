# =============================================================================
# ROOT - BACKEND
# Cấu hình lưu trữ file trạng thái (State File) từ xa trên S3 và DynamoDB Lock
# =============================================================================
# Hướng dẫn:
#   Sau khi bạn chạy thành công phần bootstrap_backend, hãy copy tên S3 Bucket
#   và DynamoDB table điền vào các tham số dưới đây. Sau đó bỏ comment phần
#   terraform block này để kích hoạt Backend Remote.
# =============================================================================

# TODO: Điền tên Bucket và DynamoDB table của bạn và bỏ comment (xóa dấu #) đoạn code bên dưới:

 terraform {
   backend "s3" {
     bucket         = "assignment-homework-tf-state-bucket-unique" # ← ĐIỀN TÊN S3 BUCKET CỦA BẠN VÀO ĐÂY
     key            = "final-project/terraform.tfstate"
     region         = "ap-southeast-1"
     dynamodb_table = "assignment-homework-tf-state-locks"        # ← ĐIỀN TÊN DYNAMODB TABLE CỦA BẠN VÀO ĐÂY
     encrypt        = true
   }
 }
