# Namespace Outputs
output "microservices_namespace" {
  description = "Name of the microservices namespace"
  value       = kubernetes_namespace.microservices.metadata[0].name
}

output "monitoring_namespace" {
  description = "Name of the monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

# Service A Outputs
output "service_a_name" {
  description = "Name of Service A deployment"
  value       = kubernetes_deployment.service_a.metadata[0].name
}

output "service_a_service_name" {
  description = "Name of Service A Kubernetes service"
  value       = kubernetes_service.service_a.metadata[0].name
}

# Service B Outputs
output "service_b_name" {
  description = "Name of Service B deployment"
  value       = kubernetes_deployment.service_b.metadata[0].name
}

output "service_b_service_name" {
  description = "Name of Service B Kubernetes service"
  value       = kubernetes_service.service_b.metadata[0].name
}

# Ingress Outputs
output "ingress_name" {
  description = "Name of the services ingress"
  value       = kubernetes_ingress_v1.services_ingress.metadata[0].name
}

output "service_urls" {
  description = "URLs for accessing services (add to /etc/hosts)"
  value = {
    service_a = "http://service-a.local"
    service_b = "http://service-b.local"
  }
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "kubernetes_context" {
  description = "Kubernetes context being used"
  value       = var.kubernetes_context
}