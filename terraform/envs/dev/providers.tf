provider "aws" {
  region = "ap-south-2"

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = "eks-production-platform"
      Environment = "dev"
    }
  }
}
