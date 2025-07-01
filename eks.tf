# EKS 클러스터 모듈 수정
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.project
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Fargate 프로필 생성
  fargate_profiles = {
    kube_system = {
      name = "kube-system"
      selectors = [{
        namespace = "kube-system"
      }]
    }
  }

  # Node Groups
  node_security_group_additional_rules = {
    # 노드 간 통신 허용
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    # Bastion 호스트에서의 SSH 접속 허용 (22 포트)
    ingress_from_bastion = {
      description              = "Allow SSH access from bastion host"
      protocol                = "tcp"
      from_port               = 22
      to_port                 = 22
      type                    = "ingress"
      source_security_group_id = aws_security_group.jskwon_bastion_sg.id
    },
    # Bastion 호스트에서의 kubelet API 접근 허용 (10250 포트)
    ingress_kubelet_from_bastion = {
      description              = "Allow kubelet API access from bastion host"
      protocol                = "tcp"
      from_port               = 10250
      to_port                 = 10250
      type                    = "ingress"
      source_security_group_id = aws_security_group.jskwon_bastion_sg.id
    }
    ingress_bastion_https = {
    description              = "Allow EKS API access from bastion"
    protocol                = "tcp"
    from_port               = 443
    to_port                 = 443
    type                    = "ingress"
    source_security_group_id = aws_security_group.jskwon_bastion_sg.id
  }
  }

  # EKS 관리형 노드 그룹
  eks_managed_node_groups = {
    eks-node-group = {
      name            = "jskwon-eks-node"
      instance_types  = ["t3.medium"]
      min_size        = 1
      max_size        = 3
      desired_size    = 2
      capacity_type   = "ON_DEMAND"
      disk_size       = 10

      # 노드 레이블
      labels = {
        role = "general"
      }

      # 태그
      tags = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
        "k8s.io/cluster-autoscaler/${local.project}" = "owned"
      }
    }
  }

  # IAM 역할 및 정책
  node_security_group_tags = {}

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}

# CoreDNS 애드온
resource "aws_eks_addon" "coredns" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "coredns"
  addon_version               = data.aws_eks_addon_version.coredns.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values = jsonencode({
    computeType = "Fargate"  # 명시적으로 Fargate 지정
  })
}

# AWS Load Balancer Controller IAM Role
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.project}-aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true
  
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# AWS Load Balancer Controller Helm Release
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.aws_load_balancer_controller_chart_version
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa.iam_role_arn
  }

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    module.eks,
    module.aws_load_balancer_controller_irsa
  ]
}