# ------------------------------------------------------------------------------
# ElastiCache Parameter Group - Optimized for Redis
# ------------------------------------------------------------------------------

resource "aws_elasticache_parameter_group" "this" {
  name   = "${var.cluster_name}-params"
  family = "redis${regex("^(\\d+\\.\\d+)", var.engine_version)[0]}"
  description = "Optimized parameter group for ${var.cluster_name}"

  # Memory Management
  parameter {
    name  = "maxmemory-policy"
    value = var.maxmemory_policy
  }

  # Persistence
  parameter {
    name  = "appendonly"
    value = var.enable_aof ? "yes" : "no"
  }

  parameter {
    name  = "appendfsync"
    value = var.enable_aof ? "everysec" : "no"
  }

  # Performance
  parameter {
    name  = "tcp-keepalive"
    value = "300"
  }

  parameter {
    name  = "timeout"
    value = "0"
  }

  parameter {
    name  = "latency-tracking"
    value = "yes"
  }

  # Keyspace Notifications (for pub/sub, expiry events)
  parameter {
    name  = "notify-keyspace-events"
    value = var.keyspace_notifications
  }

  # Slow Log
  parameter {
    name  = "slowlog-log-slower-than"
    value = var.slowlog_threshold
  }

  parameter {
    name  = "slowlog-max-len"
    value = "128"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-params"
  })
}
