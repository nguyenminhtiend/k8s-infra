# Local Foundation Layer - LocalStack Configuration
# This layer creates the basic networking infrastructure using LocalStack

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }
  }

  # Local backend for testing
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Configure AWS provider for LocalStack
provider "aws" {
  region                      = var.aws_region
  access_key                 = "test"
  secret_key                 = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2            = "http://localhost:4566"
    s3             = "http://localhost:4566"
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
    kms            = "http://localhost:4566"
  }
}

# VPC module - local version
module "vpc" {
  source = "../../../modules/networking/vpc"

  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  cluster_name = var.cluster_name
}

# Subnets module - local version  
module "subnets" {
  source = "../../../modules/networking/subnets"

  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = module.vpc.vpc_cidr_block
  cluster_name               = var.cluster_name
  enable_nat_gateway         = var.enable_nat_gateway
  single_nat_gateway         = var.single_nat_gateway
  use_public_subnets_for_eks = var.use_public_subnets_for_eks
  internet_gateway_id        = module.vpc.internet_gateway_id
}

# Security groups module - local version
module "security_groups" {
  source = "../../../modules/networking/security-groups"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr_block
}