#!/bin/bash

set -e

echo "🚀 Deploying services to local Kind cluster..."

# Create microservices namespace
echo "📦 Creating microservices namespace..."
kubectl create namespace microservices --dry-run=client -o yaml | kubectl apply -f -

# Deploy Service A
echo "🔄 Deploying Service A..."
kubectl apply -k ../../applications/microservices/service-a/overlays/local

# Deploy Service B
echo "🔄 Deploying Service B..."
kubectl apply -k ../../applications/microservices/service-b/overlays/local

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/service-a -n microservices
kubectl wait --for=condition=available --timeout=60s deployment/service-b -n microservices

echo "✅ Services deployed successfully!"
echo ""
echo "⚠️  To access services via DNS, run port forwarding:"
echo "  make port-forward"
echo ""
echo "🌐 Then access your services:"
echo "  - Service A: http://service-a.test:8000"
echo "  - Service B: http://service-b.test:8000"
echo "  - Traefik Dashboard: http://localhost:8080"
echo ""
echo "📊 Check status:"
echo "  kubectl get pods"
echo "  kubectl get services"
echo "  kubectl get ingressroutes"