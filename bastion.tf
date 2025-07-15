# IAM 역할 및 정책 추가
resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# EKS 관리자 정책 연결
resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# 추가 EKS 정책 연결
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_list_nodegroups" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "eks_admin_profile" {
  name = "eks-admin-instance-profile"
  role = aws_iam_role.eks_admin_role.name
}

# EKS 클러스터에 대한 제어
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS 노드 그룹 제어
resource "aws_iam_role_policy_attachment" "eks_nodegroup_policy" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# EKS VPC 리소스 관리 (로드 밸런서 등 포함)
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}


# 현재 리전 정보 가져오기
data "aws_region" "current" {}

# VSCode 서버 비밀번호 생성
resource "random_password" "vscode_password" {
  length  = 16
  special = true
}

resource "tls_private_key" "jskwon_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# 로컬에 키 파일 저장
resource "local_file" "private_key" {
  content  = tls_private_key.jskwon_key.private_key_pem
  filename = "${path.module}/jskwon-test-key"
  file_permission = "0600"
}

# AWS 키 페어 등록
resource "aws_key_pair" "jskwon" {
  key_name   = "jskwon-test-key"
  public_key = tls_private_key.jskwon_key.public_key_openssh
}

# EC2 인스턴스 생성
resource "aws_instance" "jskwon_bastion_ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = aws_key_pair.jskwon.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jskwon_bastion_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.eks_admin_profile.name

  tags = {
    Name = "jskwon-bastion-ec2"
  }

  # SSH 연결 설정
  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = tls_private_key.jskwon_key.private_key_pem
  }
  
  # 시스템 초기 설정
  

  # code-server 서비스 시작 (이전 단계가 완료된 후 실행)
  provisioner "remote-exec" {
    inline = [
      # code-server 서비스 시작 및 활성화
      "sudo systemctl daemon-reload",
      "sudo systemctl enable code-server",
      "sudo systemctl start code-server",
      "echo 'Code-server is running on port 8080'"
    ]
  }
  
  # 의존성 설정
  depends_on = [
    aws_key_pair.jskwon,
    module.vpc
  ]
}

# EIP 할당
resource "aws_eip" "jskwon_bastion_ec2_eip" {
  instance = aws_instance.jskwon_bastion_ec2.id
  
  tags = {
    Name = "jskwon-bastion-ec2-eip"
  }
  
  depends_on = [aws_instance.jskwon_bastion_ec2]
}