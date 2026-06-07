# ==============================================================================
# LAB CD9 - RDS MySQL Configuration
# Deploy RDS MySQL trong Private Subnet, chi cho phep EC2 ket noi
# ==============================================================================

# 1. Tao mat khau ngau nhien cho RDS bang Random Provider (tranh hardcode password)
resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%^&*()-_=+"
}

# 2. DB Subnet Group - bat buoc phai co it nhat 2 subnets o 2 AZ khac nhau
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

# 3. RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier     = "${local.name_prefix}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100 # Auto-scaling storage khi dung het
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az            = false # Lab: tat multi-AZ de tiet kiem chi phi
  publicly_accessible = false # RDS nam trong Private Subnet, KHONG expose ra Internet
  skip_final_snapshot = true  # Lab: bo qua final snapshot khi terraform destroy

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-mysql"
  })
}
