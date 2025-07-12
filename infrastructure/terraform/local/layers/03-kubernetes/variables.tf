variable "environment" {
  description = "Environment name"
  type        = string
  default     = "local"
}

variable "kubernetes_context" {
  description = "Kubernetes context to use (Kind cluster)"
  type        = string
  default     = "kind-local-cluster"
}

variable "service_a_replicas" {
  description = "Number of replicas for Service A"
  type        = number
  default     = 2
}

variable "service_b_replicas" {
  description = "Number of replicas for Service B"
  type        = number
  default     = 2
}

variable "enable_monitoring" {
  description = "Enable monitoring resources"
  type        = bool
  default     = true
}