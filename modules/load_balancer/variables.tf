variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ALB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
  default     = ""
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  type        = string
}

variable "manage_ssl" {
  description = "Whether to manage SSL/HTTPS"
  type        = bool
  default     = false
}
