# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS key for EKS cluster encryption (disabled for testing environment to save costs)
resource "aws_kms_key" "eks_cluster_key" {
  count = var.environment != "testing" ? 1 : 0

  description             = "KMS key for EKS cluster ${var.cluster_name} encryption"
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    Name        = "EKS-ClusterKey-${var.cluster_name}"
    Environment = var.environment
    Module      = "eks/cluster"
    ManagedBy   = "terraform"
  })
}

resource "aws_kms_alias" "eks_cluster_key_alias" {
  count = var.environment != "testing" ? 1 : 0

  name          = "alias/eks-cluster-${var.cluster_name}"
  target_key_id = aws_kms_key.eks_cluster_key[0].key_id
}

# CloudWatch Log Group for EKS cluster
resource "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name        = "EKS-ClusterLogGroup-${var.cluster_name}"
    Environment = var.environment
    Module      = "eks/cluster"
    ManagedBy   = "terraform"
  })
}

# EKS Cluster
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = var.cluster_service_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.enable_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.security_group_ids
  }

  # Only enable encryption for non-testing environments
  dynamic "encryption_config" {
    for_each = var.environment != "testing" ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks_cluster_key[0].arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster_log_group,
  ]

  tags = merge(var.tags, {
    Name        = var.cluster_name
    Environment = var.environment
    Module      = "eks/cluster"
    ManagedBy   = "terraform"
  })
}

# EKS Pod Identity Add-on (replaces OIDC/IRSA)
resource "aws_eks_addon" "pod_identity" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_cluster.cluster
  ]

  tags = merge(var.tags, {
    Name        = "EKS-Addon-PodIdentity-${var.cluster_name}"
    Environment = var.environment
    Module      = "eks/cluster"
    ManagedBy   = "terraform"
  })
}

# OIDC Identity Provider for IRSA (kept for backward compatibility)
data "tls_certificate" "eks_cluster_tls" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster_tls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name        = "EKS-OIDC-Provider-${var.cluster_name}"
    Environment = var.environment
    Module      = "eks/cluster"
    ManagedBy   = "terraform"
  })
}

# EKS Add-ons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = var.vpc_cni_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = var.vpc_cni_service_account_role_arn

  tags = merge(var.tags, {
    Name        = "EKS-Addon-VPC-CNI-${var.cluster_name}"
    Environment = var.environment
    Module      = "eks/cluster"
    ManagedBy   = "terraform"
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_addon.vpc_cni,
  ]

  tags = merge(var.tags, {
    Name        = "EKS-Addon-CoreDNS-${var.cluster_name}"
    Environment = var.environment
    Module      = "eks/cluster"
    ManagedBy   = "terraform"
  })
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "kube-proxy"
  addon_version               = var.kube_proxy_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.tags, {
    Name        = "EKS-Addon-KubeProxy-${var.cluster_name}"
    Environment = var.environment
    Module      = "eks/cluster"
    ManagedBy   = "terraform"
  })
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.ebs_csi_driver_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = var.ebs_csi_service_account_role_arn

  tags = merge(var.tags, {
    Name        = "EKS-Addon-EBS-CSI-Driver-${var.cluster_name}"
    Environment = var.environment
    Module      = "eks/cluster"
    ManagedBy   = "terraform"
  })
}
