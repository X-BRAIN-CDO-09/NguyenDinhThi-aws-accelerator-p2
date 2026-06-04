# ==============================================================================
# LAB CD9 - Locals Configuration
# Khai bao cac gia tri local de tai su dung va gan tags dong nhat
# ==============================================================================

locals {
  name_prefix = "lab-cd9"

  common_tags = {
    Project     = "CD9-Automation"
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Owner       = "NguyenDinhThi" # Dat theo ten cua ban
  }
}
