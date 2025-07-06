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

variable "prometheus_chart_version" {
  description = "Prometheus Stack Helm chart version"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "prometheus_retention_days" {
  description = "Prometheus data retention in days"
  type        = number
}

variable "prometheus_storage_size" {
  description = "Prometheus storage size"
  type        = string
}

variable "grafana_storage_size" {
  description = "Grafana storage size"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
