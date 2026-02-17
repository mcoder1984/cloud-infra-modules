# ------------------------------------------------------------------------------
# ElastiCache Module - Redis cluster with replication group
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# ------------------------------------------------------------------------------
# ElastiCache Subnet Group
# ------------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.cluster_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-subnet-group"
  })
}

# ------------------------------------------------------------------------------
# ElastiCache Replication Group (Redis)
# ------------------------------------------------------------------------------

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.cluster_name
  description          = "Redis replication group for ${var.cluster_name}"

  # Engine
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = var.port
  parameter_group_name = aws_elasticache_parameter_group.this.name

  # Cluster Configuration
  num_cache_clusters         = var.num_cache_clusters
  automatic_failover_enabled = var.num_cache_clusters > 1 ? true : false
  multi_az_enabled           = var.num_cache_clusters > 1 ? var.multi_az_enabled : false

  # Networking
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = var.transit_encryption_enabled
  kms_key_id                 = var.kms_key_id
  auth_token                 = var.transit_encryption_enabled ? var.auth_token : null

  # Maintenance
  maintenance_window       = var.maintenance_window
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately        = var.environment != "prod"

  # Notifications
  notification_topic_arn = var.notification_topic_arn

  tags = merge(var.tags, {
    Name        = var.cluster_name
    Environment = var.environment
  })

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }
}

# ------------------------------------------------------------------------------
# CloudWatch Alarms
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.cluster_name}-redis-cpu-high"
  alarm_description   = "Redis CPU utilization is above ${var.cpu_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.this.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  alarm_name          = "${var.cluster_name}-redis-memory-high"
  alarm_description   = "Redis memory usage is above ${var.memory_alarm_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.this.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "evictions" {
  alarm_name          = "${var.cluster_name}-redis-evictions"
  alarm_description   = "Redis evictions detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = var.evictions_alarm_threshold
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.this.id
  }

  tags = var.tags
}
