terraform {
  backend "s3" {
    bucket         = "eks-tf-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "terraform-lock"
  }
}