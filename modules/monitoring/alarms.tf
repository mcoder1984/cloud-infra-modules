# ------------------------------------------------------------------------------
# CloudWatch Alarms - CPU, Memory, Disk, Error Rate
# ------------------------------------------------------------------------------

# ECS CPU Alarms
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each = var.ecs_services

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-cpu-high"
  alarm_description   = "ECS service ${each.key} CPU utilization above ${var.cpu_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_actions       = [aws_sns_topic.alerts["warning"].arn]
  ok_actions          = [aws_sns_topic.alerts["warning"].arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.key
  }

  tags = merge(var.tags, { Service = each.key })
}

# ECS Memory Alarms
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  for_each = var.ecs_services

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-memory-high"
  alarm_description   = "ECS service ${each.key} memory utilization above ${var.memory_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_actions       = [aws_sns_topic.alerts["warning"].arn]
  ok_actions          = [aws_sns_topic.alerts["warning"].arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.key
  }

  tags = merge(var.tags, { Service = each.key })
}

# RDS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  for_each = var.rds_instances

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-rds-cpu-high"
  alarm_description   = "RDS instance ${each.key} CPU above ${var.rds_cpu_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  alarm_actions       = [aws_sns_topic.alerts["critical"].arn]
  ok_actions          = [aws_sns_topic.alerts["critical"].arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value.instance_id
  }

  tags = var.tags
}

# RDS Free Storage Alarm
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  for_each = var.rds_instances

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-rds-storage-low"
  alarm_description   = "RDS instance ${each.key} free storage below ${var.rds_storage_threshold_gb}GB"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_storage_threshold_gb * 1073741824
  alarm_actions       = [aws_sns_topic.alerts["critical"].arn]
  ok_actions          = [aws_sns_topic.alerts["critical"].arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value.instance_id
  }

  tags = var.tags
}

# RDS Connection Count Alarm
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  for_each = var.rds_instances

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-rds-connections-high"
  alarm_description   = "RDS instance ${each.key} connections above ${var.rds_connection_threshold}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_connection_threshold
  alarm_actions       = [aws_sns_topic.alerts["warning"].arn]
  ok_actions          = [aws_sns_topic.alerts["warning"].arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = each.value.instance_id
  }

  tags = var.tags
}

# ALB 5xx Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  for_each = var.alb_arns

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-alb-5xx"
  alarm_description   = "ALB ${each.key} 5xx error count above ${var.error_rate_threshold}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_actions       = [aws_sns_topic.alerts["critical"].arn]
  ok_actions          = [aws_sns_topic.alerts["critical"].arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = each.value.arn_suffix
  }

  tags = var.tags
}

# ALB Target Response Time Alarm
resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  for_each = var.alb_arns

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}-alb-latency"
  alarm_description   = "ALB ${each.key} p99 latency above ${var.latency_threshold}s"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  extended_statistic  = "p99"
  threshold           = var.latency_threshold
  alarm_actions       = [aws_sns_topic.alerts["warning"].arn]
  ok_actions          = [aws_sns_topic.alerts["warning"].arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = each.value.arn_suffix
  }

  tags = var.tags
}
