# ------------------------------------------------------------------------------
# ECS Cluster Module Variables
# ------------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "services" {
  description = "Map of ECS services to create"
  type = map(object({
    image                  = string
    cpu                    = number
    memory                 = number
    desired_count          = number
    port                   = number
    health_check           = string
    health_check_matcher   = optional(string, "200")
    min_count              = optional(number)
    max_count              = optional(number)
    cpu_scaling_target     = optional(number, 70)
    memory_scaling_target  = optional(number, 80)
    scale_in_cooldown      = optional(number, 300)
    scale_out_cooldown     = optional(number, 60)
    enable_autoscaling     = optional(bool, true)
    min_healthy_percent    = optional(number, 100)
    max_percent            = optional(number, 200)
    deregistration_delay   = optional(number, 30)
    health_check_grace_period = optional(number, 60)
    sticky_sessions        = optional(bool, false)
    force_new_deployment   = optional(bool, false)
    path_patterns          = optional(list(string), ["/*"])
    priority               = optional(number)
    environment            = optional(map(string), {})
    secrets                = optional(map(string), {})
    container_health_check = optional(bool)
    cpu_architecture       = optional(string, "X86_64")
  }))
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = true
}

variable "enable_service_discovery" {
  description = "Enable AWS Cloud Map service discovery"
  type        = bool
  default     = false
}

variable "enable_fargate_spot" {
  description = "Enable Fargate Spot capacity provider"
  type        = bool
  default     = false
}

variable "fargate_weight" {
  description = "Weight for Fargate capacity provider"
  type        = number
  default     = 1
}

variable "fargate_base" {
  description = "Base count for Fargate capacity provider"
  type        = number
  default     = 1
}

variable "fargate_spot_weight" {
  description = "Weight for Fargate Spot capacity provider"
  type        = number
  default     = 1
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = ""
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
