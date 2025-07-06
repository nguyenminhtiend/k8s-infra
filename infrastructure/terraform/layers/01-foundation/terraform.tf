terraform {
  required_version = ">= 1.10.3"

  backend "s3" {
    bucket         = "terraform-state-eks-1751637494"
    key            = "eks/01-foundation/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock-eks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83"
    }
  }
}

provider "aws" {
  region = var.aws_region
}