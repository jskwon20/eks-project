output "vscode_server_url" {
  value       = "http://${aws_instance.jskwon_bastion_ec2.public_ip}:8080"
  description = "VSCode Server 접속 URL"
}

output "vscode_password" {
  value       = random_password.vscode_password.result
  sensitive   = true
  description = "VSCode Server 접속 비밀번호"
}

output "ssh_connection" {
  value       = "ssh -i jskwon-test-key ubuntu@${aws_instance.jskwon_bastion_ec2.public_ip}"
  description = "SSH 연결 명령어"
}

output "docker_status_command" {
  value       = "ssh -i jskwon-test-key ubuntu@${aws_instance.jskwon_bastion_ec2.public_ip} 'docker ps'"
  description = "Docker 컨테이너 상태 확인 명령어"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS 클러스터 이름"
}

output "aws_region" {
  value       = data.aws_region.current.name
  description = "AWS 리전"
}

output "eks_cluster_role_arn" {
  value       = module.eks.cluster_iam_role_arn
  description = "EKS 클러스터 IAM 역할 ARN"
}

output "docker_logs_command" {
  value       = "ssh -i jskwon-test-key ubuntu@${aws_instance.jskwon_bastion_ec2.public_ip} 'docker logs code-server'"
  description = "VSCode 서버 로그 확인 명령어"
}

output "hosted_zone_name_servers" {
  value = data.aws_route53_zone.this.name_servers
}

output "update_kubeconfig" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${data.aws_region.current.name}"
}