# ==============================================================================
# LAB CD9 - Providers Configuration
# Khai bao AWS, TLS, Local va Kubernetes providers
# ==============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 🔑 Kubernetes Provider - Ket noi vao API Server cua Minikube thong qua Proxy
# Su dung host va port dong tu variables
provider "kubernetes" {
  host = "http://${aws_instance.minikube.public_ip}:${var.proxy_port}"
}
