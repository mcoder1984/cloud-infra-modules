# ------------------------------------------------------------------------------
# ECS Services with Auto-Scaling and Load Balancer Integration
# ------------------------------------------------------------------------------

resource "aws_ecs_service" "this" {
  for_each = var.services

  name            = each.key
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = lookup(each.value, "min_healthy_percent", 100)
  deployment_maximum_percent         = lookup(each.value, "max_percent", 200)
  health_check_grace_period_seconds  = lookup(each.value, "health_check_grace_period", 60)
  enable_execute_command             = var.enable_execute_command
  force_new_deployment               = lookup(each.value, "force_new_deployment", false)
  propagate_tags                     = "SERVICE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service[each.key].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this[each.key].arn
    container_name   = each.key
    container_port   = each.value.port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.this[each.key].arn
    }
  }

  tags = merge(var.tags, {
    Name    = each.key
    Service = each.key
  })

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ------------------------------------------------------------------------------
# Target Groups
# ------------------------------------------------------------------------------

resource "aws_lb_target_group" "this" {
  for_each = var.services

  name_prefix = substr(each.key, 0, 6)
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = lookup(each.value, "deregistration_delay", 30)

  health_check {
    enabled             = true
    path                = each.value.health_check
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    matcher             = lookup(each.value, "health_check_matcher", "200")
  }

  stickiness {
    type    = "lb_cookie"
    enabled = lookup(each.value, "sticky_sessions", false)
  }

  tags = merge(var.tags, {
    Name    = "${each.key}-tg"
    Service = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# ALB Listener Rules
# ------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "this" {
  for_each = var.services

  listener_arn = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = lookup(each.value, "priority", null)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    path_pattern {
      values = lookup(each.value, "path_patterns", ["/*"])
    }
  }

  tags = merge(var.tags, {
    Service = each.key
  })
}

# ------------------------------------------------------------------------------
# Service Security Groups
# ------------------------------------------------------------------------------

resource "aws_security_group" "ecs_service" {
  for_each = var.services

  name_prefix = "${each.key}-svc-"
  description = "Security group for ECS service ${each.key}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name    = "${each.key}-svc-sg"
    Service = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  for_each = var.services

  security_group_id            = aws_security_group.ecs_service[each.key].id
  description                  = "Traffic from ALB"
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = { Name = "${each.key}-alb-ingress" }
}

resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  for_each = var.services

  security_group_id = aws_security_group.ecs_service[each.key].id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "${each.key}-all-egress" }
}

# ------------------------------------------------------------------------------
# Auto Scaling
# ------------------------------------------------------------------------------

resource "aws_appautoscaling_target" "this" {
  for_each = { for k, v in var.services : k => v if lookup(v, "enable_autoscaling", true) }

  max_capacity       = lookup(each.value, "max_count", each.value.desired_count * 4)
  min_capacity       = lookup(each.value, "min_count", each.value.desired_count)
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each = { for k, v in var.services : k => v if lookup(v, "enable_autoscaling", true) }

  name               = "${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = lookup(each.value, "cpu_scaling_target", 70)
    scale_in_cooldown  = lookup(each.value, "scale_in_cooldown", 300)
    scale_out_cooldown = lookup(each.value, "scale_out_cooldown", 60)
  }
}

resource "aws_appautoscaling_policy" "memory" {
  for_each = { for k, v in var.services : k => v if lookup(v, "enable_autoscaling", true) }

  name               = "${each.key}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = lookup(each.value, "memory_scaling_target", 80)
    scale_in_cooldown  = lookup(each.value, "scale_in_cooldown", 300)
    scale_out_cooldown = lookup(each.value, "scale_out_cooldown", 60)
  }
}

# ------------------------------------------------------------------------------
# Service Discovery
# ------------------------------------------------------------------------------

resource "aws_service_discovery_service" "this" {
  for_each = var.enable_service_discovery ? var.services : {}

  name = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = var.tags
}
