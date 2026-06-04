# =============================================================================
# ROOT - PROVIDERS
# Định nghĩa các nhà cung cấp dịch vụ (Providers) và phiên bản Terraform yêu cầu
# =============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
