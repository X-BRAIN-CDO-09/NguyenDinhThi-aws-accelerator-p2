# ==============================================================================
# LAB CD9 - Backend Bootstrap Configuration
# Tao S3 Bucket + DynamoDB Table de luu tru Terraform State cho main project
# ==============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "lab-cd9"
  common_tags = {
    Project     = "CD9-Automation"
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Owner       = "NguyenDinhThi"
  }
}

# 1. S3 Bucket luu tru Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${local.name_prefix}-terraform-state-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Lab: cho phep destroy nhanh

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-terraform-state"
  })
}

# Bat Versioning de co the rollback state cu
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bat Server-Side Encryption cho state file
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Chan public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. DynamoDB Table cho State Locking (tranh 2 nguoi apply cung luc)
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${local.name_prefix}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-terraform-lock"
  })
}

# Outputs de copy sang main project
output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  value = aws_dynamodb_table.terraform_lock.name
}
