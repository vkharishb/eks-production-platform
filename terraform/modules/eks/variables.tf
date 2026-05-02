variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "vpc_id" {
  description = "The VPC ID for the EKS cluster"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "capacity_type" {
  description = "Capacity type for node group: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"   # was "SPOT" — silently enables node interruptions for envs that don't override
}

variable "instance_types" {
  description = "List of instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3   # was 2 — lower than what dev explicitly configured (3); inconsistent
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]   # override with your office/VPN CIDR in each env
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
