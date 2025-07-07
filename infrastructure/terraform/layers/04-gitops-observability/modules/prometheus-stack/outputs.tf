output "prometheus_server_url" {
  description = "Prometheus server URL"
  value       = "http://prometheus-server.monitoring.svc.cluster.local:9090"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://grafana.monitoring.svc.cluster.local:3000"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "alertmanager_url" {
  description = "AlertManager URL"
  value       = "http://alertmanager.monitoring.svc.cluster.local:9093"
}

output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_helm_release_name" {
  description = "Prometheus Stack Helm release name"
  value       = helm_release.prometheus_stack.name
}

output "prometheus_helm_release_namespace" {
  description = "Prometheus Stack Helm release namespace"
  value       = helm_release.prometheus_stack.namespace
}

output "prometheus_helm_release_status" {
  description = "Prometheus Stack Helm release status"
  value       = helm_release.prometheus_stack.status
}

output "prometheus_service_account_role_arn" {
  description = "ARN of the IAM role for Prometheus service account"
  value       = module.prometheus_pod_identity.role_arn
}

output "grafana_service_account_role_arn" {
  description = "ARN of the IAM role for Grafana service account"
  value       = module.grafana_pod_identity.role_arn
}

output "prometheus_storage_class_name" {
  description = "Name of the Prometheus storage class"
  value       = kubernetes_storage_class.prometheus_storage.metadata[0].name
}

output "prometheus_nodeport_service" {
  description = "Prometheus NodePort service name"
  value       = kubernetes_service.prometheus_nodeport.metadata[0].name
}

output "grafana_nodeport_service" {
  description = "Grafana NodePort service name"
  value       = kubernetes_service.grafana_nodeport.metadata[0].name
}

output "alertmanager_nodeport_service" {
  description = "AlertManager NodePort service name"
  value       = kubernetes_service.alertmanager_nodeport.metadata[0].name
}
