output "vscode_server_url" {
  value       = "http://${aws_instance.jskwon_test_server.public_ip}:8080"
  description = "VSCode Server 접속 URL"
}

output "vscode_password" {
  value       = random_password.vscode_password.result
  sensitive   = true
  description = "VSCode Server 접속 비밀번호"
}

output "ssh_connection" {
  value       = "ssh -i jskwon-test-key ec2-user@${aws_instance.jskwon_test_server.public_ip}"
  description = "SSH 연결 명령어"
}

output "docker_status_command" {
  value       = "ssh -i jskwon-test-key ec2-user@${aws_instance.jskwon_test_server.public_ip} 'docker ps'"
  description = "Docker 컨테이너 상태 확인 명령어"
}

output "docker_logs_command" {
  value       = "ssh -i jskwon-test-key ec2-user@${aws_instance.jskwon_test_server.public_ip} 'docker logs code-server'"
  description = "VSCode 서버 로그 확인 명령어"
}
