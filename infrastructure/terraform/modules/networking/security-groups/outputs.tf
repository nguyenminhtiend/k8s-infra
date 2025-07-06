output "cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = aws_security_group.eks_nodes.id
}