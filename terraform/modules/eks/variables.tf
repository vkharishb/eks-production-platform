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
variable "desired_size" {
    description = "The desired number of worker nodes in the EKS cluster"
    type        = number
    default     = 2
}
variable "min_size" {
    description = "The minimum number of worker nodes in the EKS cluster"
    type        = number
    default     = 1
}
variable "max_size" {
    description = "The maximum number of worker nodes in the EKS cluster"
    type        = number
    default     = 3
}
variable "instance_types" {
    description = "A list of instance types for the worker nodes in the EKS cluster"
    type        = list(string)
    default     = ["t3.medium"]
}
variable "tags" {
    description = "A map of tags to apply to the EKS cluster"
    type        = map(string)
}
variable "private_subnets" {
  type        = list(string)
  description = "Private subnet IDs passed into the module."
}