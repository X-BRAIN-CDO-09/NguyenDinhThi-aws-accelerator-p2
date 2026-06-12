variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of existing AWS key pair for SSH access (leave empty to skip SSH)"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name used for resource tagging and naming"
  type        = string
  default     = "w9-cw-agent-lab"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "lab"
}

variable "metrics_collection_interval" {
  description = "How often the CloudWatch Agent collects metrics (seconds)"
  type        = number
  default     = 60
}

variable "custom_metrics_namespace" {
  description = "CloudWatch custom metrics namespace used by the agent"
  type        = string
  default     = "W9Lab/CustomMetrics"
}
