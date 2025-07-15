# IAM 역할 및 정책 추가
resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
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
  
  provisioner "remote-exec" {
    inline = [
      # 시스템 업데이트 및 필수 패키지 설치 (오류 발생 시 계속 실행)
      "set -e",
      "echo 'Updating system packages...'",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get update -y || echo 'apt-get update failed but continuing...'",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::=\"--force-confold\" --allow-downgrades --allow-remove-essential --allow-change-held-packages || echo 'apt-get upgrade failed but continuing...'",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl software-properties-common unzip gnupg2",

      # AWS CLI v2 설치 (기존 버전 제거 후 설치)
      "echo 'Installing AWS CLI v2...'",
      "sudo rm -rf /usr/local/aws-cli",
      "curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip",
      "unzip -q awscliv2.zip",
      "sudo ./aws/install --update",
      "rm -rf awscliv2.zip aws",

      # kubectl 설치 (안정적인 버전 사용)
      "echo 'Installing kubectl...'",
      "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/",
      "mkdir -p /home/ubuntu/.kube",
      "chown ubuntu:ubuntu /home/ubuntu/.kube",

      # kubectl 자동 완성 설정
      "echo 'Configuring kubectl completion...'",
      "echo 'source <(kubectl completion bash)' >> /home/ubuntu/.bashrc",
      "echo 'alias k=kubectl' >> /home/ubuntu/.bashrc",
      "echo 'complete -o default -F __start_kubectl k' >> /home/ubuntu/.bashrc",
      "echo 'export KUBECONFIG=/home/ubuntu/.kube/config' >> /home/ubuntu/.bashrc",

      # code-server 설치 (안정적인 버전 사용)
      "echo 'Installing code-server...'",
      "curl -fsSL https://code-server.dev/install.sh | sh -s -- --version 4.16.1",

      # code-server 설정
      "echo 'Configuring code-server...'",
      "mkdir -p /home/ubuntu/.config/code-server",
      "chown -R ubuntu:ubuntu /home/ubuntu/.config",
      "cat <<'EOF' | sed 's/^  //' > /home/ubuntu/.config/code-server/config.yaml\n  bind-addr: 0.0.0.0:8080\n  auth: password\n  password: ${random_password.vscode_password.result}\n  cert: false\nEOF",

      # code-server 서비스 설정
      "echo 'Setting up code-server service...'",
      "sudo mkdir -p /etc/systemd/system",
      "cat <<EOF | sudo tee /etc/systemd/system/code-server.service > /dev/null\n[Unit]\nDescription=code-server\nAfter=network.target\n\n[Service]\nType=simple\nUser=ubuntu\nWorkingDirectory=/home/ubuntu\nEnvironment=PATH=/usr/bin:/usr/local/bin\nExecStart=/usr/bin/code-server --config /home/ubuntu/.config/code-server/config.yaml /home/ubuntu\nRestart=always\nRestartSec=5\n\n[Install]\nWantedBy=multi-user.target\nEOF",

      # 서비스 시작
      "echo 'Starting services...'",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable code-server",
      "sudo systemctl restart code-server",
      "echo 'Installation completed successfully! Code-server is running on port 8080'"
    ]
    
    # 연결 재시도 및 타임아웃 설정
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.jskwon_key.private_key_pem
      host        = self.public_ip
    }
    
    # 실패 시 재시도
    on_failure = continue
  }
  timeouts {
    create = "5m"
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