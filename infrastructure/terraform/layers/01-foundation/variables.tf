variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "my-cluster"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway creation. Set to false for testing environments to save costs"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway instead of one per AZ for cost optimization"
  type        = bool
  default     = false
}

variable "use_public_subnets_for_eks" {
  description = "Use public subnets for EKS nodes instead of private subnets (useful for testing environments without NAT gateways)"
  type        = bool
  default     = false
}