# Common Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["testing", "staging", "production"], var.environment)
    error_message = "Environment must be one of: testing, staging, production."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "k8s-infra"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

# ArgoCD Variables
variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
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

# Prometheus Stack Variables
variable "prometheus_chart_version" {
  description = "Prometheus Stack Helm chart version"
  type        = string
  default     = "56.6.2"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "prometheus_retention_days" {
  description = "Prometheus data retention in days"
  type        = number
  default     = 15
}

variable "prometheus_storage_size" {
  description = "Prometheus storage size"
  type        = string
  default     = "20Gi"
}

variable "grafana_storage_size" {
  description = "Grafana storage size"
  type        = string
  default     = "10Gi"
}

# Jaeger Variables
variable "jaeger_chart_version" {
  description = "Jaeger Helm chart version"
  type        = string
  default     = "2.1.0"
}

variable "jaeger_retention_days" {
  description = "Jaeger trace retention in days"
  type        = number
  default     = 7
}

variable "jaeger_storage_size" {
  description = "Jaeger storage size"
  type        = string
  default     = "10Gi"
}

# Loki Variables
variable "loki_retention_days" {
  description = "Loki log retention in days"
  type        = number
  default     = 30
}

variable "loki_storage_size" {
  description = "Loki storage size"
  type        = string
  default     = "20Gi"
}

# GitOps Variables
variable "gitops_repo_url" {
  description = "GitOps repository URL"
  type        = string
  default     = ""
}

variable "gitops_repo_branch" {
  description = "GitOps repository branch"
  type        = string
  default     = "main"
}

variable "gitops_repo_path" {
  description = "GitOps repository path"
  type        = string
  default     = "applications"
}
