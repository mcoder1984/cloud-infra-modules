# ------------------------------------------------------------------------------
# DEV Environment - Cost-optimized development setup
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
# VPC - Single NAT Gateway for cost savings
# ------------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  enable_nat_gateway = true
  single_nat_gateway = true  # Cost saving: single NAT for dev
  enable_flow_logs   = true
  flow_log_retention_days = 7

  tags = var.tags
}

# ------------------------------------------------------------------------------
# ECS Cluster - Minimal resources with Fargate Spot
# ------------------------------------------------------------------------------

module "ecs" {
  source = "../../modules/ecs-cluster"

  cluster_name       = "${var.project_name}-${var.environment}"
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  certificate_arn    = var.certificate_arn

  enable_container_insights = false  # Cost saving
  enable_fargate_spot       = true   # Cost saving: use spot
  fargate_weight            = 1
  fargate_spot_weight       = 3

  services = {
    api = {
      image         = "${var.project_name}/api:latest"
      cpu           = 256
      memory        = 512
      desired_count = 1
      port          = 8080
      health_check  = "/health"
      min_count     = 1
      max_count     = 2
    }
  }

  log_retention_days = 7

  tags = var.tags
}

# ------------------------------------------------------------------------------
# RDS - Smallest instance, single AZ
# ------------------------------------------------------------------------------

module "rds" {
  source = "../../modules/rds"

  identifier           = "${var.project_name}-${var.environment}"
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  engine_version        = "16.1"
  instance_class        = "db.t4g.medium"  # Cost-effective
  allocated_storage     = 20
  max_allocated_storage = 100

  database_name   = var.project_name
  multi_az        = false  # Single AZ for dev
  skip_final_snapshot = true
  backup_retention_period = 3

  monitoring_interval          = 0  # Disabled for dev
  performance_insights_enabled = false

  allowed_security_group_ids = values(module.ecs.service_security_group_ids)

  tags = var.tags
}

# ------------------------------------------------------------------------------
# ElastiCache - Single node, smallest instance
# ------------------------------------------------------------------------------

module "redis" {
  source = "../../modules/elasticache"

  cluster_name = "${var.project_name}-${var.environment}"
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.database_subnet_ids

  engine_version     = "7.1"
  node_type          = "cache.t4g.micro"  # Smallest for dev
  num_cache_clusters = 1                   # Single node
  multi_az_enabled   = false

  transit_encryption_enabled = false  # Simpler for dev
  snapshot_retention_limit   = 0

  allowed_security_group_ids = values(module.ecs.service_security_group_ids)

  tags = var.tags
}

# ------------------------------------------------------------------------------
# Monitoring - Basic alerts only
# ------------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  alert_channels = ["critical", "warning"]

  alert_email_endpoints = var.alert_email != "" ? {
    dev = {
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
