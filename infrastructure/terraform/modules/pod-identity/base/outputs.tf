output "role_arn" {
  description = "ARN of the IAM role for Pod Identity"
  value       = aws_iam_role.pod_identity_role.arn
}

output "role_name" {
  description = "Name of the IAM role for Pod Identity"
  value       = aws_iam_role.pod_identity_role.name
}

output "role_id" {
  description = "ID of the IAM role for Pod Identity"
  value       = aws_iam_role.pod_identity_role.id
}

output "role_unique_id" {
  description = "Unique ID of the IAM role for Pod Identity"
  value       = aws_iam_role.pod_identity_role.unique_id
}

output "policy_attachments" {
  description = "List of policy attachments for the Pod Identity role"
  value       = aws_iam_role_policy_attachment.pod_identity_policy[*].policy_arn
}

output "pod_identity_association_id" {
  description = "ID of the EKS Pod Identity Association"
  value       = aws_eks_pod_identity_association.pod_identity_association.association_id
}

output "pod_identity_association_arn" {
  description = "ARN of the EKS Pod Identity Association"
  value       = aws_eks_pod_identity_association.pod_identity_association.association_arn
}
