# 🚀 Phase 3 Deployment Guide: Autoscaling & Load Balancing

## 📋 Overview

Phase 3 transforms your EKS cluster into an intelligent, auto-scaling platform with advanced load balancing capabilities. This phase implements:

- **Karpenter**: Intelligent node provisioning and scaling
- **AWS Load Balancer Controller**: Native AWS load balancer integration
- **External DNS**: Automatic DNS management
- **Cluster Autoscaler**: Fallback scaling mechanism

## ✅ Prerequisites Check

Before starting Phase 3, ensure Phase 2 is complete and working:

```bash
# 1. Verify Phase 2 cluster is running
cd infrastructure/terraform/layers/02-cluster
terraform output cluster_name
terraform output cluster_status

# 2. Verify kubectl access
kubectl get nodes
kubectl get pods -A

# 3. Check required outputs exist
terraform output cluster_oidc_issuer_url
terraform output oidc_provider_arn
terraform output cluster_endpoint
```

**Expected Phase 2 Outputs:**

- ✅ EKS cluster is ACTIVE
- ✅ Single t3.micro node is Ready
- ✅ All system pods are Running
- ✅ OIDC provider is configured
- ✅ kubectl access working

## 🏗️ Phase 3 Architecture

**Current State (Post-Phase 2):**

```
Internet → ALB → EKS Cluster → Single t3.micro node → Pods
```

**Target State (Post-Phase 3):**

```
Internet → Route53 → ALB (Auto-provisioned) → EKS Cluster → Karpenter-managed nodes → Optimized pods
```

## 🔧 Phase 3 Configuration Files

### Step 1: Create Terraform Configuration Files

Navigate to Phase 3 directory and create the configuration files:

```bash
cd infrastructure/terraform/layers/03-autoscaling
```

I'll create all necessary files for you in the next steps.

## 📊 Phase 3 Cost Impact

### Testing Environment Costs (Projected)

| Resource Type             | Monthly Cost | Notes                      |
| ------------------------- | ------------ | -------------------------- |
| EKS Cluster               | $72          | Same as Phase 2            |
| Karpenter Nodes (dynamic) | $15-45       | t3.small-medium, spot      |
| ALB                       | $18          | Per load balancer          |
| Route53 Queries           | $1-2         | DNS queries                |
| EBS Volumes (dynamic)     | $4-12        | Based on nodes             |
| **Total**                 | **$110-151** | **Variable based on load** |

### Key Cost Optimizations

- ✅ **Spot Instance Priority**: 70% spot instances for cost savings
- ✅ **Automatic Scale-Down**: Unused nodes terminated within 30 seconds
- ✅ **Right-Sizing**: Optimal instance types selected automatically
- ✅ **Bin Packing**: Efficient pod placement reduces node count

## 🚀 Phase 3 Implementation Steps

### Step 1: Initialize Terraform Backend

```bash
# Navigate to Phase 3 directory
cd infrastructure/terraform/layers/03-autoscaling

# Initialize with testing environment backend
terraform init \
  -backend-config="bucket=$(cat ../../../../terraform-state-bucket.txt)" \
  -backend-config="key=testing/03-autoscaling/terraform.tfstate" \
  -backend-config="region=ap-southeast-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=terraform-state-lock-eks"
```

### Step 2: Plan the Deployment

```bash
# Review the planned changes
terraform plan -var-file="terraform.tfvars.testing"

# Expected resources to be created:
# - ~25-30 resources including:
#   - Karpenter IAM roles and policies (5-8 resources)
#   - AWS Load Balancer Controller (3-5 resources)
#   - External DNS (2-3 resources)
#   - Cluster Autoscaler (2-3 resources)
#   - Helm releases (4 resources)
#   - Various ConfigMaps and RBAC (5-8 resources)
```

### Step 3: Deploy Phase 3

```bash
# Apply the configuration
terraform apply -var-file="terraform.tfvars.testing"

# When prompted, type 'yes' to confirm
# Deployment takes approximately 15-20 minutes
```

### Step 4: Verify Core Components Installation

```bash
# Check Karpenter installation
kubectl get pods -n karpenter
kubectl get nodeclaims
kubectl get nodepools

# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check External DNS
kubectl get pods -n kube-system | grep external-dns

# Check Cluster Autoscaler (if enabled)
kubectl get pods -n kube-system | grep cluster-autoscaler
```

## 🔍 Post-Deployment Validation

### Step 1: Test Karpenter Node Provisioning

```bash
# Create a test deployment that requires scaling
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: karpenter-test
spec:
  replicas: 5
  selector:
    matchLabels:
      app: karpenter-test
  template:
    metadata:
      labels:
        app: karpenter-test
    spec:
      containers:
      - name: test
        image: nginx:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF

# Watch nodes being provisioned
kubectl get nodes -w

# Expected: New nodes should appear within 30-60 seconds
```

### Step 2: Test AWS Load Balancer Controller

```bash
# Create a test service with ALB
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: test-alb-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
spec:
  selector:
    app: karpenter-test
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

# Check if load balancer is created
kubectl get services test-alb-service

# Expected: External IP should be assigned (ALB DNS name)
```

### Step 3: Test External DNS (if Route53 configured)

```bash
# Create an ingress with DNS annotation
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-dns-ingress
  annotations:
    external-dns.alpha.kubernetes.io/hostname: test.yourdomain.com
    kubernetes.io/ingress.class: alb
spec:
  rules:
  - host: test.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-alb-service
            port:
              number: 80
EOF

# Check DNS records (if Route53 configured)
# Expected: DNS record should be created automatically
```

### Step 4: Verify Autoscaling Behavior

```bash
# Scale down test deployment
kubectl scale deployment karpenter-test --replicas=0

# Watch nodes being terminated
kubectl get nodes -w

# Expected: Empty nodes should be terminated within 30-60 seconds
```

## 🛠️ Configuration Verification

### Karpenter Configuration Check

```bash
# Check Karpenter NodePool
kubectl get nodepools -o yaml

# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter

# Expected: No errors, successful node provisioning logs
```

### ALB Controller Health Check

```bash
# Check ALB Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Expected: No errors, successful load balancer creation logs
```

### External DNS Health Check

```bash
# Check External DNS logs
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns

# Expected: No errors, successful DNS record creation logs
```

## 📈 Performance Testing

### Load Testing Karpenter

```bash
# Create a resource-intensive deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-test
spec:
  replicas: 20
  selector:
    matchLabels:
      app: load-test
  template:
    metadata:
      labels:
        app: load-test
    spec:
      containers:
      - name: load-test
        image: nginx:latest
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
EOF

# Monitor scaling behavior
kubectl top nodes
kubectl get nodes
kubectl get pods -o wide

# Expected: Multiple nodes provisioned efficiently
```

### Monitoring Resource Usage

```bash
# Check cluster resource utilization
kubectl top nodes
kubectl top pods -A

# View Karpenter metrics
kubectl get nodeclaims -o wide
kubectl describe nodepool

# Expected: Efficient resource allocation and utilization
```

## 🚨 Troubleshooting Guide

### Common Issues

#### 1. Karpenter Not Scaling Nodes

```bash
# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter

# Check NodePool configuration
kubectl describe nodepool

# Common fixes:
# - Verify IAM permissions
# - Check subnet tags
# - Verify instance type availability
```

#### 2. ALB Controller Not Creating Load Balancers

```bash
# Check ALB Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check service annotations
kubectl describe service your-service

# Common fixes:
# - Verify IRSA configuration
# - Check VPC and subnet configuration
# - Verify security group rules
```

#### 3. External DNS Not Creating Records

```bash
# Check External DNS logs
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns

# Check ingress annotations
kubectl describe ingress your-ingress

# Common fixes:
# - Verify Route53 hosted zone
# - Check DNS permissions
# - Verify domain configuration
```

#### 4. Pods Stuck in Pending State

```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node capacity
kubectl describe nodes

# Common fixes:
# - Verify resource requests
# - Check node taints and tolerations
# - Verify Karpenter NodePool configuration
```

## 🧹 Clean Up Test Resources

```bash
# Remove test deployments
kubectl delete deployment karpenter-test load-test
kubectl delete service test-alb-service
kubectl delete ingress test-dns-ingress

# Verify nodes scale down
kubectl get nodes -w
```

## 📋 Phase 3 Completion Checklist

- [ ] ✅ Terraform backend initialized successfully
- [ ] ✅ All 25-30 resources created without errors
- [ ] ✅ Karpenter pods are Running
- [ ] ✅ AWS Load Balancer Controller is Running
- [ ] ✅ External DNS is Running (if configured)
- [ ] ✅ Node provisioning test successful (<60 seconds)
- [ ] ✅ Load balancer creation test successful
- [ ] ✅ Automatic scale-down working
- [ ] ✅ No errors in component logs
- [ ] ✅ Resource utilization optimized

## 🎯 Next Steps: Phase 4

Once Phase 3 is complete, you'll be ready for:

1. **Phase 4: GitOps & Applications**
   - ArgoCD installation for GitOps
   - Application deployment automation
   - Monitoring and observability stack
   - Production workload deployment

## 💡 Performance Optimization Tips

1. **Node Pool Configuration**: Adjust instance types based on workload patterns
2. **Spot Instance Ratio**: Fine-tune spot/on-demand ratio for cost vs reliability
3. **Resource Requests**: Set appropriate CPU/memory requests for accurate scaling
4. **Pod Disruption Budgets**: Implement for high-availability workloads
5. **Cluster Monitoring**: Set up CloudWatch Container Insights

## 🔗 Useful Commands Reference

```bash
# Karpenter Management
kubectl get nodepools
kubectl get nodeclaims
kubectl describe nodepool <name>

# ALB Controller Management
kubectl get targetgroupbindings
kubectl describe targetgroupbinding <name>

# External DNS Management
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns

# Cluster Monitoring
kubectl top nodes
kubectl top pods -A
kubectl get hpa -A

# Terraform Operations
terraform output
terraform plan -var-file="terraform.tfvars.testing"
terraform apply -var-file="terraform.tfvars.testing"
```

---

**Phase 3 creates an intelligent, cost-optimized, auto-scaling EKS cluster ready for production workloads!** 🚀

## 📞 Support & Next Steps

After completing Phase 3, your cluster will automatically:

- **Scale nodes** based on workload demand
- **Optimize costs** through spot instances and right-sizing
- **Manage load balancers** natively with AWS
- **Handle DNS** automatically for services

Ready to proceed to Phase 4 for GitOps and application deployment!
