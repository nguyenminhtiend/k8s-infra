# Data sources
data "aws_caller_identity" "current" {}

# EKS Cluster Service Role
resource "aws_iam_role" "eks_cluster_service_role" {
  name = "EKS-ClusterServiceRole-${var.environment}"

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

  tags = {
    Name        = "EKS-ClusterServiceRole-${var.environment}"
    Environment = var.environment
    Module      = "iam/service-roles"
    ManagedBy   = "terraform"
  }
}

# Attach AWS managed policy for EKS cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Node Group Service Role
resource "aws_iam_role" "eks_node_group_role" {
  name = "EKS-NodeGroupServiceRole-${var.environment}"

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

  tags = {
    Name        = "EKS-NodeGroupServiceRole-${var.environment}"
    Environment = var.environment
    Module      = "iam/service-roles"
    ManagedBy   = "terraform"
  }
}

# Attach AWS managed policies for EKS node groups
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EBS CSI Driver policy for persistent volumes
resource "aws_iam_role_policy_attachment" "eks_ebs_csi_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Instance profile for node groups
resource "aws_iam_instance_profile" "eks_node_group_instance_profile" {
  name = "EKS-NodeGroupInstanceProfile-${var.environment}"
  role = aws_iam_role.eks_node_group_role.name

  tags = {
    Name        = "EKS-NodeGroupInstanceProfile-${var.environment}"
    Environment = var.environment
    Module      = "iam/service-roles"
    ManagedBy   = "terraform"
  }
}

# Additional policy for Systems Manager (optional but recommended)
resource "aws_iam_role_policy_attachment" "eks_ssm_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}