# 💰 EKS Foundation Layer - Cost Optimization Guide

## Overview

This foundation layer implements **environment-based cost optimization** for NAT gateways, allowing you to save up to **$135/month** in testing environments while maintaining high availability in production.

## 🎯 Cost Optimization Strategy

### NAT Gateway Costs

- **Single NAT Gateway**: ~$45/month + data transfer
- **Multi-AZ NAT Gateways**: ~$135/month + data transfer
- **No NAT Gateways**: $0/month (using public subnets for testing)

### Environment Configurations

| Environment    | NAT Gateways | EKS Node Subnets | Cost/Month | Internet Access       | Use Case             |
| -------------- | ------------ | ---------------- | ---------- | --------------------- | -------------------- |
| **Testing**    | 0            | Public           | $0         | Via IGW               | Development, testing |
| **Staging**    | 1            | Private          | ~$45       | Single point NAT      | Pre-production       |
| **Production** | 3            | Private          | ~$135      | High availability NAT | Production workloads |

## 🚀 Quick Start

### 1. Deploy Testing Environment (Cost: $0/month)

```bash
# Plan the deployment
./deploy.sh -e testing -a plan

# Deploy
./deploy.sh -e testing -a apply
```

### 2. Deploy Production Environment (Cost: $135/month)

```bash
# Plan the deployment
./deploy.sh -e production -a plan

# Deploy
./deploy.sh -e production -a apply
```

### 3. Deploy Staging Environment (Cost: $45/month)

```bash
# Plan the deployment
./deploy.sh -e staging -a plan

# Deploy
./deploy.sh -e staging -a apply
```

## 📋 Configuration Options

### Variables

| Variable                     | Type   | Default            | Description                                |
| ---------------------------- | ------ | ------------------ | ------------------------------------------ |
| `enable_nat_gateway`         | bool   | `true`             | Enable/disable NAT gateway creation        |
| `single_nat_gateway`         | bool   | `false`            | Use single NAT gateway vs one per AZ       |
| `use_public_subnets_for_eks` | bool   | `false`            | Use public subnets for EKS nodes (testing) |
| `environment`                | string | `"dev"`            | Environment name for tagging               |
| `aws_region`                 | string | `"ap-southeast-1"` | AWS region                                 |
| `cluster_name`               | string | `"my-cluster"`     | EKS cluster name                           |
| `vpc_cidr`                   | string | `"10.0.0.0/16"`    | VPC CIDR block                             |

### Environment Files

- `terraform.tfvars.testing` - Public subnets for EKS, no NAT gateways
- `terraform.tfvars.staging` - Private subnets for EKS, single NAT gateway
- `terraform.tfvars.production` - Private subnets for EKS, multi-AZ NAT gateways

## 🔧 Manual Deployment

### Using Terraform Directly

```bash
# Set AWS profile
export AWS_PROFILE=terraform

# Initialize Terraform
terraform init

# Plan with specific environment
terraform plan -var-file="terraform.tfvars.testing"

# Apply with specific environment
terraform apply -var-file="terraform.tfvars.production"
```

### Using Variables

```bash
# Testing environment (public subnets, no NAT gateways)
terraform apply -var="enable_nat_gateway=false" -var="use_public_subnets_for_eks=true"

# Staging environment (private subnets, single NAT gateway)
terraform apply -var="enable_nat_gateway=true" -var="single_nat_gateway=true"

# Production environment (private subnets, multi-AZ NAT gateways)
terraform apply -var="enable_nat_gateway=true" -var="single_nat_gateway=false"
```

## ⚠️ Important Considerations

### Testing Environment (Public Subnets)

- **EKS nodes in public subnets** - direct internet access via Internet Gateway
- **No NAT gateway costs** - saves $135/month
- **Security consideration**: Nodes have public IPs but security groups control access
- **Perfect for development/testing** with full connectivity

### Staging Environment (Single NAT Gateway)

- **All private subnets share one NAT gateway**
- **Potential single point of failure** for internet access
- **Cost savings**: ~$90/month vs production
- **Good for pre-production testing**

### Production Environment (Multi-AZ NAT Gateways)

- **High availability** across all AZs
- **No single point of failure**
- **Enhanced security** with private subnets
- **Recommended for production workloads**

## 📊 Cost Comparison

### Monthly AWS Costs (NAT Gateways Only)

```
Testing Environment:     $0/month    (100% savings)
Staging Environment:     $45/month   (67% savings)
Production Environment:  $135/month  (baseline)
```

### Annual Cost Savings

```
Testing vs Production:   $1,620/year savings
Staging vs Production:   $1,080/year savings
```

## 🔍 Verification

After deployment, verify the setup:

### Check NAT Gateway Creation

```bash
# List NAT gateways
aws ec2 describe-nat-gateways --region ap-southeast-1

# Check specific environment
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Environment,Values=testing" \
  --region ap-southeast-1
```

### Check EKS Node Subnets

```bash
# Check which subnets are configured for EKS nodes
terraform output eks_node_subnet_ids
terraform output eks_node_subnet_type
```

### Check Route Tables

```bash
# List route tables
aws ec2 describe-route-tables --region ap-southeast-1

# Check routes for EKS node subnets
aws ec2 describe-route-tables \
  --filter "Name=tag:Environment,Values=testing" \
  --region ap-southeast-1
```

### Test Internet Access

```bash
# Test from EKS nodes (once deployed)
kubectl run test-pod --image=alpine --rm -it --restart=Never -- wget -q --spider http://www.google.com && echo "Internet access: YES" || echo "Internet access: NO"
```

## 🛠️ Troubleshooting

### Common Issues

1. **EKS nodes in public subnets security concerns**

   - **Solution**: Security groups control access, nodes don't accept inbound traffic
   - **Best practice**: Use private subnets for production

2. **Single NAT gateway becomes bottleneck**

   - **Cause**: All traffic routes through one NAT gateway
   - **Solution**: Upgrade to multi-AZ NAT gateways

3. **Cost monitoring needed**
   - **Solution**: Set up CloudWatch cost alerts
   - **Monitor**: Data transfer costs in addition to NAT gateway costs

### Security Best Practices

#### Testing Environment (Public Subnets)

```bash
# Ensure security groups are restrictive
aws ec2 describe-security-groups \
  --group-ids sg-xxxx \
  --region ap-southeast-1
```

#### Production Environment (Private Subnets)

```bash
# Verify nodes are in private subnets
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=production" \
  --region ap-southeast-1
```

## 🎛️ Advanced Configuration

### Custom Environment

Create your own environment file:

```bash
# Create custom environment
cat > terraform.tfvars.custom << EOF
environment = "custom"
aws_region  = "ap-southeast-1"
cluster_name = "custom-cluster"
vpc_cidr     = "10.0.0.0/16"

# Custom NAT gateway configuration
enable_nat_gateway = true
single_nat_gateway = false
use_public_subnets_for_eks = false
EOF

# Deploy
terraform apply -var-file="terraform.tfvars.custom"
```

### Conditional Logic

The implementation uses Terraform's conditional logic:

```hcl
# Number of NAT gateways to create
locals {
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
}

# EKS node subnet selection
output "eks_node_subnet_ids" {
  value = var.use_public_subnets_for_eks ? aws_subnet.public[*].id : aws_subnet.private[*].id
}

# Conditional subnet tagging for EKS
tags = merge(
  {
    # Base tags
  },
  var.use_public_subnets_for_eks ? {
    "kubernetes.io/role/internal-elb" = "1"
  } : {}
)
```

## 🔒 Security Considerations

### Testing Environment Security

- **Public subnets**: Nodes have public IPs but security groups control access
- **Security groups**: Default deny all inbound, allow necessary outbound
- **Network ACLs**: Additional layer of security at subnet level
- **Monitoring**: CloudTrail logs for API calls

### Production Environment Security

- **Private subnets**: No direct internet access, enhanced security
- **NAT gateways**: Controlled outbound internet access
- **VPC Flow Logs**: Monitor network traffic patterns
- **Security groups**: Least privilege access control

## 📈 Next Steps

1. **Deploy testing environment** for cost-effective development
2. **Set up monitoring** for cost and security
3. **Configure EKS cluster** (Phase 2)
4. **Implement Karpenter** for further optimization
5. **Set up GitOps** with ArgoCD

## 🔗 Related Documentation

- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [VPC and Subnets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)
- [NAT Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [AWS Pricing Calculator](https://calculator.aws/#/)
