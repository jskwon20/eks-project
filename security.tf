# EKS 노드 보안 그룹
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = module.vpc.vpc_id

  # 임시로 모든 인바운드 트래픽 허용 (테스트용)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "TEMP: Allow all inbound traffic (for testing)"
  }

  # 아웃바운드 트래픽 허용 (모두 허용)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-nodes-sg"
  }
}

# EKS 노드 간 통신 허용
resource "aws_security_group_rule" "eks_nodes_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_nodes_sg.id
  description       = "Allow all traffic between nodes"
}

# Bastion에서 SSH 접속 허용
resource "aws_security_group_rule" "eks_nodes_ingress_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.jskwon_bastion_sg.id
  description              = "Allow SSH access from bastion"
}


resource "aws_security_group_rule" "eks_nodes_ingress_control_plane_https_webhook" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = module.eks.cluster_security_group_id
  description              = "Allow EKS access from nodes"
}

resource "aws_security_group_rule" "eks_nodes_ingress_metrics" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = module.eks.cluster_security_group_id
  description              = "Allow EKS access from nodes"
}


resource "aws_security_group_rule" "eks_nodes_ingress_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.jskwon_bastion_sg.id
  description              = "Allow EKS access from bastion"
}

# 노드 포트 서비스 접근 허용 (30000-32767)
resource "aws_security_group_rule" "eks_nodes_ingress_nodeport" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.jskwon_bastion_sg.id
  description              = "Allow NodePort access from bastion"
}

# EKS 클러스터 보안 그룹에 모든 인바운드 트래픽 허용 (임시 테스트용)
resource "aws_security_group_rule" "eks_cluster_ingress_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.cluster_security_group_id
  description       = "TEMP: Allow all inbound traffic (for testing)"
}

# EKS 클러스터 보안 그룹에 EKS 컨트롤 플레인에서의 인바운드 트래픽 허용
resource "aws_security_group_rule" "eks_cluster_ingress_nodes_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Allow nodes to communicate with control plane (HTTPS)"
}

# kubelet API 접근 허용 (노드에서 실행 중인 파드와의 통신)
resource "aws_security_group_rule" "eks_cluster_ingress_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Allow kubelet communication from nodes"
}

# etcd 클라이언트 포트 (컨트롤 플레인 내부 통신)
resource "aws_security_group_rule" "eks_cluster_ingress_etcd" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.eks.cluster_security_group_id
  description              = "Allow etcd client/server communication between control plane nodes"
}

# EKS 클러스터에서 모든 아웃바운드 트래픽 허용




# CoreDNS를 위한 DNS 포트
resource "aws_security_group_rule" "eks_nodes_ingress_dns_tcp" {
  type                     = "ingress"
  from_port                = 53
  to_port                  = 53
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = module.eks.cluster_security_group_id
  description              = "Allow DNS (TCP) from control plane"
}

resource "aws_security_group_rule" "eks_nodes_ingress_dns_udp" {
  type                     = "ingress"
  from_port                = 53
  to_port                  = 53
  protocol                 = "udp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = module.eks.cluster_security_group_id
  description              = "Allow DNS (UDP) from control plane"
}

# Bastion 호스트 보안 그룹
resource "aws_security_group" "jskwon_bastion_sg" {
  name        = "jskwon-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id

  # SSH 접속 허용
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_cidr]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.bastion_cidr]
  }
  # VSCode 웹 접속 허용
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.bastion_cidr]
  }
  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "jskwon-bastion-sg"
  }
}

resource "aws_security_group_rule" "cluster_ingress_self" {
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  self                     = true
  security_group_id        = module.eks.cluster_security_group_id
  description              = "Allow all traffic within the cluster security group"
}