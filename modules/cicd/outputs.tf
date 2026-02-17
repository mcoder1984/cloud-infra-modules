# ------------------------------------------------------------------------------
# CI/CD Module Outputs
# ------------------------------------------------------------------------------

output "artifact_bucket_name" {
  description = "S3 artifact bucket name"
  value       = aws_s3_bucket.artifacts.id
}

output "artifact_bucket_arn" {
  description = "S3 artifact bucket ARN"
  value       = aws_s3_bucket.artifacts.arn
}

output "codebuild_project_names" {
  description = "Map of CodeBuild project names"
  value       = { for k, v in aws_codebuild_project.this : k => v.name }
}

output "codebuild_project_arns" {
  description = "Map of CodeBuild project ARNs"
  value       = { for k, v in aws_codebuild_project.this : k => v.arn }
}

output "pipeline_names" {
  description = "Map of CodePipeline names"
  value       = { for k, v in aws_codepipeline.this : k => v.name }
}

output "pipeline_arns" {
  description = "Map of CodePipeline ARNs"
  value       = { for k, v in aws_codepipeline.this : k => v.arn }
}

output "codebuild_role_arn" {
  description = "CodeBuild IAM role ARN"
  value       = aws_iam_role.codebuild.arn
}

output "codepipeline_role_arn" {
  description = "CodePipeline IAM role ARN"
  value       = aws_iam_role.codepipeline.arn
}

output "codebuild_security_group_id" {
  description = "CodeBuild security group ID"
  value       = aws_security_group.codebuild.id
}
