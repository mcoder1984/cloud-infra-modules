# Cloud Infrastructure Modules

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-blue.svg)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS-%3E%3D5.0-orange.svg)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Production-grade, reusable Terraform modules for AWS infrastructure. Built with security, scalability, and operational excellence as first-class concerns.

## Architecture Overview

```
                        AWS Account
  +---------------------------------------------------------------+
  |                         VPC Module                            |
  |  +--------------+  +--------------+  +--------------+         |
  |  |  Public       |  |  Public       |  |  Public       |      |
  |  |  Subnet AZ-a  |  |  Subnet AZ-b  |  |  Subnet AZ-c  |    |
  |  |  (ALB, NAT)   |  |  (ALB, NAT)   |  |  (ALB, NAT)   |    |
  |  +------+--------+  +------+--------+  +------+--------+     |
  |         |                  |                  |               |
  |  +------v--------+  +------v--------+  +------v--------+     |
  |  |  Private       |  |  Private       |  |  Private       |  |
  |  |  Subnet AZ-a   |  |  Subnet AZ-b   |  |  Subnet AZ-c   | |
  |  |  (ECS/EKS)     |  |  (ECS/EKS)     |  |  (ECS/EKS)     | |
  |  +------+---------+  +------+---------+  +------+---------+  |
  |         |                  |                  |               |
  |  +------v--------+  +------v--------+  +------v--------+     |
  |  |  Database      |  |  Database      |  |  Database      |  |
  |  |  Subnet AZ-a   |  |  Subnet AZ-b   |  |  Subnet AZ-c   | |
  |  |  (RDS/Redis)   |  |  (RDS/Redis)   |  |  (RDS/Redis)   | |
  |  +----------------+  +----------------+  +----------------+  |
  +---------------------------------------------------------------+

  +----------+ +----------+ +----------+ +----------+
  |ECS/EKS   | |   RDS    | |ElastiCache| |Monitoring|
  |Cluster   | |PostgreSQL| |  Redis    | |CloudWatch|
  |Module    | | Module   | |  Module   | |+ Grafana |
  +----------+ +----------+ +----------+ +----------+

  +--------------------------------------------------------------+
  |              CI/CD Pipeline (CodePipeline + CodeBuild)       |
  +--------------------------------------------------------------+
```

## Module Catalog

| Module | Description | Key Features |
|--------|-------------|--------------|
| [vpc](./modules/vpc/) | Production VPC with multi-AZ networking | Public/private/database subnets, NAT gateways, VPC flow logs |
| [ecs-cluster](./modules/ecs-cluster/) | ECS Fargate cluster with services | Capacity providers, auto-scaling, ALB integration, logging |
| [eks-cluster](./modules/eks-cluster/) | Managed Kubernetes cluster | Managed node groups, IRSA, CoreDNS/kube-proxy/VPC-CNI addons |
| [rds](./modules/rds/) | PostgreSQL with HA configuration | Multi-AZ, encryption, automated backups, parameter tuning |
| [elasticache](./modules/elasticache/) | Redis cluster with replication | Replication groups, automatic failover, encryption |
| [monitoring](./modules/monitoring/) | Observability stack | CloudWatch dashboards/alarms, SNS alerting, Grafana on ECS |
| [cicd](./modules/cicd/) | Deployment pipeline | CodePipeline, CodeBuild, IAM roles, buildspec templates |

## Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [pre-commit](https://pre-commit.com/) for local development

### Deploy a Complete Environment

```bash
# Initialize pre-commit hooks
pre-commit install

# Deploy dev environment
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

### Use Individual Modules

```hcl
module "vpc" {
  source = "git::https://github.com/mcoder1984/cloud-infra-modules.git//modules/vpc?ref=v1.0.0"

  project_name       = "myapp"
  environment        = "production"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  enable_nat_gateway = true
  single_nat_gateway = false
  enable_flow_logs   = true

  tags = {
    Team      = "platform"
    ManagedBy = "terraform"
  }
}

module "ecs_cluster" {
  source = "git::https://github.com/mcoder1984/cloud-infra-modules.git//modules/ecs-cluster?ref=v1.0.0"

  cluster_name       = "myapp-production"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  services = {
    api = {
      image         = "myapp/api:latest"
      cpu           = 512
      memory        = 1024
      desired_count = 3
      port          = 8080
      health_check  = "/health"
    }
  }
}
```

## Environment Structure

```
environments/
  dev/          # Development - minimal resources, single NAT
  staging/      # Staging - mirrors production topology
  prod/         # Production - multi-AZ, HA, encryption everywhere
```

Each environment uses the same modules with environment-specific variable overrides.
State is stored in S3 with DynamoDB locking.

## Design Principles

1. **Security by Default** - Encryption at rest and in transit, least-privilege IAM, private subnets
2. **High Availability** - Multi-AZ deployments, auto-scaling, health checks, automated failover
3. **Cost Optimization** - Environment-specific sizing, single NAT for dev, spot where appropriate
4. **Observability** - CloudWatch metrics/alarms, VPC flow logs, centralized Grafana dashboards
5. **Immutable Infrastructure** - Fargate containers, blue/green deployments, IaC everything

## Development

```bash
make fmt         # Format all Terraform files
make validate    # Validate all modules
make lint        # Run tflint on all modules
make plan ENV=dev
make apply ENV=prod
```

## License

MIT License. See [LICENSE](LICENSE) for details.
