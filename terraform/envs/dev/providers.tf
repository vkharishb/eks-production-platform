provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = "eks-production-platform"
      Environment = "dev"
    }
  }
}
