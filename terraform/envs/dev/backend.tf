terraform {
  backend "s3" {
    bucket         = "eks-dev-tf-state-bucket-ap-south-1"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "eks-dev-tf-state-lock"
  }
}