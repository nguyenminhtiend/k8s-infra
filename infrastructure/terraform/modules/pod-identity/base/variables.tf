variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., testing, staging, production)"
  type        = string
  validation {
    condition     = contains(["testing", "staging", "production"], var.environment)
    error_message = "Environment must be one of: testing, staging, production."
  }
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the pod identity role"
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "JSON string of inline policy to attach to the pod identity role"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
