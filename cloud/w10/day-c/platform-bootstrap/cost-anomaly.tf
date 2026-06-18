# AWS Cost Anomaly Detection — monitor + alert when spend spikes unexpectedly
# Monitors per-service spend using ML baseline; alerts via SNS when anomaly detected

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

# Monitor: track anomalies per AWS service (EC2, EKS, RDS, etc.)
resource "aws_ce_anomaly_monitor" "service_monitor" {
  name         = "w10-service-anomaly-monitor"
  monitor_type = "DIMENSIONAL"

  monitor_dimension = "SERVICE"
}

# SNS topic to receive anomaly alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "w10-cost-anomaly-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = "thihtktk@gmail.com"
}

# Subscription: alert when daily anomaly impact exceeds $20
resource "aws_ce_anomaly_subscription" "daily_alert" {
  name      = "w10-daily-anomaly-alert"
  frequency = "DAILY"

  monitor_arn_list = [aws_ce_anomaly_monitor.service_monitor.arn]

  subscriber {
    address = aws_sns_topic.cost_alerts.arn
    type    = "SNS"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["20"]   # Alert if anomaly adds > $20 to the day's bill
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}

# Also alert on immediate basis for large spikes (> $50)
resource "aws_ce_anomaly_subscription" "immediate_alert" {
  name      = "w10-immediate-anomaly-alert"
  frequency = "IMMEDIATE"

  monitor_arn_list = [aws_ce_anomaly_monitor.service_monitor.arn]

  subscriber {
    address = aws_sns_topic.cost_alerts.arn
    type    = "SNS"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["50"]   # Wake-up alert — something is badly wrong
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}

output "cost_monitor_arn" {
  value = aws_ce_anomaly_monitor.service_monitor.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.cost_alerts.arn
}
