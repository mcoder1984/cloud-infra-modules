# ------------------------------------------------------------------------------
# CloudWatch Dashboards
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-overview"

  dashboard_body = jsonencode({
    widgets = concat(
      # Header
      [
        {
          type   = "text"
          x      = 0
          y      = 0
          width  = 24
          height = 1
          properties = {
            markdown = "# ${var.project_name} - ${upper(var.environment)} Environment Dashboard"
          }
        }
      ],

      # ECS Service Metrics
      [for idx, svc in keys(var.ecs_services) : {
        type   = "metric"
        x      = (idx % 2) * 12
        y      = 1 + floor(idx / 2) * 6
        width  = 12
        height = 6
        properties = {
          title   = "ECS: ${svc}"
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_services[svc].cluster_name, "ServiceName", svc, { label = "CPU %" }],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_services[svc].cluster_name, "ServiceName", svc, { label = "Memory %" }],
          ]
          period = 300
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      }],

      # RDS Metrics
      [for idx, db in keys(var.rds_instances) : {
        type   = "metric"
        x      = (idx % 2) * 12
        y      = 13 + floor(idx / 2) * 6
        width  = 12
        height = 6
        properties = {
          title   = "RDS: ${db}"
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instances[db].instance_id, { label = "CPU %" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instances[db].instance_id, { label = "Connections", yAxis = "right" }],
          ]
          period = 300
        }
      }],

      # ALB Metrics
      [for idx, alb in keys(var.alb_arns) : {
        type   = "metric"
        x      = (idx % 2) * 12
        y      = 25 + floor(idx / 2) * 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB: ${alb}"
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arns[alb].arn_suffix, { label = "Requests", stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arns[alb].arn_suffix, { label = "5xx Errors", stat = "Sum" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arns[alb].arn_suffix, { label = "Latency (p99)", stat = "p99" }],
          ]
          period = 300
        }
      }]
    )
  })
}

resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "${var.project_name}-${var.environment}-infrastructure"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# Infrastructure Metrics - ${upper(var.environment)}"
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 1
        width  = 24
        height = 3
        properties = {
          title  = "Alarm Status"
          alarms = concat(
            [for k, v in aws_cloudwatch_metric_alarm.ecs_cpu_high : v.arn],
            [for k, v in aws_cloudwatch_metric_alarm.rds_cpu_high : v.arn],
            [for k, v in aws_cloudwatch_metric_alarm.alb_5xx : v.arn],
          )
        }
      }
    ]
  })
}
