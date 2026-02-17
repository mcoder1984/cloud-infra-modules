# ------------------------------------------------------------------------------
# ElastiCache Module Outputs
# ------------------------------------------------------------------------------

output "replication_group_id" {
  description = "Replication group ID"
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "Replication group ARN"
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint_address" {
  description = "Primary endpoint address"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Redis port"
  value       = var.port
}

output "security_group_id" {
  description = "Redis security group ID"
  value       = aws_security_group.this.id
}

output "connection_url" {
  description = "Redis connection URL"
  value       = "redis://${aws_elasticache_replication_group.this.primary_endpoint_address}:${var.port}"
}

output "parameter_group_name" {
  description = "Parameter group name"
  value       = aws_elasticache_parameter_group.this.name
}
