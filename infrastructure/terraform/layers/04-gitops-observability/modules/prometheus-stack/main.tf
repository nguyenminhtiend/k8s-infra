# Monitoring Namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      name        = "monitoring"
      environment = var.environment
    }
  }
}

# Prometheus Stack IAM Role for Pod Identity
module "prometheus_pod_identity" {
  source = "../../../../modules/pod-identity/base"

  cluster_name         = var.cluster_name
  environment          = var.environment
  service_account_name = "prometheus-server"
  namespace            = "monitoring"

  # Add specific policies for Prometheus
  policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  tags = var.tags
}

# Grafana IAM Role for Pod Identity
module "grafana_pod_identity" {
  source = "../../../../modules/pod-identity/base"

  cluster_name         = var.cluster_name
  environment          = var.environment
  service_account_name = "grafana"
  namespace            = "monitoring"

  # Add specific policies for Grafana
  policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  ]

  tags = var.tags
}

# Prometheus Stack Storage Class
resource "kubernetes_storage_class" "prometheus_storage" {
  metadata {
    name = "prometheus-storage"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
}

# Prometheus Stack Helm Release
resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_chart_version

  # Wait for deployment to be ready
  wait    = true
  timeout = 900

  values = [
    templatefile("${path.module}/values.yaml", {
      cluster_name                    = var.cluster_name
      environment                     = var.environment
      prometheus_retention_days       = var.prometheus_retention_days
      prometheus_storage_size         = var.prometheus_storage_size
      grafana_storage_size            = var.grafana_storage_size
      grafana_admin_password          = var.grafana_admin_password
      prometheus_service_account_role = module.prometheus_pod_identity.role_arn
      grafana_service_account_role    = module.grafana_pod_identity.role_arn
      storage_class_name              = kubernetes_storage_class.prometheus_storage.metadata[0].name
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring,
    module.prometheus_pod_identity,
    module.grafana_pod_identity,
    kubernetes_storage_class.prometheus_storage
  ]
}

# Prometheus Server NodePort Service
resource "kubernetes_service" "prometheus_nodeport" {
  depends_on = [helm_release.prometheus_stack]

  metadata {
    name      = "prometheus-nodeport"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    type = "NodePort"

    port {
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
      node_port   = 30090
    }

    selector = {
      "app.kubernetes.io/name" = "prometheus"
    }
  }
}

# Grafana NodePort Service
resource "kubernetes_service" "grafana_nodeport" {
  depends_on = [helm_release.prometheus_stack]

  metadata {
    name      = "grafana-nodeport"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    type = "NodePort"

    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
      node_port   = 30030
    }

    selector = {
      "app.kubernetes.io/name" = "grafana"
    }
  }
}

# AlertManager NodePort Service
resource "kubernetes_service" "alertmanager_nodeport" {
  depends_on = [helm_release.prometheus_stack]

  metadata {
    name      = "alertmanager-nodeport"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    type = "NodePort"

    port {
      port        = 9093
      target_port = 9093
      protocol    = "TCP"
      node_port   = 30093
    }

    selector = {
      "app.kubernetes.io/name" = "alertmanager"
    }
  }
}

# Custom Prometheus Rules for EKS
resource "kubernetes_manifest" "eks_prometheus_rules" {
  depends_on = [helm_release.prometheus_stack]

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "eks-monitoring-rules"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        app     = "kube-prometheus-stack"
        release = "prometheus-stack"
      }
    }
    spec = {
      groups = [
        {
          name = "eks.rules"
          rules = [
            {
              alert = "KarpenterNodeNotReady"
              expr  = "kube_node_status_condition{condition=\"Ready\",status=\"true\"} == 0"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "Karpenter node not ready"
                description = "Node {{ $labels.node }} has been not ready for more than 5 minutes."
              }
            },
            {
              alert = "HighPodCPUUsage"
              expr  = "avg(rate(container_cpu_usage_seconds_total[5m])) by (pod, namespace) > 0.8"
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High CPU usage in pod"
                description = "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has high CPU usage."
              }
            },
            {
              alert = "HighPodMemoryUsage"
              expr  = "avg(container_memory_working_set_bytes) by (pod, namespace) / avg(container_spec_memory_limit_bytes) by (pod, namespace) > 0.8"
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High memory usage in pod"
                description = "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has high memory usage."
              }
            }
          ]
        }
      ]
    }
  }
}
