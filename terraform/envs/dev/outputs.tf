# Reference subnets from VPC, not EKS
output "private_subnets" {
  value = module.vpc.private_subnets
}
