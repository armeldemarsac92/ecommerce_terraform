locals {
  project_url  = "epitechproject.fr"
  project_name = "tdev700"
  domains = [
    "${local.project_url}",
    "api.${local.project_url}",
    "auth.${local.project_url}"
  ]
}

# Data source for external DNS zone
data "aws_route53_zone" "external" {
  name = "${local.project_url}."
}

#provider settings
provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# VPC Module
module "vpc" {
  source       = "./modules/vpc"
  project_name = local.project_name
}

# Load Balancer Module
module "load_balancer" {
  source                     = "./modules/load_balancer"
  project_name               = local.project_name
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  domains                    = local.domains
  external_dns_zone_id       = data.aws_route53_zone.external.zone_id
  api_security_group_id      = module.ecs.api_security_group_id
  auth_security_group_id     = module.ecs.auth_security_group_id
  frontend_security_group_id = module.ecs.frontend_security_group_id
}

# Database Module
module "database" {
  source                 = "./modules/database"
  project_name           = local.project_name
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_subnet_ids     = module.vpc.private_subnet_ids
  internal_dns_zone_name = "internal.${local.project_url}"
  database_host_name     = "db.internal.${local.project_url}"
  database_name          = "${local.project_name}-db"
}

# ECS Module
module "ecs" {
  source                     = "./modules/ecs"
  project_name               = local.project_name
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  load_balancer_id           = module.load_balancer.load_balancer_id
  load_balancer_arn          = module.load_balancer.load_balancer_arn
  load_balancer_dns_name     = module.load_balancer.load_balancer_dns_name
  load_balancer_zone_id      = module.load_balancer.load_balancer_zone_id
  target_group_arns          = module.load_balancer.target_group_arns
  https_listener_arn         = module.load_balancer.https_listener_arn
  domain_records             = module.load_balancer.domain_records
  database_security_group_id = module.database.security_group_id
}

# Bastion Module
module "bastion" {
  source                     = "./modules/bastion"
  project_name               = local.project_name
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  route53_zone_id            = data.aws_route53_zone.external.zone_id
  bastion_host_name          = "bastion.${local.project_url}"
  database_security_group_id = module.database.security_group_id
}