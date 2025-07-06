output "jaeger_query_url" {
  description = "Jaeger Query URL"
  value       = "http://jaeger-query.jaeger.svc.cluster.local:16686"
}

output "jaeger_collector_url" {
  description = "Jaeger Collector URL"
  value       = "http://jaeger-collector.jaeger.svc.cluster.local:14267"
}

output "jaeger_namespace" {
  description = "Jaeger namespace"
  value       = kubernetes_namespace.jaeger.metadata[0].name
}

output "jaeger_service_account_role_arn" {
  description = "ARN of the IAM role for Jaeger service account"
  value       = module.jaeger_irsa.iam_role_arn
}

output "jaeger_helm_release_name" {
  description = "Jaeger Helm release name"
  value       = helm_release.jaeger.name
}

output "jaeger_helm_release_namespace" {
  description = "Jaeger Helm release namespace"
  value       = helm_release.jaeger.namespace
}

output "jaeger_helm_release_status" {
  description = "Jaeger Helm release status"
  value       = helm_release.jaeger.status
}

output "jaeger_query_nodeport_service" {
  description = "Jaeger Query NodePort service name"
  value       = kubernetes_service.jaeger_query_nodeport.metadata[0].name
}
