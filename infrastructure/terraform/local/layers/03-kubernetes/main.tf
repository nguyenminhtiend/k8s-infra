# Local Kubernetes Layer - Kind Integration
# This layer manages Kubernetes resources using the existing Kind cluster

terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }

  # Local backend for testing
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Configure Kubernetes provider to use Kind cluster
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-local-cluster"  # Default Kind cluster context
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-local-cluster"
  }
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "kind-local-cluster"
}

# Create namespace for microservices
resource "kubernetes_namespace" "microservices" {
  metadata {
    name = "microservices"
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# Create namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# Deploy Service A using Kubernetes provider
resource "kubernetes_deployment" "service_a" {
  metadata {
    name      = "service-a"
    namespace = kubernetes_namespace.microservices.metadata[0].name
    labels = {
      app         = "service-a"
      environment = var.environment
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "service-a"
      }
    }

    template {
      metadata {
        labels = {
          app = "service-a"
        }
      }

      spec {
        container {
          image = "hashicorp/http-echo:latest"
          name  = "service-a"

          args = [
            "-text=Hello from Service A (Terraform + Kind)!",
            "-listen=:8080"
          ]

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }
        }
      }
    }
  }
}

# Create Service for Service A
resource "kubernetes_service" "service_a" {
  metadata {
    name      = "service-a"
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }

  spec {
    selector = {
      app = "service-a"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

# Deploy Service B using Kubernetes provider  
resource "kubernetes_deployment" "service_b" {
  metadata {
    name      = "service-b"
    namespace = kubernetes_namespace.microservices.metadata[0].name
    labels = {
      app         = "service-b"
      environment = var.environment
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "service-b"
      }
    }

    template {
      metadata {
        labels = {
          app = "service-b"
        }
      }

      spec {
        container {
          image = "hashicorp/http-echo:latest"
          name  = "service-b"

          args = [
            "-text=Hello from Service B (Terraform + Kind)!",
            "-listen=:8080"
          ]

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }
        }
      }
    }
  }
}

# Create Service for Service B
resource "kubernetes_service" "service_b" {
  metadata {
    name      = "service-b"
    namespace = kubernetes_namespace.microservices.metadata[0].name
  }

  spec {
    selector = {
      app = "service-b"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

# Create Ingress for both services (assuming Traefik is already deployed)
resource "kubernetes_ingress_v1" "services_ingress" {
  metadata {
    name      = "services-ingress"
    namespace = kubernetes_namespace.microservices.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }

  spec {
    rule {
      host = "service-a.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.service_a.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = "service-b.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.service_b.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}