terraform {
  required_version = ">= 1.10.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
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
