# Folder Structure for K8s Infrastructure

## Recommended Structure

```
k8s-infra/
├── infrastructure/                    # Infrastructure as Code
│   ├── terraform/
│   │   ├── environments/
│   │   │   ├── development/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── terraform.tfvars
│   │   │   │   └── versions.tf
│   │   │   ├── production/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── terraform.tfvars
│   │   │   │   └── versions.tf
│   │   │   └── shared/
│   │   │       ├── dns/
│   │   │       ├── networking/
│   │   │       └── security/
│   │   └── modules/
│   │       ├── eks-cluster/
│   │       ├── rds-database/
│   │       ├── vpc-networking/
│   │       ├── monitoring/
│   │       └── security/
│   └── helm/
│       ├── charts/
│       │   ├── microservice-base/     # Base Helm chart for microservices
│   │       ├── web-app-base/          # Base chart for Next.js apps
│       │   ├── traefik/
│       │   ├── prometheus-stack/
│       │   ├── loki-stack/
│       │   ├── jaeger/
│       │   └── argocd/
│       └── values/
│           ├── development/
│           └── production/
├── applications/                      # Application deployments
│   ├── microservices/
│   │   ├── service-1/
│   │   │   ├── base/
│   │   │   │   ├── kustomization.yaml
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── service.yaml
│   │   │   │   └── configmap.yaml
│   │   │   ├── overlays/
│   │   │   │   ├── development/
│   │   │   │   │   ├── kustomization.yaml
│   │   │   │   │   ├── ingress.yaml
│   │   │   │   │   └── patches/
│   │   │   │   └── production/
│   │   │   │       ├── kustomization.yaml
│   │   │   │       ├── ingress.yaml
│   │   │   │       ├── hpa.yaml
│   │   │   │       └── patches/
│   │   │   └── helm/
│   │   │       ├── Chart.yaml
│   │   │       ├── values.yaml
│   │   │       └── templates/
│   │   ├── service-2/
│   │   └── ...service-10/
│   ├── web-apps/
│   │   ├── marketplace/
│   │   │   ├── base/
│   │   │   ├── overlays/
│   │   │   │   ├── development/
│   │   │   │   └── production/
│   │   │   └── helm/
│   │   └── dashboard/
│   │       ├── base/
│   │       ├── overlays/
│   │       │   ├── development/
│   │       │   └── production/
│   │       └── helm/
│   └── shared/
│       ├── secrets/
│       ├── configmaps/
│       └── rbac/
├── environments/                      # Environment-specific configurations
│   ├── development/
│   │   ├── argocd/
│   │   │   ├── applications/
│   │   │   │   ├── microservices.yaml
│   │   │   │   ├── web-apps.yaml
│   │   │   │   ├── monitoring.yaml
│   │   │   │   └── security.yaml
│   │   │   └── projects/
│   │   ├── namespace/
│   │   │   ├── kustomization.yaml
│   │   │   └── namespace.yaml
│   │   ├── ingress/
│   │   │   ├── traefik-config.yaml
│   │   │   └── middleware.yaml
│   │   └── values/
│   │       ├── microservices/
│   │       ├── monitoring/
│   │       └── security/
│   └── production/
│       ├── argocd/
│       │   ├── applications/
│       │   └── projects/
│       ├── namespace/
│       ├── ingress/
│       └── values/
├── monitoring/                        # Observability stack
│   ├── prometheus/
│   │   ├── base/
│   │   ├── rules/
│   │   │   ├── microservices.yaml
│   │   │   ├── infrastructure.yaml
│   │   │   └── sla.yaml
│   │   └── overlays/
│   │       ├── development/
│   │       └── production/
│   ├── grafana/
│   │   ├── base/
│   │   ├── dashboards/
│   │   │   ├── microservices/
│   │   │   ├── infrastructure/
│   │   │   ├── business-metrics/
│   │   │   ├── logging-overview/
│   │   │   └── sla/
│   │   ├── datasources/
│   │   └── overlays/
│   ├── loki/
│   │   ├── base/
│   │   └── overlays/
│   ├── fluent-bit/
│   │   ├── base/
│   │   └── overlays/
│   ├── logging-stack/
│   │   ├── base/
│   │   └── overlays/
│   │       └── local/
│   ├── jaeger/
│   │   ├── base/
│   │   └── overlays/
│   └── kubecost/
│       ├── base/
│       └── overlays/
├── security/                          # Security configurations
│   ├── cert-manager/
│   │   ├── issuers/
│   │   └── certificates/
│   ├── falco/
│   │   ├── rules/
│   │   └── config/
│   └── network-policies/
│       ├── microservices/
│       └── infrastructure/
├── local/                             # Local development
│   ├── kind/
│   │   ├── cluster-config.yaml
│   │   └── setup.sh
│   ├── docker-compose/
│   │   ├── databases/
│   │   │   └── docker-compose.yml     # PostgreSQL + Redis
│   │   └── monitoring/
│   │       └── docker-compose.yml     # Local monitoring stack
│   ├── skaffold/
│   │   ├── skaffold.yaml
│   │   └── profiles/
│   ├── tilt/
│   │   ├── Tiltfile
│   │   └── extensions/
│   └── scripts/
│       ├── setup-local.sh
│       ├── teardown.sh
│       └── port-forward.sh
├── scripts/                           # Automation scripts
│   ├── setup/
│   │   ├── install-tools.sh
│   │   ├── setup-terraform.sh
│   │   └── setup-kubectl.sh
│   ├── deploy/
│   │   ├── deploy-infrastructure.sh
│   │   ├── deploy-applications.sh
│   │   └── rollback.sh
│   ├── maintenance/
│   │   ├── backup-databases.sh
│   │   ├── update-certificates.sh
│   │   └── cleanup-images.sh
│   └── monitoring/
│       ├── health-check.sh
│       └── generate-reports.sh
├── docs/                              # Documentation
│   ├── runbooks/
│   │   ├── deployment.md
│   │   ├── troubleshooting.md
│   │   └── disaster-recovery.md
│   ├── architecture/
│   │   ├── diagrams/
│   │   └── decisions/
│   └── onboarding/
│       ├── local-setup.md
│       └── production-access.md
├── .github/                           # CI/CD workflows
│   ├── workflows/
│   │   ├── terraform-plan.yml
│   │   ├── terraform-apply.yml
│   │   ├── build-and-push.yml
│   │   ├── security-scan.yml
│   │   └── sync-argocd.yml
│   └── templates/
│       ├── pull_request_template.md
│       └── issue_template.md
├── tools/                             # Development tools config
│   ├── pre-commit/
│   │   └── .pre-commit-config.yaml
│   ├── linters/
│   │   ├── .tflint.hcl
│   │   ├── .yamllint.yml
│   │   └── .hadolint.yaml
│   └── ide/
│       ├── .vscode/
│       └── .editorconfig
├── Makefile                           # Common commands
├── README.md                          # Project overview
├── .gitignore
└── .env.example                       # Environment variables template
```

## Key Design Principles

### 1. Environment Separation

- Clear separation between `development` and `production`
- Environment-specific configurations in dedicated folders
- Shared components with environment overlays

### 2. GitOps Ready

- ArgoCD applications defined per environment
- Kustomize overlays for environment-specific patches
- Helm values separated by environment

### 3. Microservice Independence

- Each microservice has its own deployment manifests
- Shared base configurations to reduce duplication
- Independent versioning and deployment

### 4. Infrastructure as Code

- Terraform modules for reusable infrastructure components
- Environment-specific Terraform configurations
- Helm charts for Kubernetes applications

### 5. Local Development Support

- Kind cluster configuration for local K8s
- Docker Compose for dependencies
- Development tools integration (Skaffold/Tilt)

## Workflow Examples

### Deploying a New Microservice

```bash
# 1. Create service folder
mkdir -p applications/microservices/service-11

# 2. Copy base manifests
cp -r applications/microservices/service-1/base applications/microservices/service-11/

# 3. Create environment overlays
mkdir -p applications/microservices/service-11/overlays/{development,production}

# 4. Update ArgoCD application
# Edit environments/development/argocd/applications/microservices.yaml
```

### Environment Promotion

```bash
# 1. Test in development
kubectl apply -k applications/microservices/service-1/overlays/development

# 2. Promote to production
kubectl apply -k applications/microservices/service-1/overlays/production
```

### Local Development

```bash
# Start local cluster
make local-setup

# Deploy applications locally
skaffold dev

# Access services
make port-forward
```

## Benefits

- **Scalability**: Easy to add new microservices
- **Maintainability**: Clear separation of concerns
- **Flexibility**: Multiple deployment strategies (Kustomize + Helm)
- **Consistency**: Standardized patterns across all services
- **Developer Experience**: Rich local development environment
- **Operations**: Comprehensive monitoring and security
