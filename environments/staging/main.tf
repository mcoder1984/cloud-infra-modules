# ------------------------------------------------------------------------------
# STAGING Environment - Production-like topology for validation
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.tags, {
      Environment = var.environment
      ManagedBy   = "terraform"
    })
  }
}

# ------------------------------------------------------------------------------
# VPC - Multi-AZ but single NAT
# ------------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  enable_nat_gateway = true
  single_nat_gateway = true  # Cost compromise for staging
  enable_flow_logs   = true
  flow_log_retention_days = 14

  tags = var.tags
}

# ------------------------------------------------------------------------------
# ECS Cluster - Production-like but fewer instances
# ------------------------------------------------------------------------------

module "ecs" {
  source = "../../modules/ecs-cluster"

  cluster_name       = "${var.project_name}-${var.environment}"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  certificate_arn    = var.certificate_arn

  enable_container_insights = true
  enable_fargate_spot       = true
  fargate_weight            = 1
  fargate_spot_weight       = 1

  services = {
    api = {
      image         = "${var.project_name}/api:latest"
      cpu           = 512
      memory        = 1024
      desired_count = 2
      port          = 8080
      health_check  = "/health"
      min_count     = 2
      max_count     = 6
    }
  }

  log_retention_days = 14

  tags = var.tags
}

# ------------------------------------------------------------------------------
# RDS - Multi-AZ for testing failover
# ------------------------------------------------------------------------------

module "rds" {
  source = "../../modules/rds"

  identifier           = "${var.project_name}-${var.environment}"
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  engine_version        = "16.1"
  instance_class        = "db.r6g.large"
  allocated_storage     = 50
  max_allocated_storage = 200

  database_name   = var.project_name
  multi_az        = true
  backup_retention_period = 7

  monitoring_interval          = 60
  performance_insights_enabled = true

  allowed_security_group_ids = values(module.ecs.service_security_group_ids)

  tags = var.tags
}

# ------------------------------------------------------------------------------
# ElastiCache - 2-node replica for failover testing
# ------------------------------------------------------------------------------

module "redis" {
  source = "../../modules/elasticache"

  cluster_name = "${var.project_name}-${var.environment}"
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.database_subnet_ids

  engine_version     = "7.1"
  node_type          = "cache.r6g.large"
  num_cache_clusters = 2
  multi_az_enabled   = true

  transit_encryption_enabled = true
  snapshot_retention_limit   = 3

  allowed_security_group_ids = values(module.ecs.service_security_group_ids)
  alarm_actions              = [module.monitoring.sns_topic_arn]

  tags = var.tags
}

# ------------------------------------------------------------------------------
# Monitoring
# ------------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  alert_channels = ["critical", "warning", "info"]

  alert_email_endpoints = var.alert_email != "" ? {
    staging = {
      channel = "critical"
      email   = var.alert_email
    }
  } : {}

  ecs_services = {
    api = { cluster_name = module.ecs.cluster_name }
  }

  rds_instances = {
    main = { instance_id = "${var.project_name}-${var.environment}" }
  }

  enable_grafana = false

  tags = var.tags
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "redis_endpoint" {
  value = module.redis.primary_endpoint_address
}
