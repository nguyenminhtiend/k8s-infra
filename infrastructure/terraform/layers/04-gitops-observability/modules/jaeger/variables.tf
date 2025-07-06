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

variable "jaeger_chart_version" {
  description = "Jaeger Helm chart version"
  type        = string
}

variable "jaeger_retention_days" {
  description = "Jaeger trace retention in days"
  type        = number
}

variable "jaeger_storage_size" {
  description = "Jaeger storage size"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
