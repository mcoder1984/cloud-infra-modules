# RDS Module

Deploys a production-ready PostgreSQL RDS instance with encryption, multi-AZ, automated backups, and optimized parameters.

## Features

- PostgreSQL with configurable version
- Multi-AZ for high availability
- Storage encryption with KMS
- Automated backups with configurable retention
- Enhanced Monitoring and Performance Insights
- Optimized parameter group (connection pooling, WAL, query planner)
- Forced SSL connections
- Auto-explain for slow query analysis
- pg_stat_statements for query performance tracking
- Optional read replica
- Security group with least-privilege access
- Auto-scaling storage

## Usage

```hcl
module "rds" {
  source = "../../modules/rds"

  identifier           = "myapp-prod"
  environment          = "prod"
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  engine_version        = "16.1"
  instance_class        = "db.r6g.xlarge"
  allocated_storage     = 100
  max_allocated_storage = 1000

  database_name   = "myapp"
  master_username = "dbadmin"

  multi_az                = true
  backup_retention_period = 30
  create_read_replica     = true

  allowed_security_group_ids = [
    module.ecs.service_security_group_ids["api"]
  ]

  performance_insights_enabled = true
  monitoring_interval          = 60
}
```
