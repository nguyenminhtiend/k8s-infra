variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
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

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  type        = string
}