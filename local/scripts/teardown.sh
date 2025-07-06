#!/bin/bash

set -e

echo "🧹 Tearing down local environment..."

# Delete services
echo "🗑️  Deleting services..."
kubectl delete -k ../../applications/microservices/service-a/overlays/local --ignore-not-found=true
kubectl delete -k ../../applications/microservices/service-b/overlays/local --ignore-not-found=true

# Delete Traefik
echo "🗑️  Deleting Traefik..."
kubectl delete -k ../../infrastructure/traefik/overlays/local --ignore-not-found=true

# Delete logging stack
echo "🗑️  Deleting logging stack..."
kubectl delete -k ../../monitoring/logging-stack/overlays/local --ignore-not-found=true

# Delete Kind cluster
echo "🗑️  Deleting Kind cluster..."
kind delete cluster --name k8s-infra-local

echo "✅ Teardown complete!"