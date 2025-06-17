#!/bin/bash

# Complete setup script for application server
set -e

# Log everything
exec > >(tee /var/log/startup-script.log) 2>&1
echo "Starting application server setup at $(date)"

# Update system
echo "Updating system packages..."
yum update -y

# Install essential packages
echo "Installing essential packages..."
yum install -y curl wget git vim htop unzip jq tree net-tools

# Install Docker
echo "Installing Docker..."
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install SSM Agent (should be pre-installed on Amazon Linux 2)
echo "Ensuring SSM Agent is running..."
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Install CloudWatch agent
echo "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Install Nginx
echo "Installing Nginx..."
amazon-linux-extras install nginx1 -y

# Create application directories
echo "Creating application directories..."
mkdir -p /opt/looper/{data,logs,scripts,keys}
chmod 700 /opt/looper/keys

# Create nginx configuration
echo "Creating Nginx configuration..."
cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    server {
        listen 80;
        server_name _;
        
        location /health {
            return 200 'OK';
            add_header Content-Type text/plain;
        }

        location /api/ {
            proxy_pass http://127.0.0.1:8080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Prefix /api;
            proxy_cache_bypass $http_upgrade;
        }

        location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
EOF

# Enable nginx
systemctl start nginx
systemctl enable nginx

# Create environment file
echo "Creating environment file..."
cat > /opt/looper/.env << EOF
# Production Environment Variables
ENVIRONMENT=${environment}

# Database Configuration
POSTGRES_USER=${db_username}
POSTGRES_PASSWORD=${db_password}
POSTGRES_DB=${db_name}
SPRING_DATASOURCE_URL=jdbc:postgresql://${db_host}:5432/${db_name}

# Database Server IP
DB_INSTANCE_IP=${db_host}

# Frontend URLs  
NEXT_PUBLIC_API_URL=https://${domain_name}/api
NEXT_PUBLIC_AI_URL=http://ai-service:8000

# AWS Configuration
AWS_REGION=ap-northeast-2
AWS_DEFAULT_REGION=ap-northeast-2
EOF

# Create deployment scripts
echo "Creating deployment scripts..."
cat > /opt/looper/scripts/deploy.sh << 'EOF'
#!/bin/bash
set -e

cd /opt/looper

# Pull and start services
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# Clean up old images
docker image prune -f

echo "Deployment completed!"
EOF

cat > /opt/looper/scripts/status.sh << 'EOF'
#!/bin/bash
cd /opt/looper
echo "=== Docker Services ==="
if [ -f docker-compose.prod.yml ]; then
    docker-compose -f docker-compose.prod.yml ps
else
    echo "docker-compose.prod.yml not found"
fi
echo ""
echo "=== System Resources ==="
echo "Memory:"
free -h
echo "Disk:"
df -h /opt
echo ""
echo "=== Network ==="
netstat -tlnp | grep -E "(80|8080|3000)"
EOF

cat > /opt/looper/scripts/logs.sh << 'EOF'
#!/bin/bash
cd /opt/looper
if [ -z "$1" ]; then
    docker-compose -f docker-compose.prod.yml logs --tail=50 -f
else
    docker-compose -f docker-compose.prod.yml logs --tail=50 -f $1
fi
EOF

chmod +x /opt/looper/scripts/*.sh

# Create network
docker network create looper-network || true

# Add useful aliases to bashrc
cat >> /home/ec2-user/.bashrc << 'EOF'

# Looper aliases
alias looper-deploy='/opt/looper/scripts/deploy.sh'
alias looper-status='/opt/looper/scripts/status.sh'
alias looper-logs='/opt/looper/scripts/logs.sh'
alias looper-restart='cd /opt/looper && docker-compose -f docker-compose.prod.yml restart'
alias looper-stop='cd /opt/looper && docker-compose -f docker-compose.prod.yml stop'
alias looper-start='cd /opt/looper && docker-compose -f docker-compose.prod.yml start'
EOF

# Set ownership
chown -R ec2-user:ec2-user /opt/looper

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "AWS/EC2/Looper",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/looper/${environment}/nginx/access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/looper/${environment}/nginx/error",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/startup-script.log",
                        "log_group_name": "/aws/ec2/looper/${environment}/startup",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "Application server setup completed at $(date)!"
echo "Instance is ready for deployment!"
