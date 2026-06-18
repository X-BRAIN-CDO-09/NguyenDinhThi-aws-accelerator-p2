terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. VPC
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_vpc" "security_lab" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "security-lab-vpc"
    Project = "w10-security-lab"
    Owner   = "NguyenDinhThi"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. Public Subnet
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.security_lab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name    = "security-lab-public-subnet"
    Project = "w10-security-lab"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. Internet Gateway
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.security_lab.id

  tags = {
    Name    = "security-lab-igw"
    Project = "w10-security-lab"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. Route Table → Public Internet
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.security_lab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "security-lab-public-rt"
    Project = "w10-security-lab"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. Security Group
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_security_group" "lab_sg" {
  name        = "security-lab-sg"
  description = "Security Group for W10 Kubernetes Security Lab"
  vpc_id      = aws_vpc.security_lab.id

  # SSH Access (restrict via my_ip variable)
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # ArgoCD Web UI Access (NodePort 30443 → host port 8443)
  ingress {
    description = "ArgoCD Web UI"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Demo App API (NodePort 30080 → host port 8080)
  ingress {
    description = "Demo App API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "security-lab-sg"
    Project = "w10-security-lab"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. Auto-generate SSH Key Pair (không cần tạo thủ công trên AWS Console)
# ─────────────────────────────────────────────────────────────────────────────
resource "tls_private_key" "lab_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab_key" {
  key_name   = var.key_name
  public_key = tls_private_key.lab_key.public_key_openssh

  tags = {
    Name    = var.key_name
    Project = "w10-security-lab"
  }
}

# Lưu private key ra file .pem local (dùng để SSH)
resource "local_file" "private_key_pem" {
  content         = tls_private_key.lab_key.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0600"
}

# ─────────────────────────────────────────────────────────────────────────────
# 7. Lookup latest Ubuntu 22.04 AMI (Canonical)
# ─────────────────────────────────────────────────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 8. IAM Role cho EC2 — truy cập Secrets Manager không cần static credentials
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "ec2_role" {
  name = "security-lab-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name    = "security-lab-ec2-role"
    Project = "w10-security-lab"
  }
}

# Policy: cho phép đọc Secrets Manager
resource "aws_iam_role_policy" "secrets_manager_policy" {
  name = "secrets-manager-read"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:prod/*"
    }]
  })
}

# Instance Profile — gắn IAM Role vào EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "security-lab-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ─────────────────────────────────────────────────────────────────────────────
# 9. EC2 Instance — Ubuntu 22.04, t3.large, 20GB gp3
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_instance" "security_lab_node" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  key_name               = aws_key_pair.lab_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "optional"
  }

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name    = "security-lab-node"
    Project = "w10-security-lab"
    Owner   = "NguyenDinhThi"
  }
}

