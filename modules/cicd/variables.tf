# ------------------------------------------------------------------------------
# CI/CD Module Variables
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
  description = "VPC ID for CodeBuild"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for CodeBuild"
  type        = list(string)
}

variable "codestar_connection_arn" {
  description = "CodeStar connection ARN for GitHub/Bitbucket"
  type        = string
}

variable "build_projects" {
  description = "Map of CodeBuild projects"
  type = map(object({
    description                  = optional(string)
    timeout                      = optional(number, 30)
    compute_type                 = optional(string, "BUILD_GENERAL1_MEDIUM")
    image                        = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:5.0")
    privileged_mode              = optional(bool, true)
    buildspec                    = optional(string, "buildspec.yml")
    environment_variables        = optional(map(string), {})
    secret_environment_variables = optional(map(string), {})
  }))
}

variable "pipelines" {
  description = "Map of CodePipeline configurations"
  type = map(object({
    repository    = string
    branch        = string
    build_project = string
    deploy_config = optional(object({
      provider      = string
      configuration = map(string)
    }))
  }))
}

variable "kms_key_arn" {
  description = "KMS key ARN for artifact encryption"
  type        = string
  default     = null
}

variable "notification_topic_arn" {
  description = "SNS topic ARN for pipeline notifications"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
