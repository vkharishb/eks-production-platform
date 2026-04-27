variable "name" {   
    description = "The name of the VPC"
    type        = string
    default     = "eks-vpc"
}

variable "cidr" {
    description = "The CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "azs" {
    description = "A list of availability zones"
    type        = list(string)
    default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "private_subnets" {
    description = "A list of private subnets"
    type        = list(string)
    default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "public_subnets" {
    description = "A list of public subnets"
    type        = list(string)
    default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "enable_nat_gateway" {
    description = "Whether to enable the NAT gateway"
    type        = bool
    default     = true
}

variable "single_nat_gateway" {
    description = "Whether to use a single NAT gateway"
    type        = bool
    default     = false
}

variable "tags" {
    description = "A map of tags to apply to the VPC"
    type        = map(string)
}