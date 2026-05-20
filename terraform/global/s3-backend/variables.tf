variable "region" {
  description = "AWS region for the S3 backend"
  default     = "ap-south-1"
}

variable "env" {
  description = "Environment name"
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  default     = "eks-production-platform"
}
