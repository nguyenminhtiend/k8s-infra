# Environment Configuration
variable "environment" {
  description = "Environment name (local for testing)"
  type        = string
  default     = "local"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k8s-infra"
}

variable "aws_region" {
  description = "AWS region (for LocalStack compatibility)"
  type        = string
  default     = "ap-southeast-1"
}

# EKS Cluster Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}