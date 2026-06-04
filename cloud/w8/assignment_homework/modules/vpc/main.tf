# =============================================================================
# MODULE VPC - MAIN
# Triển khai hạ tầng mạng: VPC, Subnet, Route Table, Internet Gateway
# =============================================================================

# TODO 1: Khởi tạo resource aws_vpc
#   Syntax:
#     resource "aws_vpc" "main" {
#       cidr_block           = var.vpc_cidr
#       enable_dns_hostnames = true
#       tags = {
#         Name = "homework-vpc"
#       }
#     }
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "homework-vpc"
  }
}

# TODO 2: Tạo Internet Gateway (IGW) để Public Subnet có thể kết nối Internet
#   Syntax:
#     resource "aws_internet_gateway" "igw" {
#       vpc_id = aws_vpc.main.id
#       tags = { Name = "homework-igw" }
#     }
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "homework-igw"
  }
}

# TODO 3: Tạo Public Subnet (dành cho Web Server EC2)
#   Yêu cầu:
#     - map_public_ip_on_launch = true (Tự động cấp IP công cộng cho EC2)
#     - availability_zone = var.availability_zones[0]
#   Syntax:
#     resource "aws_subnet" "public" {
#       vpc_id                  = aws_vpc.main.id
#       cidr_block              = var.public_subnet_cidr
#       availability_zone       = var.availability_zones[0]
#       map_public_ip_on_launch = true
#       tags = { Name = "homework-public-subnet" }
#     }
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "homework-public-subnet"
  }
}

# TODO 4: Tạo 2 Private Subnets (dành cho Database RDS ở 2 AZ khác nhau)
#   Sử dụng: meta-argument count = 2 để lặp qua danh sách CIDR và AZ.
#   Syntax:
#     resource "aws_subnet" "private" {
#       count             = 2
#       vpc_id            = aws_vpc.main.id
#       cidr_block        = var.private_subnet_cidrs[count.index]
#       availability_zone = var.availability_zones[count.index]
#       tags = { Name = "homework-private-subnet-${count.index + 1}" }
#     }
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "homework-private-subnet-${count.index + 1}"
  }
}

# TODO 5: Tạo Route Table cho Public Subnet và cấu hình định tuyến ra IGW
#   Syntax:
#     resource "aws_route_table" "public" {
#       vpc_id = aws_vpc.main.id
#       route {
#         cidr_block = "0.0.0.0/0"
#         gateway_id = aws_internet_gateway.igw.id
#       }
#       tags = { Name = "homework-public-rt" }
#     }
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "homework-public-rt"
  }
}

# TODO 6: Liên kết Public Subnet vào Public Route Table vừa tạo ở trên
#   Syntax:
#     resource "aws_route_table_association" "public" {
#       subnet_id      = aws_subnet.public.id
#       route_table_id = aws_route_table.public.id
#     }
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# TODO 7: Tạo Route Table cho Private Subnets (không định tuyến ra Internet Gateway để đảm bảo an toàn)
#   Syntax:
#     resource "aws_route_table" "private" {
#       vpc_id = aws_vpc.main.id
#       tags = { Name = "homework-private-rt" }
#     }
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "homework-private-rt"
  }
}

# TODO 8: Liên kết 2 Private Subnets vào Private Route Table
#   Sử dụng: count = 2
#   Syntax:
#     resource "aws_route_table_association" "private" {
#       count          = 2
#       subnet_id      = aws_subnet.private[count.index].id
#       route_table_id = aws_route_table.private.id
#     }
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
