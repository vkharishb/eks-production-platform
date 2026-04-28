module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>20.8.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets 


  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      desired_size = var.desired_size
      min_size     = var.min_size
      max_size     = var.max_size
      capacity_type   = "SPOT" 
      instance_types = var.instance_types
    }
  }

  tags = var.tags
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-eks-sg"
  description = "EKS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = var.cluster_name
  addon_name   = "vpc-cni"
  depends_on = [ module.eks ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = var.cluster_name
  addon_name   = "coredns"
  depends_on = [ module.eks ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = var.cluster_name
  addon_name   = "kube-proxy"
  depends_on = [ module.eks ]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  depends_on = [ module.eks ]
}
# IAM Role for EBS CSI Driver (IRSA)
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}