# Staging Environment Configuration

# Environment
environment = "stage"

# Domain Configuration
domain_name = "dev.looper.my"
create_hosted_zone = false  # Use existing hosted zone
manage_dns = true          # Manage DNS records in Route53

# Instance Configuration
instance_type = "t3.micro"  # Smaller for staging
min_size = 1
max_size = 3
desired_capacity = 1

# Database Configuration
db_instance_class = "db.t3.micro"  # Smaller for staging
db_allocated_storage = 20
db_engine_version = "15.7"
db_username = "looper"
db_password = "looperismylooper"  # Use same for consistency
db_name = "looperdb_stage"

# Security
allowed_cidr_blocks = ["0.0.0.0/0"]
