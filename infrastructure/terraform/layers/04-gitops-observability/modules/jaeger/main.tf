# Jaeger Namespace
resource "kubernetes_namespace" "jaeger" {
  metadata {
    name = "jaeger"

    labels = {
      name        = "jaeger"
      environment = var.environment
    }
  }
}

# Jaeger IAM Role for Pod Identity
module "jaeger_pod_identity" {
  source = "../../../../modules/pod-identity/base"

  cluster_name         = var.cluster_name
  environment          = var.environment
  service_account_name = "jaeger"
  namespace            = "jaeger"

  # Add specific policies for Jaeger
  policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  tags = var.tags
}

# Jaeger Storage Class
resource "kubernetes_storage_class" "jaeger_storage" {
  metadata {
    name = "jaeger-storage"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
}

# Jaeger Helm Release
resource "helm_release" "jaeger" {
  name       = "jaeger"
  namespace  = kubernetes_namespace.jaeger.metadata[0].name
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  version    = var.jaeger_chart_version

  # Wait for deployment to be ready
  wait    = true
  timeout = 600

  values = [
    templatefile("${path.module}/values.yaml", {
      cluster_name             = var.cluster_name
      environment              = var.environment
      jaeger_retention_days    = var.jaeger_retention_days
      jaeger_storage_size      = var.jaeger_storage_size
      service_account_role_arn = module.jaeger_pod_identity.role_arn
      storage_class_name       = kubernetes_storage_class.jaeger_storage.metadata[0].name
    })
  ]

  depends_on = [
    kubernetes_namespace.jaeger,
    module.jaeger_pod_identity,
    kubernetes_storage_class.jaeger_storage
  ]
}

# Jaeger Query NodePort Service
resource "kubernetes_service" "jaeger_query_nodeport" {
  depends_on = [helm_release.jaeger]

  metadata {
    name      = "jaeger-query-nodeport"
    namespace = kubernetes_namespace.jaeger.metadata[0].name
  }

  spec {
    type = "NodePort"

    port {
      port        = 16686
      target_port = 16686
      protocol    = "TCP"
      node_port   = 30686
    }

    selector = {
      "app.kubernetes.io/component" = "query"
      "app.kubernetes.io/name"      = "jaeger"
    }
  }
}
