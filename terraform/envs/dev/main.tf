module "vpc" {
  source = "../../modules/vpc"

  name = "${var.project_name}-${var.env}-vpc"
  cidr = "10.0.0.0/16"

  azs = ["ap-south-2a", "ap-south-2b"]

  private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # single NAT = cheaper for dev/showcase

  tags = {
    env = "dev"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "${var.project_name}-eks-cluster-${var.env}"
  cluster_version = "1.32"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  desired_size = 1
  min_size     = 1
  max_size     = 3

  instance_types = ["t3.micro"] # t3a.medium not available in ap-south-2
  capacity_type  = "ON_DEMAND"   # SPOT has no capacity in ap-south-2

  tags = {
    env = "dev"
  }
}

variable "project_name" {
  description = "Name of the project"
  default     = "eks"
}

variable "env" {
  description = "Deployment environment"
  default     = "dev"
}
