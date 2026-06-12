variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "key_pair_name" {
  description = "Name of existing AWS key pair for SSH access (leave empty to skip SSH)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "cpu_threshold" {
  description = "CPU utilization threshold (%) to trigger alarm"
  type        = number
  default     = 80
}

variable "alarm_period_seconds" {
  description = "Period in seconds for CloudWatch alarm evaluation"
  type        = number
  default     = 300 # 5 minutes
}

variable "evaluation_periods" {
  description = "Number of periods to evaluate before triggering alarm"
  type        = number
  default     = 1
}

variable "project_name" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "w9-cpu-alarm-lab"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "lab"
}
