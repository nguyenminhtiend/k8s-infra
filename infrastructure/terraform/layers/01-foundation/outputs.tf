output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.subnets.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.subnets.public_subnet_ids
}

output "eks_node_subnet_ids" {
  description = "IDs of subnets to use for EKS nodes"
  value       = module.subnets.eks_node_subnet_ids
}

output "eks_node_subnet_type" {
  description = "Type of subnets used for EKS nodes (public or private)"
  value       = module.subnets.eks_node_subnet_type
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways"
  value       = module.subnets.nat_gateway_ids
}

output "nat_gateway_count" {
  description = "Number of NAT gateways created"
  value       = module.subnets.nat_gateway_count
}

output "internet_access_enabled" {
  description = "Whether private subnets have internet access via NAT gateways"
  value       = module.subnets.internet_access_enabled
}

output "use_public_subnets_for_eks" {
  description = "Whether public subnets are used for EKS nodes"
  value       = module.subnets.use_public_subnets_for_eks
}

output "cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = module.security_groups.cluster_security_group_id
}

output "nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = module.security_groups.nodes_security_group_id
}

# Alias for documentation consistency
output "node_security_group_id" {
  description = "Security group ID for EKS nodes (alias for nodes_security_group_id)"
  value       = module.security_groups.nodes_security_group_id
}
