output "developer_base_role_arn" {
  description = "ARN of the developer base role"
  value       = aws_iam_role.developer_base.arn
}

output "developer_base_role_name" {
  description = "Name of the developer base role"
  value       = aws_iam_role.developer_base.name
}

output "developer_readonly_role_arn" {
  description = "ARN of the developer read-only role"
  value       = var.create_readonly_role ? aws_iam_role.developer_readonly[0].arn : null
}

output "developer_readonly_role_name" {
  description = "Name of the developer read-only role"
  value       = var.create_readonly_role ? aws_iam_role.developer_readonly[0].name : null
}

output "developer_eks_access_policy_arn" {
  description = "ARN of the developer EKS access policy"
  value       = aws_iam_policy.developer_eks_access.arn
}

output "developer_ecr_access_policy_arn" {
  description = "ARN of the developer ECR access policy"
  value       = aws_iam_policy.developer_ecr_access.arn
}

output "developer_irsa_assume_policy_arn" {
  description = "ARN of the developer IRSA assume policy"
  value       = aws_iam_policy.developer_irsa_assume.arn
}

output "kubeconfig_role_arn" {
  description = "Role ARN to use in kubeconfig for developers"
  value       = aws_iam_role.developer_base.arn
}

output "aws_auth_configmap_yaml" {
  description = "YAML configuration for aws-auth ConfigMap"
  value = templatefile("${path.module}/aws-auth-configmap.yaml.tpl", {
    developer_base_role_arn     = aws_iam_role.developer_base.arn
    developer_readonly_role_arn = var.create_readonly_role ? aws_iam_role.developer_readonly[0].arn : ""
    create_readonly_role        = var.create_readonly_role
  })
}