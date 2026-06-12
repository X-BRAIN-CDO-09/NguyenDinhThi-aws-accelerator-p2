terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Lab         = "W9-Session03-CPU-Alarm-SNS"
    }
  }
}

# ─────────────────────────────────────────────
# DATA SOURCES
# ─────────────────────────────────────────────

# Lấy default VPC
data "aws_vpc" "default" {
  default = true
}

# Lấy tất cả subnets trong default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Lấy Amazon Linux 2023 AMI mới nhất
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ─────────────────────────────────────────────
# SECURITY GROUP
# ─────────────────────────────────────────────

resource "aws_security_group" "lab_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for W9 CPU Alarm Lab EC2"
  vpc_id      = data.aws_vpc.default.id

  # SSH (optional, chỉ mở nếu có key pair)
  dynamic "ingress" {
    for_each = var.key_pair_name != "" ? [1] : []
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Trong lab thật nên giới hạn IP của bạn
    }
  }

  # Cho phép tất cả outbound (cần để CloudWatch agent gửi metrics)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# ─────────────────────────────────────────────
# IAM ROLE cho EC2 (CloudWatch Agent)
# ─────────────────────────────────────────────

resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach CloudWatchAgentServerPolicy (cho phép EC2 gửi metrics lên CloudWatch)
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

# ─────────────────────────────────────────────
# EC2 INSTANCE (t3.micro)
# ─────────────────────────────────────────────

resource "aws_instance" "lab_ec2" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  # Bật detailed monitoring (1 phút thay vì 5 phút mặc định)
  monitoring = true

  # User data: cài stress tool để test CPU alarm
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Cập nhật hệ thống
    dnf update -y

    # Cài stress-ng để giả lập CPU load
    dnf install -y stress-ng

    # Cài CloudWatch Agent
    dnf install -y amazon-cloudwatch-agent

    # Tạo script stress CPU để dùng sau
    cat > /home/ec2-user/stress-cpu.sh << 'STRESS_SCRIPT'
    #!/bin/bash
    echo "=== Starting CPU stress test ==="
    echo "CPU sẽ bị đẩy lên ~100% trong 6 phút (360 giây)"
    echo "CloudWatch sẽ detect sau 5 phút → ALARM → Email sẽ được gửi"
    echo ""
    stress-ng --cpu $(nproc) --timeout 360s --metrics-brief
    echo ""
    echo "=== Stress test completed ==="
    STRESS_SCRIPT

    chmod +x /home/ec2-user/stress-cpu.sh
    chown ec2-user:ec2-user /home/ec2-user/stress-cpu.sh

    echo "Lab setup completed! Run ~/stress-cpu.sh to trigger alarm." >> /var/log/lab-setup.log
  EOF
  )

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

# ─────────────────────────────────────────────
# SNS TOPIC & SUBSCRIPTION
# ─────────────────────────────────────────────

resource "aws_sns_topic" "cpu_alerts" {
  name         = "${var.project_name}-cpu-alerts"
  display_name = "W9 Lab - CPU High Alert"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ─────────────────────────────────────────────
# CLOUDWATCH ALARM — CPU > 80% trong 5 phút
# ─────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "cpu_high_alarm" {
  alarm_name          = "${var.project_name}-cpu-high"
  alarm_description   = "Alert: EC2 CPU utilization exceeded ${var.cpu_threshold}% for ${var.alarm_period_seconds / 60} minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = aws_instance.lab_ec2.id
  }

  # Khi CPU vào trạng thái ALARM → gửi SNS
  alarm_actions = [aws_sns_topic.cpu_alerts.arn]

  # Khi CPU trở về bình thường (OK) → gửi SNS recovery alert
  ok_actions = [aws_sns_topic.cpu_alerts.arn]

  # Khi không đủ dữ liệu → cũng notify
  insufficient_data_actions = []

  tags = {
    Name = "${var.project_name}-cpu-alarm"
  }
}

# ─────────────────────────────────────────────
# CLOUDWATCH DASHBOARD (bonus: visualize)
# ─────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "lab_dashboard" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title   = "EC2 CPU Utilization — ${aws_instance.lab_ec2.id}"
          view    = "timeSeries"
          stacked = false
          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              aws_instance.lab_ec2.id,
              {
                label  = "CPU %"
                color  = "#ff6b6b"
                period = 60
                stat   = "Average"
              }
            ]
          ]
          yAxis = {
            left = {
              min   = 0
              max   = 100
              label = "CPU Utilization (%)"
            }
          }
          annotations = {
            horizontal = [
              {
                label = "Alarm Threshold (${var.cpu_threshold}%)"
                value = var.cpu_threshold
                color = "#d13212"
              }
            ]
          }
          period = 60
          region = var.aws_region
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 6
        width  = 6
        height = 3
        properties = {
          title  = "CPU Alarm Status"
          alarms = [aws_cloudwatch_metric_alarm.cpu_high_alarm.arn]
        }
      }
    ]
  })
}
