locals {
  project     = "ecs-v2"
  environment = "dev"

  name_prefix = "${local.project}-${local.environment}"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}