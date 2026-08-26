module "vpc" {
  source = "./modules/vpc"

  aws_region = var.aws_region
  name_prefix = local.name_prefix
  common_tags = local.common_tags
  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs = var.public_subnet_cidrs
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
  repositories = var.repositories
}

module "sqs" {
  source = "./modules/sqs"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

module "alb" {
  source = "./modules/alb"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  certificate_arn = var.certificate_arn
}

module "ecs_security" {
  source = "./modules/ecs_security"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_id = module.vpc.vpc_id
  alb_security_group_id = module.alb.security_group_id
}

module "rds" {
  source = "./modules/rds"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs_security.ecs_security_group_id

  db_username = var.db_username
  db_password = var.db_password
}