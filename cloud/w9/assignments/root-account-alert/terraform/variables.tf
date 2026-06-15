variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "alert_email" {
  description = "Email address to receive root account login alerts"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource tagging and naming"
  type        = string
  default     = "w9-root-alert-lab"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "lab"
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "w9-root-alert-lab-trail"
}

variable "log_group_name" {
  description = "CloudWatch Logs group name for CloudTrail logs"
  type        = string
  default     = "/aws/cloudtrail/root-login-alert"
}

variable "metric_namespace" {
  description = "CloudWatch metric namespace for the root login metric filter"
  type        = string
  default     = "Security"
}

variable "metric_name" {
  description = "CloudWatch metric name for root account login count"
  type        = string
  default     = "RootAccountLoginCount"
}

variable "alarm_period_seconds" {
  description = "Period in seconds for CloudWatch alarm evaluation (5 minutes)"
  type        = number
  default     = 300
}

variable "evaluation_periods" {
  description = "Number of periods to evaluate before triggering alarm"
  type        = number
  default     = 1
}

variable "alarm_threshold" {
  description = "Threshold for root login count to trigger alarm (>= 1 means any login)"
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "Number of days to retain CloudTrail logs in CloudWatch Logs"
  type        = number
  default     = 7
}
