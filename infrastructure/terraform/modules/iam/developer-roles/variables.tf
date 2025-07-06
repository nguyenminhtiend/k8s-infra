variable "environment" {
  description = "Environment name (e.g., testing, staging, production)"
  type        = string
  validation {
    condition     = contains(["testing", "staging", "production"], var.environment)
    error_message = "Environment must be one of: testing, staging, production."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "allowed_principal_arns" {
  description = "List of ARNs that can assume the developer roles"
  type        = list(string)
}

variable "external_id" {
  description = "External ID for role assumption (optional)"
  type        = string
  default     = null
}

variable "ecr_repository_prefix" {
  description = "Prefix for ECR repositories that developers can push to"
  type        = string
  default     = "microservices/"
}

variable "additional_policy_arns" {
  description = "Additional policy ARNs to attach to developer roles"
  type        = list(string)
  default     = []
}

variable "create_readonly_role" {
  description = "Whether to create a read-only developer role"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}