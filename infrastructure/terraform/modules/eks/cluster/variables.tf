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

variable "cluster_service_role_arn" {
  description = "ARN of the IAM role for the EKS cluster service"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the EKS cluster"
  type        = list(string)
  default     = []
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

# EKS Add-on versions
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

# Service account role ARNs for add-ons
variable "vpc_cni_service_account_role_arn" {
  description = "ARN of the IAM role for the VPC CNI service account"
  type        = string
  default     = null
}

variable "ebs_csi_service_account_role_arn" {
  description = "ARN of the IAM role for the EBS CSI driver service account"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}