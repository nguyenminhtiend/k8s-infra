terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    # Backend configuration will be provided during terraform init
    # Example:
    # bucket = "your-terraform-state-bucket"
    # key    = "testing/02-cluster/terraform.tfstate"
    # region = "ap-southeast-1"
    # encrypt = true
    # dynamodb_table = "terraform-state-lock"
  }
}