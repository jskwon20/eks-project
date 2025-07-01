# 로컬 환경변수 지정
locals {
  project = "jskwon-eks-project"
}

# 태그
locals {
  tags = {
    Project = local.project
  }
}
