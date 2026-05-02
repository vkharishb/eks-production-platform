terraform {
  backend "s3" {
    # bucket name must match what s3-backend/main.tf creates:
    # "${var.project_name}-tf-state-${var.env}" = "eks-production-platform-tf-state-dev"
    bucket         = "eks-production-platform-tf-state-dev"
    key            = "envs/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "eks-production-platform-tf-state-lock-dev"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0.0"
    }
  }

  required_version = ">= 1.3.0"
}
