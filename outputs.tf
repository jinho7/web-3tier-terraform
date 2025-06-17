# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.network.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateways"
  value       = module.network.nat_gateway_ips
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.load_balancer.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.load_balancer.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = module.load_balancer.alb_arn
}

# Database Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_instance_endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.database.db_instance_port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.database.db_instance_name
}

# DNS Outputs
output "domain_name" {
  description = "Domain name"
  value       = module.dns.domain_name
}

output "certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = module.dns.certificate_arn
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.dns.hosted_zone_id
}

# Security Outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.security.web_security_group_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_security_group_id
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.security.waf_web_acl_arn
}

# Compute Outputs
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.compute.autoscaling_group_arn
}

# Useful connection information
output "connection_info" {
  description = "Connection information for the infrastructure"
  value = {
    domain_url     = var.manage_dns ? "https://${var.domain_name}" : "http://${module.load_balancer.alb_dns_name}"
    www_url       = var.manage_dns ? "https://www.${var.domain_name}" : "http://${module.load_balancer.alb_dns_name}"
    alb_dns       = module.load_balancer.alb_dns_name
    environment   = var.environment
    region        = var.aws_region
    ssl_enabled   = var.manage_dns
  }
}

# Database connection info (sensitive)
output "database_connection_info" {
  description = "Database connection information"
  sensitive   = true
  value = {
    endpoint = module.database.db_instance_endpoint
    port     = module.database.db_instance_port
    database = module.database.db_instance_name
    username = var.db_username
  }
}

# Session Manager connection command
output "ssm_connection_command" {
  description = "AWS CLI command to connect to instances via Session Manager"
  value       = "aws ssm start-session --target <instance-id> --region ${var.aws_region}"
}
