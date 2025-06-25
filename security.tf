resource "aws_security_group" "jskwon_test_server" {
  name        = "jskwon-test-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = module.vpc.vpc_id

  # SSH 접근 허용
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access"
  }

  # HTTP 접근 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP access"
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
