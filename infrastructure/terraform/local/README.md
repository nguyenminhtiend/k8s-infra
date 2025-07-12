# Local Terraform Testing with LocalStack

This directory contains Terraform configurations for local testing using LocalStack and Kind. It provides a complete local development environment that simulates AWS infrastructure and Kubernetes deployments.

## 🏗️ Architecture Overview

The local testing setup consists of three main components:

1. **LocalStack**: Simulates AWS services locally
2. **Kind**: Provides a local Kubernetes cluster  
3. **Terraform**: Manages infrastructure as code for both

### Directory Structure

```
infrastructure/terraform/local/
├── docker-compose.yml          # LocalStack container setup
├── init/                       # LocalStack initialization scripts
├── scripts/
│   └── tflocal                 # Terraform wrapper for LocalStack
├── layers/
│   ├── 01-foundation/          # VPC, subnets, security groups (LocalStack)
│   ├── 02-cluster/             # EKS cluster simulation (LocalStack)
│   └── 03-kubernetes/          # Kubernetes resources (Kind)
└── tests/                      # Terraform test files
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Terraform >= 1.0
- kubectl
- Kind (for Kubernetes testing)

### 1. Setup Everything

```bash
# Start LocalStack and apply Terraform configs
make terraform-local-quick

# Or step by step:
make terraform-local-setup     # Start LocalStack
make terraform-local-apply     # Apply Terraform configs
```

### 2. Setup Kind Cluster (for Kubernetes testing)

```bash
# Setup Kind cluster with Traefik
make setup

# Deploy Kubernetes resources via Terraform
cd infrastructure/terraform/local/layers/03-kubernetes
terraform init
terraform plan -var-file="terraform.tfvars.local"
terraform apply -var-file="terraform.tfvars.local"
```

### 3. Verify Setup

```bash
# Check LocalStack and Terraform resources
make terraform-local-status

# Check Kind cluster
kubectl get nodes
kubectl get pods -A
```

## 🧪 Testing Workflows

### Option 1: LocalStack Only (AWS Simulation)

Test AWS infrastructure components without real AWS costs:

```bash
# Plan changes
make terraform-local-plan

# Apply changes
make terraform-local-apply

# Run Terraform tests
make terraform-local-test

# Check resources
make terraform-local-status
```

### Option 2: Kind + Terraform (Kubernetes)

Test Kubernetes resources using Terraform against Kind:

```bash
# Ensure Kind cluster is running
make setup

# Apply Kubernetes configurations
cd infrastructure/terraform/local/layers/03-kubernetes
terraform init
terraform apply -var-file="terraform.tfvars.local"

# Test services
curl http://service-a.local  # (add to /etc/hosts first)
curl http://service-b.local
```

### Option 3: Hybrid Testing

Combine LocalStack and Kind for full stack testing:

```bash
# 1. Start LocalStack
make terraform-local-setup

# 2. Setup Kind cluster
make setup

# 3. Apply AWS simulation (LocalStack)
make terraform-local-apply

# 4. Apply Kubernetes resources (Kind)
cd infrastructure/terraform/local/layers/03-kubernetes
terraform apply -var-file="terraform.tfvars.local"
```

## 📊 What Gets Tested

### LocalStack Layers

1. **Foundation Layer** (`01-foundation/`)
   - VPC creation and configuration
   - Subnet creation (public/private)
   - Security groups
   - Internet Gateway
   - Route tables

2. **Cluster Layer** (`02-cluster/`)
   - EKS cluster simulation
   - IAM roles and policies
   - CloudWatch log groups
   - Node groups

### Kind Integration

3. **Kubernetes Layer** (`03-kubernetes/`)
   - Namespace creation
   - Service deployments (A & B)
   - Kubernetes services
   - Ingress configuration
   - Resource limits and requests

## 🔧 Configuration Files

### LocalStack Configuration

- `docker-compose.yml`: LocalStack container setup
- `init/setup.sh`: LocalStack initialization script
- `scripts/tflocal`: Terraform wrapper for LocalStack endpoints

### Terraform Variables

Each layer has local-specific variables:

- `terraform.tfvars.local`: Local environment settings
- Optimized for testing (no NAT gateways, minimal resources)
- LocalStack-compatible configurations

### Provider Configurations

LocalStack layers use special provider configurations:

```hcl
provider "aws" {
  region                      = "ap-southeast-1"
  access_key                 = "test"
  secret_key                 = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    eks = "http://localhost:4566"
    iam = "http://localhost:4566"
    # ... other services
  }
}
```

## 🧪 Terraform Testing

### Native Terraform Tests

Run built-in Terraform tests:

```bash
# Test foundation layer
cd infrastructure/terraform/local/layers/01-foundation
terraform test

# Test individual modules
cd infrastructure/terraform/modules/networking/vpc
terraform test
```

### Test Files

- `foundation.tftest.hcl`: Tests VPC, subnet, and security group creation
- `vpc.tftest.hcl`: Tests VPC module functionality
- `subnets.tftest.hcl`: Tests subnet configuration and CIDR calculations

## 🔍 Debugging and Troubleshooting

### LocalStack Issues

```bash
# Check LocalStack health
curl http://localhost:4566/_localstack/health

# View LocalStack logs
cd infrastructure/terraform/local
docker-compose logs -f localstack

# Reset LocalStack
make terraform-local-teardown
make terraform-local-setup
```

### Terraform Issues

```bash
# Check Terraform state
cd infrastructure/terraform/local/layers/01-foundation
terraform show

# Validate configuration
terraform validate

# Debug with verbose output
TF_LOG=DEBUG terraform plan
```

### Kind Issues

```bash
# Check Kind cluster
kind get clusters
kubectl cluster-info --context kind-local-cluster

# Restart Kind cluster
make teardown
make setup
```

## 🧹 Cleanup

### Clean LocalStack

```bash
# Destroy Terraform resources
make terraform-local-destroy

# Stop LocalStack
make terraform-local-teardown
```

### Clean Kind

```bash
# Clean Kubernetes resources
cd infrastructure/terraform/local/layers/03-kubernetes
terraform destroy -var-file="terraform.tfvars.local"

# Teardown Kind cluster
make teardown
```

### Complete Cleanup

```bash
# Clean everything
make terraform-local-destroy
make terraform-local-teardown
make teardown
```

## 💡 Tips and Best Practices

### LocalStack

- Use the `tflocal` script instead of `terraform` directly
- LocalStack provides free simulation of basic AWS services
- Data persists during container restarts (using volumes)
- Pro features require LocalStack Pro subscription

### Testing Strategy

1. **Unit Tests**: Test individual modules with Terraform tests
2. **Integration Tests**: Test layer interactions with LocalStack
3. **End-to-End Tests**: Test full stack with LocalStack + Kind

### Performance

- LocalStack startup takes ~10 seconds
- Terraform apply is much faster than real AWS
- Kind provides instant Kubernetes feedback
- Use `make terraform-local-quick` for rapid iteration

### Cost Optimization

- No AWS costs for LocalStack testing
- Disabled NAT gateways in local configs
- Minimal resource specifications
- Fast iteration without infrastructure wait times

## 🔗 Integration with Existing Workflow

This local testing setup complements the existing development workflow:

1. **Local Development**: Use Kind + Kustomize (existing `make setup`)
2. **Infrastructure Testing**: Use LocalStack + Terraform (new capability)
3. **AWS Deployment**: Use real Terraform layers (existing process)

The local Terraform testing provides a bridge between local Kubernetes development and AWS production deployment, allowing you to validate infrastructure code before applying to real AWS resources.