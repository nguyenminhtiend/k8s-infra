.PHONY: help setup deploy teardown port-forward status clean deploy-logging logs-logging port-forward-logging

help: ## Show this help message
	@echo "🚀 K8s Infrastructure - Local Development"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Setup Kind cluster with Traefik
	@echo "🚀 Setting up local infrastructure..."
	@cd local/kind && ./setup.sh

deploy: ## Deploy services A and B
	@echo "🚀 Deploying services..."
	@cd local/scripts && ./deploy-services.sh

deploy-logging: ## Deploy logging stack (Fluent Bit + Loki + Grafana)
	@echo "🚀 Deploying logging stack..."
	@cd local/scripts && ./deploy-logging.sh



teardown: ## Teardown entire local environment
	@echo "🧹 Tearing down local environment..."
	@cd local/scripts && ./teardown.sh

port-forward: ## Setup port forwarding for services
	@echo "🌐 Setting up port forwarding..."
	@cd local/scripts && ./port-forward.sh

port-forward-logging: ## Setup port forwarding for logging services
	@echo "🌐 Setting up port forwarding for logging..."
	@cd local/scripts && ./port-forward-logging.sh

status: ## Check status of deployments
	@echo "📊 Checking status..."
	@echo "Pods:"
	@kubectl get pods -o wide -n microservices
	@echo ""
	@echo "Services:"
	@kubectl get services -n microservices
	@echo ""
	@echo "IngressRoutes:"
	@kubectl get ingressroutes -n microservices
	@echo ""
	@echo "Traefik status:"
	@kubectl get pods -n traefik-system
	@echo ""
	@echo "Logging status:"
	@kubectl get pods -n logging

logs-a: ## Show logs for Service A
	@kubectl logs -l app=service-a --tail=50 -f -n microservices

logs-b: ## Show logs for Service B
	@kubectl logs -l app=service-b --tail=50 -f -n microservices

logs-traefik: ## Show Traefik logs
	@kubectl logs -n traefik-system -l app=traefik --tail=50 -f

logs-logging: ## Show logging stack logs
	@echo "📊 Logging Stack Logs:"
	@echo "=== Loki ==="
	@kubectl logs -n logging -l app=loki --tail=20
	@echo ""
	@echo "=== Grafana ==="
	@kubectl logs -n logging -l app=grafana --tail=20
	@echo ""
	@echo "=== Fluent Bit ==="
	@kubectl logs -n logging -l app=fluent-bit --tail=20

clean: ## Clean up resources but keep cluster
	@echo "🧹 Cleaning up services..."
	@kubectl delete -k applications/microservices/service-a/overlays/local --ignore-not-found=true
	@kubectl delete -k applications/microservices/service-b/overlays/local --ignore-not-found=true

clean-logging: ## Clean up logging stack
	@echo "🧹 Cleaning up logging stack..."
	@kubectl delete -k monitoring/logging-stack/overlays/local --ignore-not-found=true



restart: ## Restart services
	@echo "🔄 Restarting services..."
	@kubectl rollout restart deployment/service-a -n microservices
	@kubectl rollout restart deployment/service-b -n microservices
	@kubectl rollout status deployment/service-a -n microservices
	@kubectl rollout status deployment/service-b -n microservices

# Quick setup - run everything in sequence
quick-start: setup deploy ## Setup cluster and deploy services in one command
	@echo "✅ Quick start complete!"
	@echo ""
	@echo "⚠️  To access services via DNS, run:"
	@echo "  make port-forward"
	@echo ""
	@echo "🌐 Then your services will be available at:"
	@echo "  - Service A: http://service-a.test:8000"
	@echo "  - Service B: http://service-b.test:8000"
	@echo ""
	@echo "💡 Make sure you have in /etc/hosts:"
	@echo "127.0.0.1 service-a.test service-b.test"

