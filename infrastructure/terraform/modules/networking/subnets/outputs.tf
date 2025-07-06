output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "eks_node_subnet_ids" {
  description = "IDs of subnets to use for EKS nodes (public if use_public_subnets_for_eks is true, private otherwise)"
  value       = var.use_public_subnets_for_eks ? aws_subnet.public[*].id : aws_subnet.private[*].id
}

output "eks_node_subnet_type" {
  description = "Type of subnets used for EKS nodes"
  value       = var.use_public_subnets_for_eks ? "public" : "private"
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_count" {
  description = "Number of NAT gateways created"
  value       = local.nat_gateway_count
}

output "internet_access_enabled" {
  description = "Whether private subnets have internet access via NAT gateways"
  value       = var.enable_nat_gateway
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "use_public_subnets_for_eks" {
  description = "Whether public subnets are used for EKS nodes"
  value       = var.use_public_subnets_for_eks
}