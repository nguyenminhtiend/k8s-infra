# Logging Stack (Fluent Bit + Loki + Grafana)

Complete logging solution for the K8s microservices infrastructure using CNCF-graduated Fluent Bit and Grafana Loki.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Fluent Bit    │───▶│      Loki       │◀───│    Grafana      │
│  (Log Agent)    │    │  (Log Storage)  │    │ (Visualization) │
│  - Collects     │    │  - Stores logs  │    │  - Dashboards   │
│  - Parses       │    │  - Indexes      │    │  - Queries      │
│  - Ships logs   │    │  - Queries      │    │  - Alerts       │
│  - C/C++ Fast   │    │  - Cost-eff.    │    │  - LogQL        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Components

### 🗃️ Loki

- **Purpose**: Log aggregation and storage
- **Port**: 3100 (HTTP), 9096 (gRPC)
- **Storage**: Filesystem-based for local dev
- **Config**: `/monitoring/loki/base/configmap.yaml`

### 📊 Grafana

- **Purpose**: Log visualization and dashboards
- **Port**: 3000
- **Credentials**: admin/admin123
- **Config**: `/monitoring/grafana/base/`

### 🚚 Fluent Bit

- **Purpose**: High-performance log collection agent (DaemonSet)
- **Port**: 2020 (HTTP API), native Loki output
- **Features**: CNCF graduated, C/C++ performance, 650KB memory footprint
- **Collects From**:
  - All Kubernetes pod logs (with metadata enrichment)
  - Traefik access logs``
  - Microservice application logs
  - System logs (systemd)

## Quick Start

### 1. Deploy the Stack

```bash
# Deploy all logging components
make deploy-logging

# Or manually
kubectl apply -k monitoring/logging-stack/overlays/local
```

### 2. Access Grafana

```bash
# Option 1: NodePort (direct access)
open http://localhost:30300

# Option 2: Port forward
make port-forward-logging
open http://localhost:3000

# Option 3: Via Traefik (add grafana.test to /etc/hosts)
echo "127.0.0.1 grafana.test" >> /etc/hosts
open http://grafana.test
```

### 3. View Logs

In Grafana:

1. Go to **Explore** (compass icon)
2. Select **Loki** datasource
3. Use these queries:

```logql
# All logs from microservices
{namespace="microservices"}

# Error logs only
{namespace="microservices"} |= "error"

# Traefik access logs
`{namespace="traefik-system",app="traefik"}`

# Specific service logs
{namespace="microservices",app="service-a"}

# Filter by log level
{namespace="microservices"} | json | level="error"
```

## Log Queries (LogQL)

### Basic Queries

```logql
# All logs from a namespace
{namespace="microservices"}

# Logs from specific app
{app="service-a"}

# Multiple labels
{namespace="microservices",app="service-a"}
```

### Text Filtering

```logql
# Contains text
{namespace="microservices"} |= "error"

# Doesn't contain text
{namespace="microservices"} != "health"

# Regex match
{namespace="microservices"} |~ "error|Error|ERROR"
```

### JSON Parsing

```logql
# Parse JSON and filter
{namespace="microservices"} | json | level="error"

# Extract fields
{namespace="microservices"} | json | __error__="" | level="error", service="user-service"
```

### Metrics Queries

```logql
# Count logs per minute
count_over_time({namespace="microservices"}[1m])

# Error rate
sum(rate({namespace="microservices"} |= "error" [5m])) by (app)

# Log volume by service
sum(count_over_time({namespace="microservices"}[1m])) by (app)
```

## Log Sources Configuration

### Fluent Bit Input Sources

1. **tail**: Kubernetes container logs from `/var/log/containers/*.log`
2. **systemd**: Host system logs (kubelet, containerd, etc.)
3. **kubernetes filter**: Automatic metadata enrichment

### Log Labels Added by Fluent Bit

- `namespace`: Kubernetes namespace (auto-discovered)
- `pod`: Pod name (auto-discovered)
- `container`: Container name (auto-discovered)
- `app`: Application name (from K8s labels)
- `level`: Log level (parsed from JSON)
- `service`: Service name (parsed from JSON)
- `hostname`: Node hostname
- `stream`: stdout/stderr

## Dashboards

### Pre-built Dashboard

- **Logging Overview**: `/monitoring/grafana/dashboards/logging-overview.json`
  - Log volume by namespace
  - Error rate by service
  - Recent logs view

### Import Additional Dashboards

1. Go to Grafana → **+** → **Import**
2. Use dashboard ID: `13639` (Loki Dashboard)
3. Select **Loki** as datasource

## Configuration Files

```
monitoring/
├── loki/
│   └── base/
│       ├── kustomization.yaml     # Component list
│       ├── namespace.yaml         # logging namespace
│       ├── configmap.yaml         # Loki configuration
│       ├── deployment.yaml        # Loki deployment
│       ├── service.yaml          # Loki service
│       └── persistentvolumeclaim.yaml # Storage
├── grafana/
│   └── base/
│       ├── kustomization.yaml     # Component list
│       ├── configmap.yaml         # Grafana config + datasources
│       ├── deployment.yaml        # Grafana deployment
│       ├── service.yaml          # Grafana service
│       ├── secret.yaml           # Admin credentials
│       └── persistentvolumeclaim.yaml # Storage
├── fluent-bit/
│   └── base/
│       ├── kustomization.yaml     # Component list
│       ├── rbac.yaml             # Permissions
│       ├── configmap.yaml        # Input/output configs
│       └── daemonset.yaml        # Log collector

└── logging-stack/
    ├── base/
    │   └── kustomization.yaml     # Combined stack (Fluent Bit + Loki + Grafana)
    └── overlays/
        └── local/
            ├── kustomization.yaml         # Local overrides
            ├── grafana-ingressroute.yaml  # Traefik routing
            ├── grafana-service-patch.yaml # NodePort access
            └── loki-storage-patch.yaml    # Smaller storage
```

## Operations

### View Component Status

```bash
# Check all logging components
kubectl get all -n logging

# Check pod logs
make logs-logging

# Check specific component
kubectl logs -n logging deployment/loki -f
kubectl logs -n logging deployment/grafana -f
kubectl logs -n logging daemonset/fluent-bit -f
```

### Storage Management

```bash
# Check storage usage
kubectl get pvc -n logging

# Loki storage location (inside container)
kubectl exec -n logging deployment/loki -- du -sh /loki

# Clear old logs (if needed)
kubectl exec -n logging deployment/loki -- rm -rf /loki/chunks/*
```

### Troubleshooting

#### Fluent Bit Not Collecting Logs

```bash
# Check fluent-bit is running on all nodes
kubectl get pods -n logging -l app=fluent-bit -o wide

# Check fluent-bit logs
kubectl logs -n logging daemonset/fluent-bit

# Check fluent-bit health
kubectl port-forward -n logging daemonset/fluent-bit 2020:2020
curl http://localhost:2020/api/v1/health
curl http://localhost:2020/api/v1/metrics
```

#### Loki Not Receiving Logs

```bash
# Check Loki status
kubectl port-forward -n logging service/loki 3100:3100
curl http://localhost:3100/ready

# Check ingestion
curl http://localhost:3100/metrics | grep loki_distributor
```

#### Grafana Can't Connect to Loki

```bash
# Test datasource connection
kubectl exec -n logging deployment/grafana -- curl -s http://loki:3100/ready

# Check Grafana logs
kubectl logs -n logging deployment/grafana | grep -i loki
```

## Customization

### Add New Log Source

Edit `/monitoring/fluent-bit/base/configmap.yaml`:

```yaml
# Add new input
[INPUT]
    Name tail
    Path /path/to/your/logs/*.log
    Tag custom.*
    Parser json

# Add custom output/filter if needed
[FILTER]
    Name modify
    Match custom.*
    Add source custom-app

[OUTPUT]
    Name loki
    Match custom.*
    Host loki.logging.svc.cluster.local
    Port 3100
    Labels job=custom-app
```

### Modify Loki Retention

Edit `/monitoring/loki/base/configmap.yaml`:

```yaml
limits_config:
  retention_period: 720h # Keep logs for 30 days
table_manager:
  retention_deletes_enabled: true
```

### Add Grafana Dashboard

1. Create dashboard JSON in `/monitoring/grafana/dashboards/`
2. Mount in Grafana deployment
3. Or import via Grafana UI

## Security Notes

- Default credentials: `admin/admin123` (change in production)
- Logs may contain sensitive data - ensure proper access controls
- Consider log retention policies for compliance
- Network policies can restrict access between components

## Next Steps

1. **Add alerting**: Configure Grafana alerts on log patterns
2. **Structured logging**: Update applications to output JSON logs
3. **Log sampling**: Reduce volume for high-traffic services
4. **Multi-tenancy**: Separate logs by team/environment
5. **Backup**: Set up log backup strategy
