# ------------------------------------------------------------------------------
# RDS Module - PostgreSQL with Multi-AZ, encryption, automated backups
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------

data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# Random password for master user (stored in Secrets Manager)
# ------------------------------------------------------------------------------

resource "random_password" "master" {
  count = var.manage_master_user_password ? 0 : 1

  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|;:,.<>?"
}

resource "aws_secretsmanager_secret" "master_password" {
  count = var.manage_master_user_password ? 0 : 1

  name        = "${var.identifier}-master-password"
  description = "Master password for RDS instance ${var.identifier}"
  kms_key_id  = var.kms_key_id

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "master_password" {
  count = var.manage_master_user_password ? 0 : 1

  secret_id     = aws_secretsmanager_secret.master_password[0].id
  secret_string = random_password.master[0].result
}

# ------------------------------------------------------------------------------
# RDS Instance
# ------------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier = var.identifier

  # Engine
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = true
  kms_key_id           = var.kms_key_id
  iops                 = var.storage_type == "io1" ? var.iops : null

  # Database
  db_name  = var.database_name
  username = var.master_username
  password = var.manage_master_user_password ? null : random_password.master[0].result
  port     = var.port

  manage_master_user_password = var.manage_master_user_password

  # Networking
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false

  # High Availability
  multi_az = var.multi_az

  # Backups
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = true
  delete_automated_backups  = var.environment != "prod"
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-${formatdate("YYYYMMDD", timestamp())}"
  skip_final_snapshot       = var.skip_final_snapshot

  # Monitoring
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? aws_iam_role.enhanced_monitoring[0].arn : null
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_id : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention : null
  enabled_cloudwatch_logs_exports = var.cloudwatch_log_exports

  # Parameters
  parameter_group_name = aws_db_parameter_group.this.name

  # Upgrades
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = false
  apply_immediately           = var.environment != "prod"

  # Deletion protection
  deletion_protection = var.environment == "prod"

  tags = merge(var.tags, {
    Name        = var.identifier
    Environment = var.environment
  })

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

# ------------------------------------------------------------------------------
# Read Replica (optional)
# ------------------------------------------------------------------------------

resource "aws_db_instance" "replica" {
  count = var.create_read_replica ? 1 : 0

  identifier          = "${var.identifier}-replica"
  replicate_source_db = aws_db_instance.this.identifier
  instance_class      = var.replica_instance_class != "" ? var.replica_instance_class : var.instance_class

  storage_encrypted = true
  kms_key_id        = var.kms_key_id

  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false

  monitoring_interval          = var.monitoring_interval
  monitoring_role_arn          = var.monitoring_interval > 0 ? aws_iam_role.enhanced_monitoring[0].arn : null
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_id : null

  parameter_group_name = aws_db_parameter_group.this.name

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.environment != "prod"
  skip_final_snapshot        = true

  tags = merge(var.tags, {
    Name        = "${var.identifier}-replica"
    Environment = var.environment
    Role        = "replica"
  })
}

# ------------------------------------------------------------------------------
# Enhanced Monitoring IAM Role
# ------------------------------------------------------------------------------

resource "aws_iam_role" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.identifier}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
