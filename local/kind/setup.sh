#!/bin/bash

set -e

echo "🚀 Setting up local Kind cluster..."

# Create Kind cluster
kind create cluster --config=cluster-config.yaml

# Wait for cluster to be ready
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install Traefik
echo "📦 Installing Traefik..."
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.4/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml

# Apply Traefik configuration
kubectl apply -k ../../infrastructure/traefik/overlays/local

# Wait for Traefik to be ready
kubectl -n traefik-system wait --for=condition=available --timeout=300s deployment/traefik

echo "✅ Kind cluster is ready!"
echo "🌐 Access your services at:"
echo "  - Service A: http://service-a.test"
echo "  - Service B: http://service-b.test"
echo ""
echo "💡 Add these to your /etc/hosts:"
echo "127.0.0.1 service-a.test service-b.test"