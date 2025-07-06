# GitOps Bootstrap Module
# This module creates initial ArgoCD applications for GitOps workflow

# Bootstrap Application for Infrastructure
resource "kubernetes_manifest" "infrastructure_app" {
  count = var.gitops_repo_url != "" ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "infrastructure-${var.environment}"
      namespace = "argocd"
      labels = {
        environment = var.environment
        type        = "infrastructure"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_branch
        path           = "${var.gitops_repo_path}/infrastructure/${var.environment}"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}

# Bootstrap Application for Applications
resource "kubernetes_manifest" "applications_app" {
  count = var.gitops_repo_url != "" ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "applications-${var.environment}"
      namespace = "argocd"
      labels = {
        environment = var.environment
        type        = "applications"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_branch
        path           = "${var.gitops_repo_path}/applications/${var.environment}"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}

# Sample application for testing GitOps
resource "kubernetes_manifest" "sample_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "sample-app-${var.environment}"
      namespace = "argocd"
      labels = {
        environment = var.environment
        type        = "sample"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/argoproj/argocd-example-apps.git"
        targetRevision = "HEAD"
        path           = "guestbook"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}
