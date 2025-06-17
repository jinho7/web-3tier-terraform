# Data sources
data "aws_route53_zone" "existing" {
  count = var.create_hosted_zone ? 0 : (var.manage_dns ? 1 : 0)
  name  = "looper.my"
}

locals {
  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : (
    var.manage_dns ? data.aws_route53_zone.existing[0].zone_id : ""
  )
}

#######################
# Route53 DNS
#######################

# Create hosted zone only for prod
resource "aws_route53_zone" "main" {
  count = var.create_hosted_zone ? 1 : 0
  name  = "looper.my"

  tags = {
    Name = "${var.project_name}-hosted-zone"
  }
}

#######################
# SSL Certificate
#######################

resource "aws_acm_certificate" "main" {
  count = var.manage_dns ? 1 : 0
  
  domain_name       = var.domain_name
  subject_alternative_names = [
    "www.${var.domain_name}"
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-certificate"
  }
}

# DNS validation for ACM certificate
resource "aws_route53_record" "cert_validation" {
  for_each = var.manage_dns ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  count = var.manage_dns ? 1 : 0
  
  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Main domain A record
resource "aws_route53_record" "main" {
  count = var.manage_dns ? 1 : 0
  
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# www subdomain A record
resource "aws_route53_record" "www" {
  count = var.manage_dns ? 1 : 0
  
  zone_id = local.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Migrate existing Google Domains records
# MX Records for email (improvmx)
resource "aws_route53_record" "mx" {
  count = var.manage_dns && var.create_hosted_zone ? 1 : 0
  
  zone_id = local.zone_id
  name    = "looper.my"
  type    = "MX"
  ttl     = 300
  records = [
    "10 mx1.improvmx.com",
    "20 mx2.improvmx.com"
  ]
}

# SPF Record
resource "aws_route53_record" "spf" {
  count = var.manage_dns && var.create_hosted_zone ? 1 : 0
  
  zone_id = local.zone_id
  name    = "looper.my"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:spf.improvmx.com ~all"]
}
