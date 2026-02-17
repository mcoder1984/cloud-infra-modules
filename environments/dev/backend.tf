# ------------------------------------------------------------------------------
# Terraform Backend Configuration - DEV
# ------------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    kms_key_id     = "alias/terraform-state"
  }
}
