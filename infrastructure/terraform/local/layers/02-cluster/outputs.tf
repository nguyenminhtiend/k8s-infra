# Cluster Information
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the EKS cluster"
  value       = aws_eks_cluster.cluster.version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = aws_eks_cluster.cluster.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.cluster.status
}

# Cluster ARN and Security
output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.cluster.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

# IAM Roles
output "cluster_service_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster_role.arn
}

output "node_group_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node_role.arn
}

# Node Group Information
output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.node_group.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.node_group.status
}

# Environment and Network Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  value       = data.terraform_remote_state.foundation.outputs.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs where the cluster is deployed"
  value       = data.terraform_remote_state.foundation.outputs.subnet_ids
}

# CloudWatch Log Group
output "cluster_cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group for cluster"
  value       = aws_cloudwatch_log_group.eks_cluster_log_group.name
}

output "cluster_cloudwatch_log_group_arn" {
  description = "Arn of cloudwatch log group for cluster"
  value       = aws_cloudwatch_log_group.eks_cluster_log_group.arn
}