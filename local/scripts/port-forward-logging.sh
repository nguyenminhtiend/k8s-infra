#!/bin/bash

echo "🌐 Setting up port forwarding for logging stack..."

# Function to run port-forward in background
port_forward() {
    local service=$1
    local namespace=$2
    local local_port=$3
    local remote_port=$4
    local description=$5

    echo "📡 Port forwarding $description ($service:$remote_port -> localhost:$local_port)"
    kubectl port-forward -n $namespace service/$service $local_port:$remote_port &
    sleep 2
}

# Kill existing port-forwards
echo "🧹 Killing existing port-forwards..."
pkill -f "kubectl port-forward" || true
sleep 2

# Port forward logging services
port_forward "grafana" "logging" "3000" "3000" "Grafana"
port_forward "loki" "logging" "3100" "3100" "Loki"

echo ""
echo "🎉 Port forwarding setup complete!"
echo ""
echo "📊 Access URLs:"
echo "  Grafana: http://localhost:3000"
echo "  Loki: http://localhost:3100"
echo ""
echo "🔐 Grafana Credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "⚠️  Press Ctrl+C to stop all port forwards"
echo ""

# Wait for interrupt
trap 'echo "🛑 Stopping port forwards..."; pkill -f "kubectl port-forward"; exit 0' INT
while true; do sleep 1; done