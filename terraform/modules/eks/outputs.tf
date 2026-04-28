output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "VPC ID passed into this module"
  value       = var.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs passed into this module"
  value       = var.private_subnets   # ✅ pass-through the variable, don't create subnets here
}