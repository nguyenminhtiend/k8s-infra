# EKS Cluster Outputs
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks_cluster.cluster_id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_cluster.cluster_name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks_cluster.cluster_arn
}

output "cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = module.eks_cluster.cluster_version
}

output "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster"
  value       = module.eks_cluster.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster"
  value       = module.eks_cluster.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for the EKS cluster"
  value       = module.eks_cluster.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster"
  value       = module.eks_cluster.oidc_provider_arn
}

# Node Group Outputs
output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = module.eks_node_groups.node_group_arn
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = module.eks_node_groups.node_group_status
}

output "node_group_capacity_type" {
  description = "Capacity type of the EKS node group"
  value       = module.eks_node_groups.node_group_capacity_type
}

output "node_group_instance_types" {
  description = "Instance types of the EKS node group"
  value       = module.eks_node_groups.node_group_instance_types
}

output "node_group_scaling_config" {
  description = "Scaling configuration of the EKS node group"
  value       = module.eks_node_groups.node_group_scaling_config
}

# IAM Role Outputs
output "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = module.iam_service_roles.cluster_service_role_arn
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group service role"
  value       = module.iam_service_roles.node_group_role_arn
}

output "developer_base_role_arn" {
  description = "ARN of the developer base role"
  value       = module.developer_roles.developer_base_role_arn
}

output "developer_readonly_role_arn" {
  description = "ARN of the developer read-only role"
  value       = module.developer_roles.developer_readonly_role_arn
}

# Pod Identity Outputs
output "pod_identity_test_role_arn" {
  description = "ARN of the test Pod Identity role"
  value       = module.pod_identity_base_example.role_arn
}

output "pod_identity_test_association_id" {
  description = "ID of the test Pod Identity association"
  value       = module.pod_identity_base_example.pod_identity_association_id
}

# Configuration Outputs
output "aws_auth_configmap_yaml" {
  description = "YAML configuration for aws-auth ConfigMap"
  value       = module.developer_roles.aws_auth_configmap_yaml
}

output "kubeconfig_role_arn" {
  description = "Role ARN to use in kubeconfig for developers"
  value       = module.developer_roles.kubeconfig_role_arn
}

# Environment Configuration
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# Kubeconfig Command
output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${module.eks_cluster.cluster_name}"
}

# Developer Setup Instructions
output "developer_setup_instructions" {
  description = "Instructions for developers to set up access"
  value = <<-EOT
    # Developer Setup Instructions

    1. Configure AWS CLI with your credentials
    2. Assume the developer role:
       aws sts assume-role --role-arn ${module.developer_roles.developer_base_role_arn} --role-session-name dev-session

    3. Update kubeconfig:
       aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${module.eks_cluster.cluster_name}

    4. Test access:
       kubectl get nodes
       kubectl get pods -A

    Environment: ${var.environment}
    Cluster Name: ${module.eks_cluster.cluster_name}
    Region: ${data.aws_region.current.name}
  EOT
}