# ==============================================================================
# LAB CD9 - S3 Bucket Configuration
# Tao S3 Bucket chua static assets (images, CSS, JS, v.v.)
# ==============================================================================

# 1. Khoi tao S3 Bucket (ten bucket phai duy nhat toan cau)
resource "aws_s3_bucket" "static_assets" {
  bucket        = "${local.name_prefix}-static-assets-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Lab: cho phep destroy ngay ca khi bucket con objects ben trong

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-static-assets"
  })
}

# 2. Mo Public Access de lam Static Website Hosting
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3. Bat Server-Side Encryption (ma hoa du lieu luu tru)
resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Bat Versioning (phien ban hoa file de co the khoi phuc khi can)
resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 5. Cau hinh Static Website Hosting
resource "aws_s3_bucket_website_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  index_document {
    suffix = "index.html"
  }
}

# 6. Policy cho phep doc cong khai cac file trong bucket de lam website
resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.static_assets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_assets.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.static_assets]
}

# 7. Upload file index.html tu scripts/ len S3
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_assets.id
  key          = "index.html"
  source       = "${path.module}/scripts/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/scripts/index.html")
}

