# VPC Module

Creates a production-grade VPC with multi-tier networking across multiple availability zones.

## Features

- Multi-AZ public, private, and database subnets
- NAT Gateways (single or per-AZ for HA)
- VPC Flow Logs to CloudWatch with configurable retention
- Database subnet group for RDS/ElastiCache
- Restrictive Network ACLs for database tier
- Kubernetes-compatible subnet tagging (ELB discovery)
- Configurable CIDR allocation

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name       = "myapp"
  environment        = "production"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  enable_nat_gateway = true
  single_nat_gateway = false  # One NAT per AZ for HA
  enable_flow_logs   = true

  flow_log_retention_days = 90

  tags = {
    Team      = "platform"
    ManagedBy = "terraform"
  }
}
```

## Subnet Layout (default /16 VPC)

| Tier     | AZ-a         | AZ-b         | AZ-c         |
|----------|-------------|-------------|-------------|
| Public   | 10.0.0.0/20 | 10.0.16.0/20| 10.0.32.0/20|
| Private  | 10.0.48.0/20| 10.0.64.0/20| 10.0.80.0/20|
| Database | 10.0.96.0/20| 10.0.112.0/20| 10.0.128.0/20|

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name prefix | string | - | yes |
| environment | Environment name | string | - | yes |
| vpc_cidr | VPC CIDR block | string | 10.0.0.0/16 | no |
| availability_zones | List of AZs | list(string) | - | yes |
| enable_nat_gateway | Enable NAT Gateway | bool | true | no |
| single_nat_gateway | Use single NAT Gateway | bool | false | no |
| enable_flow_logs | Enable VPC Flow Logs | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| public_subnet_ids | Public subnet IDs |
| private_subnet_ids | Private subnet IDs |
| database_subnet_ids | Database subnet IDs |
| nat_gateway_public_ips | NAT Gateway public IPs |
