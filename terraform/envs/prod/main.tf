module "vpc" {
  source = "../../modules/vpc"

  name = "${var.project_name}-${var.env}-vpc"
  cidr = "10.0.0.0/16"

  azs = ["ap-south-1a", "ap-south-1b"]

  private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    env = "prod"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "${var.project_name}-cluster-${var.env}"
  cluster_version = "1.32"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  aws_region = var.aws_region

  desired_size = 1
  min_size     = 1
  max_size     = 3

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  cluster_endpoint_public_access_cidrs = var.allowed_cidr_blocks

  tags = {
    env = "prod"
  }
}

variable "project_name" {
  description = "Name of the project"
  default     = "eks"
}

variable "env" {
  description = "Deployment environment"
  default     = "prod"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks permitted to reach the EKS public API endpoint"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}
