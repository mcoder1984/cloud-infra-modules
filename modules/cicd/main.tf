# ------------------------------------------------------------------------------
# CI/CD Module - CodePipeline with CodeBuild
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
# Data Sources
# ------------------------------------------------------------------------------

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# S3 Artifact Bucket
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project_name}-${var.environment}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.environment != "prod"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-pipeline-artifacts"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# ------------------------------------------------------------------------------
# CodeBuild Project
# ------------------------------------------------------------------------------

resource "aws_codebuild_project" "this" {
  for_each = var.build_projects

  name          = "${var.project_name}-${var.environment}-${each.key}"
  description   = lookup(each.value, "description", "Build project for ${each.key}")
  build_timeout = lookup(each.value, "timeout", 30)
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = lookup(each.value, "compute_type", "BUILD_GENERAL1_MEDIUM")
    image                       = lookup(each.value, "image", "aws/codebuild/amazonlinux2-x86_64-standard:5.0")
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = lookup(each.value, "privileged_mode", true)

    dynamic "environment_variable" {
      for_each = merge(
        {
          AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
          AWS_REGION     = data.aws_region.current.name
          ENVIRONMENT    = var.environment
          PROJECT_NAME   = var.project_name
        },
        lookup(each.value, "environment_variables", {})
      )
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }

    dynamic "environment_variable" {
      for_each = lookup(each.value, "secret_environment_variables", {})
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "SECRETS_MANAGER"
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = lookup(each.value, "buildspec", "buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild[each.key].name
      stream_name = "build"
    }
  }

  cache {
    type  = "S3"
    location = "${aws_s3_bucket.artifacts.bucket}/cache/${each.key}"
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.private_subnet_ids
    security_group_ids = [aws_security_group.codebuild.id]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}"
  })
}

resource "aws_cloudwatch_log_group" "codebuild" {
  for_each = var.build_projects

  name              = "/aws/codebuild/${var.project_name}-${var.environment}-${each.key}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# ------------------------------------------------------------------------------
# CodeBuild Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "codebuild" {
  name_prefix = "${var.project_name}-codebuild-"
  description = "Security group for CodeBuild projects"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-codebuild-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "codebuild_all" {
  security_group_id = aws_security_group.codebuild.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "codebuild-egress" }
}

# ------------------------------------------------------------------------------
# CodePipeline
# ------------------------------------------------------------------------------

resource "aws_codepipeline" "this" {
  for_each = var.pipelines

  name          = "${var.project_name}-${var.environment}-${each.key}"
  role_arn      = aws_iam_role.codepipeline.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"

    dynamic "encryption_key" {
      for_each = var.kms_key_arn != null ? [1] : []
      content {
        id   = var.kms_key_arn
        type = "KMS"
      }
    }
  }

  # Source Stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = each.value.repository
        BranchName       = each.value.branch
      }
    }
  }

  # Build Stage
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.this[each.value.build_project].name
      }
    }
  }

  # Deploy Stage
  dynamic "stage" {
    for_each = lookup(each.value, "deploy_config", null) != null ? [each.value.deploy_config] : []
    content {
      name = "Deploy"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = stage.value.provider
        version         = "1"
        input_artifacts = ["build_output"]

        configuration = stage.value.configuration
      }
    }
  }

  tags = merge(var.tags, {
    Name     = "${var.project_name}-${var.environment}-${each.key}"
    Pipeline = each.key
  })
}

# ------------------------------------------------------------------------------
# Pipeline Notifications
# ------------------------------------------------------------------------------

resource "aws_codestarnotifications_notification_rule" "pipeline" {
  for_each = var.notification_topic_arn != "" ? var.pipelines : {}

  name        = "${var.project_name}-${var.environment}-${each.key}-notifications"
  detail_type = "FULL"
  resource    = aws_codepipeline.this[each.key].arn

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-manual-approval-needed",
  ]

  target {
    address = var.notification_topic_arn
    type    = "SNS"
  }

  tags = var.tags
}
