variable "aws_region" {
  type        = string
  description = "AWS Region to deploy the resources"
  default     = "ap-southeast-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance type — t3.medium (2 vCPU, 4GB) is recommended minimum"
  default     = "t3.medium"
}

variable "key_name" {
  type        = string
  description = "Name cho EC2 Key Pair (tự động tạo bởi Terraform)"
  default     = "w10-lab-key"
}

variable "my_ip" {
  type        = string
  description = "Your public IP in CIDR format to restrict SSH access. Use 0.0.0.0/0 to allow all (not recommended in production)."
  default     = "0.0.0.0/0"
}

variable "volume_size" {
  type        = number
  description = "Root EBS volume size in GB (gp3)"
  default     = 20
}
