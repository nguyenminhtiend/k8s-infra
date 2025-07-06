output "role_arn" {
  description = "ARN of the IAM role for the service account"
  value       = aws_iam_role.service_account_role.arn
}

output "role_name" {
  description = "Name of the IAM role for the service account"
  value       = aws_iam_role.service_account_role.name
}

output "role_id" {
  description = "ID of the IAM role for the service account"
  value       = aws_iam_role.service_account_role.id
}

output "role_unique_id" {
  description = "Unique ID of the IAM role for the service account"
  value       = aws_iam_role.service_account_role.unique_id
}

output "policy_attachments" {
  description = "List of policy attachments for the service account role"
  value       = aws_iam_role_policy_attachment.service_account_policy[*].policy_arn
}

output "service_account_annotation" {
  description = "Annotation to add to the Kubernetes service account"
  value       = "eks.amazonaws.com/role-arn: ${aws_iam_role.service_account_role.arn}"
}