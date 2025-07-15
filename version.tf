
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.16.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
  required_version = ">= 1.0.0"
}

# AWS Provider (default)
provider "aws" {
  region = "ap-northeast-2"
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = local.project
      Terraform   = "True"
      ManagedBy   = "terraform"
      Owner       = "jskwon"
      # 여기에 추가로 필요한 태그를 자유롭게 추가하세요
    }
  }
}

# AWS Provider for gsitm-test
provider "aws" {
  alias  = "gsitm-test"
  region = "ap-northeast-2"
}

module "iam" {
  source  = "terraform-aws-modules/iam/aws"
  version = "~> 5.0"
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        "ap-northeast-2"
      ]
    }
  }
}