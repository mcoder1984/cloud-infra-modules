# ------------------------------------------------------------------------------
# Monitoring Module Outputs
# ------------------------------------------------------------------------------

output "sns_topic_arns" {
  description = "Map of SNS topic ARNs by channel"
  value       = { for k, v in aws_sns_topic.alerts : k => v.arn }
}

output "sns_topic_arn" {
  description = "Critical SNS topic ARN (convenience output)"
  value       = contains(var.alert_channels, "critical") ? aws_sns_topic.alerts["critical"].arn : null
}

output "dashboard_names" {
  description = "CloudWatch dashboard names"
  value = {
    overview       = aws_cloudwatch_dashboard.main.dashboard_name
    infrastructure = aws_cloudwatch_dashboard.infrastructure.dashboard_name
  }
}

output "ecs_cpu_alarm_arns" {
  description = "ECS CPU alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.ecs_cpu_high : k => v.arn }
}

output "rds_cpu_alarm_arns" {
  description = "RDS CPU alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.rds_cpu_high : k => v.arn }
}

output "alb_5xx_alarm_arns" {
  description = "ALB 5xx alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.alb_5xx : k => v.arn }
}

output "grafana_security_group_id" {
  description = "Grafana security group ID"
  value       = var.enable_grafana ? aws_security_group.grafana[0].id : null
}
