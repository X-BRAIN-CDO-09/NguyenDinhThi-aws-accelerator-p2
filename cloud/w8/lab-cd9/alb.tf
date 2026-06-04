# ==============================================================================
# LAB CD9 - Application Load Balancer Configuration
# Cau hinh Bo can bang tai va dinh huong traffic tu Internet den EC2
# ==============================================================================

# 1. Khoi tao Application Load Balancer (ALB)
resource "aws_lb" "app" {
  name               = "${local.name_prefix}-alb"
  internal           = false # Expose ra Internet (public)
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id] # Gắn ALB vào 2 Subnet thuộc 2 AZ của Custom VPC để đảm bảo HA

  tags = local.common_tags
}

# 2. Target Group de ALB biet can gui traffic den cong 30080 cua EC2
resource "aws_lb_target_group" "app" {
  name     = "${local.name_prefix}-tg"
  port     = var.app_port # Port NodePort cua K8s App (30080)
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Cau hinh Health Check cho Target Group de ALB kiem tra xem app san sang chua
  health_check {
    path                = "/"
    port                = var.app_port
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2 # Chi can 2 lan pass -> status healthy
    unhealthy_threshold = 5 # 5 lan fail -> unhealthy (cho thoi gian boot Minikube)
  }

  tags = local.common_tags
}

# 3. Listener port 80 (HTTP) tren ALB de nhan request tu nguoi dung va forward vao Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = local.common_tags
}

# 4. Dinh kem (Attach) EC2 Instance dang chay Minikube vao Target Group
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.minikube.id
  port             = var.app_port # Forward luu luong vao dung port NodePort 30080
}
