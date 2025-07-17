# 🛠️ Terraform 기반 AWS EKS 실습 프로젝트

> 클라우드 인프라의 자동화를 위한 IaC 도입과 Terraform 활용 실습

---

## 📌 배경 및 목적

클라우드 환경에서의 인프라 운영은 점점 더 복잡해지고 있습니다.
수동 설정은 반복성과 신뢰성이 떨어지고, 변경 이력 관리가 어렵다는 문제가 있습니다.
이에 따라 **Infrastructure as Code(IaC)** 도입이 필요하며, 본 프로젝트는 다음과 같은 목적을 가지고 있습니다:

- **Terraform을 통한 IaC 구성 및 이해**
- **AWS EKS 클러스터의 실습 환경 구성**
- **운영 환경 적용을 고려한 인프라 설계 연습**

---

## 🎯 실습 목표

- Terraform 구조 및 명령어 이해
- Git으로 IaC 코드 버전 관리 및 협업
- AWS 리소스(VPC, EC2, IAM, EKS 등) 코드 기반 생성
- EKS 클러스터에 Karpenter, Ingress, External-DNS 구성
- 실시간 모니터링 및 오토스케일링 테스트

---

## 🧰 사용 기술

| 항목       | 내용                         |
|------------|------------------------------|
| IaC 도구    | Terraform                    |
| 클라우드    | AWS                          |
| 컨테이너    | Kubernetes (EKS)             |
| Auto Scaling | Karpenter                     |
| DNS 자동화 | ExternalDNS + Route53        |
| 모니터링    | Metrics Server, kubectl watch |

---

