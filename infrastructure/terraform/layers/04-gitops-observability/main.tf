terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }

  backend "s3" {
    # Backend configuration is provided via -backend-config during terraform init
  }
}

# Data sources from previous phases
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/01-foundation/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/02-cluster/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "autoscaling" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/03-autoscaling/terraform.tfstate"
    region = var.aws_region
  }
}

# Provider configurations
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.cluster.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.terraform_remote_state.cluster.outputs.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.cluster.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.terraform_remote_state.cluster.outputs.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

provider "kubectl" {
  host                   = data.terraform_remote_state.cluster.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.terraform_remote_state.cluster.outputs.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

# Local values
locals {
  cluster_name = data.terraform_remote_state.cluster.outputs.cluster_name

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Phase       = "04-gitops-observability"
  }
}

# ArgoCD Module
module "argocd" {
  source = "./modules/argocd"

  cluster_name            = local.cluster_name
  cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  oidc_provider_arn       = data.terraform_remote_state.cluster.outputs.oidc_provider_arn
  environment             = var.environment

  # ArgoCD Configuration
  argocd_chart_version  = var.argocd_chart_version
  argocd_admin_password = var.argocd_admin_password
  argocd_github_org     = var.argocd_github_org
  argocd_github_repo    = var.argocd_github_repo
  argocd_github_token   = var.argocd_github_token

  tags = local.common_tags
}

# Prometheus Stack Module
module "prometheus_stack" {
  source = "./modules/prometheus-stack"

  cluster_name            = local.cluster_name
  cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  oidc_provider_arn       = data.terraform_remote_state.cluster.outputs.oidc_provider_arn
  environment             = var.environment

  # Prometheus Configuration
  prometheus_chart_version  = var.prometheus_chart_version
  grafana_admin_password    = var.grafana_admin_password
  prometheus_retention_days = var.prometheus_retention_days

  # Storage Configuration
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size    = var.grafana_storage_size

  tags = local.common_tags
}

# Jaeger Module
module "jaeger" {
  source = "./modules/jaeger"

  cluster_name            = local.cluster_name
  cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  oidc_provider_arn       = data.terraform_remote_state.cluster.outputs.oidc_provider_arn
  environment             = var.environment

  # Jaeger Configuration
  jaeger_chart_version  = var.jaeger_chart_version
  jaeger_retention_days = var.jaeger_retention_days
  jaeger_storage_size   = var.jaeger_storage_size

  tags = local.common_tags
}

# Loki Enhancement Module (extends existing monitoring)
module "loki_enhancement" {
  source = "./modules/loki-enhancement"

  cluster_name = local.cluster_name
  environment  = var.environment

  # Loki Configuration
  loki_retention_days = var.loki_retention_days
  loki_storage_size   = var.loki_storage_size

  tags = local.common_tags
}

# GitOps Bootstrap Module
module "gitops_bootstrap" {
  source = "./modules/gitops-bootstrap"

  cluster_name = local.cluster_name
  environment  = var.environment

  # GitOps Repository Configuration
  gitops_repo_url    = var.gitops_repo_url
  gitops_repo_branch = var.gitops_repo_branch
  gitops_repo_path   = var.gitops_repo_path

  # Wait for ArgoCD to be ready
  depends_on = [module.argocd]

  tags = local.common_tags
}
