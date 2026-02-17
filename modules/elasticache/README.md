# ElastiCache Module

Deploys a production-ready Redis cluster with replication, encryption, and monitoring.

## Features

- Redis replication group with automatic failover
- Multi-AZ support
- Encryption at rest (KMS) and in transit (TLS)
- AUTH token support
- Optimized parameter group
- CloudWatch alarms (CPU, memory, evictions)
- Configurable persistence (AOF)
- Keyspace notifications
- Slow log tracking

## Usage

```hcl
module "redis" {
  source = "../../modules/elasticache"

  cluster_name = "myapp-prod"
  environment  = "prod"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.database_subnet_ids

  engine_version     = "7.1"
  node_type          = "cache.r6g.large"
  num_cache_clusters = 3

  multi_az_enabled           = true
  transit_encryption_enabled = true

  snapshot_retention_limit = 14

  allowed_security_group_ids = [
    module.ecs.service_security_group_ids["api"]
  ]

  alarm_actions = [module.monitoring.sns_topic_arn]

  maxmemory_policy = "allkeys-lru"
}
```
