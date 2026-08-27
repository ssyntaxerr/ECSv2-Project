module "vpc" {
  source = "./modules/vpc"

  aws_region           = var.aws_region
  name_prefix          = local.name_prefix
  common_tags          = local.common_tags
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
}

module "sqs" {
  source = "./modules/sqs"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

module "alb" {
  source = "./modules/alb"

  name_prefix       = local.name_prefix
  common_tags       = local.common_tags
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  certificate_arn = data.aws_acm_certificate.main.arn
}

module "ecs_security" {
  source = "./modules/ecs_security"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.alb.security_group_id
}

module "rds" {
  source = "./modules/rds"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs_security.ecs_security_group_id

  db_username = var.db_username
  db_password = var.db_password
}

module "redis" {
  source = "./modules/redis"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs_security.ecs_security_group_id
}

module "secrets" {
  source = "./modules/secrets"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  db_endpoint = module.rds.db_endpoint
  db_port     = module.rds.db_port
  db_name     = module.rds.db_name

  db_username = var.db_username
  db_password = var.db_password
}

module "iam" {
  source = "./modules/iam"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  queue_arn           = module.sqs.queue_arn
  postgres_secret_arn = module.secrets.postgres_secret_arn
}

module "ecs" {
  source = "./modules/ecs"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
  aws_region  = var.aws_region

  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs_security.ecs_security_group_id

  api_image       = "${data.aws_ecr_repository.api.repository_url}:v1"
  worker_image    = "${data.aws_ecr_repository.worker.repository_url}:v1"
  dashboard_image = "${data.aws_ecr_repository.dashboard.repository_url}:v1"

  execution_role_arn      = module.iam.ecs_execution_role_arn
  api_task_role_arn       = module.iam.api_task_role_arn
  worker_task_role_arn    = module.iam.worker_task_role_arn
  dashboard_task_role_arn = module.iam.dashboard_task_role_arn

  postgres_secret_arn = module.secrets.postgres_secret_arn

  sqs_queue_url = module.sqs.queue_url

  redis_endpoint = module.redis.redis_endpoint
  redis_port     = module.redis.redis_port

  base_url = var.base_url

  api_target_group_arn       = module.alb.api_target_group_arn
  dashboard_target_group_arn = module.alb.dashboard_target_group_arn
}

module "waf" {
  source = "./modules/waf"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  alb_arn = module.alb.alb_arn
}

resource "cloudflare_dns_record" "root" {
  zone_id = data.cloudflare_zone.main.id

  name    = "@"
  type    = "CNAME"
  content = module.alb.alb_dns_name

  proxied = false
  ttl     = 120
}