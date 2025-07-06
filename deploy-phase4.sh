#!/bin/bash

# Phase 4 Deployment Script: GitOps & Production-Ready Observability
# This script deploys ArgoCD, Prometheus Stack, Jaeger, and Loki enhancements

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_status "🚀 Starting Phase 4 Deployment: GitOps & Observability"

# Check prerequisites
print_status "Checking prerequisites..."

if ! command_exists terraform; then
    print_error "Terraform is not installed. Please install terraform first."
    exit 1
fi

if ! command_exists kubectl; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

if ! command_exists aws; then
    print_error "AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

print_success "All prerequisites are installed ✅"

# Check if we're in the correct directory
if [ ! -f "infrastructure/terraform/layers/04-gitops-observability/main.tf" ]; then
    print_error "Please run this script from the root of the k8s-infra project"
    exit 1
fi

# Check if Phase 3 is deployed
print_status "Checking Phase 3 deployment status..."
cd infrastructure/terraform/layers/03-autoscaling

if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    print_warning "Phase 3 terraform state not found locally. This might be normal if using remote state."
fi

# Test kubectl connectivity
if ! kubectl get nodes >/dev/null 2>&1; then
    print_error "Unable to connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_success "Kubernetes cluster is accessible ✅"

# Navigate to Phase 4 directory
cd ../04-gitops-observability

# Check if terraform.tfvars.testing exists and is configured
if [ ! -f "terraform.tfvars.testing" ]; then
    print_error "terraform.tfvars.testing file not found. Please create it first."
    exit 1
fi

# Update terraform_state_bucket if needed
TERRAFORM_STATE_BUCKET=$(cat ../../../../terraform-state-bucket.txt 2>/dev/null || echo "")
if [ -n "$TERRAFORM_STATE_BUCKET" ]; then
    print_status "Updating terraform_state_bucket in terraform.tfvars.testing..."
    sed -i.bak "s/your-terraform-state-bucket-name/$TERRAFORM_STATE_BUCKET/g" terraform.tfvars.testing
    print_success "Updated terraform_state_bucket to: $TERRAFORM_STATE_BUCKET"
fi

# Initialize Terraform
print_status "Initializing Terraform backend..."
terraform init \
  -backend-config="bucket=${TERRAFORM_STATE_BUCKET:-$(cat ../../../../terraform-state-bucket.txt)}" \
  -backend-config="key=testing/04-gitops-observability/terraform.tfstate" \
  -backend-config="region=ap-southeast-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=terraform-state-lock-eks"

if [ $? -ne 0 ]; then
    print_error "Terraform initialization failed"
    exit 1
fi

print_success "Terraform initialized successfully ✅"

# Plan deployment
print_status "Planning Phase 4 deployment..."
terraform plan -var-file="terraform.tfvars.testing" -out=phase4.tfplan

if [ $? -ne 0 ]; then
    print_error "Terraform planning failed"
    exit 1
fi

print_success "Terraform plan completed successfully ✅"

# Ask for confirmation
print_warning "This will deploy the following components:"
echo "  • ArgoCD for GitOps automation"
echo "  • Prometheus Stack for metrics and monitoring"
echo "  • Grafana for visualization and dashboards"
echo "  • Jaeger for distributed tracing"
echo "  • Loki enhancements for logging"
echo ""
echo "Estimated deployment time: 15-20 minutes"
echo "Estimated cost increase: 40-65% over Phase 3 (~$65-100/month for testing)"
echo ""

read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Deployment cancelled by user"
    exit 0
fi

# Apply deployment
print_status "Applying Phase 4 deployment..."
terraform apply phase4.tfplan

if [ $? -ne 0 ]; then
    print_error "Terraform apply failed"
    exit 1
fi

print_success "Phase 4 deployment completed successfully! 🎉"

# Wait for pods to be ready
print_status "Waiting for pods to be ready..."
sleep 30

# Check ArgoCD
print_status "Checking ArgoCD deployment..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd

# Check Prometheus Stack
print_status "Checking Prometheus Stack deployment..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-stack-grafana -n monitoring
kubectl wait --for=condition=ready --timeout=300s statefulset/prometheus-prometheus-stack-prometheus -n monitoring

# Check Jaeger
print_status "Checking Jaeger deployment..."
kubectl wait --for=condition=available --timeout=300s deployment/jaeger -n jaeger

print_success "All components are ready! ✅"

# Get access information
print_status "Getting access information..."

# ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Grafana admin password
GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

# Display access information
echo ""
print_success "🎉 Phase 4 deployment completed successfully!"
echo ""
echo "================================================================="
echo "                    ACCESS INFORMATION"
echo "================================================================="
echo ""
echo "🔸 ArgoCD (GitOps Management):"
echo "   Port Forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   URL: https://localhost:8080"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "🔸 Grafana (Dashboards & Visualization):"
echo "   Port Forward: kubectl port-forward svc/grafana -n monitoring 3000:80"
echo "   URL: http://localhost:3000"
echo "   Username: admin"
echo "   Password: $GRAFANA_PASSWORD"
echo ""
echo "🔸 Prometheus (Metrics & Monitoring):"
echo "   Port Forward: kubectl port-forward svc/prometheus-server -n monitoring 9090:80"
echo "   URL: http://localhost:9090"
echo ""
echo "🔸 Jaeger (Distributed Tracing):"
echo "   Port Forward: kubectl port-forward svc/jaeger-query -n jaeger 16686:16686"
echo "   URL: http://localhost:16686"
echo ""
echo "================================================================="
echo ""
print_status "Next steps:"
echo "1. Access ArgoCD to configure GitOps workflows"
echo "2. Import Grafana dashboards for cluster monitoring"
echo "3. Configure alerting rules in Prometheus"
echo "4. Test distributed tracing with sample applications"
echo "5. Set up your GitOps repository for application deployment"
echo ""
print_status "For detailed instructions, see: PHASE_4_DEPLOYMENT_GUIDE.md"
echo ""
print_success "Phase 4 is now ready for production workloads! 🚀"