# ArgoCD Outputs
output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = module.argocd.argocd_server_url
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = module.argocd.argocd_admin_password
  sensitive   = true
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = module.argocd.argocd_namespace
}

# Prometheus Stack Outputs
output "prometheus_server_url" {
  description = "Prometheus server URL"
  value       = module.prometheus_stack.prometheus_server_url
}

output "grafana_url" {
  description = "Grafana URL"
  value       = module.prometheus_stack.grafana_url
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = module.prometheus_stack.grafana_admin_password
  sensitive   = true
}

output "alertmanager_url" {
  description = "AlertManager URL"
  value       = module.prometheus_stack.alertmanager_url
}

output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = module.prometheus_stack.monitoring_namespace
}

# Jaeger Outputs
output "jaeger_query_url" {
  description = "Jaeger Query URL"
  value       = module.jaeger.jaeger_query_url
}

output "jaeger_collector_url" {
  description = "Jaeger Collector URL"
  value       = module.jaeger.jaeger_collector_url
}

output "jaeger_namespace" {
  description = "Jaeger namespace"
  value       = module.jaeger.jaeger_namespace
}

# Loki Outputs
output "loki_url" {
  description = "Loki URL"
  value       = module.loki_enhancement.loki_url
}

# GitOps Outputs
output "gitops_applications" {
  description = "GitOps applications deployed"
  value       = module.gitops_bootstrap.gitops_applications
}

# General Outputs
output "phase" {
  description = "Deployment phase"
  value       = "04-gitops-observability"
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = local.cluster_name
}

# Port Forward Commands
output "port_forward_commands" {
  description = "Port forward commands for accessing services"
  value = {
    argocd     = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
    prometheus = "kubectl port-forward svc/prometheus-server -n monitoring 9090:80"
    grafana    = "kubectl port-forward svc/grafana -n monitoring 3000:80"
    jaeger     = "kubectl port-forward svc/jaeger-query -n jaeger 16686:16686"
    loki       = "kubectl port-forward svc/loki -n monitoring 3100:3100"
  }
}

# Access URLs (for port-forwarded services)
output "access_urls" {
  description = "Access URLs for services (after port forwarding)"
  value = {
    argocd     = "https://localhost:8080"
    prometheus = "http://localhost:9090"
    grafana    = "http://localhost:3000"
    jaeger     = "http://localhost:16686"
    loki       = "http://localhost:3100"
  }
}

# Credentials Information
output "credentials_info" {
  description = "Information about retrieving credentials"
  value = {
    argocd_admin  = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    grafana_admin = "kubectl get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}' | base64 --decode"
  }
}
