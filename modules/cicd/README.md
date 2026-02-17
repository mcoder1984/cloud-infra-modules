# CI/CD Module

Deploys AWS CodePipeline with CodeBuild for automated build and deployment workflows.

## Features

- CodePipeline V2 with CodeStar source connections
- CodeBuild with VPC access and Docker support
- S3 artifact bucket with encryption and lifecycle
- Pipeline notifications via SNS
- Least-privilege IAM roles
- Build caching for faster builds
- JUnit test report integration

## Usage

```hcl
module "cicd" {
  source = "../../modules/cicd"

  project_name            = "myapp"
  environment             = "prod"
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  codestar_connection_arn = "arn:aws:codestar-connections:us-east-1:123456789:connection/abc-123"

  build_projects = {
    api = {
      description   = "Build API service"
      compute_type  = "BUILD_GENERAL1_MEDIUM"
      timeout       = 20
      environment_variables = {
        SERVICE_NAME = "api"
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
          ClusterName = "myapp-prod"
          ServiceName = "api"
        }
      }
    }
  }

  notification_topic_arn = module.monitoring.sns_topic_arn
}
```
