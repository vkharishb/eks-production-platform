module "vpc" {
  source = "../../modules/vpc"

  name = "eks-dev"
  cidr = "10.0.0.0/16"

  azs = ["ap-south-2a", "ap-south-2b"]

  private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = true

  tags = {
    env = "dev"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "eks-dev"
  cluster_version = "1.30"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  tags = {
    env = "dev"
  }
}
