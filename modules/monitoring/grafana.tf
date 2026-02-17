# ------------------------------------------------------------------------------
# Grafana on ECS (Optional)
# ------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "grafana" {
  count = var.enable_grafana ? 1 : 0

  family                   = "${var.project_name}-${var.environment}-grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.grafana_cpu
  memory                   = var.grafana_memory
  execution_role_arn       = aws_iam_role.grafana_execution[0].arn
  task_role_arn            = aws_iam_role.grafana_task[0].arn

  container_definitions = jsonencode([
    {
      name      = "grafana"
      image     = "grafana/grafana:${var.grafana_version}"
      essential = true
      cpu       = var.grafana_cpu
      memory    = var.grafana_memory

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "GF_SERVER_ROOT_URL", value = var.grafana_root_url },
        { name = "GF_SECURITY_ADMIN_USER", value = "admin" },
        { name = "GF_AUTH_ANONYMOUS_ENABLED", value = "false" },
        { name = "GF_INSTALL_PLUGINS", value = "grafana-cloudwatch-datasource" },
        { name = "GF_AWS_SDK_LOAD_CONFIG", value = "true" },
        { name = "GF_AWS_default_REGION", value = data.aws_region.current.name },
      ]

      secrets = [
        {
          name      = "GF_SECURITY_ADMIN_PASSWORD"
          valueFrom = var.grafana_admin_password_ssm_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.grafana[0].name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "grafana"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "grafana" {
  count = var.enable_grafana ? 1 : 0

  name              = "/aws/ecs/${var.project_name}-${var.environment}/grafana"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_ecs_service" "grafana" {
  count = var.enable_grafana ? 1 : 0

  name            = "grafana"
  cluster         = var.grafana_ecs_cluster_id
  task_definition = aws_ecs_task_definition.grafana[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.grafana_subnet_ids
    security_groups  = [aws_security_group.grafana[0].id]
    assign_public_ip = false
  }

  tags = var.tags
}

resource "aws_security_group" "grafana" {
  count = var.enable_grafana ? 1 : 0

  name_prefix = "${var.project_name}-grafana-"
  description = "Security group for Grafana"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-grafana-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "grafana" {
  count = var.enable_grafana ? 1 : 0

  security_group_id = aws_security_group.grafana[0].id
  description       = "Grafana UI"
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  cidr_ipv4         = var.grafana_allowed_cidr

  tags = { Name = "grafana-ingress" }
}

resource "aws_vpc_security_group_egress_rule" "grafana" {
  count = var.enable_grafana ? 1 : 0

  security_group_id = aws_security_group.grafana[0].id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "grafana-egress" }
}

# Grafana IAM Roles
resource "aws_iam_role" "grafana_execution" {
  count = var.enable_grafana ? 1 : 0

  name = "${var.project_name}-${var.environment}-grafana-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "grafana_execution" {
  count = var.enable_grafana ? 1 : 0

  role       = aws_iam_role.grafana_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "grafana_execution_ssm" {
  count = var.enable_grafana ? 1 : 0

  name = "ssm-access"
  role = aws_iam_role.grafana_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ssm:GetParameters", "ssm:GetParameter"]
      Resource = [var.grafana_admin_password_ssm_arn]
    }]
  })
}

resource "aws_iam_role" "grafana_task" {
  count = var.enable_grafana ? 1 : 0

  name = "${var.project_name}-${var.environment}-grafana-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "grafana_cloudwatch" {
  count = var.enable_grafana ? 1 : 0

  name = "cloudwatch-read"
  role = aws_iam_role.grafana_task[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetInsightRuleReport"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })
}
