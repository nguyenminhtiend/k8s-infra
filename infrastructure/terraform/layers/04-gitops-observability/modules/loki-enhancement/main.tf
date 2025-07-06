# Loki Enhancement Module
# This module enhances the existing Loki setup from Phase 2

# Update Loki configuration with additional retention and storage
resource "kubernetes_config_map" "loki_enhanced_config" {
  metadata {
    name      = "loki-enhanced-config"
    namespace = "monitoring"
  }

  data = {
    "loki.yaml" = templatefile("${path.module}/loki-config.yaml", {
      cluster_name        = var.cluster_name
      environment         = var.environment
      loki_retention_days = var.loki_retention_days
      loki_storage_size   = var.loki_storage_size
    })
  }
}

# Enhanced Loki PVC for additional storage
resource "kubernetes_persistent_volume_claim" "loki_enhanced_storage" {
  metadata {
    name      = "loki-enhanced-storage"
    namespace = "monitoring"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.loki_storage_size
      }
    }

    storage_class_name = "gp3"
  }
}

# ServiceMonitor for Loki metrics
resource "kubernetes_manifest" "loki_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "loki-enhanced"
      namespace = "monitoring"
      labels = {
        app     = "loki"
        release = "prometheus-stack"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "loki"
        }
      }
      endpoints = [
        {
          port     = "http-metrics"
          interval = "30s"
          path     = "/metrics"
        }
      ]
    }
  }
}
