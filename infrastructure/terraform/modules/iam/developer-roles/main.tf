# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Developer base role
resource "aws_iam_role" "developer_base" {
  name = "EKS-Developer-Base-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principal_arns
        }
        Condition = var.external_id != null ? {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        } : {}
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "EKS-Developer-Base-${var.environment}"
    Environment = var.environment
    Module      = "iam/developer-roles"
    ManagedBy   = "terraform"
  })
}

# Developer EKS access policy
resource "aws_iam_policy" "developer_eks_access" {
  name        = "EKS-Developer-Access-${var.environment}"
  description = "Base EKS access policy for developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeUpdate",
          "eks:ListUpdates",
          "eks:DescribeAddon",
          "eks:ListAddons",
          "eks:DescribeAddonVersions"
        ]
        Resource = [
          "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}*",
          "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:nodegroup/${var.cluster_name}/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "EKS-Developer-Access-${var.environment}"
    Environment = var.environment
    Module      = "iam/developer-roles"
    ManagedBy   = "terraform"
  })
}

# Developer ECR access policy
resource "aws_iam_policy" "developer_ecr_access" {
  name        = "EKS-Developer-ECR-Access-${var.environment}"
  description = "ECR access policy for developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_prefix}*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "EKS-Developer-ECR-Access-${var.environment}"
    Environment = var.environment
    Module      = "iam/developer-roles"
    ManagedBy   = "terraform"
  })
}

# Developer IRSA assume role policy
resource "aws_iam_policy" "developer_irsa_assume" {
  name        = "EKS-Developer-IRSA-Assume-${var.environment}"
  description = "Policy to allow developers to assume IRSA roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/EKS-${var.cluster_name}-ServiceAccount-*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "EKS-Developer-IRSA-Assume-${var.environment}"
    Environment = var.environment
    Module      = "iam/developer-roles"
    ManagedBy   = "terraform"
  })
}

# Attach policies to developer base role
resource "aws_iam_role_policy_attachment" "developer_eks_access" {
  role       = aws_iam_role.developer_base.name
  policy_arn = aws_iam_policy.developer_eks_access.arn
}

resource "aws_iam_role_policy_attachment" "developer_ecr_access" {
  role       = aws_iam_role.developer_base.name
  policy_arn = aws_iam_policy.developer_ecr_access.arn
}

resource "aws_iam_role_policy_attachment" "developer_irsa_assume" {
  role       = aws_iam_role.developer_base.name
  policy_arn = aws_iam_policy.developer_irsa_assume.arn
}

# Attach additional policies if provided
resource "aws_iam_role_policy_attachment" "developer_additional_policies" {
  count      = length(var.additional_policy_arns)
  role       = aws_iam_role.developer_base.name
  policy_arn = var.additional_policy_arns[count.index]
}

# Create environment-specific developer roles
resource "aws_iam_role" "developer_readonly" {
  count = var.create_readonly_role ? 1 : 0
  name  = "EKS-Developer-ReadOnly-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principal_arns
        }
        Condition = var.external_id != null ? {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        } : {}
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "EKS-Developer-ReadOnly-${var.environment}"
    Environment = var.environment
    Module      = "iam/developer-roles"
    ManagedBy   = "terraform"
  })
}

# Read-only policy for developers
resource "aws_iam_policy" "developer_readonly_policy" {
  count       = var.create_readonly_role ? 1 : 0
  name        = "EKS-Developer-ReadOnly-Policy-${var.environment}"
  description = "Read-only access policy for developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeUpdate",
          "eks:ListUpdates",
          "eks:DescribeAddon",
          "eks:ListAddons",
          "eks:DescribeAddonVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "EKS-Developer-ReadOnly-Policy-${var.environment}"
    Environment = var.environment
    Module      = "iam/developer-roles"
    ManagedBy   = "terraform"
  })
}

# Attach read-only policy
resource "aws_iam_role_policy_attachment" "developer_readonly_policy" {
  count      = var.create_readonly_role ? 1 : 0
  role       = aws_iam_role.developer_readonly[0].name
  policy_arn = aws_iam_policy.developer_readonly_policy[0].arn
}