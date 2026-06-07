# ==============================================================================
# LAB CD9 - Custom VPC Configuration
# Tu dung mang ao (VPC), Subnets, Internet Gateway va Route Tables tu dau
# ==============================================================================

# 1. Khoi tao Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# 2. Khoi tao Internet Gateway (IGW) de cho phep VPC ket noi ra ngoai Internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# 3. Khoi tao Public Subnet A (ap-southeast-1a) - Chay ALB va EC2
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true # Tu dong gan IP Public khi bat EC2 trong subnet nay

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet-a"
  })
}

# 4. Khoi tao Public Subnet B (ap-southeast-1b) - Chay ALB de dam bao High Availability (HA)
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet-b"
  })
}

# 5. Khoi tao Route Table (Bang dinh tuyen) trỏ moi traffic ra ngoai qua Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

# 6. Lien ket Bang dinh tuyen vao Public Subnet A
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# 7. Lien ket Bang dinh tuyen vao Public Subnet B
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# PRIVATE SUBNETS (cho RDS MySQL) + NAT Gateway
# ==============================================================================

# 8. Private Subnet A (ap-southeast-1a) - Chay RDS MySQL
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet-a"
  })
}

# 9. Private Subnet B (ap-southeast-1b) - RDS Subnet Group bat buoc can it nhat 2 AZ
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet-b"
  })
}

# 10. Elastic IP cho NAT Gateway (IP tinh de NAT traffic ra ngoai Internet)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip"
  })
}

# 11. NAT Gateway (dat o Public Subnet A, cho phep Private Subnets truy cap Internet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-gw"
  })

  depends_on = [aws_internet_gateway.gw]
}

# 12. Route Table cho Private Subnets (traffic ra Internet di qua NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt"
  })
}

# 13. Lien ket Private Route Table vao Private Subnet A
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# 14. Lien ket Private Route Table vao Private Subnet B
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
