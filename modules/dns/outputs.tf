output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.manage_dns || var.create_hosted_zone ? local.zone_id : null
}

output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = var.manage_dns ? aws_acm_certificate.main[0].arn : null
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}
