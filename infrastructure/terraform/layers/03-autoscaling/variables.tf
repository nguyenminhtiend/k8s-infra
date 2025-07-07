# =============================================================================
# PHASE 3: AUTOSCALING & LOAD BALANCING VARIABLES
# =============================================================================

# Basic Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name (testing, staging, production)"
  type        = string

  validation {
    condition     = contains(["testing", "staging", "production"], var.environment)
    error_message = "Environment must be one of: testing, staging, production."
  }
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

# Karpenter Configuration
variable "karpenter_enabled" {
  description = "Enable Karpenter for node provisioning"
  type        = bool
  default     = true
}

variable "karpenter_version" {
  description = "Version of Karpenter to install"
  type        = string
  default     = "0.37.0"
}

variable "karpenter_node_instance_types" {
  description = "List of instance types for Karpenter nodes"
  type        = list(string)
  default     = ["t3.small", "t3.medium", "t3.large", "m5.large", "m5.xlarge"]
}

variable "karpenter_node_capacity_type" {
  description = "Capacity type for Karpenter nodes (spot, on-demand, or both)"
  type        = list(string)
  default     = ["spot", "on-demand"]
}

variable "karpenter_spot_percentage" {
  description = "Percentage of spot instances (0-100)"
  type        = number
  default     = 70

  validation {
    condition     = var.karpenter_spot_percentage >= 0 && var.karpenter_spot_percentage <= 100
    error_message = "Spot percentage must be between 0 and 100."
  }
}

variable "karpenter_max_nodes" {
  description = "Maximum number of nodes Karpenter can provision"
  type        = number
  default     = 10
}

variable "karpenter_ttl_seconds_after_empty" {
  description = "Seconds after which empty nodes are terminated"
  type        = number
  default     = 30
}

variable "karpenter_ttl_seconds_until_expired" {
  description = "Seconds until nodes expire and are replaced"
  type        = number
  default     = 2592000 # 30 days
}

# AWS Load Balancer Controller Configuration
variable "alb_controller_enabled" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "alb_controller_version" {
  description = "Version of AWS Load Balancer Controller"
  type        = string
  default     = "1.8.1"
}

variable "alb_controller_replica_count" {
  description = "Number of replicas for ALB Controller"
  type        = number
  default     = 2
}

# External DNS Configuration
variable "external_dns_enabled" {
  description = "Enable External DNS for automatic DNS management"
  type        = bool
  default     = true
}

variable "external_dns_version" {
  description = "Version of External DNS"
  type        = string
  default     = "1.14.5"
}

variable "external_dns_domain_filters" {
  description = "List of domains to manage with External DNS"
  type        = list(string)
  default     = []
}

variable "external_dns_source" {
  description = "Source for External DNS (service, ingress, etc.)"
  type        = list(string)
  default     = ["service", "ingress"]
}

variable "external_dns_txt_owner_id" {
  description = "Owner ID for TXT records"
  type        = string
  default     = ""
}

# Cluster Autoscaler Configuration
variable "cluster_autoscaler_enabled" {
  description = "Enable Cluster Autoscaler as fallback"
  type        = bool
  default     = false # Disabled by default since we have Karpenter
}

variable "cluster_autoscaler_version" {
  description = "Version of Cluster Autoscaler"
  type        = string
  default     = "1.33.0"
}

variable "cluster_autoscaler_scale_down_delay_after_add" {
  description = "How long after scale up before scale down evaluation resumes"
  type        = string
  default     = "10m"
}

variable "cluster_autoscaler_scale_down_unneeded_time" {
  description = "How long a node should be unneeded before it is eligible for scale down"
  type        = string
  default     = "10m"
}

variable "cluster_autoscaler_scale_down_utilization_threshold" {
  description = "Node utilization level below which node can be considered for scale down"
  type        = number
  default     = 0.5
}

# Monitoring Configuration
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "enable_cost_monitoring" {
  description = "Enable cost monitoring and optimization features"
  type        = bool
  default     = true
}

# Tagging Configuration
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Environment-specific Configuration
variable "node_taints" {
  description = "Taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "node_labels" {
  description = "Labels to apply to nodes"
  type        = map(string)
  default     = {}
}

# Security Configuration
variable "enable_pod_identity" {
  description = "Enable Pod Identity for service accounts"
  type        = bool
  default     = true
}

variable "enable_pod_security_policy" {
  description = "Enable Pod Security Policy (deprecated in favor of Pod Security Standards)"
  type        = bool
  default     = false
}

# Networking Configuration
variable "enable_vpc_cni_prefix_delegation" {
  description = "Enable VPC CNI prefix delegation for more IP addresses per node"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable network policy support"
  type        = bool
  default     = false
}

# Performance Configuration
variable "enable_gpu_support" {
  description = "Enable GPU support for nodes"
  type        = bool
  default     = false
}

variable "enable_nvme_ssd_optimization" {
  description = "Enable NVMe SSD optimization"
  type        = bool
  default     = true
}
