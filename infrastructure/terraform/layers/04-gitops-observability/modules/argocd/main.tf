# ArgoCD Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"

    labels = {
      name        = "argocd"
      environment = var.environment
    }
  }
}

# ArgoCD IAM Role for Pod Identity
module "argocd_pod_identity" {
  source = "../../../../modules/pod-identity/base"

  cluster_name         = var.cluster_name
  environment          = var.environment
  service_account_name = "argocd-server"
  namespace            = "argocd"

  # Add specific policies for ArgoCD
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]

  tags = var.tags
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  # Wait for deployment to be ready
  wait    = true
  timeout = 600

  values = [
    templatefile("${path.module}/values.yaml", {
      cluster_name             = var.cluster_name
      environment              = var.environment
      argocd_admin_password    = var.argocd_admin_password
      service_account_role_arn = module.argocd_pod_identity.role_arn
      github_org               = var.argocd_github_org
      github_repo              = var.argocd_github_repo
      github_token             = var.argocd_github_token
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd,
    module.argocd_pod_identity
  ]
}

# ArgoCD Admin Secret (for initial login)
resource "kubernetes_secret" "argocd_admin" {
  depends_on = [helm_release.argocd]

  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    password = var.argocd_admin_password
  }

  type = "Opaque"
}

# ArgoCD Server Service (for external access)
resource "kubernetes_service" "argocd_server_nodeport" {
  depends_on = [helm_release.argocd]

  metadata {
    name      = "argocd-server-nodeport"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  spec {
    type = "NodePort"

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
      node_port   = 30080
    }

    port {
      port        = 443
      target_port = 8080
      protocol    = "TCP"
      node_port   = 30443
    }

    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }
  }
}
