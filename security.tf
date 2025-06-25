resource "aws_security_group" "jskwon_test_server" {
  name        = "jskwon-test-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = module.vpc.vpc_id

  # SSH 접근 허용
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["61.34.245.211/32"]
    description = "Allow SSH access"
  }

  # VSCode 서버 접속 허용 (8080 포트)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["61.34.245.211/32"]
    description = "VSCode Server Access"
  }

  # Docker API 접속 허용 (2375 포트)
  ingress {
    from_port   = 2375
    to_port     = 2375
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Docker API Access"
  }

  # 모든 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "jskwon-test-sg"
  }
}

# 이전 보안 그룹 규칙 제거를 위한 리소스
resource "null_resource" "cleanup_security_group_rules" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Cleaning up old security group rules..."
    EOT
  }
  
  triggers = {
    always_run = timestamp()
  }
  
  depends_on = [aws_security_group.jskwon_test_server]
}
