# 🚀 Phase 2 Deployment Guide: EKS Cluster & Core Components

## 📋 Overview

Phase 2 deploys the core EKS infrastructure including the Kubernetes cluster, worker nodes, IAM roles, and IRSA (IAM Roles for Service Accounts) foundation. This phase builds on the VPC foundation from Phase 1.

## ✅ Prerequisites Check

Before starting Phase 2, ensure Phase 1 is complete:

```bash
# 1. Verify Phase 1 foundation is deployed
cd infrastructure/terraform/layers/01-foundation
terraform output

# 2. Check required outputs exist
terraform output vpc_id
terraform output eks_node_subnet_ids
terraform output cluster_security_group_id
terraform output nodes_security_group_id

# 3. Verify S3 state bucket access
aws s3 ls s3://$(cat ../../../../terraform-state-bucket.txt)
```

**Expected Phase 1 Outputs:**

- ✅ VPC ID (vpc-xxxxxxxxx)
- ✅ EKS node subnet IDs (public subnets for testing)
- ✅ Security group IDs for cluster and nodes
- ✅ S3 state bucket accessible

## 🔧 Phase 2 Configuration

### Step 1: Update Configuration Files

#### 1.1 Update Terraform State Bucket Name

```bash
# Navigate to Phase 2 directory
cd infrastructure/terraform/layers/02-cluster

# Update terraform.tfvars files with your actual S3 bucket name
BUCKET_NAME=$(cat ../../../../terraform-state-bucket.txt)

# Update testing environment
sed -i "s/your-terraform-state-bucket/$BUCKET_NAME/g" terraform.tfvars.testing

# Update staging environment
sed -i "s/your-terraform-state-bucket/$BUCKET_NAME/g" terraform.tfvars.staging

# Update production environment
sed -i "s/your-terraform-state-bucket/$BUCKET_NAME/g" terraform.tfvars.production
```

#### 1.2 Configure Developer Access (Optional)

Edit `terraform.tfvars.testing` to add your developer principal ARNs:

```hcl
# Developer Access Configuration
developer_principal_arns = [
  "arn:aws:iam::YOUR_ACCOUNT_ID:user/your-username",
  "arn:aws:iam::YOUR_ACCOUNT_ID:role/your-role"
]
```

To find your account ID:

```bash
aws sts get-caller-identity --query Account --output text
```

## 🚀 Phase 2 Deployment

### Step 1: Initialize Terraform Backend

```bash
# Navigate to Phase 2 directory
cd infrastructure/terraform/layers/02-cluster

# Initialize with testing environment backend
terraform init \
  -backend-config="bucket=$(cat ../../../../terraform-state-bucket.txt)" \
  -backend-config="key=testing/02-cluster/terraform.tfstate" \
  -backend-config="region=ap-southeast-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=terraform-state-lock-eks"
```

### Step 2: Plan the Deployment

```bash
# Review the planned changes
terraform plan -var-file="terraform.tfvars.testing"

# Expected resources to be created:
# - ~15-20 resources including:
#   - IAM roles and policies (5-8 resources)
#   - EKS cluster (1 resource)
#   - EKS node group (1 resource)
#   - EKS add-ons (4 resources)
#   - OIDC provider (1 resource)
#   - IRSA test role (1 resource)
#   - Launch template (1 resource)
#   - KMS key and alias (2 resources)
#   - CloudWatch log group (1 resource)
```

### Step 3: Deploy Phase 2

```bash
# Apply the configuration
terraform apply -var-file="terraform.tfvars.testing"

# When prompted, type 'yes' to confirm
# Deployment takes approximately 10-15 minutes
```

### Step 4: Verify Deployment

```bash
# Check cluster status
terraform output cluster_name
terraform output cluster_endpoint
terraform output cluster_status

# Expected outputs:
# - cluster_name: k8s-infra-testing
# - cluster_endpoint: https://xxxxxxxxx.gr7.ap-southeast-1.eks.amazonaws.com
# - cluster_status: ACTIVE
```

## 🔍 Post-Deployment Validation

### Step 1: Configure kubectl Access

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name $(terraform output -raw cluster_name)

# Verify cluster access
kubectl get nodes

# Expected output:
# NAME                                                STATUS   ROLES    AGE   VERSION
# ip-10-0-x-x.ap-southeast-1.compute.internal       Ready    <none>   5m    v1.33.x
```

### Step 2: Verify EKS Add-ons

```bash
# Check add-on status
kubectl get pods -n kube-system

# Expected system pods:
# - aws-node-* (VPC CNI)
# - coredns-*
# - kube-proxy-*
# - ebs-csi-node-*
# - ebs-csi-controller-*
```

### Step 3: Test IRSA Functionality

```bash
# Check if OIDC provider is working
kubectl get serviceaccounts -o yaml | grep eks.amazonaws.com

# Test the example service account
kubectl describe serviceaccount test-service-account
```

### Step 4: Verify Developer Access (If Configured)

```bash
# Get developer setup instructions
terraform output developer_setup_instructions

# Test assuming developer role (if configured)
aws sts get-caller-identity
```

## 📊 Phase 2 Cost Impact

### Testing Environment Costs

| Resource Type     | Quantity | Monthly Cost   | Notes              |
| ----------------- | -------- | -------------- | ------------------ |
| EKS Cluster       | 1        | $72            | Control plane      |
| t3.micro Node     | 1        | $7.50          | Single worker node |
| EBS Volume (20GB) | 1        | $2             | Node storage       |
| CloudWatch Logs   | Minimal  | $1-2           | Cluster logs       |
| **Total**         |          | **~$82/month** | Cost-optimized     |

### Cost Optimization Features

- ✅ **Single t3.micro node** in testing (vs 3 nodes in production)
- ✅ **Minimal logging** (api, audit only)
- ✅ **Public subnets** (no NAT Gateway costs)
- ✅ **20GB EBS volumes** (vs 50GB in production)
- ✅ **7-day log retention** (vs 90 days in production)

## 🛠️ Troubleshooting

### Common Issues

#### 1. Node Group Creation Fails

```bash
# Check IAM role permissions
aws iam get-role --role-name EKS-NodeGroupServiceRole-testing

# Verify subnet tags
aws ec2 describe-subnets --subnet-ids $(terraform output -raw eks_node_subnet_ids | tr ',' ' ')
```

#### 2. Pods Stuck in Pending

```bash
# Check node status
kubectl describe nodes

# Check for resource constraints
kubectl top nodes

# For t3.micro, ensure resource requests are small
```

#### 3. IRSA Not Working

```bash
# Verify OIDC provider
aws iam list-open-id-connect-providers

# Check cluster OIDC URL
terraform output cluster_oidc_issuer_url
```

#### 4. kubectl Access Denied

```bash
# Update kubeconfig with correct cluster name
aws eks update-kubeconfig --region ap-southeast-1 --name k8s-infra-testing

# Check AWS credentials
aws sts get-caller-identity

# Verify cluster exists
aws eks describe-cluster --name k8s-infra-testing --region ap-southeast-1
```

## 🧹 Cleanup (If Needed)

```bash
# To destroy Phase 2 resources
terraform destroy -var-file="terraform.tfvars.testing"

# Note: This will NOT affect Phase 1 foundation infrastructure
```

## 📋 Phase 2 Completion Checklist

- [ ] ✅ Terraform backend initialized successfully
- [ ] ✅ All 15-20 resources created without errors
- [ ] ✅ EKS cluster status is ACTIVE
- [ ] ✅ Single t3.micro node is Ready
- [ ] ✅ All system pods are Running
- [ ] ✅ kubectl access working
- [ ] ✅ IRSA OIDC provider created
- [ ] ✅ Developer roles configured (if applicable)
- [ ] ✅ Cost monitoring shows ~$82/month

## 🎯 Next Steps: Phase 3

Once Phase 2 is complete, you'll be ready for:

1. **Phase 3: Autoscaling & Load Balancing**

   - Karpenter for intelligent node provisioning
   - AWS Load Balancer Controller
   - External DNS controller
   - Cluster Autoscaler (fallback)

2. **Phase 4: GitOps & Applications**
   - ArgoCD installation
   - Application deployments
   - Monitoring stack

## 💡 Tips for Success

1. **Start with Testing**: Always deploy testing environment first
2. **Monitor Costs**: Use AWS Cost Explorer to track spending
3. **Resource Limits**: Set appropriate resource requests/limits for t3.micro
4. **Gradual Scaling**: Start small, scale as needed
5. **Documentation**: Keep track of cluster endpoints and access methods

## 🔗 Useful Commands Reference

```bash
# Get cluster info
terraform output cluster_name
terraform output cluster_endpoint
terraform output kubeconfig_command

# Check node capacity
kubectl describe node $(kubectl get nodes -o name | head -1)

# Monitor resource usage
kubectl top nodes
kubectl top pods -A

# Get developer instructions
terraform output developer_setup_instructions
```

---

**Phase 2 creates a production-ready EKS cluster optimized for development and testing with intelligent cost management.** 🚀
