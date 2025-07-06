# Data sources for remote state from Layer 1
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "eks/01-foundation/terraform.tfstate"
    region = var.aws_region
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get latest EKS optimized AMI
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.kubernetes_version}-v*"]
  }
  most_recent = true
  owners      = ["amazon"]
}

# Local values
locals {
  cluster_name = "${var.project_name}-${var.environment}"

  # Environment-specific node group configurations
  node_group_configs = {
    testing = {
      instance_types = ["t3.micro"]
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      disk_size      = 20
    }
    staging = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      max_size       = 3
      min_size       = 2
      disk_size      = 30
    }
    production = {
      instance_types = ["t3.medium", "t3.large"]
      desired_size   = 3
      max_size       = 5
      min_size       = 2
      disk_size      = 50
    }
  }

  current_config = local.node_group_configs[var.environment]

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Layer       = "02-cluster"
    ManagedBy   = "terraform"
  }
}

# Step 1: IAM Service Roles (must be created first)
module "iam_service_roles" {
  source = "../../modules/iam/service-roles"

  environment = var.environment

  tags = local.common_tags
}

# Step 2: EKS Cluster (uses IAM service roles)
module "eks_cluster" {
  source = "../../modules/eks/cluster"

  cluster_name             = local.cluster_name
  environment              = var.environment
  cluster_service_role_arn = module.iam_service_roles.cluster_service_role_arn
  kubernetes_version       = var.kubernetes_version

  # VPC Configuration from Layer 1
  subnet_ids         = data.terraform_remote_state.foundation.outputs.eks_node_subnet_ids
  security_group_ids = [data.terraform_remote_state.foundation.outputs.cluster_security_group_id]

  # API endpoint configuration
  enable_public_access = var.enable_public_access
  public_access_cidrs  = var.public_access_cidrs

  # Logging configuration
  enabled_cluster_log_types = var.enabled_cluster_log_types
  log_retention_days        = var.log_retention_days

  # Add-on versions
  vpc_cni_version        = var.vpc_cni_version
  coredns_version        = var.coredns_version
  kube_proxy_version     = var.kube_proxy_version
  ebs_csi_driver_version = var.ebs_csi_driver_version

  tags = local.common_tags

  depends_on = [module.iam_service_roles]
}

# Step 3: EKS Node Groups (uses IAM instance profile)
module "eks_node_groups" {
  source = "../../modules/eks/node-groups"

  cluster_name        = module.eks_cluster.cluster_name
  environment         = var.environment
  node_group_role_arn = module.iam_service_roles.node_group_role_arn

  # VPC Configuration
  subnet_ids         = data.terraform_remote_state.foundation.outputs.eks_node_subnet_ids
  security_group_ids = [data.terraform_remote_state.foundation.outputs.node_security_group_id]

  # Environment-specific configuration
  instance_types = local.current_config.instance_types
  desired_size   = local.current_config.desired_size
  max_size       = local.current_config.max_size
  min_size       = local.current_config.min_size
  disk_size      = local.current_config.disk_size

  # Use latest EKS optimized AMI
  ami_id = data.aws_ami.eks_worker.id

  # System workload configuration
  enable_system_taints = var.enable_system_taints

  # Node labels
  labels = {
    Environment = var.environment
    NodeType    = "system"
  }

  tags = local.common_tags

  depends_on = [
    module.iam_service_roles,
    module.eks_cluster
  ]
}

# Step 4: IRSA Base (uses OIDC from EKS cluster)
module "irsa_base_example" {
  source = "../../modules/irsa/base"

  cluster_name            = module.eks_cluster.cluster_name
  environment             = var.environment
  cluster_oidc_issuer_url = module.eks_cluster.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks_cluster.oidc_provider_arn

  # Example service account for testing IRSA
  service_account_name = "test-service-account"
  namespace            = "default"

  # No policies attached for this example
  policy_arns = []

  tags = local.common_tags

  depends_on = [module.eks_cluster]
}

# Step 5: Developer Roles (uses cluster info)
module "developer_roles" {
  source = "../../modules/iam/developer-roles"

  environment  = var.environment
  cluster_name = module.eks_cluster.cluster_name

  # Configure allowed principals (modify as needed)
  allowed_principal_arns = var.developer_principal_arns
  external_id            = var.developer_external_id

  # ECR repository configuration
  ecr_repository_prefix = var.ecr_repository_prefix

  # Create read-only role for junior developers
  create_readonly_role = var.create_readonly_role

  tags = local.common_tags

  depends_on = [module.eks_cluster]
}
