# Infrastructure Only Configuration (No DNS Management)
# Use this if you want to manage DNS manually

# Environment
environment = "prod"

# Domain Configuration (for reference only)
domain_name = "looper.my"
create_hosted_zone = false  # Don't create hosted zone
manage_dns = false         # Don't manage DNS records

# Instance Configuration
instance_type = "t3.small"
min_size = 2
max_size = 6
desired_capacity = 2

# Database Configuration
db_instance_class = "db.t3.small"
db_allocated_storage = 20
db_engine_version = "15.7"
db_username = "looper"
db_password = "looperismylooper"  # Change this in production!
db_name = "looperdb"

# Security
allowed_cidr_blocks = ["0.0.0.0/0"]

# Note: After deployment, manually point your domain to the ALB DNS name:
# - Get ALB DNS from terraform output: alb_dns_name
# - Create A record in Google Domains: looper.my -> ALB DNS
# - Create A record in Google Domains: dev.looper.my -> ALB DNS
