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
      Lab         = "W9-Session02-CloudWatch-Agent"
    }
  }
}

# ─────────────────────────────────────────────
# DATA SOURCES
# ─────────────────────────────────────────────

data "aws_vpc" "default" {
  default = true
}

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
# IAM ROLE — CloudWatchAgentServerPolicy (Prerequisite từ slide)
# ─────────────────────────────────────────────

resource "aws_iam_role" "ec2_cw_agent_role" {
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

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# CloudWatchAgentServerPolicy — cho phép EC2 gửi custom metrics và logs lên CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# AmazonSSMManagedInstanceCore — cho phép dùng SSM Session Manager (SSH không cần key)
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_cw_agent_role.name
}

# ─────────────────────────────────────────────
# SECURITY GROUP
# ─────────────────────────────────────────────

resource "aws_security_group" "lab_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for W9 CloudWatch Agent Lab EC2"
  vpc_id      = data.aws_vpc.default.id

  # SSH (optional — chỉ mở nếu có key pair)
  dynamic "ingress" {
    for_each = var.key_pair_name != "" ? [1] : []
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Outbound: cần cho CloudWatch Agent gửi metrics + SSM agent
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
# CLOUDWATCH AGENT CONFIG — lưu lên SSM Parameter Store
# (Best practice: agent đọc config từ SSM thay vì hardcode trên EC2)
# ─────────────────────────────────────────────

resource "aws_ssm_parameter" "cw_agent_config" {
  name  = "/w9-lab/cloudwatch-agent/config"
  type  = "String"
  value = file("${path.module}/cloudwatch-agent.json")

  tags = {
    Name = "${var.project_name}-cw-agent-config"
  }
}

# ─────────────────────────────────────────────
# EC2 INSTANCE
# ─────────────────────────────────────────────

resource "aws_instance" "lab_ec2" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null

  # Bật Detailed Monitoring (1 phút) — thu thập EC2 built-in metrics chính xác hơn
  monitoring = true

  # ─────────────────────────────────────────────
  # USER DATA: Tự động thực hiện đủ 4 bước từ slide
  # ─────────────────────────────────────────────
  user_data = base64encode(
    join("\n", [
      "#!/bin/bash",
      "set -e",
      "exec > /var/log/lab-setup.log 2>&1",
      "",
      "echo '============================================='",
      "echo 'W9 Session 02 - CloudWatch Agent Lab Setup'",
      "echo \"Started at: $(date)\"",
      "echo '============================================='",
      "",
      "echo '[STEP 1] Installing CloudWatch Agent...'",
      "dnf update -y",
      "dnf install -y amazon-cloudwatch-agent stress-ng",
      "echo '[STEP 1] CloudWatch Agent installed successfully.'",
      "",
      "echo '[STEP 2] Fetching agent config from SSM Parameter Store...'",
      "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:/w9-lab/cloudwatch-agent/config",
      "echo '[STEP 2] Agent config applied from SSM.'",
      "",
      "echo '[STEP 3] Enabling and starting CloudWatch Agent...'",
      "systemctl enable amazon-cloudwatch-agent",
      "systemctl start amazon-cloudwatch-agent",
      "echo '[STEP 3] CloudWatch Agent started.'",
      "",
      "echo '[STEP 4] Verifying CloudWatch Agent status...'",
      "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status",
      "echo '[STEP 4] Verification complete.'",
      "",
      "cat > /home/ec2-user/verify-agent.sh << 'VERIFY_SCRIPT'",
      "#!/bin/bash",
      "echo '========================================='",
      "echo ' CloudWatch Agent Status Check'",
      "echo '========================================='",
      "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status",
      "systemctl status amazon-cloudwatch-agent --no-pager",
      "tail -20 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
      "VERIFY_SCRIPT",
      "",
      "cat > /home/ec2-user/generate-memory-load.sh << 'LOAD_SCRIPT'",
      "#!/bin/bash",
      "echo 'Running stress-ng: 2 workers, 70% RAM, 120s'",
      "stress-ng --vm 2 --vm-bytes 70% --timeout 120s --metrics-brief",
      "echo 'Done! Check CloudWatch in a few minutes.'",
      "LOAD_SCRIPT",
      "",
      "chmod +x /home/ec2-user/verify-agent.sh /home/ec2-user/generate-memory-load.sh",
      "chown ec2-user:ec2-user /home/ec2-user/verify-agent.sh /home/ec2-user/generate-memory-load.sh",
      "",
      "echo '============================================='",
      "echo 'Setup complete!'",
      "echo 'Namespace: ${var.custom_metrics_namespace}'",
      "echo '============================================='"
    ])
  )

  tags = {
    Name = "${var.project_name}-ec2"
  }

  # Chờ user_data hoàn thành trước khi destroy
  # (không cần với apply, nhưng giúp diagnostics)
  depends_on = [
    aws_ssm_parameter.cw_agent_config,
    aws_iam_role_policy_attachment.cloudwatch_agent_policy,
    aws_iam_role_policy_attachment.ssm_policy,
  ]
}

# ─────────────────────────────────────────────
# CLOUDWATCH DASHBOARD — Visualize tất cả Custom Metrics
# ─────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "lab_dashboard" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: Memory Usage (metric quan trọng nhất — không có trong AWS/EC2 built-in)
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Memory Used % — ${aws_instance.lab_ec2.id}"
          view    = "timeSeries"
          stacked = false
          metrics = [
            [var.custom_metrics_namespace, "mem_used_percent", "InstanceId", aws_instance.lab_ec2.id, { label = "Memory Used %", color = "#ff6b6b", period = 60, stat = "Average" }]
          ]
          yAxis = {
            left = { min = 0, max = 100, label = "Memory (%)" }
          }
          annotations = {
            horizontal = [{ label = "80% threshold", value = 80, color = "#d13212" }]
          }
          period = 60
          region = var.aws_region
        }
      },
      # Row 1: Disk Usage
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Disk Used % (/) — ${aws_instance.lab_ec2.id}"
          view    = "timeSeries"
          stacked = false
          metrics = [
            [var.custom_metrics_namespace, "disk_used_percent", "InstanceId", aws_instance.lab_ec2.id, "path", "/", { label = "Disk Used %", color = "#f59e0b", period = 60, stat = "Average" }]
          ]
          yAxis = {
            left = { min = 0, max = 100, label = "Disk (%)" }
          }
          annotations = {
            horizontal = [{ label = "85% threshold", value = 85, color = "#d13212" }]
          }
          period = 60
          region = var.aws_region
        }
      },
      # Row 2: CPU (Custom via Agent vs Built-in)
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "CPU Usage (Agent Custom) — ${aws_instance.lab_ec2.id}"
          view    = "timeSeries"
          stacked = false
          metrics = [
            [var.custom_metrics_namespace, "cpu_usage_user", "InstanceId", aws_instance.lab_ec2.id, { label = "User %", color = "#3b82f6", period = 60, stat = "Average" }],
            [var.custom_metrics_namespace, "cpu_usage_system", "InstanceId", aws_instance.lab_ec2.id, { label = "System %", color = "#8b5cf6", period = 60, stat = "Average" }],
            [var.custom_metrics_namespace, "cpu_usage_idle", "InstanceId", aws_instance.lab_ec2.id, { label = "Idle %", color = "#22c55e", period = 60, stat = "Average" }]
          ]
          yAxis = {
            left = { min = 0, max = 100, label = "CPU (%)" }
          }
          period = 60
          region = var.aws_region
        }
      },
      # Row 2: Network I/O
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Network I/O — ${aws_instance.lab_ec2.id}"
          view    = "timeSeries"
          stacked = false
          metrics = [
            [var.custom_metrics_namespace, "bytes_sent", "InstanceId", aws_instance.lab_ec2.id, { label = "Bytes Sent", color = "#0ea5e9", period = 60, stat = "Sum" }],
            [var.custom_metrics_namespace, "bytes_recv", "InstanceId", aws_instance.lab_ec2.id, { label = "Bytes Recv", color = "#f97316", period = 60, stat = "Sum" }]
          ]
          yAxis = {
            left = { label = "Bytes" }
          }
          period = 60
          region = var.aws_region
        }
      },
      # Row 3: EC2 Built-in CPU (so sánh với Agent custom CPU)
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 4
        properties = {
          title   = "EC2 Built-in CPUUtilization vs Agent Custom (So sánh)"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.lab_ec2.id, { label = "Built-in CPU%", color = "#94a3b8", period = 60, stat = "Average" }],
            [var.custom_metrics_namespace, "cpu_usage_user", "InstanceId", aws_instance.lab_ec2.id, { label = "Agent cpu_usage_user", color = "#3b82f6", period = 60, stat = "Average" }]
          ]
          yAxis = {
            left = { min = 0, max = 100, label = "CPU (%)" }
          }
          period = 60
          region = var.aws_region
        }
      }
    ]
  })
}
