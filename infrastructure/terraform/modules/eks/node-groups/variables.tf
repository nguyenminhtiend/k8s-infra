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

variable "node_group_role_arn" {
  description = "ARN of the IAM role for the EKS node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS node group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the EKS node group"
  type        = list(string)
}

variable "instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS node group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 5
}

variable "min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "ami_id" {
  description = "AMI ID for the EKS node group (if not provided, latest EKS-optimized AMI will be used)"
  type        = string
  default     = null
}

variable "disk_size" {
  description = "Disk size in GB for the EKS node group"
  type        = number
  default     = 20
}

variable "enable_system_taints" {
  description = "Whether to enable taints for system workloads"
  type        = bool
  default     = true
}

variable "bootstrap_arguments" {
  description = "Additional arguments to pass to the bootstrap script"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Kubernetes labels to apply to the node group"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}