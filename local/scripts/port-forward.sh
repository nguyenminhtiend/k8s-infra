#!/bin/bash

echo "🌐 Setting up port forwarding..."

# Port forward Traefik main ingress for DNS access
echo "🌍 Traefik Ingress: http://service-a.test:8000, http://service-b.test:8000"
kubectl port-forward -n traefik-system svc/traefik 8000:80 &

# Port forward Traefik dashboard
echo "📊 Traefik Dashboard: http://localhost:8080"
kubectl port-forward -n traefik-system svc/traefik-dashboard 8080:8080 &

# Port forward services for direct access
echo "🔗 Service A (direct): http://localhost:8081"
kubectl port-forward -n microservices svc/service-a 8081:80 &

echo "🔗 Service B (direct): http://localhost:8082"
kubectl port-forward -n microservices svc/service-b 8082:80 &

echo ""
echo "✅ Port forwarding active!"
echo "🌐 Access your services:"
echo "  - Via DNS: http://service-a.test:8000, http://service-b.test:8000"
echo "  - Direct: http://localhost:8081, http://localhost:8082"
echo "  - Dashboard: http://localhost:8080"
echo ""
echo "💡 Make sure you have in /etc/hosts:"
echo "127.0.0.1 service-a.test service-b.test"
echo ""
echo "Press Ctrl+C to stop all port forwards"

# Wait for interrupt
trap 'kill $(jobs -p)' EXIT
wait