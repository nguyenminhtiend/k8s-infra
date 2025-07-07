output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = "https://argocd-server.argocd.svc.cluster.local"
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = var.argocd_admin_password
  sensitive   = true
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_service_account_role_arn" {
  description = "ARN of the IAM role for ArgoCD service account"
  value       = module.argocd_pod_identity.role_arn
}

output "argocd_nodeport_service" {
  description = "ArgoCD NodePort service name"
  value       = kubernetes_service.argocd_server_nodeport.metadata[0].name
}

output "argocd_helm_release_name" {
  description = "ArgoCD Helm release name"
  value       = helm_release.argocd.name
}

output "argocd_helm_release_namespace" {
  description = "ArgoCD Helm release namespace"
  value       = helm_release.argocd.namespace
}

output "argocd_helm_release_status" {
  description = "ArgoCD Helm release status"
  value       = helm_release.argocd.status
}
