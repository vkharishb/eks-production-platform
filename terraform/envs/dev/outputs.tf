output "cluster_id" {
  value = module.eks.cluster_id
}

# Reference subnets from VPC, not EKS
output "private_subnets" {
  value = module.vpc.private_subnets
}
