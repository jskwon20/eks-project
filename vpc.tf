module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.project
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.azs.names
  public_subnets  = [for idx, _ in data.aws_availability_zones.azs.names : cidrsubnet(var.vpc_cidr, 8, idx)]
  private_subnets = [for idx, _ in data.aws_availability_zones.azs.names : cidrsubnet(var.vpc_cidr, 8, idx + 10)]

  enable_nat_gateway        = true
  single_nat_gateway        = true
  create_igw                = true
  enable_dns_hostnames      = true
  enable_dns_support        = true
  map_public_ip_on_launch   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"           = local.project
  }
}

data "aws_route53_zone" "this" {
  name         = "gsitm-test.com"
  private_zone = false
}

# ACM 인증서 발급 요청
resource "aws_acm_certificate" "this" {
  domain_name       = "*.gsitm-test.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ACM에서 요구하는 DNS 검증용 레코드 등록
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]

  allow_overwrite = true
}

# 인증서 최종 검증 완료 처리
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}