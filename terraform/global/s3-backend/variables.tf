variable "region" {
  default = "ap-south-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  default     = "eks-dev-tf-state-bucket-ap-south-1"
}

variable "dynamodb_table" {
  default = "eks-dev-tf-state-lock"
}

variable "env" {
  default = "global"
}