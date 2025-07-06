output "gitops_applications" {
  description = "GitOps applications deployed"
  value = [
    var.gitops_repo_url != "" ? "infrastructure-${var.environment}" : null,
    var.gitops_repo_url != "" ? "applications-${var.environment}" : null,
    "sample-app-${var.environment}"
  ]
}

output "infrastructure_app_name" {
  description = "Name of the infrastructure GitOps application"
  value       = var.gitops_repo_url != "" ? "infrastructure-${var.environment}" : null
}

output "applications_app_name" {
  description = "Name of the applications GitOps application"
  value       = var.gitops_repo_url != "" ? "applications-${var.environment}" : null
}

output "sample_app_name" {
  description = "Name of the sample application"
  value       = "sample-app-${var.environment}"
}
