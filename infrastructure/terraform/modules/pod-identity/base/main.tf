# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM role for Pod Identity
resource "aws_iam_role" "pod_identity_role" {
  name = "EKS-${var.cluster_name}-PodIdentity-${var.service_account_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name           = "EKS-${var.cluster_name}-PodIdentity-${var.service_account_name}"
    Environment    = var.environment
    Cluster        = var.cluster_name
    Namespace      = var.namespace
    ServiceAccount = var.service_account_name
    Module         = "pod-identity/base"
    ManagedBy      = "terraform"
  })
}

# Attach IAM policies to the Pod Identity role
resource "aws_iam_role_policy_attachment" "pod_identity_policy" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.pod_identity_role.name
  policy_arn = var.policy_arns[count.index]
}

# Optional: Create custom inline policy if provided
resource "aws_iam_role_policy" "pod_identity_inline_policy" {
  count  = var.inline_policy_json != null ? 1 : 0
  name   = "inline-policy-${var.service_account_name}"
  role   = aws_iam_role.pod_identity_role.id
  policy = var.inline_policy_json
}

# EKS Pod Identity Association
resource "aws_eks_pod_identity_association" "pod_identity_association" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.pod_identity_role.arn

  tags = merge(var.tags, {
    Name           = "EKS-${var.cluster_name}-PodIdentity-${var.service_account_name}"
    Environment    = var.environment
    Cluster        = var.cluster_name
    Namespace      = var.namespace
    ServiceAccount = var.service_account_name
    Module         = "pod-identity/base"
    ManagedBy      = "terraform"
  })
}
