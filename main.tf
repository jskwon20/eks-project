# 키 파일 로컬 생성 (jskwon-test-key 및 jskwon-test-key.pub)
# 키 페어 생성
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
resource "aws_instance" "jskwon_test_server" {
  ami                         = data.aws_ami.aml2.id
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = aws_key_pair.jskwon.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jskwon_test_server.id]

  tags = {
    Name = "jskwon-test-server"
  }


  # SSH 연결 설정
  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = self.public_ip
    private_key = tls_private_key.jskwon_key.private_key_pem
  }
  
  # 원격 명령 실행
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y nginx1",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
  }

  
  # 의존성 설정
  depends_on = [
    aws_key_pair.jskwon,
    module.vpc
  ]
}

# EIP 할당
resource "aws_eip" "jskwon_test_server_eip" {
  instance = aws_instance.jskwon_test_server.id
  
  tags = {
    Name = "jskwon-test-server-eip"
  }
  
  depends_on = [aws_instance.jskwon_test_server]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "jskwon-test-vpc"
  cidr = "10.1.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.10.0/24", "10.1.20.0/24", "10.1.30.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

