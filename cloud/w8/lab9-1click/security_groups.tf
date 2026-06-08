# ==============================================================================
# LAB CD9 - Security Groups Configuration
# Cau hinh tuong lua cho ALB va EC2 (cho phep cong proxy dong de Terraform ket noi vao K8s)
# ==============================================================================

# 1. Security Group cho ALB (Cho phep nguoi dung tu Internet truy cap vao qua HTTP port 80)
resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow HTTP port 80 from Internet"
  vpc_id      = aws_vpc.main.id

  # Inbound: Cho phep HTTP port 80 tu moi noi
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Cho phep gui traffic di bat ky dau
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

# 2. Security Group cho EC2 (Chi cho phep ALB va IP cua Dev ket noi)
resource "aws_security_group" "ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Allow traffic from ALB SG to NodePort, SSH and K8s API proxy from Dev IP"
  vpc_id      = aws_vpc.main.id

  # Inbound: Cho phep port 30080 (NodePort) nhung CHI tu ALB SG
  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Inbound: Cho phep SSH port 22 tu IP cua Dev
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Inbound: Cho phep port proxy dong tu IP cua Dev de Terraform ket noi K8s Provider
  ingress {
    from_port   = var.proxy_port
    to_port     = var.proxy_port
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Outbound: Cho phep ket noi Internet (de EC2 tai Docker, Minikube, Nginx)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-sg"
  })
}