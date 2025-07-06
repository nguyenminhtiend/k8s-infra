# 🚀 Phase 4 Deployment Guide: GitOps & Production-Ready Observability

## 📋 Overview

Phase 4 transforms your auto-scaling EKS cluster into a production-ready platform with GitOps automation and comprehensive observability. This phase implements:

- **ArgoCD**: GitOps continuous deployment and application management
- **Prometheus Stack**: Metrics collection, alerting, and monitoring
- **Grafana**: Visualization dashboards and alerting
- **Jaeger**: Distributed tracing for microservices
- **Loki**: Centralized logging (extending existing setup)

## ✅ Prerequisites Check

Before starting Phase 4, ensure Phase 3 is complete and working:

```bash
# 1. Verify Phase 3 cluster is running
cd infrastructure/terraform/layers/03-autoscaling
terraform output cluster_name
terraform output karpenter_node_pool_name

# 2. Verify Karpenter is working
kubectl get nodes
kubectl get nodepools
kubectl get nodeclaims

# 3. Verify AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# 4. Check External DNS (if configured)
kubectl get pods -n kube-system | grep external-dns
```

**Expected Phase 3 Outputs:**

- ✅ EKS cluster with Karpenter auto-scaling
- ✅ AWS Load Balancer Controller operational
- ✅ External DNS working (if configured)
- ✅ Nodes scaling up/down based on demand
- ✅ All system pods are Running

## 🏗️ Phase 4 Architecture

**Current State (Post-Phase 3):**

```
Internet → Route53 → ALB → EKS Cluster → Karpenter Nodes → Applications
```

**Target State (Post-Phase 4):**

```
Internet → Route53 → ALB → EKS Cluster → Karpenter Nodes → Instrumented Applications
    ↓
GitOps Repository → ArgoCD → Kubernetes Manifests → Applications
    ↓
Observability Stack (Prometheus + Grafana + Jaeger + Loki)
```

## 🔧 Phase 4 Configuration Files

### Step 1: Navigate to Phase 4 Directory

```bash
cd infrastructure/terraform/layers/04-gitops-observability
```

All configuration files will be created in the next steps.

## 📊 Phase 4 Cost Impact

### Testing Environment Costs (Projected)

| Resource Type               | Monthly Cost | Notes                            |
| --------------------------- | ------------ | -------------------------------- |
| **Phase 3 Base**            | $110-151     | Existing EKS + Karpenter         |
| ArgoCD (t3.medium)          | $12-18       | Dedicated node for GitOps        |
| Prometheus Stack (t3.large) | $25-35       | Metrics storage and processing   |
| Grafana (t3.small)          | $8-12        | Dashboards and visualization     |
| Jaeger (t3.medium)          | $12-18       | Distributed tracing              |
| Additional EBS Storage      | $8-15        | Persistent volumes               |
| **Total Phase 4**           | **$175-249** | **40-65% increase from Phase 3** |

### Key Cost Optimizations

- ✅ **Spot Instances**: 80% spot usage for observability workloads
- ✅ **Resource Right-sizing**: Automated scaling based on metrics
- ✅ **Storage Optimization**: Efficient retention policies
- ✅ **Query Optimization**: Efficient Prometheus queries

## 🚀 Phase 4 Implementation Steps

### Step 1: Initialize Terraform Backend

```bash
# Navigate to Phase 4 directory
cd infrastructure/terraform/layers/04-gitops-observability

# Initialize with testing environment backend
terraform init \
  -backend-config="bucket=$(cat ../../../../terraform-state-bucket.txt)" \
  -backend-config="key=testing/04-gitops-observability/terraform.tfstate" \
  -backend-config="region=ap-southeast-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=terraform-state-lock-eks"
```

### Step 2: Plan the Deployment

```bash
# Review the planned changes
terraform plan -var-file="terraform.tfvars.testing"

# Expected resources to be created:
# - ~35-45 resources including:
#   - ArgoCD Helm release and RBAC (8-10 resources)
#   - Prometheus Stack (Prometheus, Grafana, AlertManager) (12-15 resources)
#   - Jaeger tracing stack (5-7 resources)
#   - Loki logging enhancement (3-5 resources)
#   - IRSA roles and policies (8-10 resources)
#   - Storage and networking (5-8 resources)
```

### Step 3: Deploy Phase 4

```bash
# Apply the configuration
terraform apply -var-file="terraform.tfvars.testing"

# When prompted, type 'yes' to confirm
# Deployment takes approximately 20-25 minutes
```

### Step 4: Verify Core Components Installation

```bash
# Check ArgoCD installation
kubectl get pods -n argocd
kubectl get svc -n argocd

# Check Prometheus Stack
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# Check Jaeger installation
kubectl get pods -n jaeger
kubectl get svc -n jaeger

# Check all CRDs are installed
kubectl get crd | grep -E "(argocd|prometheus|grafana|jaeger)"
```

## 🔍 Post-Deployment Validation

### Step 1: Access ArgoCD UI

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access ArgoCD UI at https://localhost:8080
# Username: admin
# Password: (from command above)
```

### Step 2: Access Grafana Dashboard

```bash
# Get Grafana admin password
kubectl get secret --namespace monitoring grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode && echo

# Port forward to access Grafana
kubectl port-forward svc/grafana -n monitoring 3000:80

# Access Grafana at http://localhost:3000
# Username: admin
# Password: (from command above)
```

### Step 3: Access Prometheus UI

```bash
# Port forward to access Prometheus
kubectl port-forward svc/prometheus-server -n monitoring 9090:80

# Access Prometheus at http://localhost:9090
# Verify metrics are being collected
```

### Step 4: Access Jaeger UI

```bash
# Port forward to access Jaeger
kubectl port-forward svc/jaeger-query -n jaeger 16686:16686

# Access Jaeger at http://localhost:16686
# Verify tracing is working
```

## 🔧 GitOps Configuration

### Step 1: Create GitOps Repository Structure

```bash
# Create GitOps repository (or use existing)
mkdir -p ~/k8s-gitops
cd ~/k8s-gitops

# Initialize Git repository
git init
git remote add origin <your-gitops-repo-url>

# Create directory structure
mkdir -p {bootstrap,infrastructure,applications,environments}/{testing,staging,production}
mkdir -p infrastructure/{monitoring,networking,security}
mkdir -p applications/{microservices,databases,external-services}
```

### Step 2: Configure ArgoCD Applications

```bash
# Create ArgoCD application for infrastructure
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infrastructure-monitoring
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-gitops-repo-url>
    targetRevision: HEAD
    path: infrastructure/monitoring/testing
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

### Step 3: Test GitOps Workflow

```bash
# Create a test application
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-gitops-repo-url>
    targetRevision: HEAD
    path: applications/microservices/test-app
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# Verify application appears in ArgoCD UI
# Expected: Application should sync automatically
```

## 📈 Observability Configuration

### Step 1: Configure Prometheus Targets

```bash
# Verify Prometheus is discovering targets
# In Prometheus UI (localhost:9090), go to Status > Targets
# Expected: All Kubernetes endpoints should be discovered

# Check service monitors
kubectl get servicemonitors -n monitoring
kubectl get podmonitors -n monitoring
```

### Step 2: Import Grafana Dashboards

```bash
# Import pre-built dashboards
# In Grafana UI (localhost:3000):
# 1. Go to Dashboards > Import
# 2. Import dashboard ID: 3119 (Kubernetes cluster monitoring)
# 3. Import dashboard ID: 6417 (Kubernetes cluster autoscaler)
# 4. Import dashboard ID: 1860 (Node Exporter Full)

# Verify dashboards show data
# Expected: Real-time metrics from your cluster
```

### Step 3: Configure Alerting Rules

```bash
# Check existing alerting rules
kubectl get prometheusrules -n monitoring

# Test alerting by creating a test alert
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: test-alert
  namespace: monitoring
spec:
  groups:
  - name: test.rules
    rules:
    - alert: TestAlert
      expr: up == 0
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: "Test alert fired"
EOF

# Check alerts in Prometheus UI
# Expected: Alert should appear in Alerts section
```

### Step 4: Configure Jaeger Tracing

```bash
# Deploy a sample traced application
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger-example
spec:
  replicas: 2
  selector:
    matchLabels:
      app: jaeger-example
  template:
    metadata:
      labels:
        app: jaeger-example
    spec:
      containers:
      - name: jaeger-example
        image: jaegertracing/example-hotrod:latest
        ports:
        - containerPort: 8080
        env:
        - name: JAEGER_AGENT_HOST
          value: "jaeger-agent.jaeger.svc.cluster.local"
---
apiVersion: v1
kind: Service
metadata:
  name: jaeger-example
spec:
  selector:
    app: jaeger-example
  ports:
  - port: 8080
    targetPort: 8080
  type: LoadBalancer
EOF

# Wait for LoadBalancer and generate traces
kubectl get svc jaeger-example
# Access the service and generate some traffic
# Check Jaeger UI for traces
```

## 🛠️ Application Deployment via GitOps

### Step 1: Deploy Sample Microservice

```bash
# Create application manifest in GitOps repo
cat > ~/k8s-gitops/applications/microservices/sample-app/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: sample-app
        image: nginx:1.20
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  namespace: default
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF

# Commit and push to GitOps repository
cd ~/k8s-gitops
git add .
git commit -m "Add sample application"
git push origin main

# ArgoCD should automatically sync and deploy
# Expected: Application appears in ArgoCD UI and deploys
```

### Step 2: Test Auto-scaling with Monitoring

```bash
# Create a load test to trigger scaling
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-generator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: load-generator
  template:
    metadata:
      labels:
        app: load-generator
    spec:
      containers:
      - name: load-generator
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          while true; do
            for i in \$(seq 1 100); do
              wget -q -O- http://sample-app.default.svc.cluster.local/
            done
            sleep 1
          done
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
EOF

# Monitor scaling in Grafana dashboards
# Expected: See increased metrics and potential node scaling
```

## 🚨 Troubleshooting Guide

### Common Issues

#### 1. ArgoCD Not Syncing Applications

```bash
# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller

# Check application status
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd

# Common fixes:
# - Verify Git repository access
# - Check RBAC permissions
# - Validate application manifests
```

#### 2. Prometheus Not Collecting Metrics

```bash
# Check Prometheus logs
kubectl logs -n monitoring deployment/prometheus-server

# Check service discovery
kubectl get endpoints -n monitoring
kubectl get servicemonitors -n monitoring

# Common fixes:
# - Verify service labels match ServiceMonitor selectors
# - Check RBAC permissions
# - Validate Prometheus configuration
```

#### 3. Grafana Dashboards Not Loading

```bash
# Check Grafana logs
kubectl logs -n monitoring deployment/grafana

# Check data source configuration
# In Grafana UI: Configuration > Data Sources

# Common fixes:
# - Verify Prometheus data source URL
# - Check authentication settings
# - Validate dashboard JSON
```

#### 4. Jaeger Not Receiving Traces

```bash
# Check Jaeger components
kubectl get pods -n jaeger
kubectl logs -n jaeger deployment/jaeger-collector

# Check application instrumentation
kubectl describe pod <your-app-pod>

# Common fixes:
# - Verify JAEGER_AGENT_HOST environment variable
# - Check network connectivity
# - Validate tracing library configuration
```

## 🧹 Performance Optimization

### Step 1: Optimize Prometheus Storage

```bash
# Check Prometheus storage usage
kubectl exec -n monitoring deployment/prometheus-server -- \
  df -h /prometheus

# Configure retention policies
# Edit Prometheus configuration for optimal retention
# Expected: Balanced storage usage vs historical data
```

### Step 2: Optimize Grafana Performance

```bash
# Check Grafana performance metrics
kubectl top pods -n monitoring | grep grafana

# Configure dashboard refresh intervals
# Optimize query performance
# Expected: Responsive dashboards with minimal resource usage
```

### Step 3: Optimize Jaeger Performance

```bash
# Check Jaeger performance
kubectl top pods -n jaeger

# Configure sampling rates
# Optimize trace retention
# Expected: Efficient tracing with minimal overhead
```

## 📋 Phase 4 Completion Checklist

- [ ] ✅ Terraform backend initialized successfully
- [ ] ✅ All 35-45 resources created without errors
- [ ] ✅ ArgoCD UI accessible and functional
- [ ] ✅ Prometheus collecting metrics from all targets
- [ ] ✅ Grafana dashboards showing real-time data
- [ ] ✅ Jaeger tracing working end-to-end
- [ ] ✅ GitOps workflow functional (commit → sync → deploy)
- [ ] ✅ Alerting rules configured and tested
- [ ] ✅ Sample applications deployed via GitOps
- [ ] ✅ Auto-scaling monitored and working
- [ ] ✅ No errors in component logs
- [ ] ✅ Performance optimization applied

## 🎯 Next Steps: Production Readiness

Once Phase 4 is complete, you'll be ready for:

1. **Production Deployment**

   - Multi-environment GitOps workflows
   - Advanced alerting and incident response
   - Backup and disaster recovery
   - Security hardening

2. **Advanced Features**
   - Service mesh integration (Istio - when ready)
   - Advanced deployment strategies (Canary, Blue-Green)
   - Chaos engineering with Chaos Monkey
   - Cost optimization with Kubecost

## 💡 Best Practices Implemented

1. **GitOps Workflow**: Declarative configuration management
2. **Observability**: Three pillars - metrics, logs, and traces
3. **Infrastructure as Code**: All components managed via Terraform
4. **Security**: RBAC, network policies, and secure secret management
5. **Cost Optimization**: Right-sizing and efficient resource usage
6. **Automation**: Self-healing and auto-scaling capabilities

## 🔗 Useful Commands Reference

```bash
# ArgoCD Management
kubectl get applications -n argocd
kubectl get appprojects -n argocd
argocd app list (if CLI installed)

# Prometheus Management
kubectl get prometheusrules -n monitoring
kubectl get servicemonitors -n monitoring
kubectl port-forward svc/prometheus-server -n monitoring 9090:80

# Grafana Management
kubectl get secrets -n monitoring | grep grafana
kubectl port-forward svc/grafana -n monitoring 3000:80

# Jaeger Management
kubectl get pods -n jaeger
kubectl port-forward svc/jaeger-query -n jaeger 16686:16686

# Terraform Operations
terraform output
terraform plan -var-file="terraform.tfvars.testing"
terraform apply -var-file="terraform.tfvars.testing"
terraform destroy -var-file="terraform.tfvars.testing"
```

---

**Phase 4 creates a production-ready GitOps platform with comprehensive observability!** 🚀

## 📞 Support & Monitoring

After completing Phase 4, your cluster will provide:

- **Full GitOps Automation**: Declarative application management
- **Comprehensive Monitoring**: Real-time metrics and alerting
- **Distributed Tracing**: End-to-end request visibility
- **Centralized Logging**: Unified log management
- **Self-Healing**: Automated recovery and scaling

Your infrastructure is now ready for production workloads with enterprise-grade observability and automation!
