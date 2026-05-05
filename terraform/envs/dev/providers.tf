provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = "eks-production-platform"
      Environment = "dev"
    }
  }
}
