terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }

  backend "s3" {
    # Backend configuration provided via CLI
    # bucket  = "your-terraform-state-bucket"
    # key     = "testing/04-gitops-observability/terraform.tfstate"
    # region  = "ap-southeast-1"
    # encrypt = true
    # dynamodb_table = "terraform-state-lock-eks"
  }
}
