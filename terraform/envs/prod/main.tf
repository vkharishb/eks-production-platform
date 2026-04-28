module "vpc" {
  source = "../../modules/vpc"

  name = "eks-prod"
  cidr = "10.0.0.0/16"

  azs = ["ap-south-1a", "ap-south-1b"]

  private_subnets = ["10.1.10.0/24", "10.1.20.0/24"]
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]

  single_nat_gateway = true

  tags = {
    env = "prod"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "eks-prod"
  cluster_version = "1.29"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  tags = {
    env = "prod"
  }
}
