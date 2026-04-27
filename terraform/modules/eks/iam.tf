resource "aws_iam_role" "eks_nodes" {
  name = "${var.name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

variable "name" {
    description = "The name of the IAM role"
    type        = string
    default     = "eks"
}