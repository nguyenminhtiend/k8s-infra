variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
}

variable "argocd_admin_password" {
  description = "ArgoCD admin password"
  type        = string
  sensitive   = true
}

variable "argocd_github_org" {
  description = "GitHub organization for ArgoCD repositories"
  type        = string
  default     = ""
}

variable "argocd_github_repo" {
  description = "GitHub repository for ArgoCD applications"
  type        = string
  default     = ""
}

variable "argocd_github_token" {
  description = "GitHub token for ArgoCD repository access"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
