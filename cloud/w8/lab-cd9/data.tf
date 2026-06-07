# ==============================================================================
# LAB CD9 - Data Sources Configuration
# Truy van thong tin dong tu AWS truoc khi build ha tang
# ==============================================================================

# 0. Lay thong tin AWS Account ID hien tai (dung de dat ten S3 Bucket duy nhat toan cau)
data "aws_caller_identity" "current" {}

# 1. Tim kiem Ubuntu 22.04 AMI moi nhat tu nha phat hanh Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Ubuntu Canonical ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
