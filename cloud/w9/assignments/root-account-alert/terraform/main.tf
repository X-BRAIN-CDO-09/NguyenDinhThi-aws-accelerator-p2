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
      Lab         = "W9-Session05-Root-Account-Alert"
    }
  }
}

# ─────────────────────────────────────────────
# DATA SOURCES
# ─────────────────────────────────────────────

# Lấy AWS Account ID hiện tại
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# ─────────────────────────────────────────────
# BƯỚC 1: CLOUDTRAIL — Enable & Send Logs to CloudWatch
# ─────────────────────────────────────────────

# S3 Bucket để CloudTrail lưu log files
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.project_name}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy — cho phép CloudTrail ghi vào bucket
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_name}"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_name}"
          }
        }
      }
    ]
  })
}

# CloudWatch Logs Group — nơi CloudTrail gửi log events
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days
}

# IAM Role cho CloudTrail để ghi vào CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.project_name}-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "${var.project_name}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# CloudTrail Trail — theo dõi ALL management events
resource "aws_cloudtrail" "main" {
  name                          = var.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  # Gửi log đến CloudWatch Logs (bắt buộc để tạo Metric Filter)
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs,
    aws_cloudwatch_log_group.cloudtrail
  ]
}

# ─────────────────────────────────────────────
# BƯỚC 2: CLOUDWATCH METRIC FILTER
# Filter Pattern từ Slide:
# { $.userIdentity.type = "Root" && $.eventType != "AwsServiceEvent" }
# ─────────────────────────────────────────────

resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "${var.project_name}-root-login-filter"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name          = var.metric_name       # "RootAccountLoginCount"
    namespace     = var.metric_namespace  # "Security"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# ─────────────────────────────────────────────
# BƯỚC 3: SNS TOPIC & SUBSCRIPTION
# ─────────────────────────────────────────────

resource "aws_sns_topic" "root_alerts" {
  name = "${var.project_name}-root-account-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.root_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ─────────────────────────────────────────────
# BƯỚC 4: CLOUDWATCH ALARM
# Trigger khi RootAccountLoginCount >= 1 trong bất kỳ 5-phút nào
# ─────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "root_login_alarm" {
  alarm_name          = "${var.project_name}-root-login-detected"
  alarm_description   = "SECURITY ALERT: Root account login detected! Investigate immediately."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name      # "RootAccountLoginCount"
  namespace           = var.metric_namespace # "Security"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_threshold  # >= 1 = bất kỳ root login nào
  treat_missing_data  = "notBreaching"       # Không có data = bình thường (không có login)

  # Gửi thông báo khi ALARM
  alarm_actions = [aws_sns_topic.root_alerts.arn]
  # Gửi thông báo khi quay lại OK (optional, cho biết không còn bất thường)
  ok_actions = [aws_sns_topic.root_alerts.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.root_login]
}

# ─────────────────────────────────────────────
# CLOUDWATCH DASHBOARD — Tổng quan bảo mật
# ─────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "${var.project_name}-security-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Root Account Login Count (Security Namespace)"
          view    = "timeSeries"
          stacked = false
          metrics = [
            [var.metric_namespace, var.metric_name]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          annotations = {
            horizontal = [
              {
                label = "ALARM Threshold"
                value = var.alarm_threshold
                color = "#ff0000"
              }
            ]
          }
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title = "Root Login Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.root_login_alarm.arn
          ]
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          title   = "CloudTrail - Root Login Events (Last 1 Hour)"
          region  = var.aws_region
          query   = "SOURCE '${var.log_group_name}' | fields @timestamp, eventName, userIdentity.type, sourceIPAddress, awsRegion | filter userIdentity.type = 'Root' | sort @timestamp desc | limit 20"
          view    = "table"
        }
      }
    ]
  })
}
