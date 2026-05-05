output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "vpc_id" {
  description = "VPC ID used by the cluster"
  value       = var.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs used by the cluster"
  value       = var.private_subnets
}

output "alb_controller_role_arn" {
  description = "ARN of the IRSA role used by the AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}
