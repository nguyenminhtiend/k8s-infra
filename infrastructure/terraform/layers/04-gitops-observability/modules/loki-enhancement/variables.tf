variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "loki_retention_days" {
  description = "Loki log retention in days"
  type        = number
}

variable "loki_storage_size" {
  description = "Loki storage size"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
