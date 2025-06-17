#######################
# Network Module
#######################

module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
}

#######################
# Security Module
#######################

module "security" {
  source = "./modules/security"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id              = module.network.vpc_id
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

#######################
# Database Module
#######################

module "database" {
  source = "./modules/database"

  project_name        = var.project_name
  environment         = var.environment
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.rds_security_group_id]
  
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine_version   = var.db_engine_version
  db_username         = var.db_username
  db_password         = var.db_password
  db_name            = var.db_name
}

#######################
# DNS Module
#######################

module "dns" {
  source = "./modules/dns"

  project_name        = var.project_name
  environment         = var.environment
  domain_name         = var.domain_name
  create_hosted_zone  = var.create_hosted_zone
  manage_dns         = var.manage_dns
  alb_dns_name       = module.load_balancer.alb_dns_name
  alb_zone_id        = module.load_balancer.alb_zone_id
}

#######################
# Load Balancer Module
#######################

module "load_balancer" {
  source = "./modules/load_balancer"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  security_group_ids = [module.security.alb_security_group_id]
  certificate_arn    = module.dns.certificate_arn
  waf_web_acl_arn   = module.security.waf_web_acl_arn
  manage_ssl        = var.manage_dns
}

#######################
# Compute Module
#######################

module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  instance_type         = var.instance_type
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  subnet_ids           = module.network.private_subnet_ids
  security_group_ids   = [module.security.web_security_group_id]
  target_group_arns    = [module.load_balancer.target_group_arn]
  instance_profile_name = module.security.ec2_instance_profile_name
  
  db_host     = module.database.db_instance_address
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  domain_name = var.domain_name
}
