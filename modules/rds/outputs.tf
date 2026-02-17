# ------------------------------------------------------------------------------
# RDS Module Outputs
# ------------------------------------------------------------------------------

output "instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.this.id
}

output "instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}

output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Name of the default database"
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master username"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "master_password_secret_arn" {
  description = "Secrets Manager ARN for the master password"
  value       = var.manage_master_user_password ? aws_db_instance.this.master_user_secret[0].secret_arn : (length(aws_secretsmanager_secret.master_password) > 0 ? aws_secretsmanager_secret.master_password[0].arn : null)
}

output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.this.id
}

output "replica_endpoint" {
  description = "Read replica endpoint"
  value       = var.create_read_replica ? aws_db_instance.replica[0].endpoint : null
}

output "replica_address" {
  description = "Read replica hostname"
  value       = var.create_read_replica ? aws_db_instance.replica[0].address : null
}

output "parameter_group_name" {
  description = "Parameter group name"
  value       = aws_db_parameter_group.this.name
}
