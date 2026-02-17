# ------------------------------------------------------------------------------
# Monitoring Module - CloudWatch, SNS, Grafana
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
# SNS Topics for Alerting
# ------------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  for_each = toset(var.alert_channels)

  name         = "${var.project_name}-${var.environment}-${each.key}-alerts"
  display_name = "${var.project_name} ${var.environment} ${each.key} Alerts"
  kms_master_key_id = var.kms_key_id

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-${each.key}-alerts"
    Channel = each.key
  })
}

resource "aws_sns_topic_subscription" "email" {
  for_each = var.alert_email_endpoints

  topic_arn = aws_sns_topic.alerts[each.value.channel].arn
  protocol  = "email"
  endpoint  = each.value.email
}

resource "aws_sns_topic_subscription" "slack" {
  for_each = var.slack_webhook_urls

  topic_arn = aws_sns_topic.alerts[each.value.channel].arn
  protocol  = "https"
  endpoint  = each.value.url
}

# ------------------------------------------------------------------------------
# SNS Topic Policy
# ------------------------------------------------------------------------------

resource "aws_sns_topic_policy" "alerts" {
  for_each = toset(var.alert_channels)

  arn = aws_sns_topic.alerts[each.key].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts[each.key].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alarm:*"
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Composite Alarm for Critical Issues
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_composite_alarm" "critical" {
  count = length(var.critical_alarm_arns) > 0 ? 1 : 0

  alarm_name        = "${var.project_name}-${var.environment}-critical-composite"
  alarm_description = "Critical composite alarm - triggers when any critical alarm fires"

  alarm_rule = join(" OR ", [
    for arn in var.critical_alarm_arns : "ALARM("${arn}")"
  ])

  alarm_actions = [aws_sns_topic.alerts["critical"].arn]
  ok_actions    = [aws_sns_topic.alerts["critical"].arn]

  tags = var.tags
}
