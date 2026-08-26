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