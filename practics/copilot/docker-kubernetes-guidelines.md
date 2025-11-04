# Rule: Docker & Kubernetes Guidelines

## Intent
Enforce containerization and orchestration best practices for Docker images, Kubernetes deployments, and cloud-native applications.

## Scope
Applies to all Dockerfile creation, container configurations, Kubernetes manifests, and deployment strategies.

---

## 1. Dockerfile Best Practices

### Multi-Stage Builds

```dockerfile
# ✅ GOOD - Multi-stage build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
USER node
EXPOSE 3000
CMD ["npm", "start"]

# ❌ BAD - Single stage with dev dependencies
FROM node:18
COPY . .
RUN npm install  # Includes devDependencies
CMD ["npm", "start"]
```

### Image Optimization

- ✅ **MUST** use alpine base images
- ✅ **MUST** use multi-stage builds
- ✅ **MUST** minimize layers
- ✅ **MUST** run as non-root user
- ❌ **MUST NOT** include secrets in image

```dockerfile
# ✅ GOOD - Optimized
FROM node:18-alpine

# Install dependencies first (cached)
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Security: Run as non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

EXPOSE 3000
CMD ["node", "server.js"]
```

### Security

```dockerfile
# ✅ GOOD - Security measures
FROM node:18-alpine

# Update packages
RUN apk update && apk upgrade

# Use specific versions
RUN npm install express@4.18.2

# Don't run as root
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node healthcheck.js || exit 1
```

---

## 2. Docker Compose

```yaml
# ✅ GOOD - docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    restart: unless-stopped

volumes:
  postgres_data:
```

---

## 3. Kubernetes Deployment

### Deployment Manifest

```yaml
# ✅ GOOD - deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:1.0.0
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-url
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Service

```yaml
# ✅ GOOD - service.yml
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: LoadBalancer
```

### ConfigMap & Secret

```yaml
# ✅ GOOD - configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"

---
# ✅ GOOD - secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
type: Opaque
data:
  database-url: <base64-encoded>
  api-key: <base64-encoded>
```

---

## 4. Resource Management

### Resource Requests & Limits

```yaml
# ✅ GOOD - Define resources
resources:
  requests:
    memory: "128Mi"  # Minimum guaranteed
    cpu: "100m"
  limits:
    memory: "512Mi"  # Maximum allowed
    cpu: "500m"
```

### Horizontal Pod Autoscaler

```yaml
# ✅ GOOD - HPA
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

## 5. Health Checks

### Liveness & Readiness

```yaml
# ✅ GOOD - Probes
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```

```javascript
// ✅ GOOD - Health endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy' });
});

app.get('/ready', async (req, res) => {
    try {
        await db.ping();
        res.status(200).json({ status: 'ready' });
    } catch (error) {
        res.status(503).json({ status: 'not ready' });
    }
});
```

---

## 6. Ingress Configuration

```yaml
# ✅ GOOD - ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
```

---

## 7. Security Best Practices

### Pod Security

```yaml
# ✅ GOOD - Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

### Network Policies

```yaml
# ✅ GOOD - Network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-network-policy
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
```

---

## 8. Monitoring & Logging

### Prometheus Metrics

```yaml
# ✅ GOOD - ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 30s
```

### Logging

```yaml
# ✅ GOOD - Structured logs to stdout
containers:
- name: myapp
  env:
  - name: LOG_FORMAT
    value: "json"
```

---

## 9. Best Practices Summary

### Docker
- ✅ **MUST** use multi-stage builds
- ✅ **MUST** use alpine base images
- ✅ **MUST** run as non-root user
- ✅ **MUST** include health checks
- ✅ **SHOULD** keep image size < 200MB
- ❌ **MUST NOT** include secrets in image

### Kubernetes
- ✅ **MUST** define resource requests/limits
- ✅ **MUST** implement liveness/readiness probes
- ✅ **MUST** use ConfigMaps for configuration
- ✅ **MUST** use Secrets for sensitive data
- ✅ **MUST** run ≥ 2 replicas for availability
- ✅ **SHOULD** implement HPA
- ❌ **MUST NOT** use latest tag in production

---

## 10. Copilot Instructions

When generating container configs, Copilot **MUST**:

1. **CREATE** multi-stage Dockerfiles
2. **USE** alpine base images
3. **ADD** health checks
4. **SET** resource limits
5. **IMPLEMENT** liveness/readiness probes
6. **USE** non-root user
7. **SEPARATE** secrets from config
8. **SUGGEST** HPA for scaling

---

## Checklist

### Docker
- [ ] Multi-stage build used
- [ ] Alpine base image
- [ ] Runs as non-root
- [ ] Health check included
- [ ] Image size < 200MB
- [ ] No secrets in image

### Kubernetes
- [ ] Resource requests/limits defined
- [ ] Liveness probe configured
- [ ] Readiness probe configured
- [ ] ConfigMap for config
- [ ] Secrets for sensitive data
- [ ] ≥ 2 replicas
- [ ] HPA configured
- [ ] Network policy defined

---

## References

- Docker Best Practices
- Kubernetes Best Practices - Brendan Burns
- The Kubernetes Book - Nigel Poulton
