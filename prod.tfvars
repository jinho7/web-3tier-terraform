# Production Environment Configuration

# Environment
environment = "prod"

# Domain Configuration
domain_name = "looper.my"
create_hosted_zone = true  # Create hosted zone for production
manage_dns = true         # Manage DNS records in Route53

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
allowed_cidr_blocks = ["0.0.0.0/0"]  # Restrict this in production if needed
