output "loki_url" {
  description = "Loki URL"
  value       = "http://loki.monitoring.svc.cluster.local:3100"
}

output "loki_enhanced_config_name" {
  description = "Name of the enhanced Loki configuration"
  value       = kubernetes_config_map.loki_enhanced_config.metadata[0].name
}

output "loki_enhanced_storage_name" {
  description = "Name of the enhanced Loki storage PVC"
  value       = kubernetes_persistent_volume_claim.loki_enhanced_storage.metadata[0].name
}
