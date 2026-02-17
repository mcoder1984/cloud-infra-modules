# EKS Cluster Module

Deploys a production-grade Amazon EKS cluster with managed node groups, IRSA, and essential add-ons.

## Features

- EKS cluster with configurable Kubernetes version
- Managed node groups with auto-scaling
- IRSA (IAM Roles for Service Accounts) via OIDC
- Essential add-ons: CoreDNS, kube-proxy, VPC-CNI, EBS CSI
- Secrets encryption with KMS
- Full control plane logging
- Private and public API endpoint configuration
- VPC CNI prefix delegation support

## Usage

```hcl
module "eks" {
  source = "../../modules/eks-cluster"

  cluster_name       = "myapp-prod"
  cluster_version    = "1.29"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["203.0.113.0/24"]  # Office IP

  node_groups = {
    general = {
      instance_types = ["m6i.xlarge", "m5.xlarge"]
      desired_size   = 3
      max_size       = 10
      min_size       = 2
      capacity_type  = "ON_DEMAND"
    }
    spot = {
      instance_types = ["m6i.xlarge", "m5.xlarge", "m6a.xlarge"]
      desired_size   = 2
      max_size       = 20
      min_size       = 0
      capacity_type  = "SPOT"
      labels = {
        "workload-type" = "non-critical"
      }
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  enable_ebs_csi_driver    = true
  enable_prefix_delegation = true
}
```
