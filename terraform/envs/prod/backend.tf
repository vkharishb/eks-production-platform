terraform {
  backend "s3" {
    bucket         = "eks-Prod-tf-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "terraform-lock"
  }
}