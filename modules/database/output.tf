output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.postgresql.id
}

output "security_group_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.main.id
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.postgresql.address
}

output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = aws_db_instance.postgresql.endpoint
}

output "db_subnet_group_id" {
  description = "The ID of the database subnet group"
  value       = aws_db_subnet_group.database.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.postgresql.arn
}

output "db_instance_name" {
  description = "The database name"
  value       = var.database_name
}