module "vpc" {
  source = "../../modules/vpc"

  name = "eks-prod"
  cidr = "10.1.0.0/16"

  azs = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

  private_subnets = ["10.1.10.0/24", "10.1.20.0/24", "10.1.30.0/24"]
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]

  single_nat_gateway = false

  tags = {
        env = "prod"
    }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name = "eks-prod"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = {
        env = "prod"
    }
}