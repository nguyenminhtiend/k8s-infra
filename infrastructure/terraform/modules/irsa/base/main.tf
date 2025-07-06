# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Extract OIDC provider URL without https://
locals {
  oidc_provider_url = replace(var.cluster_oidc_issuer_url, "https://", "")
}

# IAM role for service account
resource "aws_iam_role" "service_account_role" {
  name = "EKS-${var.cluster_name}-SA-${var.service_account_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name           = "EKS-${var.cluster_name}-SA-${var.service_account_name}"
    Environment    = var.environment
    Cluster        = var.cluster_name
    Namespace      = var.namespace
    ServiceAccount = var.service_account_name
    Module         = "irsa/base"
    ManagedBy      = "terraform"
  })
}

# Attach IAM policies to the service account role
resource "aws_iam_role_policy_attachment" "service_account_policy" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.service_account_role.name
  policy_arn = var.policy_arns[count.index]
}

# Optional: Create custom inline policy if provided
resource "aws_iam_role_policy" "service_account_inline_policy" {
  count  = var.inline_policy_json != null ? 1 : 0
  name   = "inline-policy-${var.service_account_name}"
  role   = aws_iam_role.service_account_role.id
  policy = var.inline_policy_json
}
