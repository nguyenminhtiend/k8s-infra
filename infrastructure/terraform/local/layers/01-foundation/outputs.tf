# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

# Subnet Outputs
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.subnets.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.subnets.public_subnet_ids
}

output "subnet_ids" {
  description = "All subnet IDs (for EKS)"
  value       = var.use_public_subnets_for_eks ? module.subnets.public_subnet_ids : module.subnets.private_subnet_ids
}

# Security Group Outputs
output "cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = module.security_groups.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = module.security_groups.node_security_group_id
}

# Environment Info
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = var.cluster_name
}