# Environment Configuration
variable "environment" {
  description = "Environment name (e.g., testing, staging, production)"
  type        = string
  validation {
    condition     = contains(["testing", "staging", "production"], var.environment)
    error_message = "Environment must be one of: testing, staging, production."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k8s-infra"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

# Terraform State Configuration
variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

# EKS Cluster Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "enable_public_access" {
  description = "Whether to enable public API server endpoint access"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of enabled cluster log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30
}

# EKS Add-on Versions
variable "vpc_cni_version" {
  description = "Version of the VPC CNI add-on"
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "Version of the CoreDNS add-on"
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "Version of the kube-proxy add-on"
  type        = string
  default     = null
}

variable "ebs_csi_driver_version" {
  description = "Version of the EBS CSI driver add-on"
  type        = string
  default     = null
}

# Node Group Configuration
variable "enable_system_taints" {
  description = "Whether to enable taints for system workloads"
  type        = bool
  default     = true
}

# Developer Access Configuration
variable "developer_principal_arns" {
  description = "List of ARNs that can assume the developer roles"
  type        = list(string)
  default     = []
}

variable "developer_external_id" {
  description = "External ID for developer role assumption"
  type        = string
  default     = null
}

variable "ecr_repository_prefix" {
  description = "Prefix for ECR repositories that developers can push to"
  type        = string
  default     = "microservices/"
}

variable "create_readonly_role" {
  description = "Whether to create a read-only developer role"
  type        = bool
  default     = false
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}