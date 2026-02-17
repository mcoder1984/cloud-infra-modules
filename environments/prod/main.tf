# ------------------------------------------------------------------------------
# PRODUCTION Environment - Full HA with encryption and monitoring
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
# VPC - Full HA: NAT per AZ
# ------------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  enable_nat_gateway = true
  single_nat_gateway = false  # HA: one NAT per AZ
  enable_flow_logs   = true
  flow_log_retention_days = 90

  tags = var.tags
}

# ------------------------------------------------------------------------------
# ECS Cluster - Production workloads with auto-scaling
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
  enable_fargate_spot       = false  # ON_DEMAND only for production
  enable_service_discovery  = true

  services = {
    api = {
      image         = "${var.project_name}/api:latest"
      cpu           = 1024
      memory        = 2048
      desired_count = 3
      port          = 8080
      health_check  = "/health"
      min_count     = 3
      max_count     = 20
      cpu_scaling_target    = 60
      memory_scaling_target = 70
      deregistration_delay  = 60
      environment = {
        NODE_ENV     = "production"
        LOG_LEVEL    = "info"
      }
    }
    worker = {
      image         = "${var.project_name}/worker:latest"
      cpu           = 512
      memory        = 1024
      desired_count = 2
      port          = 8081
      health_check  = "/health"
      min_count     = 2
      max_count     = 10
      path_patterns = ["/internal/*"]
      priority      = 200
    }
  }

  log_retention_days = 90

  tags = var.tags
}

# ------------------------------------------------------------------------------
# RDS - Full HA with read replica, enhanced monitoring
# ------------------------------------------------------------------------------

module "rds" {
  source = "../../modules/rds"

  identifier           = "${var.project_name}-${var.environment}"
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  engine_version        = "16.1"
  instance_class        = "db.r6g.xlarge"
  allocated_storage     = 200
  max_allocated_storage = 1000
  storage_type          = "gp3"

  database_name   = var.project_name
  multi_az        = true
  backup_retention_period = 30
  create_read_replica     = true

  monitoring_interval          = 60
  performance_insights_enabled = true
  performance_insights_retention = 31

  allowed_security_group_ids = values(module.ecs.service_security_group_ids)

  skip_final_snapshot = false

  tags = var.tags
}

# ------------------------------------------------------------------------------
# ElastiCache - 3-node cluster for HA
# ------------------------------------------------------------------------------

module "redis" {
  source = "../../modules/elasticache"

  cluster_name = "${var.project_name}-${var.environment}"
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.database_subnet_ids

  engine_version     = "7.1"
  node_type          = "cache.r6g.xlarge"
  num_cache_clusters = 3
  multi_az_enabled   = true

  transit_encryption_enabled = true
  snapshot_retention_limit   = 14

  allowed_security_group_ids = values(module.ecs.service_security_group_ids)
  alarm_actions              = [module.monitoring.sns_topic_arn]

  maxmemory_policy = "volatile-lru"

  tags = var.tags
}

# ------------------------------------------------------------------------------
# Monitoring - Full observability with Grafana
# ------------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  alert_channels = ["critical", "warning", "info"]

  alert_email_endpoints = {
    oncall = {
      channel = "critical"
      email   = var.alert_email
    }
  }

  ecs_services = {
    api    = { cluster_name = module.ecs.cluster_name }
    worker = { cluster_name = module.ecs.cluster_name }
  }

  rds_instances = {
    main = { instance_id = "${var.project_name}-${var.environment}" }
  }

  cpu_threshold    = 70
  memory_threshold = 80
  rds_cpu_threshold = 70

  enable_grafana         = true
  grafana_ecs_cluster_id = module.ecs.cluster_id
  grafana_subnet_ids     = module.vpc.private_subnet_ids

  log_retention_days = 90

  tags = var.tags
}

# ------------------------------------------------------------------------------
# CI/CD Pipeline
# ------------------------------------------------------------------------------

module "cicd" {
  source = "../../modules/cicd"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  codestar_connection_arn = var.codestar_connection_arn

  build_projects = {
    api = {
      description  = "Build API service"
      compute_type = "BUILD_GENERAL1_MEDIUM"
      timeout      = 20
      environment_variables = {
        SERVICE_NAME  = "api"
        ECS_CLUSTER   = module.ecs.cluster_name
        ECS_SERVICE   = "api"
      }
    }
    worker = {
      description  = "Build worker service"
      compute_type = "BUILD_GENERAL1_SMALL"
      timeout      = 15
      environment_variables = {
        SERVICE_NAME  = "worker"
        ECS_CLUSTER   = module.ecs.cluster_name
        ECS_SERVICE   = "worker"
      }
    }
  }

  pipelines = {
    api = {
      repository    = "myorg/myapp-api"
      branch        = "main"
      build_project = "api"
      deploy_config = {
        provider = "ECS"
        configuration = {
          ClusterName = module.ecs.cluster_name
          ServiceName = "api"
        }
      }
    }
    worker = {
      repository    = "myorg/myapp-worker"
      branch        = "main"
      build_project = "worker"
      deploy_config = {
        provider = "ECS"
        configuration = {
          ClusterName = module.ecs.cluster_name
          ServiceName = "worker"
        }
      }
    }
  }

  notification_topic_arn = module.monitoring.sns_topic_arn
  log_retention_days     = 90

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
  value     = module.rds.endpoint
  sensitive = true
}

output "rds_replica_endpoint" {
  value     = module.rds.replica_endpoint
  sensitive = true
}

output "redis_endpoint" {
  value = module.redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  value = module.redis.reader_endpoint_address
}

output "monitoring_dashboard" {
  value = module.monitoring.dashboard_names
}
