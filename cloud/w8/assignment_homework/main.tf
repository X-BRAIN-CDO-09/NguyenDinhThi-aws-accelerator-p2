# =============================================================================
# ROOT - MAIN
# Định nghĩa và lắp ghép các tài nguyên chính: VPC Module, Security Groups, S3, EC2, RDS
# =============================================================================

# TODO 1: Gọi Module VPC từ thư mục cục bộ (modules/vpc)
#   Yêu cầu: Truyền các tham số tương ứng từ variables ở root vào module
#   Syntax:
#     module "vpc" {
#       source               = "./modules/vpc"
#       vpc_cidr             = var.vpc_cidr
#       public_subnet_cidr   = var.public_subnet_cidr
#       private_subnet_cidrs = var.private_subnet_cidrs
#       availability_zones   = var.availability_zones
#     }
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# =============================================================================
# SECURITY GROUPS (Cấu hình Tường lửa)
# =============================================================================

# TODO 2: Tạo Security Group cho Web Server EC2 (Cho phép HTTP port 80 và SSH port 22)
#   Syntax:
#     resource "aws_security_group" "web_sg" {
#       name        = "homework-web-sg"
#       description = "Allow HTTP and SSH"
#       vpc_id      = module.vpc.vpc_id
#
#       ingress {
#         description = "Allow HTTP"
#         from_port   = 80
#         to_port     = 80
#         protocol    = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#       }
#
#       ingress {
#         description = "Allow SSH"
#         from_port   = 22
#         to_port     = 22
#         protocol    = "tcp"
#         cidr_blocks = ["0.0.0.0/0"] # Bạn có thể đổi thành IP cá nhân của bạn để bảo mật hơn
#       }
#
#       egress {
#         from_port   = 0
#         to_port     = 0
#         protocol    = "-1"
#         cidr_blocks = ["0.0.0.0/0"]
#       }
#     }
resource "aws_security_group" "web_sg" {
  name        = "homework-web-sg"
  description = "Allow HTTP and SSH traffic to Web Server"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "homework-web-sg"
  }
}

# TODO 3: Tạo Security Group cho RDS Database (CHỈ cho phép truy cập cổng MySQL 3306 từ Web SG)
#   Yêu cầu bảo mật: Không mở cổng database ra toàn bộ internet (0.0.0.0/0), chỉ nhận traffic từ web_sg.
#   Syntax:
#     resource "aws_security_group" "db_sg" {
#       name   = "homework-db-sg"
#       vpc_id = module.vpc.vpc_id
#       ingress {
#         from_port       = 3306
#         to_port         = 3306
#         protocol        = "tcp"
#         security_groups = [aws_security_group.web_sg.id] # ← ĐÂY LÀ ĐIỂM QUAN TRỌNG
#       }
#       egress {
#         from_port   = 0
#         to_port     = 0
#         protocol    = "-1"
#         cidr_blocks = ["0.0.0.0/0"]
#       }
#     }
resource "aws_security_group" "db_sg" {
  name        = "homework-db-sg"
  description = "Allow MySQL traffic only from Web Server Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow MySQL from Web Server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "homework-db-sg"
  }
}

# =============================================================================
# DATA SOURCE (Lấy thông tin AMI tự động)
# =============================================================================

# TODO 4: Dùng data source aws_ami để tự động tìm AMI mới nhất của Amazon Linux 2
#   Syntax:
#     data "aws_ami" "amazon_linux" {
#       most_recent = true
#       owners      = ["amazon"]
#       filter {
#         name   = "name"
#         values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#       }
#     }
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# =============================================================================
# EC2 INSTANCE (Web Server)
# =============================================================================

# TODO 5: Tạo máy chủ EC2 Web Server đặt ở Public Subnet
#   Yêu cầu:
#     - Sử dụng AMI từ data source đã tìm ở trên
#     - Sử dụng instance_type từ variables
#     - Gán public subnet id lấy từ đầu ra của module vpc
#     - Gán security group của web
#   Syntax:
#     resource "aws_instance" "web" {
#       ami                    = data.aws_ami.amazon_linux.id
#       instance_type          = var.instance_type
#       subnet_id              = module.vpc.public_subnet_id
#       vpc_security_group_ids = [aws_security_group.web_sg.id]
#       user_data              = <<-EOF
#                                #!/bin/bash
#                                yum update -y
#                                yum install -y httpd
#                                systemctl start httpd
#                                systemctl enable httpd
#                                echo "<h1>Hello World from AWS Web Server!</h1>" > /var/www/html/index.html
#                                EOF
#       tags = { Name = "homework-web-server" }
#     }
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Khởi chạy một trang Web Apache đơn giản khi tạo server thành công
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Welcome to AWS Web Server (Deployed by Terraform)</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "homework-web-server"
  }
}

# =============================================================================
# STORAGE (S3 Static Assets Bucket)
# =============================================================================

# TODO 6: Tạo S3 Bucket cho static assets
#   Syntax:
#     resource "aws_s3_bucket" "static_assets" {
#       bucket        = var.s3_bucket_static_name
#       force_destroy = true
#       tags          = { Name = "homework-static-assets" }
#     }
resource "aws_s3_bucket" "static_assets" {
  bucket        = var.s3_bucket_static_name
  force_destroy = true # Cho phép xóa bucket dễ dàng kể cả khi đang có dữ liệu khi ta chạy destroy

  tags = {
    Name = "homework-static-assets"
  }
}

# =============================================================================
# DATABASE (RDS MySQL)
# =============================================================================

# TODO 7: Tạo DB Subnet Group liên kết 2 private subnets
#   Yêu cầu: RDS cần group subnet này để biết được dải mạng nội bộ được dùng.
#   Syntax:
#     resource "aws_db_subnet_group" "db_subnet_group" {
#       name       = "homework-db-subnet-group"
#       subnet_ids = module.vpc.private_subnet_ids
#       tags       = { Name = "homework-db-subnet-group" }
#     }
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "homework-db-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Name = "homework-db-subnet-group"
  }
}

# TODO 8: Tạo DB Instance RDS MySQL chạy trong Private Subnets
#   Yêu cầu cấu hình cơ bản (để tiết kiệm chi phí học tập):
#     - engine: "mysql", engine_version: "8.0" (hoặc version mới nhất)
#     - instance_class: "db.t3.micro" (Phù hợp Free Tier)
#     - allocated_storage: 20 (GB)
#     - publicly_accessible: false (Bảo mật tuyệt đối, không mở IP public)
#   Syntax:
#     resource "aws_db_instance" "db" {
#       allocated_storage      = 20
#       engine                 = "mysql"
#       engine_version         = "8.0"
#       instance_class         = "db.t3.micro"
#       db_name                = var.db_name
#       username               = var.db_username
#       password               = var.db_password
#       db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
#       vpc_security_group_ids = [aws_security_group.db_sg.id]
#       skip_final_snapshot    = true
#       tags = { Name = "homework-db-mysql" }
#     }
resource "aws_db_instance" "db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true # Bỏ qua snapshot khi destroy để quá trình xóa diễn ra nhanh chóng

  tags = {
    Name = "homework-db-mysql"
  }
}
