# Monitoring Module

Comprehensive observability stack with CloudWatch dashboards, alarms, SNS alerting, and optional Grafana deployment.

## Features

- SNS topics with multi-channel alerting (email, Slack)
- CloudWatch alarms for ECS, RDS, ALB
- Composite alarms for critical issue escalation
- Auto-generated CloudWatch dashboards
- Grafana on ECS with CloudWatch data source
- Configurable thresholds per metric

## Usage

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  project_name = "myapp"
  environment  = "prod"
  vpc_id       = module.vpc.vpc_id

  alert_channels = ["critical", "warning", "info"]

  alert_email_endpoints = {
    oncall = {
      channel = "critical"
      email   = "oncall@company.com"
    }
    team = {
      channel = "warning"
      email   = "platform-team@company.com"
    }
  }

  ecs_services = {
    api = { cluster_name = module.ecs.cluster_name }
    web = { cluster_name = module.ecs.cluster_name }
  }

  rds_instances = {
    main = { instance_id = module.rds.instance_id }
  }

  alb_arns = {
    main = { arn_suffix = module.ecs.alb_arn }
  }

  cpu_threshold    = 80
  memory_threshold = 85

  enable_grafana         = true
  grafana_ecs_cluster_id = module.ecs.cluster_id
  grafana_subnet_ids     = module.vpc.private_subnet_ids
}
```
