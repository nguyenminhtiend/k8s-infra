# =============================================================================
# PHASE 3: AUTOSCALING & LOAD BALANCING MAIN CONFIGURATION
# =============================================================================

# =============================================================================
# KARPENTER CONFIGURATION
# =============================================================================

# Karpenter Node IAM Instance Profile
resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  count = var.karpenter_enabled ? 1 : 0
  name  = "KarpenterNodeInstanceProfile-${var.environment}"
  role  = aws_iam_role.karpenter_node_role[0].name
}

# Karpenter Node IAM Role
resource "aws_iam_role" "karpenter_node_role" {
  count = var.karpenter_enabled ? 1 : 0
  name  = "KarpenterNodeRole-${var.environment}"

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

# Attach AWS managed policies to Karpenter node role
resource "aws_iam_role_policy_attachment" "karpenter_node_worker_policy" {
  count      = var.karpenter_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni_policy" {
  count      = var.karpenter_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_registry_policy" {
  count      = var.karpenter_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm_policy" {
  count      = var.karpenter_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node_role[0].name
}

# Karpenter Controller IAM Role
resource "aws_iam_role" "karpenter_controller_role" {
  count = var.karpenter_enabled ? 1 : 0
  name  = "KarpenterControllerRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = data.terraform_remote_state.cluster.outputs.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
            "${replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Karpenter Controller IAM Policy
resource "aws_iam_policy" "karpenter_controller_policy" {
  count = var.karpenter_enabled ? 1 : 0
  name  = "KarpenterControllerPolicy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "pricing:GetProducts",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteLaunchTemplateVersions"
        ]
        Resource = "arn:aws:ec2:*:*:launch-template/*"
        Condition = {
          StringEquals = {
            "ec2:LaunchTemplate/karpenter.sh/cluster" = data.terraform_remote_state.cluster.outputs.cluster_name
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = [
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:spot-instances-request/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = [
          "arn:aws:ec2:*:*:launch-template/*",
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:subnet/*",
          "arn:aws:ec2:*:*:image/*",
          "arn:aws:ec2:*:*:key-pair/*",
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:volume/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:TerminateInstances",
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/karpenter.sh/cluster" = data.terraform_remote_state.cluster.outputs.cluster_name
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::*:role/KarpenterNodeRole-${var.environment}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy" {
  count      = var.karpenter_enabled ? 1 : 0
  policy_arn = aws_iam_policy.karpenter_controller_policy[0].arn
  role       = aws_iam_role.karpenter_controller_role[0].name
}

# Karpenter Helm Release
resource "helm_release" "karpenter" {
  count      = var.karpenter_enabled ? 1 : 0
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version
  namespace  = "karpenter"

  create_namespace = true
  wait             = true
  timeout          = 300

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller_role[0].arn
  }

  set {
    name  = "settings.clusterName"
    value = data.terraform_remote_state.cluster.outputs.cluster_name
  }

  set {
    name  = "settings.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter_node_instance_profile[0].name
  }

  set {
    name  = "settings.interruptionQueue"
    value = aws_sqs_queue.karpenter_interruption_queue[0].name
  }

  depends_on = [
    aws_iam_role_policy_attachment.karpenter_controller_policy
  ]
}

# SQS Queue for Karpenter Interruption Handling
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  count = var.karpenter_enabled ? 1 : 0
  name  = "karpenter-interruption-queue-${var.environment}"
}

# EventBridge Rule for Spot Interruption
resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  count = var.karpenter_enabled ? 1 : 0
  name  = "karpenter-spot-interruption-${var.environment}"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
  count     = var.karpenter_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.karpenter_spot_interruption[0].name
  target_id = "KarpenterSpotInterruptionTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue[0].arn
}

# Karpenter NodePool Configuration
resource "kubernetes_manifest" "karpenter_nodepool" {
  count = var.karpenter_enabled ? 1 : 0

  depends_on = [helm_release.karpenter]

  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "default-nodepool"
    }
    spec = {
      template = {
        metadata = {
          labels = merge(
            {
              "node-type"   = "karpenter"
              "environment" = var.environment
            },
            var.node_labels
          )
        }
        spec = {
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = var.karpenter_node_capacity_type
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = var.karpenter_node_instance_types
            }
          ]
          nodeClassRef = {
            apiVersion = "karpenter.k8s.aws/v1beta1"
            kind       = "EC2NodeClass"
            name       = "default-nodeclass"
          }
          taints = var.node_taints
        }
      }
      limits = {
        cpu = var.karpenter_max_nodes * 4 # Assuming 4 vCPUs per node on average
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        consolidateAfter    = "${var.karpenter_ttl_seconds_after_empty}s"
        expireAfter         = "${var.karpenter_ttl_seconds_until_expired}s"
      }
    }
  }
}

# Karpenter EC2NodeClass Configuration
resource "kubernetes_manifest" "karpenter_nodeclass" {
  count = var.karpenter_enabled ? 1 : 0

  depends_on = [helm_release.karpenter]

  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default-nodeclass"
    }
    spec = {
      instanceStorePolicy = "NVMe"
      amiFamily           = "AL2"
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = data.terraform_remote_state.cluster.outputs.cluster_name
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = data.terraform_remote_state.cluster.outputs.cluster_name
          }
        }
      ]
      role = aws_iam_role.karpenter_node_role[0].name
      userData = base64encode(<<-EOT
        #!/bin/bash
        /etc/eks/bootstrap.sh ${data.terraform_remote_state.cluster.outputs.cluster_name}
        EOT
      )
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize = var.environment == "production" ? 50 : 20
            volumeType = "gp3"
            encrypted  = true
          }
        }
      ]
    }
  }
}

# =============================================================================
# AWS LOAD BALANCER CONTROLLER CONFIGURATION
# =============================================================================

# AWS Load Balancer Controller IAM Role
resource "aws_iam_role" "alb_controller_role" {
  count = var.alb_controller_enabled ? 1 : 0
  name  = "AWSLoadBalancerControllerRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = data.terraform_remote_state.cluster.outputs.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# AWS Load Balancer Controller IAM Policy
resource "aws_iam_policy" "alb_controller_policy" {
  count = var.alb_controller_enabled ? 1 : 0
  name  = "AWSLoadBalancerControllerPolicy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:GetManagedPrefixListEntries",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:DescribeProtection",
          "shield:GetSubscriptionState",
          "shield:DescribeSubscription",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestedRegion" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          Null = {
            "aws:RequestedRegion"                   = "false"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestedRegion" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestedRegion"                   = "false"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          StringEquals = {
            "elasticloadbalancing:CreateAction" = [
              "CreateTargetGroup",
              "CreateLoadBalancer"
            ]
          }
          Null = {
            "aws:RequestedRegion" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_policy" {
  count      = var.alb_controller_enabled ? 1 : 0
  policy_arn = aws_iam_policy.alb_controller_policy[0].arn
  role       = aws_iam_role.alb_controller_role[0].name
}

# AWS Load Balancer Controller Service Account
resource "kubernetes_service_account" "alb_controller" {
  count = var.alb_controller_enabled ? 1 : 0

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role[0].arn
    }
  }
}

# AWS Load Balancer Controller Helm Release
resource "helm_release" "alb_controller" {
  count      = var.alb_controller_enabled ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.alb_controller_version
  namespace  = "kube-system"

  wait    = true
  timeout = 300

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.cluster.outputs.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "replicaCount"
    value = var.alb_controller_replica_count
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = data.terraform_remote_state.foundation.outputs.vpc_id
  }

  depends_on = [
    kubernetes_service_account.alb_controller,
    aws_iam_role_policy_attachment.alb_controller_policy
  ]
}

# =============================================================================
# EXTERNAL DNS CONFIGURATION
# =============================================================================

# External DNS IAM Role
resource "aws_iam_role" "external_dns_role" {
  count = var.external_dns_enabled ? 1 : 0
  name  = "ExternalDNSRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = data.terraform_remote_state.cluster.outputs.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:external-dns"
            "${replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# External DNS IAM Policy
resource "aws_iam_policy" "external_dns_policy" {
  count = var.external_dns_enabled ? 1 : 0
  name  = "ExternalDNSPolicy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_policy" {
  count      = var.external_dns_enabled ? 1 : 0
  policy_arn = aws_iam_policy.external_dns_policy[0].arn
  role       = aws_iam_role.external_dns_role[0].name
}

# External DNS Service Account
resource "kubernetes_service_account" "external_dns" {
  count = var.external_dns_enabled ? 1 : 0

  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns_role[0].arn
    }
  }
}

# External DNS Helm Release
resource "helm_release" "external_dns" {
  count      = var.external_dns_enabled ? 1 : 0
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = var.external_dns_version
  namespace  = "kube-system"

  wait    = true
  timeout = 300

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  dynamic "set" {
    for_each = var.external_dns_domain_filters
    content {
      name  = "domainFilters[${set.key}]"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.external_dns_source
    content {
      name  = "sources[${set.key}]"
      value = set.value
    }
  }

  set {
    name  = "txtOwnerId"
    value = var.external_dns_txt_owner_id != "" ? var.external_dns_txt_owner_id : "external-dns-${var.environment}"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  depends_on = [
    kubernetes_service_account.external_dns,
    aws_iam_role_policy_attachment.external_dns_policy
  ]
}

# =============================================================================
# CLUSTER AUTOSCALER CONFIGURATION (FALLBACK)
# =============================================================================

# Cluster Autoscaler IAM Role
resource "aws_iam_role" "cluster_autoscaler_role" {
  count = var.cluster_autoscaler_enabled ? 1 : 0
  name  = "ClusterAutoscalerRole-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = data.terraform_remote_state.cluster.outputs.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
            "${replace(data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Cluster Autoscaler IAM Policy
resource "aws_iam_policy" "cluster_autoscaler_policy" {
  count = var.cluster_autoscaler_enabled ? 1 : 0
  name  = "ClusterAutoscalerPolicy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_policy" {
  count      = var.cluster_autoscaler_enabled ? 1 : 0
  policy_arn = aws_iam_policy.cluster_autoscaler_policy[0].arn
  role       = aws_iam_role.cluster_autoscaler_role[0].name
}

# Cluster Autoscaler Service Account
resource "kubernetes_service_account" "cluster_autoscaler" {
  count = var.cluster_autoscaler_enabled ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler_role[0].arn
    }
  }
}

# Cluster Autoscaler Helm Release
resource "helm_release" "cluster_autoscaler" {
  count      = var.cluster_autoscaler_enabled ? 1 : 0
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_version
  namespace  = "kube-system"

  wait    = true
  timeout = 300

  set {
    name  = "autoDiscovery.clusterName"
    value = data.terraform_remote_state.cluster.outputs.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = var.cluster_autoscaler_scale_down_delay_after_add
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = var.cluster_autoscaler_scale_down_unneeded_time
  }

  set {
    name  = "extraArgs.scale-down-utilization-threshold"
    value = var.cluster_autoscaler_scale_down_utilization_threshold
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }

  depends_on = [
    kubernetes_service_account.cluster_autoscaler,
    aws_iam_role_policy_attachment.cluster_autoscaler_policy
  ]
}

# =============================================================================
# MONITORING & OBSERVABILITY
# =============================================================================

# CloudWatch Container Insights
resource "aws_cloudwatch_log_group" "container_insights" {
  count             = var.enable_container_insights ? 1 : 0
  name              = "/aws/containerinsights/${data.terraform_remote_state.cluster.outputs.cluster_name}/application"
  retention_in_days = var.environment == "production" ? 90 : 7

  tags = {
    Name        = "container-insights-${var.environment}"
    Environment = var.environment
  }
}

# =============================================================================
# SUBNET TAGGING FOR KARPENTER
# =============================================================================

# Tag subnets for Karpenter discovery
resource "aws_ec2_tag" "karpenter_subnet_tags" {
  count       = var.karpenter_enabled ? length(data.terraform_remote_state.foundation.outputs.eks_node_subnet_ids) : 0
  resource_id = data.terraform_remote_state.foundation.outputs.eks_node_subnet_ids[count.index]
  key         = "karpenter.sh/discovery"
  value       = data.terraform_remote_state.cluster.outputs.cluster_name
}

# Tag security groups for Karpenter discovery
resource "aws_ec2_tag" "karpenter_sg_tags" {
  count       = var.karpenter_enabled ? 1 : 0
  resource_id = data.terraform_remote_state.foundation.outputs.nodes_security_group_id
  key         = "karpenter.sh/discovery"
  value       = data.terraform_remote_state.cluster.outputs.cluster_name
}
