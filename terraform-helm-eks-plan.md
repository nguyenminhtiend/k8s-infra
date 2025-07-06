# Terraform + Helm + EKS Implementation Plan (2025 Best Practices)

## Architecture Overview

This plan outlines the implementation of a production-ready EKS infrastructure using Terraform and Helm with modern best practices for 2025, including Karpenter for intelligent node provisioning and cost optimization.

## 1. Terraform Architecture - Layered Approach

### Terraform Module Structure

The architecture uses **reusable modules** consumed by **deployment layers**:

```
infrastructure/terraform/
├── modules/                           # Reusable modules
│   ├── iam/                          # IAM & Security modules
│   │   ├── developer-roles/
│   │   ├── github-oidc/
│   │   ├── service-roles/
│   │   └── cross-account-roles/
│   ├── irsa/                         # IRSA-specific modules
│   │   ├── base/
│   │   ├── s3-access/
│   │   ├── rds-access/
│   │   ├── secrets-access/
│   │   └── ecr-access/
│   ├── networking/                   # VPC & Networking
│   │   ├── vpc/
│   │   ├── subnets/
│   │   ├── security-groups/
│   │   └── vpc-endpoints/
│   ├── eks/                          # EKS components
│   │   ├── cluster/
│   │   ├── node-groups/
│   │   ├── addons/
│   │   └── oidc-provider/
│   ├── karpenter/                    # Karpenter modules
│   │   ├── controller/
│   │   ├── node-classes/
│   │   └── provisioners/
│   └── applications/                 # Application modules
│       ├── argocd/
│       ├── external-secrets/
│       ├── cert-manager/
│       └── monitoring/
└── layers/                           # Deployment layers
    ├── 01-foundation/
    ├── 02-cluster/
    ├── 03-autoscaling/
    └── 04-applications/
```

### IAM & Security Modules

#### Core IAM Module Structure

```hcl
# infrastructure/terraform/modules/iam/developer-roles/main.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "external_id" {
  description = "External ID for role assumption"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

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
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Module      = "iam/developer-roles"
  }
}

# Outputs
output "developer_base_role_arn" {
  description = "ARN of the developer base role"
  value       = aws_iam_role.developer_base.arn
}

output "developer_base_role_name" {
  description = "Name of the developer base role"
  value       = aws_iam_role.developer_base.name
}
```

#### IRSA Base Module

```hcl
# infrastructure/terraform/modules/irsa/base/main.tf
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach"
  type        = list(string)
  default     = []
}

data "aws_iam_openid_connect_provider" "eks" {
  url = var.cluster_oidc_issuer_url
}

locals {
  oidc_provider_arn = data.aws_iam_openid_connect_provider.eks.arn
}

resource "aws_iam_role" "service_account_role" {
  name = "EKS-${var.cluster_name}-ServiceAccount-${var.service_account_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "EKS-${var.cluster_name}-ServiceAccount-${var.service_account_name}"
    Environment = var.environment
    Namespace   = var.namespace
    Service     = var.service_account_name
    Module      = "irsa/base"
  }
}

resource "aws_iam_role_policy_attachment" "service_account_policy" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.service_account_role.name
  policy_arn = var.policy_arns[count.index]
}

# Outputs
output "role_arn" {
  description = "ARN of the IRSA role"
  value       = aws_iam_role.service_account_role.arn
}

output "role_name" {
  description = "Name of the IRSA role"
  value       = aws_iam_role.service_account_role.name
}
```

#### GitHub OIDC Module

```hcl
# infrastructure/terraform/modules/iam/github-oidc/main.tf
variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name        = "GitHub-OIDC-Provider"
    Environment = var.environment
    Module      = "iam/github-oidc"
  }
}

resource "aws_iam_role" "github_ci" {
  name = "EKS-GitHub-CI-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "EKS-GitHub-CI-${var.environment}"
    Environment = var.environment
    Module      = "iam/github-oidc"
  }
}

# Outputs
output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_ci_role_arn" {
  description = "ARN of the GitHub CI role"
  value       = aws_iam_role.github_ci.arn
}
```

### Deployment Layers

Now the layers consume these modules:

### Layer 1: Foundation Infrastructure

**Path**: `infrastructure/terraform/layers/01-foundation/`

- VPC with public/private subnets across 3 AZs
- Internet Gateway, NAT Gateways
- Security groups for EKS cluster and nodes
- Route tables and subnet associations
- VPC endpoints for cost optimization

**Uses modules**: `networking/vpc`, `networking/subnets`, `networking/security-groups`

### Layer 2: EKS Cluster & Core Components

**Path**: `infrastructure/terraform/layers/02-cluster/`

- EKS cluster with private endpoint
- System node group (on-demand, t3.medium)
- IRSA (IAM Roles for Service Accounts)
- EKS add-ons: vpc-cni, coredns, kube-proxy
- CloudWatch logging configuration

**Uses modules**: `eks/cluster`, `eks/node-groups`, `eks/oidc-provider`, `iam/developer-roles`

### Layer 3: Autoscaling & Load Balancing

**Path**: `infrastructure/terraform/layers/03-autoscaling/`

- Karpenter installation and configuration
- Karpenter node classes for different workload types
- AWS Load Balancer Controller
- External DNS controller
- Cluster Autoscaler (as fallback)

**Uses modules**: `karpenter/controller`, `karpenter/node-classes`, `irsa/base`

### Layer 4: Application Infrastructure

**Path**: `infrastructure/terraform/layers/04-applications/`

- ArgoCD installation
- External Secrets Operator
- Cert-manager for TLS certificates
- Application-specific resources (RDS, ElastiCache, etc.)

**Uses modules**: `applications/argocd`, `applications/external-secrets`, `iam/github-oidc`, `irsa/base`

## 2. EKS Node Strategy - Karpenter + Managed Node Groups

### System Node Group (Managed)

```yaml
Configuration:
  - Instance Types: t3.medium, t3.large
  - Capacity Type: ON_DEMAND
  - Min/Max/Desired: 2/5/3
  - Purpose: System pods, ArgoCD, monitoring
  - Taints: CriticalAddonsOnly=true:NoSchedule
```

### Karpenter Node Classes

#### General Purpose Nodes

```yaml
NodeClass: general-purpose
  - Instance Types: m5.large, m5.xlarge, m5.2xlarge, m6i.large, m6i.xlarge
  - Capacity Types: spot (80%), on-demand (20%)
  - Architecture: amd64
  - Subnets: private-subnets
  - Taints: none
```

#### Compute Optimized Nodes

```yaml
NodeClass: compute-optimized
  - Instance Types: c5.large, c5.xlarge, c5.2xlarge, c6i.large, c6i.xlarge
  - Capacity Types: spot (90%), on-demand (10%)
  - Architecture: amd64
  - Purpose: CPU-intensive workloads
```

#### Memory Optimized Nodes

```yaml
NodeClass: memory-optimized
  - Instance Types: r5.large, r5.xlarge, r5.2xlarge, r6i.large, r6i.xlarge
  - Capacity Types: spot (85%), on-demand (15%)
  - Architecture: amd64
  - Purpose: Memory-intensive workloads
```

### Cost Optimization Strategy

- **Target**: 70-80% spot instance usage
- **Savings**: 60-70% cost reduction
- **Resilience**: Multiple instance families, AZ distribution
- **Spot interruption**: Graceful handling with node termination handlers

## 3. Helm Management - ArgoCD GitOps

### ArgoCD Installation

**Method**: Terraform Helm provider for initial installation
**Path**: `infrastructure/terraform/layers/04-applications/argocd.tf`

### Application Management

**Pattern**: App-of-apps pattern
**Structure**:

```
environments/
├── development/
│   └── argocd/
│       ├── applications/
│       │   ├── microservices.yaml
│       │   ├── monitoring.yaml
│       │   └── security.yaml
│       └── projects/
└── production/
    └── argocd/
        ├── applications/
        └── projects/
```

### Helm Chart Strategy

- **Base charts**: Reusable templates in `infrastructure/helm/charts/`
- **Values**: Environment-specific in `infrastructure/helm/values/`
- **Custom charts**: Application-specific in `applications/*/helm/`

## 4. Security Implementation & IRSA

### IRSA (IAM Roles for Service Accounts) Architecture

IRSA enables Kubernetes pods to assume IAM roles without storing AWS credentials, providing secure, fine-grained access control.

**Architecture Flow**: `Pod → ServiceAccount → IAM Role → AWS Services`

**Key Components**:

- **OIDC Provider**: EKS cluster's OpenID Connect provider
- **Service Account**: Kubernetes service account with role annotation
- **IAM Role**: AWS IAM role with trust policy for OIDC
- **IAM Policy**: Specific permissions for AWS services

### Base IRSA Terraform Module

```hcl
# infrastructure/terraform/modules/irsa/main.tf
data "aws_iam_openid_connect_provider" "eks" {
  url = var.cluster_oidc_issuer_url
}

locals {
  oidc_provider_arn = data.aws_iam_openid_connect_provider.eks.arn
}

resource "aws_iam_role" "service_account_role" {
  name = "EKS-${var.cluster_name}-ServiceAccount-${var.service_account_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "EKS-${var.cluster_name}-ServiceAccount-${var.service_account_name}"
    Environment = var.environment
    Namespace   = var.namespace
    Service     = var.service_account_name
  }
}

resource "aws_iam_role_policy_attachment" "service_account_policy" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.service_account_role.name
  policy_arn = var.policy_arns[count.index]
}
```

### Developer IAM Roles

```hcl
# infrastructure/terraform/modules/iam/developer-roles.tf
resource "aws_iam_role" "developer_base" {
  name = "EKS-Developer-Base-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })
}

# Developer EKS access policy
resource "aws_iam_policy" "developer_eks_access" {
  name        = "EKS-Developer-Access-${var.environment}"
  description = "Base EKS access for developers"

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
          "eks:ListUpdates"
        ]
        Resource = [
          "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/EKS-*-ServiceAccount-*"
        ]
      }
    ]
  })
}
```

### GitHub CI/CD IRSA Setup

```hcl
# infrastructure/terraform/modules/iam/github-oidc.tf
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# GitHub Actions CI Role
resource "aws_iam_role" "github_ci" {
  name = "EKS-GitHub-CI-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# CI permissions policy
resource "aws_iam_policy" "github_ci_policy" {
  name        = "EKS-GitHub-CI-Policy-${var.environment}"
  description = "GitHub Actions CI permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = [
          "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/EKS-*-ServiceAccount-*"
        ]
      }
    ]
  })
}
```

### Pod-to-AWS Service Access Patterns

#### S3 Access Pattern

```hcl
# infrastructure/terraform/modules/irsa/s3-access.tf
resource "aws_iam_policy" "s3_bucket_access" {
  name        = "EKS-S3-Access-${var.service_name}"
  description = "S3 bucket access for ${var.service_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/${var.service_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}"
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = "${var.service_name}/*"
          }
        }
      }
    ]
  })
}

module "s3_irsa" {
  source = "../irsa"

  cluster_name             = var.cluster_name
  cluster_oidc_issuer_url = var.cluster_oidc_issuer_url
  service_account_name     = "service-a-sa"
  namespace               = "microservices"
  environment             = var.environment

  policy_arns = [
    aws_iam_policy.s3_bucket_access.arn
  ]
}
```

#### RDS Access Pattern

```hcl
# infrastructure/terraform/modules/irsa/rds-access.tf
resource "aws_iam_policy" "rds_access" {
  name        = "EKS-RDS-Access-${var.service_name}"
  description = "RDS access for ${var.service_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.db_instance_resource_id}/${var.db_username}"
        ]
      }
    ]
  })
}
```

#### Secrets Manager Access Pattern

```hcl
# infrastructure/terraform/modules/irsa/secrets-access.tf
resource "aws_iam_policy" "secrets_access" {
  name        = "EKS-Secrets-Access-${var.service_name}"
  description = "Secrets Manager access for ${var.service_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.service_name}/*"
        ]
      }
    ]
  })
}
```

### Service Account Kubernetes Manifests

```yaml
# applications/microservices/service-a/base/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: service-a-sa
  namespace: microservices
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/EKS-CLUSTER_NAME-ServiceAccount-service-a-sa
automountServiceAccountToken: true
```

### Security Best Practices

#### Principle of Least Privilege

```hcl
# Example: Service-specific minimal permissions
resource "aws_iam_policy" "minimal_service_policy" {
  name        = "EKS-Minimal-${var.service_name}"
  description = "Minimal permissions for ${var.service_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/${var.service_name}/config/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.service_name}/database-*"
        ]
      }
    ]
  })
}
```

#### Conditional Access

```hcl
# Time-based access for developers
resource "aws_iam_policy" "time_based_access" {
  name        = "EKS-Time-Based-Access"
  description = "Time-restricted access for developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
        Condition = {
          DateGreaterThan = {
            "aws:CurrentTime" = "08:00Z"
          }
          DateLessThan = {
            "aws:CurrentTime" = "18:00Z"
          }
          StringEquals = {
            "aws:RequestedRegion" = "ap-southeast-1"
          }
        }
      }
    ]
  })
}
```

### Monitoring & Auditing

```hcl
# CloudTrail for IRSA monitoring
resource "aws_cloudtrail" "irsa_audit" {
  name                          = "irsa-audit-${var.environment}"
  s3_bucket_name               = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.bucket_name}/*"]
    }
  }
}

# CloudWatch for role assumption monitoring
resource "aws_cloudwatch_log_group" "irsa_logs" {
  name              = "/aws/eks/${var.cluster_name}/irsa"
  retention_in_days = 30
}
```

### Traditional Security Layers

- **Pod Security Standards**: Restricted policy enforcement
- **Network Policies**: Calico CNI with policy enforcement
- **Private API endpoint**: EKS cluster in private subnets
- **Encryption**: EKS secrets encryption at rest
- **Security groups**: Least privilege principle
- **VPC Flow Logs**: Network traffic monitoring

### Karpenter Security

- **Node isolation**: Dedicated security groups per node class
- **IAM policies**: Least privilege for Karpenter controller
- **Spot interruption**: Secure handling of node termination

## 5. Monitoring & Observability

### Prometheus Stack

**Components**:

- Prometheus Operator
- Grafana with pre-built dashboards
- AlertManager for notifications
- Loki for log aggregation
- Fluent Bit for log collection

### Karpenter Monitoring

**Metrics**:

- Node provisioning time
- Spot interruption rates
- Cost optimization metrics
- Instance type utilization

### Custom Dashboards

- **Cost tracking**: Real-time spend analysis
- **Node efficiency**: Resource utilization
- **Application performance**: SLA monitoring
- **Security events**: Falco integration

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)

1. Create Terraform modules for Layer 1 (VPC, networking)
2. Implement Layer 2 (EKS cluster, system nodes)
3. Basic security setup (IRSA, security groups)
4. Testing and validation

### Phase 2: Autoscaling (Week 2)

1. Deploy Karpenter via Terraform
2. Configure node classes and provisioners
3. Install AWS Load Balancer Controller
4. Test spot instance handling

### Phase 3: GitOps (Week 3)

1. Install ArgoCD via Terraform
2. Configure app-of-apps pattern
3. Create base Helm charts
4. Set up environment-specific applications

### Phase 4: Production Hardening (Week 4)

1. Implement monitoring stack
2. Set up security scanning (Falco)
3. Configure backup and disaster recovery
4. Performance optimization and testing

## 7. Cost Optimization Features

### Immediate Savings

- **Spot instances**: 60-70% cost reduction
- **Right-sizing**: Karpenter automatic optimization
- **VPC endpoints**: Reduced NAT Gateway costs
- **Reserved instances**: For predictable system workloads

### Long-term Optimization

- **Auto-scaling**: Scale-to-zero for dev environments
- **Instance diversity**: Maximize spot availability
- **Workload-specific nodes**: Optimal instance types
- **Cost monitoring**: Real-time spend visibility

## 8. Disaster Recovery & Backup

### Cluster Backup

- **EKS cluster**: Configuration stored in Terraform state
- **Applications**: GitOps ensures reproducibility
- **Persistent data**: Regular EBS snapshots
- **Secrets**: AWS Secrets Manager replication

### Multi-AZ Resilience

- **Node distribution**: Across 3 availability zones
- **Spot diversification**: Multiple instance types
- **Data replication**: RDS Multi-AZ, ElastiCache clusters
- **Load balancing**: ALB with health checks

## 9. Development Workflow

### Local Developer Setup

#### AWS CLI Configuration

```bash
# ~/.aws/config
[default]
region = ap-southeast-1

[profile eks-dev]
role_arn = arn:aws:iam::ACCOUNT_ID:role/EKS-Developer-Dev
source_profile = default
external_id = your-external-id

[profile eks-prod]
role_arn = arn:aws:iam::ACCOUNT_ID:role/EKS-Developer-Prod
source_profile = default
external_id = your-external-id
```

#### kubeconfig Setup

```bash
# Update kubeconfig for development
aws eks update-kubeconfig --region ap-southeast-1 --name my-cluster-dev --profile eks-dev

# Update kubeconfig for production
aws eks update-kubeconfig --region ap-southeast-1 --name my-cluster-prod --profile eks-prod
```

#### Local Development Script

```bash
#!/bin/bash
# scripts/local-dev-setup.sh

set -e

ENVIRONMENT=${1:-development}
CLUSTER_NAME="my-cluster-${ENVIRONMENT}"
PROFILE="eks-${ENVIRONMENT}"

echo "Setting up local development for ${ENVIRONMENT}"

# Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name $CLUSTER_NAME --profile $PROFILE

# Verify access
kubectl auth can-i get pods --namespace=microservices

# Port forward services
kubectl port-forward svc/service-a 8080:80 --namespace=microservices &
kubectl port-forward svc/grafana 3000:80 --namespace=monitoring &

echo "Local development setup complete!"
echo "Service A: http://localhost:8080"
echo "Grafana: http://localhost:3000"
```

### GitHub Actions CI/CD Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy to EKS
on:
  push:
    branches: [main, develop]

env:
  AWS_REGION: ap-southeast-1
  EKS_CLUSTER_NAME: my-cluster

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/EKS-GitHub-CI-${{ github.ref_name }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --region ${{ env.AWS_REGION }} --name ${{ env.EKS_CLUSTER_NAME }}

      - name: Deploy to EKS
        run: |
          kubectl apply -k applications/microservices/service-a/overlays/${{ github.ref_name }}
```

### Local Development

```bash
# Set up local cluster
make local-setup

# Deploy applications
kubectl apply -k applications/microservices/service-a/overlays/local

# Port forwarding
make port-forward
```

### Environment Promotion

```bash
# Development
git push origin feature/new-service
# ArgoCD auto-deploys to dev

# Production
git push origin main
# ArgoCD auto-deploys to prod (with approvals)
```

## 10. Compliance & Governance

### Resource Tagging

- **Cost allocation**: Team, environment, project
- **Lifecycle management**: Automated cleanup
- **Compliance**: Data classification, retention
- **Monitoring**: Resource ownership tracking

### Access Control

- **RBAC**: Fine-grained Kubernetes permissions
- **IAM integration**: AWS IAM roles for teams
- **Audit logging**: EKS audit logs to CloudWatch
- **Secret rotation**: Automated certificate management

## 11. Troubleshooting & Debugging

### IRSA Issues

#### Debug Service Account Issues

```bash
# Check service account configuration
kubectl describe serviceaccount service-a-sa -n microservices

# Check if pod is using correct service account
kubectl get pods -n microservices -o yaml | grep -A 5 -B 5 serviceAccount

# Test AWS credentials in pod
kubectl exec -it pod-name -n microservices -- aws sts get-caller-identity
```

#### Role Assumption Problems

```bash
# Check trust policy
aws iam get-role --role-name EKS-CLUSTER_NAME-ServiceAccount-service-a-sa

# Verify OIDC provider
aws iam list-open-id-connect-providers

# Check EKS cluster OIDC issuer
aws eks describe-cluster --name CLUSTER_NAME --query cluster.identity.oidc.issuer
```

### Karpenter Issues

#### Node Provisioning Problems

```bash
# Check Karpenter logs
kubectl logs -l app.kubernetes.io/name=karpenter -n karpenter

# Check node class status
kubectl get ec2nodeclass

# Check node pool status
kubectl get nodepool
```

#### Spot Instance Interruptions

```bash
# Check for spot interruption events
kubectl get events --field-selector reason=SpotInterruption

# Check node termination handling
kubectl logs -l app.kubernetes.io/name=aws-node-termination-handler -n kube-system
```

### Common Fixes

#### IRSA Not Working

1. Verify OIDC provider exists and matches cluster
2. Check service account annotation format
3. Ensure IAM role trust policy includes correct conditions
4. Verify pod is using the correct service account

#### Karpenter Not Scaling

1. Check node class configuration
2. Verify security groups allow communication
3. Check subnet tags for discovery
4. Ensure IAM permissions for Karpenter

## 12. Implementation Checklist

### Phase 1: Foundation

- [ ] Set up Terraform state backend (S3 + DynamoDB)
- [ ] Create VPC and networking (Layer 1)
- [ ] Deploy EKS cluster with system node group (Layer 2)
- [ ] Configure OIDC provider for EKS cluster
- [ ] Set up base developer IAM roles
- [ ] Test local developer access

### Phase 2: Security & Access

- [ ] Create IRSA modules and policies
- [ ] Configure GitHub OIDC provider
- [ ] Deploy service accounts with IRSA annotations
- [ ] Set up External Secrets Operator
- [ ] Configure Pod Security Standards
- [ ] Test service-to-AWS access patterns

### Phase 3: Autoscaling & Load Balancing

- [ ] Deploy Karpenter (Layer 3)
- [ ] Configure node classes and provisioners
- [ ] Install AWS Load Balancer Controller
- [ ] Set up External DNS controller
- [ ] Test spot instance handling and scaling

### Phase 4: GitOps & Applications

- [ ] Install ArgoCD via Terraform (Layer 4)
- [ ] Configure app-of-apps pattern
- [ ] Create base Helm charts
- [ ] Set up environment-specific applications
- [ ] Test deployment workflows

### Phase 5: Monitoring & Observability

- [ ] Deploy Prometheus stack
- [ ] Configure Grafana dashboards
- [ ] Set up Loki for log aggregation
- [ ] Configure Fluent Bit for log collection
- [ ] Set up cost monitoring dashboards

### Phase 6: Security Hardening

- [ ] Configure network policies
- [ ] Set up Falco for runtime security
- [ ] Configure backup and disaster recovery
- [ ] Set up CloudTrail for audit logging
- [ ] Configure certificate management

### Phase 7: Testing & Validation

- [ ] Test disaster recovery procedures
- [ ] Validate security configurations
- [ ] Performance testing and optimization
- [ ] Create troubleshooting runbooks
- [ ] Document access patterns for team

### Phase 8: Production Readiness

- [ ] Configure monitoring alerts
- [ ] Set up on-call procedures
- [ ] Create deployment approval workflows
- [ ] Configure automated backups
- [ ] Final security review and compliance check

## Next Steps

1. **Review and approve** this implementation plan
2. **Set up Terraform state backend** (S3 + DynamoDB)
3. **Create initial Layer 1** terraform modules
4. **Begin Phase 1 implementation**

This comprehensive plan provides a robust, cost-effective, and scalable EKS infrastructure that aligns with 2025 best practices while maintaining operational excellence. The detailed IRSA implementation ensures secure, least-privilege access control for developers, CI/CD pipelines, and pod-to-AWS service interactions.
