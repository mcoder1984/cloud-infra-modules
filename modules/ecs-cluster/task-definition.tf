# ------------------------------------------------------------------------------
# ECS Task Definitions with CloudWatch Logging
# ------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "this" {
  for_each = var.services

  family                   = "${var.cluster_name}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task[each.key].arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      essential = true
      cpu       = each.value.cpu
      memory    = each.value.memory

      portMappings = [
        {
          containerPort = each.value.port
          protocol      = "tcp"
        }
      ]

      environment = [
        for k, v in lookup(each.value, "environment", {}) : {
          name  = k
          value = v
        }
      ]

      secrets = [
        for k, v in lookup(each.value, "secrets", {}) : {
          name      = k
          valueFrom = v
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service[each.key].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = each.key
        }
      }

      healthCheck = lookup(each.value, "container_health_check", null) != null ? {
        command     = ["CMD-SHELL", "curl -f http://localhost:${each.value.port}${each.value.health_check} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      } : null

      linuxParameters = {
        initProcessEnabled = true
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = lookup(each.value, "cpu_architecture", "X86_64")
  }

  tags = merge(var.tags, {
    Service = each.key
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Log Groups for Services
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "service" {
  for_each = var.services

  name              = "/aws/ecs/${var.cluster_name}/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(var.tags, {
    Service = each.key
  })
}
