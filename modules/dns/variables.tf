variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "create_hosted_zone" {
  description = "Whether to create Route53 hosted zone"
  type        = bool
  default     = false
}

variable "manage_dns" {
  description = "Whether to manage DNS records"
  type        = bool
  default     = false
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB zone ID"
  type        = string
}
