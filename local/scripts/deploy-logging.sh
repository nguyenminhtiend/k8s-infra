#!/bin/bash

set -e

echo "🚀 Deploying Logging Stack (Fluent Bit + Loki + Grafana)..."

# Change to project root
cd "$(dirname "$0")/../.."

# Deploy logging stack
echo "📊 Deploying logging components..."
kubectl apply -k monitoring/logging-stack/overlays/local

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."

# Wait for Loki
kubectl wait --for=condition=available --timeout=300s deployment/loki -n logging
echo "✅ Loki is ready"

# Wait for Grafana
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n logging
echo "✅ Grafana is ready"

# Wait for Fluent Bit
kubectl wait --for=condition=ready --timeout=300s daemonset/fluent-bit -n logging
echo "✅ Fluent Bit is ready"

echo ""
echo "🎉 Logging Stack deployed successfully!"
echo ""
echo "📊 Access URLs:"
echo "  Grafana: http://localhost:30300"
echo "  Grafana (via Traefik): http://grafana.test (add to /etc/hosts)"
echo "  Loki: http://localhost:3100 (internal)"
echo ""
echo "🔐 Grafana Credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "📝 To view logs in Grafana:"
echo "  1. Go to Explore"
echo "  2. Select 'Loki' datasource"
echo "  3. Use query: {namespace=\"microservices\"}"
echo ""