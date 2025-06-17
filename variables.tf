# General Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "Environment (prod or stage)"
  type        = string
  
  validation {
    condition     = contains(["prod", "stage"], var.environment)
    error_message = "Environment must be either 'prod' or 'stage'."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "looper"
}

# Network Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# Domain Variables
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
  description = "Whether to manage DNS records (requires Route53 hosted zone)"
  type        = bool
  default     = false
}

variable "existing_hosted_zone_id" {
  description = "Existing Route53 hosted zone ID (if not creating new one)"
  type        = string
  default     = ""
}

# EC2 Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

# Database Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.7"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "looper"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "looperismylooper"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "looperdb"
}

# Security Variables
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
