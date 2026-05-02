terraform {
  backend "s3" {
    bucket         = "eks-platform-tf-state-dev"
    key            = "envs/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "eks-platform-tf-state-lock-dev"
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