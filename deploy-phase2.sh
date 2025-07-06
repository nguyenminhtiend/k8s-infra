#!/bin/bash

# 🚀 Phase 2 EKS Cluster Deployment Script
# This script automates the deployment of Phase 2 - EKS Cluster & Core Components

set -e  # Exit on any error

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    # Check if we're in the right directory
    if [[ ! -f "terraform-state-bucket.txt" ]]; then
        print_error "terraform-state-bucket.txt not found. Please run from project root."
        exit 1
    fi

    # Check if Phase 1 is deployed
    if [[ ! -d "infrastructure/terraform/layers/01-foundation" ]]; then
        print_error "Phase 1 foundation layer not found."
        exit 1
    fi

    # Check if Phase 2 files exist
    if [[ ! -d "infrastructure/terraform/layers/02-cluster" ]]; then
        print_error "Phase 2 cluster layer not found."
        exit 1
    fi

    # Check required tools
    for tool in terraform aws kubectl; do
        if ! command -v $tool &> /dev/null; then
            print_error "$tool is not installed or not in PATH"
            exit 1
        fi
    done

    print_success "All prerequisites check passed!"
}

# Function to show cost information
show_cost_info() {
    echo ""
    print_status "📊 COST INFORMATION FOR PHASE 2"
    echo "======================================"
    echo "Testing Environment Monthly Costs:"
    echo "  • EKS Cluster (Control Plane): ~$72"
    echo "  • t3.micro Worker Node (1): ~$7.50"
    echo "  • EBS Volume (20GB): ~$2"
    echo "  • CloudWatch Logs: ~$1-2"
    echo "  • TOTAL: ~$82/month"
    echo ""
    echo "Additional benefits:"
    echo "  • No NAT Gateway costs (Phase 1 optimization)"
    echo "  • Single node for development efficiency"
    echo "  • ap-southeast-1 (Singapore) region"
    echo "======================================"
    echo ""
}

# Function to update terraform state bucket in tfvars files
update_bucket_name() {
    local bucket_name=$(cat terraform-state-bucket.txt)
    print_status "Updating terraform.tfvars files with bucket: $bucket_name"

    cd infrastructure/terraform/layers/02-cluster

    # Update all environment files
    for env in testing staging production; do
        if [[ -f "terraform.tfvars.$env" ]]; then
            sed -i.bak "s/your-terraform-state-bucket/$bucket_name/g" "terraform.tfvars.$env"
            print_success "Updated terraform.tfvars.$env"
        fi
    done

    cd ../../../../
}

# Function to initialize terraform
init_terraform() {
    print_status "Initializing Terraform backend..."

    local bucket_name=$(cat terraform-state-bucket.txt)

    cd infrastructure/terraform/layers/02-cluster

    terraform init \
        -backend-config="bucket=$bucket_name" \
        -backend-config="key=testing/02-cluster/terraform.tfstate" \
        -backend-config="region=ap-southeast-1" \
        -backend-config="encrypt=true" \
        -backend-config="dynamodb_table=terraform-state-lock-eks"

    cd ../../../../
    print_success "Terraform initialized successfully!"
}

# Function to plan deployment
plan_deployment() {
    print_status "Planning Phase 2 deployment..."

    cd infrastructure/terraform/layers/02-cluster

    print_status "Running terraform plan..."
    terraform plan -var-file="terraform.tfvars.testing" -out=tfplan

    cd ../../../../
    print_success "Plan completed successfully!"
}

# Function to deploy Phase 2
deploy_phase2() {
    print_status "Deploying Phase 2 - EKS Cluster & Core Components..."

    cd infrastructure/terraform/layers/02-cluster

    print_status "Applying terraform configuration..."
    terraform apply tfplan

    cd ../../../../
    print_success "Phase 2 deployment completed!"
}

# Function to validate deployment
validate_deployment() {
    print_status "Validating Phase 2 deployment..."

    cd infrastructure/terraform/layers/02-cluster

    # Get cluster name
    local cluster_name=$(terraform output -raw cluster_name)
    local cluster_endpoint=$(terraform output -raw cluster_endpoint)

    print_status "Cluster Name: $cluster_name"
    print_status "Cluster Endpoint: $cluster_endpoint"

    # Update kubeconfig
    print_status "Updating kubeconfig..."
    aws eks update-kubeconfig --region ap-southeast-1 --name "$cluster_name"

    # Test cluster access
    print_status "Testing cluster access..."
    kubectl get nodes

    print_status "Checking system pods..."
    kubectl get pods -n kube-system

    cd ../../../../
    print_success "Validation completed!"
}

# Function to show post-deployment information
show_post_deployment_info() {
    echo ""
    print_success "🎉 PHASE 2 DEPLOYMENT COMPLETE!"
    echo "=================================="
    echo ""
    echo "Next steps:"
    echo "1. Your EKS cluster is ready in ap-southeast-1 (Singapore)"
    echo "2. kubectl is configured and ready to use"
    echo "3. Single t3.micro node is running (~$82/month total cost)"
    echo ""
    echo "Useful commands:"
    echo "  kubectl get nodes                    # Check node status"
    echo "  kubectl get pods -A                 # Check all pods"
    echo "  kubectl top nodes                   # Check resource usage"
    echo ""
    echo "What's next:"
    echo "  • Phase 3: Autoscaling & Load Balancing (Karpenter)"
    echo "  • Phase 4: GitOps & Applications (ArgoCD)"
    echo ""
    echo "Documentation:"
    echo "  • Full guide: PHASE_2_DEPLOYMENT_GUIDE.md"
    echo "  • Troubleshooting: See guide for common issues"
    echo ""
    print_success "Happy Kubernetes development! 🚀"
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy Phase 2 - EKS Cluster & Core Components"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -p, --plan     Only run terraform plan (no apply)"
    echo "  -y, --yes      Skip confirmation prompts"
    echo ""
    echo "Examples:"
    echo "  $0             # Interactive deployment"
    echo "  $0 --plan      # Only show what will be created"
    echo "  $0 --yes       # Deploy without confirmation"
}

# Main execution
main() {
    local plan_only=false
    local auto_approve=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--plan)
                plan_only=true
                shift
                ;;
            -y|--yes)
                auto_approve=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Show header
    echo ""
    echo "🚀 Phase 2 EKS Cluster Deployment"
    echo "=================================="
    echo ""

    # Run prerequisite checks
    check_prerequisites

    # Show cost information
    show_cost_info

    # Confirm deployment unless auto-approve is set
    if [[ "$auto_approve" != "true" && "$plan_only" != "true" ]]; then
        echo ""
        read -p "Do you want to proceed with Phase 2 deployment? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Deployment cancelled."
            exit 0
        fi
    fi

    # Update bucket names in tfvars files
    update_bucket_name

    # Initialize Terraform
    init_terraform

    # Plan deployment
    plan_deployment

    # If plan only, exit here
    if [[ "$plan_only" == "true" ]]; then
        print_success "Plan completed. Use '$0 --yes' to deploy."
        exit 0
    fi

    # Deploy Phase 2
    deploy_phase2

    # Validate deployment
    validate_deployment

    # Show post-deployment information
    show_post_deployment_info
}

# Run main function with all arguments
main "$@"