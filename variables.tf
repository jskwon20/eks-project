variable "vpc_cidr" {
  description = "VPC 대역대"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
}

variable "aws_load_balancer_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm 차트 버전"
  type        = string
}

variable "external_dns_chart_version" {
  description = "Kubernetes ExternalDNS Helm 차트 버전"
  type        = string
}

variable "ingress_nginx_chart_version" {
  description = "Ingess-nginx Controller Helm 차트 버전 "
  type        = string
}

variable "bastion_cidr" {
  description = "Bastion host CIDR"
  type        = string
}

variable "karpenter_chart_version" {
  description = "Karpenter Helm 차트 버전"
  type        = string
}