# ECS Cluster Module

Deploys an ECS Fargate cluster with ALB, auto-scaling services, and full observability.

## Features

- ECS Fargate cluster with Container Insights
- FARGATE and FARGATE_SPOT capacity providers
- Application Load Balancer with HTTPS support
- Per-service auto-scaling (CPU and memory targets)
- Deployment circuit breaker with automatic rollback
- ECS Exec support for container debugging
- AWS Cloud Map service discovery (optional)
- CloudWatch logging per service
- Least-privilege IAM roles per service

## Usage

```hcl
module "ecs" {
  source = "../../modules/ecs-cluster"

  cluster_name       = "myapp-prod"
  environment        = "prod"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  certificate_arn    = "arn:aws:acm:us-east-1:123456789:certificate/abc-123"

  services = {
    api = {
      image         = "123456789.dkr.ecr.us-east-1.amazonaws.com/api:latest"
      cpu           = 512
      memory        = 1024
      desired_count = 3
      port          = 8080
      health_check  = "/health"
      path_patterns = ["/api/*"]
      environment = {
        NODE_ENV = "production"
      }
      secrets = {
        DATABASE_URL = "arn:aws:secretsmanager:us-east-1:123456789:secret:myapp/db-url"
      }
    }
    web = {
      image         = "123456789.dkr.ecr.us-east-1.amazonaws.com/web:latest"
      cpu           = 256
      memory        = 512
      desired_count = 2
      port          = 3000
      health_check  = "/"
      path_patterns = ["/*"]
      priority      = 200
    }
  }

  enable_container_insights = true
  enable_fargate_spot       = true
}
```
