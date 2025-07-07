output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.cluster.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.cluster.arn
}

output "cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.cluster.version
}

output "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster"
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "The primary security group ID of the EKS cluster"
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

# OIDC outputs removed - using Pod Identity instead

output "cluster_status" {
  description = "The status of the EKS cluster"
  value       = aws_eks_cluster.cluster.status
}

output "cluster_platform_version" {
  description = "The platform version of the EKS cluster"
  value       = aws_eks_cluster.cluster.platform_version
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for cluster encryption"
  value       = var.environment != "testing" ? aws_kms_key.eks_cluster_key[0].arn : null
}

output "kms_key_id" {
  description = "The ID of the KMS key used for cluster encryption"
  value       = var.environment != "testing" ? aws_kms_key.eks_cluster_key[0].key_id : null
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster_log_group.name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster_log_group.arn
}

output "pod_identity_addon_arn" {
  description = "The ARN of the EKS Pod Identity addon"
  value       = aws_eks_addon.pod_identity.arn
}

output "pod_identity_addon_status" {
  description = "The status of the EKS Pod Identity addon"
  value       = aws_eks_addon.pod_identity.status
}
