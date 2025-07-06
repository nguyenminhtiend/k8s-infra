# K8s Infrastructure - Local Development

This project sets up a local Kubernetes environment using Kind with two HTTP services (Service A and Service B) and Traefik ingress controller, following best practices for microservices deployment.

## 🏗️ Architecture

- **Kind Cluster**: 3-node Kubernetes cluster (1 control-plane, 2 workers)
- **Service A & B**: HTTP echo services with 2 replicas each
- **Traefik**: Ingress controller with dashboard
- **Kustomize**: Configuration management with base/overlay pattern

## 🚀 Quick Start

### Prerequisites

Make sure you have these tools installed:

- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### 1. Setup Everything (One Command)

```bash
make quick-start
```

### 2. Add Local DNS

```bash
echo "127.0.0.1 service-a.local service-b.local" | sudo tee -a /etc/hosts
```

### 3. Access Your Services

- **Service A**: http://service-a.local
- **Service B**: http://service-b.local
- **Traefik Dashboard**: http://localhost:8080 (with port-forward)

## 🛠️ Available Commands

```bash
make help              # Show available commands
make setup             # Setup Kind cluster with Traefik
make deploy            # Deploy services A and B
make status            # Check status of deployments
make port-forward      # Setup port forwarding
make teardown          # Teardown entire environment
```

## 🔍 Testing Your Setup

```bash
curl http://service-a.local
curl http://service-b.local
make status
```

Happy coding! 🎉
