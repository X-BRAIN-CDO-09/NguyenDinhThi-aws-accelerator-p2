# ==============================================================================
# LAB CD9 - Key Pair Configuration
# Wire 2 Provider: tls (sinh key) va aws (import key len cloud)
# ==============================================================================

# 1. Sinh khoa private key su dung TLS Provider
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. ÄÄƒng ky khoa public key len AWS Key Pair (de EC2 gan khoa nay vao)
resource "aws_key_pair" "deployer" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh
  tags       = local.common_tags
}

# 3. Ghi file private key (.pem) xuong thu muc lab hien tai de thuan tien cho dev SSH
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/${local.name_prefix}-key.pem"
  file_permission = "0600" # Dat quyen Read-Write cho chu so huu file (tranh loi Access is denied tren Windows)
}