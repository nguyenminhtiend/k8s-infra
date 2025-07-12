# Local Terraform Testing - Separate Approaches

This directory contains Terraform configurations for local testing using **two independent approaches**. Each approach serves different testing purposes and they are **NOT connected** to each other.

## 🏗️ Architecture Overview

**IMPORTANT**: These are **separate, independent** testing environments:

### **Approach 1: LocalStack (AWS Infrastructure Testing)**
- **Purpose**: Test AWS infrastructure code (VPC, IAM, EKS)
- **What it simulates**: AWS APIs only (no real Kubernetes)
- **Use case**: Validate Terraform modules before AWS deployment

### **Approach 2: Kind (Kubernetes Application Testing)**
- **Purpose**: Test Kubernetes applications and manifests
- **What it provides**: Real Kubernetes cluster locally
- **Use case**: Test deployments, services, ingress (use existing workflow)

**❌ These are NOT connected** - LocalStack EKS is simulated, Kind is real K8s

### Directory Structure

```
infrastructure/terraform/local/
├── docker-compose.yml          # LocalStack container setup
├── init/                       # LocalStack initialization scripts
├── scripts/
│   └── tflocal                 # Terraform wrapper for LocalStack
├── layers/
│   ├── 01-foundation/          # VPC, subnets (LocalStack ONLY)
│   ├── 02-cluster/             # EKS simulation (LocalStack ONLY)
│   └── 03-kubernetes/          # ⚠️ DEPRECATED - Use existing Kind workflow
└── tests/                      # Terraform test files
```

**Note**: The `03-kubernetes/` layer is deprecated. Use the existing Kind workflow in the root directory instead.

## 🚀 Quick Start - Choose Your Testing Approach

### Prerequisites

- Docker and Docker Compose
- Terraform >= 1.0
- kubectl (for Kind testing only)
- Kind (for Kubernetes testing only)

## **Approach 1: LocalStack (AWS Infrastructure Testing)**

### Setup and Test AWS Infrastructure

```bash
# Start LocalStack and test infrastructure
make terraform-local-setup     # Start LocalStack
make terraform-local-apply     # Test VPC, EKS creation
make terraform-local-status    # Verify resources
```

### What This Tests
- VPC, subnets, security groups creation
- EKS cluster configuration (simulated)
- IAM roles and policies
- Terraform module logic

## **Approach 2: Kind (Kubernetes Application Testing)**

### Use Existing Workflow (Recommended)

```bash
# Use the existing, proven Kind workflow
make setup              # Setup Kind cluster with Traefik
make deploy             # Deploy services A and B
make status             # Check deployments
```

### What This Tests
- Real Kubernetes deployments
- Service discovery and networking
- Ingress and load balancing
- Application functionality

## 🧪 Testing Workflows

### **Workflow 1: AWS Infrastructure Testing (LocalStack)**

Test AWS infrastructure components without real AWS costs:

```bash
# Start LocalStack
make terraform-local-setup

# Test infrastructure code
make terraform-local-plan     # Validate Terraform plans
make terraform-local-apply    # Create simulated resources
make terraform-local-test     # Run Terraform tests
make terraform-local-status   # Check resource status

# Cleanup
make terraform-local-destroy
make terraform-local-teardown
```

**What gets tested:**
- VPC and subnet creation logic
- Security group configurations  
- EKS cluster parameters
- IAM role relationships
- Terraform state management

### **Workflow 2: Kubernetes Application Testing (Kind)**

**Use the existing, proven workflow** (no Terraform needed):

```bash
# Setup Kind cluster
make setup

# Deploy applications
make deploy

# Test applications
curl http://service-a.local  # (add to /etc/hosts first)
curl http://service-b.local
make status

# Optional: Deploy logging
make deploy-logging
make port-forward-logging

# Cleanup
make teardown
```

**What gets tested:**
- Real Kubernetes deployments
- Service networking
- Ingress functionality
- Application health

### **❌ Hybrid Testing (NOT Recommended)**

**Don't try to combine them** - they are separate testing environments that don't communicate.

## 📊 What Gets Tested

### **LocalStack Testing (AWS Infrastructure)**

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
   - Node groups (simulated)

### **Kind Testing (Real Kubernetes)**

**Use existing workflows** in the root directory:
- Namespace creation (via Kustomize)
- Service deployments A & B (via YAML manifests)
- Kubernetes services and ingress
- Traefik load balancing
- Logging stack (Fluent Bit, Loki, Grafana)

## 🔧 Configuration Files

### **LocalStack Configuration**

- `docker-compose.yml`: LocalStack container setup
- `init/setup.sh`: LocalStack initialization script
- `scripts/tflocal`: Terraform wrapper for LocalStack endpoints

### **Terraform Variables (LocalStack)**

Layers 01-02 have local-specific variables:

- `terraform.tfvars.local`: Local environment settings
- Optimized for testing (no NAT gateways, minimal resources)
- LocalStack-compatible configurations

### **Provider Configurations (LocalStack)**

Layers 01-02 use special provider configurations:

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

### **Kind Configuration**

Use existing configurations in the root directory:
- `local/kind/cluster-config.yaml`: Kind cluster setup
- `applications/microservices/`: Kustomize manifests
- `monitoring/`: Logging stack configurations

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

### **LocalStack Issues**

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

### **Terraform Issues (LocalStack)**

```bash
# Check Terraform state (foundation layer)
cd infrastructure/terraform/local/layers/01-foundation
terraform show

# Validate configuration
terraform validate

# Debug with verbose output
TF_LOG=DEBUG terraform plan
```

### **Kind Issues**

**Use existing troubleshooting** from root directory workflows:

```bash
# Check Kind cluster
kind get clusters
kubectl cluster-info --context kind-local-cluster

# Check services
make status

# Restart Kind cluster
make teardown
make setup
```

## 🧹 Cleanup

### **Clean LocalStack**

```bash
# Destroy Terraform resources
make terraform-local-destroy

# Stop LocalStack
make terraform-local-teardown
```

### **Clean Kind**

**Use existing cleanup** (no Terraform needed):

```bash
# Teardown Kind cluster and all resources
make teardown
```

### **Clean Both (If Used Separately)**

```bash
# Clean LocalStack testing
make terraform-local-destroy
make terraform-local-teardown

# Clean Kind testing
make teardown
```

## 💡 Tips and Best Practices

### **LocalStack Testing**

- Use the `tflocal` script instead of `terraform` directly
- LocalStack provides free simulation of basic AWS services
- Data persists during container restarts (using volumes)
- Pro features require LocalStack Pro subscription
- **Purpose**: Test infrastructure logic, not real Kubernetes

### **Kind Testing**

- Use existing workflows (`make setup`, `make deploy`)
- Real Kubernetes provides actual networking and functionality
- Faster feedback than AWS EKS
- **Purpose**: Test application deployments and K8s functionality

### **Testing Strategy**

1. **Infrastructure Validation**: Use LocalStack for Terraform modules
2. **Application Testing**: Use Kind for Kubernetes workloads
3. **AWS Deployment**: Use real Terraform layers after local validation

### **Performance**

- LocalStack startup takes ~10 seconds
- Terraform apply is much faster than real AWS
- Kind provides instant Kubernetes feedback
- **Don't mix them** - use separately for best performance

### **Cost Optimization**

- No AWS costs for LocalStack testing
- No cloud costs for Kind testing
- Fast iteration without infrastructure wait times
- Test early, deploy to AWS only when confident

## 🎯 **Recommended Workflow**

1. **Infrastructure Development**: Test with LocalStack first
   ```bash
   make terraform-local-setup
   make terraform-local-apply
   ```

2. **Application Development**: Test with Kind
   ```bash
   make setup
   make deploy
   ```

3. **AWS Deployment**: Deploy to real AWS after local validation
   ```bash
   cd infrastructure/terraform/layers/01-foundation
   terraform apply -var-file="terraform.tfvars.staging"
   ```

**⚠️ Important**: These are **separate testing approaches** - don't try to connect LocalStack EKS to Kind cluster. They serve different purposes in your development workflow.

---

## 🚫 What NOT to Do

1. **Don't try to connect LocalStack EKS to Kind cluster** - they are separate environments
2. **Don't use the 03-kubernetes layer** - use existing Kind workflows instead
3. **Don't expect LocalStack EKS to run real pods** - it's just API simulation
4. **Don't mix the approaches** - use them independently for their specific purposes

## ✅ What TO Do

1. **Use LocalStack for infrastructure testing** - validate your Terraform modules
2. **Use Kind for application testing** - test your Kubernetes workloads
3. **Use existing workflows** - leverage the proven `make setup` and `make deploy` commands
4. **Test separately, deploy confidently** - validate locally before AWS deployment