terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  tags = merge(
    { Project = var.name_prefix },
    var.tags
  )
}

module "vpc" {
  source      = "./modules/vpc"
  name_prefix = var.name_prefix
  vpc_cidr    = var.vpc_cidr
  tags        = local.tags
}

module "subnets" {
  source      = "./modules/subnets"
  name_prefix = var.name_prefix
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = var.vpc_cidr
  azs         = local.azs
  tags        = local.tags
}

module "nat" {
  source           = "./modules/nat"
  name_prefix      = var.name_prefix
  public_subnet_id = module.subnets.public_subnet_ids[0]
  tags             = local.tags
}

module "rt" {
  source                = "./modules/rt"
  name_prefix           = var.name_prefix
  vpc_id                = module.vpc.vpc_id
  igw_id                = module.vpc.igw_id
  nat_gateway_id        = module.nat.nat_gateway_id
  public_subnet_ids     = module.subnets.public_subnet_ids
  private_subnet_ids    = module.subnets.private_subnet_ids
  public_subnet_count   = var.az_count
  private_subnet_count  = var.az_count
  tags                  = local.tags
}

module "sg" {
  source            = "./modules/sg"
  name_prefix       = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  tags              = local.tags
}

module "ec2" {
  source             = "./modules/ec2"
  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.subnets.private_subnet_ids
  private_subnet_ids = module.subnets.private_subnet_ids
  instance_count     = var.instance_count
  instance_type      = var.instance_type
  key_name           = var.key_name
  ec2_sg_id          = module.sg.ec2_sg_id
  tags               = local.tags
}

module "alb" {
  source             = "./modules/alb"
  name               = "${var.name_prefix}-alb"
  vpc_id             = module.vpc.vpc_id
  security_groups    = [module.sg.alb_sg_id]
  subnets            = module.subnets.public_subnet_ids
  listener_port      = 80
  target_group_name  = "${var.name_prefix}-tg"
  target_group_port  = 8080
  target_ids         = module.ec2.instance_ids
  target_count       = var.instance_count
  health_check_path  = "/"
  tags               = local.tags
}
