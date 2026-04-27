variable "region" {
  default = "ap-south-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  default = "eks-tf-state-bucket"
}

variable "dynamodb_table" {
  default = "terraform-lock"
}

variable "env" {
  default = "global"
}