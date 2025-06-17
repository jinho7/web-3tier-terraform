#######################
# RDS Database
#######################

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp2"
  storage_encrypted     = true

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  multi_az               = var.environment == "prod" ? true : false
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false  # 개발/테스트용으로 비활성화

  performance_insights_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-database"
  }
}
