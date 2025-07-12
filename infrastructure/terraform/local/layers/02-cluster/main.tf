# Local Cluster Layer - LocalStack EKS Configuration
# This layer creates a simulated EKS cluster using LocalStack

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
    eks            = "http://localhost:4566"
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
    kms            = "http://localhost:4566"
  }
}

# Data source for foundation layer outputs
data "terraform_remote_state" "foundation" {
  backend = "local"
  config = {
    path = "../01-foundation/terraform.tfstate"
  }
}

# Local values
locals {
  cluster_name = "${var.project_name}-${var.environment}"
  
  # Simplified node group configuration for local testing
  node_group_configs = {
    local = {
      instance_types = ["t3.micro"]
      capacity_type  = "ON_DEMAND"
      min_size      = 1
      max_size      = 2
      desired_size  = 1
      disk_size     = 20
      ami_type      = "AL2_x86_64"
    }
  }
}

# IAM role for EKS cluster
resource "aws_iam_role" "cluster_role" {
  name = "eks-cluster-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# IAM role for EKS node group
resource "aws_iam_role" "node_role" {
  name = "eks-node-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach required policies to node role
resource "aws_iam_role_policy_attachment" "node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

# CloudWatch Log Group for EKS cluster (simplified for local testing)
resource "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 7  # Reduced retention for local testing

  tags = {
    Name        = "EKS-ClusterLogGroup-${local.cluster_name}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# EKS Cluster (simplified for local testing)
resource "aws_eks_cluster" "cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = data.terraform_remote_state.foundation.outputs.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]  # Open for local testing
  }

  enabled_cluster_log_types = ["api", "audit"]  # Reduced logging for local testing

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.eks_cluster_log_group,
  ]

  tags = {
    Name        = local.cluster_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# EKS Node Group (simplified for local testing)
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${local.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = data.terraform_remote_state.foundation.outputs.subnet_ids

  capacity_type  = local.node_group_configs.local.capacity_type
  instance_types = local.node_group_configs.local.instance_types
  ami_type       = local.node_group_configs.local.ami_type
  disk_size      = local.node_group_configs.local.disk_size

  scaling_config {
    desired_size = local.node_group_configs.local.desired_size
    max_size     = local.node_group_configs.local.max_size
    min_size     = local.node_group_configs.local.min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.registry_policy,
  ]

  tags = {
    Name        = "${local.cluster_name}-nodes"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}