# ------------------------------------------------------------------------------
# RDS Module Variables
# ------------------------------------------------------------------------------

variable "identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_group_name" {
  description = "DB subnet group name"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.1"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling in GB"
  type        = number
  default     = 500
}

variable "storage_type" {
  description = "Storage type (gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "iops" {
  description = "Provisioned IOPS (for io1 storage type)"
  type        = number
  default     = 3000
}

variable "database_name" {
  description = "Name of the default database"
  type        = string
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master password via Secrets Manager"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 14
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:30-sun:05:30"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 60
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention" {
  description = "Performance Insights retention in days"
  type        = number
  default     = 7
}

variable "cloudwatch_log_exports" {
  description = "CloudWatch log exports"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect"
  type        = list(string)
  default     = []
}

variable "create_read_replica" {
  description = "Create a read replica"
  type        = bool
  default     = false
}

variable "replica_instance_class" {
  description = "Instance class for the read replica"
  type        = string
  default     = ""
}

variable "max_connections" {
  description = "Maximum number of connections"
  type        = string
  default     = "LEAST({DBInstanceClassMemory/9531392},5000)"
}

variable "work_mem" {
  description = "Work memory in KB"
  type        = string
  default     = "65536"
}

variable "maintenance_work_mem" {
  description = "Maintenance work memory in KB"
  type        = string
  default     = "524288"
}

variable "log_min_duration_statement" {
  description = "Log statements taking longer than this (ms)"
  type        = string
  default     = "1000"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
