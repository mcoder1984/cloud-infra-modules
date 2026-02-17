# ------------------------------------------------------------------------------
# ECS Cluster Module Outputs
# ------------------------------------------------------------------------------

output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = aws_lb.this.zone_id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "service_security_group_ids" {
  description = "Map of service name to security group ID"
  value       = { for k, v in aws_security_group.ecs_service : k => v.id }
}

output "service_names" {
  description = "Map of service names"
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_execution.arn
}

output "task_role_arns" {
  description = "Map of service name to task role ARN"
  value       = { for k, v in aws_iam_role.ecs_task : k => v.arn }
}

output "service_discovery_namespace_id" {
  description = "Service discovery namespace ID"
  value       = var.enable_service_discovery ? aws_service_discovery_private_dns_namespace.this[0].id : null
}

output "log_group_names" {
  description = "Map of service name to CloudWatch log group name"
  value       = { for k, v in aws_cloudwatch_log_group.service : k => v.name }
}
