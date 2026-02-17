# ------------------------------------------------------------------------------
# Monitoring Module Variables
# ------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name"
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

variable "alert_channels" {
  description = "Alert channel names (e.g., critical, warning, info)"
  type        = list(string)
  default     = ["critical", "warning", "info"]
}

variable "alert_email_endpoints" {
  description = "Map of email alert subscriptions"
  type = map(object({
    channel = string
    email   = string
  }))
  default = {}
}

variable "slack_webhook_urls" {
  description = "Map of Slack webhook subscriptions"
  type = map(object({
    channel = string
    url     = string
  }))
  default   = {}
  sensitive = true
}

variable "ecs_services" {
  description = "Map of ECS services to monitor"
  type = map(object({
    cluster_name = string
  }))
  default = {}
}

variable "rds_instances" {
  description = "Map of RDS instances to monitor"
  type = map(object({
    instance_id = string
  }))
  default = {}
}

variable "alb_arns" {
  description = "Map of ALBs to monitor"
  type = map(object({
    arn_suffix = string
  }))
  default = {}
}

variable "critical_alarm_arns" {
  description = "List of critical alarm ARNs for composite alarm"
  type        = list(string)
  default     = []
}

# Thresholds
variable "cpu_threshold" {
  description = "ECS CPU alarm threshold"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "ECS memory alarm threshold"
  type        = number
  default     = 85
}

variable "rds_cpu_threshold" {
  description = "RDS CPU alarm threshold"
  type        = number
  default     = 80
}

variable "rds_storage_threshold_gb" {
  description = "RDS free storage threshold in GB"
  type        = number
  default     = 10
}

variable "rds_connection_threshold" {
  description = "RDS connection count threshold"
  type        = number
  default     = 100
}

variable "error_rate_threshold" {
  description = "ALB 5xx error count threshold"
  type        = number
  default     = 50
}

variable "latency_threshold" {
  description = "ALB p99 latency threshold in seconds"
  type        = number
  default     = 2.0
}

# Grafana
variable "enable_grafana" {
  description = "Deploy Grafana on ECS"
  type        = bool
  default     = false
}

variable "grafana_version" {
  description = "Grafana Docker image version"
  type        = string
  default     = "10.2.3"
}

variable "grafana_cpu" {
  description = "Grafana task CPU"
  type        = number
  default     = 512
}

variable "grafana_memory" {
  description = "Grafana task memory"
  type        = number
  default     = 1024
}

variable "grafana_ecs_cluster_id" {
  description = "ECS cluster ID for Grafana"
  type        = string
  default     = ""
}

variable "grafana_subnet_ids" {
  description = "Subnet IDs for Grafana"
  type        = list(string)
  default     = []
}

variable "grafana_root_url" {
  description = "Grafana root URL"
  type        = string
  default     = "http://localhost:3000"
}

variable "grafana_admin_password_ssm_arn" {
  description = "SSM parameter ARN for Grafana admin password"
  type        = string
  default     = ""
}

variable "grafana_allowed_cidr" {
  description = "CIDR allowed to access Grafana"
  type        = string
  default     = "10.0.0.0/8"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
