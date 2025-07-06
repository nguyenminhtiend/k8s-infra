# Complete Request Flow: Internet to Microservice Pod

## Overview

This document traces the complete journey of an HTTP request from the internet through every component in our cloud-native microservices stack until it reaches the target NestJS microservice pod.

## Request Flow Diagram

```
[Internet] → [DNS] → [Cloud LB] → [Kong Gateway] → [Istio Service Mesh] → [K8s Service] → [Pod Network] → [Istio Sidecar] → [NestJS App]
```

---

## 1. Internet Entry Point

### User Request Initiation

```
[User Browser/Mobile App] → [DNS Resolution] → [Cloud Load Balancer]
```

**DNS Resolution Process:**

- User enters `api.yourapp.com` in browser/app
- DNS query resolves to cloud load balancer public IP
- Example: `api.yourapp.com` → `35.244.179.100` (GCP Global Load Balancer)
- SSL/TLS certificates served (Let's Encrypt managed by Cert-Manager)

**Cloud Load Balancer (Layer 4/7):**

- **Health Checks:** Continuously verifies Kong Gateway pods are healthy
- **Geographic Routing:** Routes traffic to nearest regional Kubernetes cluster
- **DDoS Protection:** Built-in cloud provider DDoS mitigation
- **SSL Termination:** Decrypts HTTPS traffic, forwards HTTP internally
- **Load Distribution:** Distributes across multiple Kong Gateway replicas

---

## 2. Kubernetes Ingress Layer

### Kong Gateway Processing

```
[Cloud LB] → [Kong Gateway Pod] → [Kong Plugins Pipeline]
```

**Kong Gateway (Ingress Controller):**

- **Listening Ports:** Receives requests on ports 80/443
- **Route Matching:** Matches request path/host to backend services
- **Service Discovery:** Resolves Kubernetes service names to cluster IPs

**Route Matching Examples:**

```yaml
# Route Configuration
api.yourapp.com/user-service/*    → user-service
api.yourapp.com/order-service/*   → order-service
api.yourapp.com/payment-service/* → payment-service
api.yourapp.com/dashboard/*       → dashboard-app
api.yourapp.com/marketplace/*     → marketplace-app
```

**Kong Plugin Pipeline (Sequential Processing):**

1. **Rate Limiting Plugin:**

   - Checks request limits per IP/user/API key
   - Redis-backed distributed rate limiting
   - Returns 429 Too Many Requests if exceeded

2. **Authentication Plugin:**

   - Validates JWT tokens from Auth0
   - Verifies token signature and expiration
   - Extracts user identity and permissions

3. **CORS Plugin:**

   - Handles cross-origin requests from web frontends
   - Sets appropriate CORS headers
   - Manages preflight OPTIONS requests

4. **Request Transformer Plugin:**

   - Adds/modifies/removes headers
   - Injects correlation IDs and trace headers
   - Standardizes request format

5. **Logging Plugin:**

   - Logs request metadata to Loki
   - Records timing, status, user information
   - Structured JSON logging format

6. **Prometheus Plugin:**
   - Exports metrics (request count, latency, status codes)
   - Labels by service, method, status code
   - Fed into Prometheus for monitoring

---

## 3. Service Mesh Entry (Istio)

### Istio Traffic Management

```
[Kong Gateway] → [Istio Ingress Gateway] → [Istio Sidecar Proxy]
```

**Istio Ingress Gateway:**

- **mTLS Initiation:** Establishes mutual TLS for all internal service communication
- **Traffic Policy Application:** Applies retry policies, timeouts, circuit breakers
- **Load Balancing:** Selects specific microservice pod based on configured algorithm
- **Header Injection:** Adds distributed tracing headers (X-Request-ID, X-B3-TraceId)

**Istio Envoy Sidecar (at Kong Gateway level):**

- **Traffic Interception:** Captures all outbound traffic from Kong pods
- **Service Discovery:** Resolves Kubernetes service names to actual pod endpoints
- **Load Balancing Algorithms:**
  - Round Robin (default)
  - Least Request
  - Random
  - Consistent Hash
- **Observability Collection:** Metrics, traces, and access logs for every request

**Traffic Policy Examples:**

```yaml
# Retry Policy
retryPolicy:
  attempts: 3
  perTryTimeout: 2s
  retryOn: 5xx,reset,connect-failure

# Circuit Breaker
connectionPool:
  tcp:
    maxConnections: 100
  http:
    http1MaxPendingRequests: 10
    maxRequestsPerConnection: 2
outlierDetection:
  consecutiveErrors: 3
  interval: 30s
  baseEjectionTime: 30s
```

---

## 4. Kubernetes Service Layer

### Service Discovery and Load Balancing

```
[Istio Sidecar] → [Kubernetes Service] → [Service Endpoints]
```

**Kubernetes Service (ClusterIP Type):**

- **DNS Name:** Full service name `user-service.default.svc.cluster.local`
- **Virtual IP:** Service gets stable cluster IP (e.g., `10.96.0.100`)
- **Port Mapping:** Maps service port 80 to pod port 3000
- **Endpoint Management:** Tracks healthy pod IPs automatically

**kube-proxy (iptables/IPVS mode):**

- **NAT Rules:** Translates service IP to actual pod IP addresses
- **Load Balancing:** Distributes requests across available pod replicas
- **Health Checking:** Only routes to pods passing readiness probes
- **Session Affinity:** Optional sticky sessions based on client IP

**Endpoint Selection Example:**

```
Service: user-service (ClusterIP: 10.96.0.100:80)
Endpoints:
├── user-service-pod-1: 10.244.1.10:3000 ✅ Ready
├── user-service-pod-2: 10.244.1.11:3000 ✅ Ready
├── user-service-pod-3: 10.244.1.12:3000 ✅ Ready
└── user-service-pod-4: 10.244.1.13:3000 ❌ Not Ready (excluded)
```

---

## 5. Pod Network Layer

### Container Networking

```
[Service] → [CNI Network] → [Target Pod]
```

**Container Network Interface (CNI):**

- **Network Namespace:** Each pod has isolated network stack
- **Pod IP Assignment:** Unique IP from cluster CIDR range
- **Pod-to-Pod Communication:** Direct IP communication within cluster
- **Network Policies:** Istio enforces traffic security policies

**Network Flow:**

- Service IP (`10.96.0.100`) → NAT → Pod IP (`10.244.1.10`)
- Packet routing through cluster network fabric
- CNI plugin (e.g., Calico, Cilium) handles low-level networking

**Pod Network Configuration:**

```yaml
# Pod specification
spec:
  containers:
    - name: user-service
      image: user-service:latest
      ports:
        - containerPort: 3000
          name: http
          protocol: TCP
```

---

## 6. Istio Sidecar (Destination)

### Inbound Traffic Processing

```
[Pod Network] → [Istio Envoy Sidecar] → [Application Container]
```

**Istio Envoy Sidecar (at microservice pod):**

- **Traffic Interception:** Captures all inbound traffic to the pod
- **mTLS Termination:** Verifies and decrypts service mesh traffic
- **Authorization Policies:** Enforces RBAC (which services can call this pod)
- **Rate Limiting:** Pod-level request rate limiting
- **Circuit Breaker:** Protects individual pod from overload
- **Metrics Collection:** Records detailed request metrics for Prometheus

**Security Policies Example:**

```yaml
# Authorization Policy
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: user-service-authz
spec:
  selector:
    matchLabels:
      app: user-service
  rules:
    - from:
        - source:
            principals: ['cluster.local/ns/default/sa/kong-gateway']
    - to:
        - operation:
            methods: ['GET', 'POST', 'PUT', 'DELETE']
```

**Traffic Flow Inside Pod:**

1. Packet arrives at pod network interface
2. Istio sidecar intercepts traffic (iptables rules)
3. mTLS certificate verification
4. Authorization policy check
5. Request forwarded to application container on localhost:3000

---

## 7. Application Container

### NestJS Microservice Processing

```
[Istio Sidecar] → [NestJS Application] → [Business Logic]
```

**NestJS Microservice:**

- **HTTP Server:** Express.js server listening on port 3000
- **Request Processing:** NestJS framework handles HTTP request
- **Routing:** Maps URL path to controller method
- **Middleware:** Authentication, validation, logging middleware
- **Business Logic:** Your application code processes the request
- **Database Integration:** Connects to PostgreSQL through service mesh
- **Cache Integration:** Connects to Redis through service mesh

**Application Flow:**

```typescript
// Example NestJS Controller
@Controller('users')
export class UsersController {
  @Get(':id')
  async getUser(@Param('id') id: string) {
    // Business logic execution
    const user = await this.usersService.findById(id);
    return user;
  }
}
```

---

## Detailed Network Flow Example

### Complete Request Trace: `GET https://api.yourapp.com/user-service/users/123`

```
1. DNS Resolution:
   api.yourapp.com → 35.244.179.100 (GCP Global Load Balancer)

2. Cloud Load Balancer (35.244.179.100):
   ├── TLS Termination: Decrypt HTTPS with Let's Encrypt certificate
   ├── Health Check: Verify Kong Gateway pods are responding
   ├── Geographic Routing: Route to nearest cluster region
   └── Forward: HTTP request to Kong Gateway pod (172.16.0.10:80)

3. Kong Gateway Pod (172.16.0.10):
   ├── Route Matching: /user-service/* → user-service backend
   ├── Authentication Plugin: Validate JWT token from Auth0
   ├── Rate Limiting Plugin: Check request limits for user
   ├── Request Transformer: Add X-Request-ID: abc-123-def
   ├── Logging Plugin: Log request to Loki
   ├── Prometheus Plugin: Increment request counter
   └── Forward: http://user-service.default.svc.cluster.local/users/123

4. Istio Sidecar (Kong Gateway Pod):
   ├── Service Discovery: user-service → ClusterIP 10.96.0.100
   ├── Load Balancing: Select healthy pod → 10.244.1.10
   ├── mTLS Encryption: Encrypt with service mesh certificate
   ├── Distributed Tracing: Add Jaeger trace headers
   ├── Traffic Policy: Apply retry/timeout policies
   └── Forward: https://10.244.1.10:15443/users/123 (Istio sidecar port)

5. Kubernetes Service (user-service):
   ├── Virtual IP: 10.96.0.100:80
   ├── Endpoint Discovery: List healthy pod IPs [10.244.1.10, 10.244.1.11, 10.244.1.12]
   ├── kube-proxy: NAT translation 10.96.0.100 → 10.244.1.10
   ├── Load Balancing: Round-robin selection
   └── Forward: Direct packet to selected pod

6. Pod Network (10.244.1.10):
   ├── Pod IP: 10.244.1.10 (assigned by CNI)
   ├── Network Namespace: Isolated networking per pod
   ├── CNI Plugin: Route packet to pod interface
   ├── Network Policy: Verify traffic is allowed
   └── Forward: Packet to Istio sidecar process

7. Istio Sidecar (User Service Pod):
   ├── Traffic Interception: iptables redirect inbound traffic
   ├── mTLS Termination: Decrypt and verify service mesh certificate
   ├── Authorization: Verify Kong Gateway can call user-service
   ├── Rate Limiting: Check pod-level request limits
   ├── Circuit Breaker: Verify pod health status
   ├── Metrics Collection: Record request in Prometheus
   ├── Distributed Tracing: Continue Jaeger trace span
   └── Forward: http://localhost:3000/users/123

8. NestJS Application (Port 3000):
   ├── HTTP Server: Express.js receives request
   ├── Middleware Pipeline: Authentication, validation, logging
   ├── Route Handler: GET /users/:id → UsersController.getUser()
   ├── Service Layer: UsersService.findById(123)
   ├── Database Query: SELECT * FROM users WHERE id = 123
   │   └── Connection: PostgreSQL through service mesh
   ├── Cache Check: Redis lookup for user data (optional)
   │   └── Connection: Redis through service mesh
   ├── Business Logic: Process user data, apply business rules
   ├── Response Formation: { "id": 123, "name": "John Doe", ... }
   └── HTTP Response: 200 OK with JSON payload
```

---

## Observability During Request Flow

### Metrics Collection (Prometheus)

Request flow generates metrics at each layer:

**Kong Gateway Metrics:**

```
kong_http_requests_total{service="user-service",method="GET",status="200"}
kong_request_latency_seconds{service="user-service",quantile="0.95"}
kong_bandwidth_bytes{service="user-service",direction="ingress"}
```

**Istio Service Mesh Metrics:**

```
istio_requests_total{source_app="kong",destination_service="user-service"}
istio_request_duration_milliseconds{source_app="kong",destination_service="user-service"}
istio_tcp_connections_opened_total{source_app="kong",destination_service="user-service"}
```

**Application Metrics:**

```
nestjs_http_requests_total{method="GET",route="/users/:id",status="200"}
nestjs_http_request_duration_seconds{method="GET",route="/users/:id"}
business_users_retrieved_total{service="user-service"}
```

**Infrastructure Metrics:**

```
container_cpu_usage_seconds_total{pod="user-service-pod-1"}
container_memory_usage_bytes{pod="user-service-pod-1"}
container_network_receive_bytes_total{pod="user-service-pod-1"}
```

### Distributed Tracing (Jaeger)

Single request creates hierarchical trace spans:

```
Trace ID: 1a2b3c4d5e6f7890
└── kong-gateway (Root Span): 25ms
    ├── auth-plugin: 3ms
    ├── rate-limit-plugin: 1ms
    ├── request-transformer: 0.5ms
    └── proxy-upstream: 20.5ms
        └── user-service: 18ms
            ├── istio-inbound: 1ms
            ├── application-handler: 15ms
            │   ├── database-query: 8ms
            │   ├── cache-lookup: 2ms
            │   └── business-logic: 5ms
            └── response-serialization: 2ms
```

### Structured Logging (Loki)

Logs collected from each component:

**Kong Gateway Access Logs:**

```json
{
  "timestamp": "2025-01-08T10:30:45Z",
  "level": "info",
  "service": "kong-gateway",
  "request_id": "abc-123-def",
  "method": "GET",
  "path": "/user-service/users/123",
  "status": 200,
  "latency_ms": 25,
  "user_id": "user-456",
  "client_ip": "203.0.113.42"
}
```

**Istio Envoy Access Logs:**

```json
{
  "timestamp": "2025-01-08T10:30:45Z",
  "level": "info",
  "service": "istio-proxy",
  "source_app": "kong-gateway",
  "destination_service": "user-service",
  "method": "GET",
  "path": "/users/123",
  "status": 200,
  "duration_ms": 18,
  "mtls": "STRICT",
  "trace_id": "1a2b3c4d5e6f7890"
}
```

**Application Business Logs:**

```json
{
  "timestamp": "2025-01-08T10:30:45Z",
  "level": "info",
  "service": "user-service",
  "controller": "UsersController",
  "method": "getUser",
  "user_id": "123",
  "execution_time_ms": 15,
  "trace_id": "1a2b3c4d5e6f7890",
  "message": "User retrieved successfully"
}
```

---

## Security Checkpoints Throughout Flow

### 1. Internet Boundary

- **DDoS Protection:** Cloud provider DDoS mitigation
- **SSL/TLS:** Encryption in transit with valid certificates
- **WAF (Optional):** Web Application Firewall rules

### 2. API Gateway (Kong)

- **Authentication:** JWT token validation
- **Rate Limiting:** Prevent API abuse
- **Input Validation:** Basic request validation
- **API Key Management:** Optional API key requirements

### 3. Service Mesh (Istio)

- **mTLS:** Mandatory encryption for all service-to-service communication
- **Service Authorization:** RBAC policies control which services can communicate
- **Network Policies:** Fine-grained network access control
- **Certificate Management:** Automatic certificate rotation

### 4. Application Layer

- **Input Validation:** Detailed request payload validation
- **Business Logic Security:** Authorization checks for business operations
- **Data Access Control:** Database query authorization
- **Output Sanitization:** Prevent data leakage

### 5. Infrastructure Security

- **Pod Security Policies:** Restrict pod capabilities
- **Network Segmentation:** Isolate workloads by namespace
- **Runtime Security:** Falco monitors for suspicious activity

---

## High Availability & Resilience Patterns

### Multi-Level Redundancy

- **Multiple Replicas:** 3+ instances per microservice across availability zones
- **Health Checks:** Kubernetes readiness/liveness probes at every level
- **Auto-Scaling:** HPA scales pods based on CPU/memory/custom metrics
- **Node Resilience:** Cluster autoscaler replaces failed nodes

### Failure Handling

- **Circuit Breakers:** Istio prevents cascade failures between services
- **Retry Logic:** Exponential backoff with jitter for transient failures
- **Timeout Policies:** Request timeouts at multiple layers prevent hanging requests
- **Graceful Degradation:** Fallback responses when downstream services fail

### Data Consistency

- **Database Transactions:** ACID compliance with PostgreSQL
- **Cache Invalidation:** Redis cache consistency strategies
- **Event Sourcing:** Optional event log for audit and recovery
- **Backup Strategies:** Automated database backups and point-in-time recovery

---

## Performance Optimizations

### Request Optimization

- **Connection Pooling:** Reuse HTTP connections between services
- **Keep-Alive:** Persistent connections reduce connection overhead
- **Compression:** gzip/br compression for response payloads
- **Caching:** Multi-layer caching (Redis, CDN, application-level)

### Resource Optimization

- **Resource Limits:** CPU/memory limits prevent resource starvation
- **Vertical Scaling:** VPA automatically right-sizes containers
- **Horizontal Scaling:** HPA adds replicas during high load
- **Spot Instances:** Cost optimization with preemptible nodes

### Network Optimization

- **Service Mesh Optimization:** Envoy proxy performance tuning
- **Load Balancing:** Optimal algorithms for request distribution
- **Traffic Shaping:** Rate limiting and traffic prioritization
- **Geographic Distribution:** Multi-region deployment for global performance

This complete request flow demonstrates how modern cloud-native architecture provides security, observability, and resilience at every layer while maintaining high performance and developer productivity.
