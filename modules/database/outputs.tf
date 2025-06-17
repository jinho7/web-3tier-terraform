output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "db_instance_address" {
  description = "RDS instance address"
  value       = aws_db_instance.main.address
}
