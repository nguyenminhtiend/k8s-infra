output "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = aws_iam_role.eks_cluster_service_role.arn
}

output "cluster_service_role_name" {
  description = "Name of the EKS cluster service role"
  value       = aws_iam_role.eks_cluster_service_role.name
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group service role"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "node_group_role_name" {
  description = "Name of the EKS node group service role"
  value       = aws_iam_role.eks_node_group_role.name
}

output "node_group_instance_profile_arn" {
  description = "ARN of the EKS node group instance profile"
  value       = aws_iam_instance_profile.eks_node_group_instance_profile.arn
}

output "node_group_instance_profile_name" {
  description = "Name of the EKS node group instance profile"
  value       = aws_iam_instance_profile.eks_node_group_instance_profile.name
}