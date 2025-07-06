terraform {
  required_version = ">= 1.10.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
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