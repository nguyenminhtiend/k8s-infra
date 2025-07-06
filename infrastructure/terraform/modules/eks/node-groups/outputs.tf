output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.system_node_group.arn
}

output "node_group_id" {
  description = "ID of the EKS node group"
  value       = aws_eks_node_group.system_node_group.id
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.system_node_group.status
}

output "node_group_capacity_type" {
  description = "Capacity type of the EKS node group"
  value       = aws_eks_node_group.system_node_group.capacity_type
}

output "node_group_instance_types" {
  description = "Instance types of the EKS node group"
  value       = aws_eks_node_group.system_node_group.instance_types
}

output "node_group_scaling_config" {
  description = "Scaling configuration of the EKS node group"
  value       = aws_eks_node_group.system_node_group.scaling_config
}

output "node_group_remote_access" {
  description = "Remote access configuration of the EKS node group"
  value       = aws_eks_node_group.system_node_group.remote_access
}

output "launch_template_id" {
  description = "ID of the launch template used by the node group"
  value       = aws_launch_template.eks_node_group_template.id
}

output "launch_template_version" {
  description = "Version of the launch template used by the node group"
  value       = aws_launch_template.eks_node_group_template.latest_version
}

output "autoscaling_group_names" {
  description = "Names of the autoscaling groups associated with the node group"
  value       = aws_eks_node_group.system_node_group.resources[0].autoscaling_groups[*].name
}