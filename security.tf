# EKS 노드 보안 그룹
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = module.vpc.vpc_id

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

# EKS 클러스터 보안 그룹에 EKS 컨트롤 플레인에서의 인바운드 트래픽 허용
resource "aws_security_group_rule" "eks_cluster_ingress_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Allow unmanaged nodes to communicate with control plane"
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
