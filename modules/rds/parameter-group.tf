# ------------------------------------------------------------------------------
# RDS Parameter Group - Optimized for PostgreSQL
# ------------------------------------------------------------------------------

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.identifier}-"
  family      = "postgres${split(".", var.engine_version)[0]}"
  description = "Optimized parameter group for ${var.identifier}"

  # Connection Management
  parameter {
    name  = "max_connections"
    value = var.max_connections
  }

  # Memory
  parameter {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4}"
  }

  parameter {
    name  = "effective_cache_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "work_mem"
    value = var.work_mem
  }

  parameter {
    name  = "maintenance_work_mem"
    value = var.maintenance_work_mem
  }

  # WAL
  parameter {
    name  = "wal_buffers"
    value = "64"
  }

  parameter {
    name  = "checkpoint_completion_target"
    value = "0.9"
  }

  # Query Planner
  parameter {
    name  = "random_page_cost"
    value = "1.1"
  }

  parameter {
    name  = "effective_io_concurrency"
    value = "200"
  }

  # Logging
  parameter {
    name  = "log_min_duration_statement"
    value = var.log_min_duration_statement
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name  = "log_temp_files"
    value = "0"
  }

  # SSL
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # Auto-explain for slow queries
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,auto_explain"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "auto_explain.log_min_duration"
    value = var.log_min_duration_statement
  }

  # pg_stat_statements
  parameter {
    name  = "pg_stat_statements.track"
    value = "all"
  }

  tags = merge(var.tags, {
    Name = "${var.identifier}-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}
