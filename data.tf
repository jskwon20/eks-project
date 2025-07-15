data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical (Ubuntu 공식)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_availability_zones" "azs" {
  state = "available"
}
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# EKS Addon Version Data Sources
data "aws_eks_addon_version" "aws_ebs_csi_driver" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.eks_cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = var.eks_cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = var.eks_cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = var.eks_cluster_version
  most_recent        = true
}
