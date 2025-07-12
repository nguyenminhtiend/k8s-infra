variable "environment" {
  description = "Environment name"
  type        = string
  default     = "local"
}

variable "aws_region" {
  description = "AWS region (for LocalStack compatibility)"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "local-cluster"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.100.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway creation (disabled for local testing)"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway instead of one per AZ"
  type        = bool
  default     = false
}

variable "use_public_subnets_for_eks" {
  description = "Use public subnets for EKS nodes (enabled for local testing)"
  type        = bool
  default     = true
}