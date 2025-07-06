data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/networking/vpc"

  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  cluster_name = var.cluster_name
}

module "subnets" {
  source = "../../modules/networking/subnets"

  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = module.vpc.vpc_cidr_block
  cluster_name               = var.cluster_name
  enable_nat_gateway         = var.enable_nat_gateway
  single_nat_gateway         = var.single_nat_gateway
  use_public_subnets_for_eks = var.use_public_subnets_for_eks
  internet_gateway_id        = module.vpc.internet_gateway_id
}

module "security_groups" {
  source = "../../modules/networking/security-groups"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr_block
}