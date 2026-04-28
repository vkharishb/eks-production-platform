terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95" # pins to v5, blocks v6 which breaks EKS module 20.x
    }
  }

  required_version = ">= 1.3.0"
}
