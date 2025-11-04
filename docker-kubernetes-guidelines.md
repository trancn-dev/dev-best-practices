# Docker & Kubernetes Guidelines - Hướng Dẫn Docker & Kubernetes

> Best practices for containerization and orchestration
>
> **Mục đích**: Containerize applications, deploy và scale với Kubernetes

---

## 📋 Mục Lục
- [Docker Best Practices](#docker-best-practices)
- [Dockerfile Optimization](#dockerfile-optimization)
- [Docker Compose](#docker-compose)
- [Kubernetes Fundamentals](#kubernetes-fundamentals)
- [Kubernetes Deployments](#kubernetes-deployments)
- [Service & Networking](#service--networking)
- [ConfigMaps & Secrets](#configmaps--secrets)
- [Monitoring & Scaling](#monitoring--scaling)

---

## 🐳 DOCKER BEST PRACTICES

### Multi-Stage Builds

```dockerfile
# ✅ GOOD - Multi-stage build for Node.js

# Stage 1: Dependencies
FROM node:18-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 3: Production
FROM node:18-alpine AS production
WORKDIR /app

# Copy only production dependencies
COPY --from=dependencies /app/node_modules ./node_modules

# Copy built application
COPY --from=builder /app/dist ./dist
COPY package*.json ./

# Security: Run as non-root user
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

CMD ["node", "dist/index.js"]

# ❌ BAD - Single stage, large image
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
CMD ["node", "dist/index.js"]
```

### Minimize Image Size

```dockerfile
# ✅ GOOD - Optimized Python image

FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim

WORKDIR /app

# Copy only necessary files
COPY --from=builder /root/.local /root/.local
COPY app/ ./app/

# Make sure scripts in .local are usable
ENV PATH=/root/.local/bin:$PATH

# Security
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

CMD ["python", "-m", "app.main"]

# Image size: ~150MB vs ~900MB for full python:3.11
```

### Layer Caching

```dockerfile
# ✅ GOOD - Optimize layer caching

FROM node:18-alpine

WORKDIR /app

# 1. Copy package files first (changes least frequently)
COPY package*.json ./

# 2. Install dependencies (cached if package files unchanged)
RUN npm ci --only=production

# 3. Copy source code (changes most frequently)
COPY . .

# ❌ BAD - Copy everything first, no caching
FROM node:18-alpine
WORKDIR /app
COPY . .  # Any file change invalidates all subsequent layers
RUN npm install
```

### Security Best Practices

```dockerfile
# ✅ GOOD - Secure Dockerfile

FROM node:18-alpine

# Update packages and install security updates
RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

WORKDIR /app

# Don't run as root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY --chown=nodejs:nodejs . .

# Security: Remove unnecessary files
RUN rm -rf .git .gitignore .dockerignore

USER nodejs

EXPOSE 3000

CMD ["node", "index.js"]
```

---

## 📝 DOCKERFILE OPTIMIZATION

### .dockerignore File

```dockerignore
# ✅ GOOD - Comprehensive .dockerignore

# Git
.git
.gitignore
.gitattributes

# Dependencies
node_modules
npm-debug.log
yarn-error.log

# Testing
coverage
.nyc_output
*.test.js
*.spec.js
__tests__
__mocks__

# IDE
.vscode
.idea
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Docs
README.md
CHANGELOG.md
docs/

# CI/CD
.github
.gitlab-ci.yml
.travis.yml

# Docker
Dockerfile
docker-compose.yml
.dockerignore

# Environment
.env
.env.local
.env.*.local
```

### Build Arguments

```dockerfile
# ✅ GOOD - Using build arguments

FROM node:18-alpine

ARG NODE_ENV=production
ARG BUILD_DATE
ARG VERSION
ARG PORT=3000

ENV NODE_ENV=${NODE_ENV} \
    PORT=${PORT}

LABEL maintainer="your-email@example.com" \
      version="${VERSION}" \
      build-date="${BUILD_DATE}"

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=${NODE_ENV}

COPY . .

EXPOSE ${PORT}

CMD ["node", "index.js"]
```

```bash
# Build with arguments
docker build \
  --build-arg VERSION=1.0.0 \
  --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  -t myapp:1.0.0 .
```

---

## 🔧 DOCKER COMPOSE

### Production Docker Compose

```yaml
# ✅ GOOD - Production docker-compose.yml

version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        NODE_ENV: production
    image: myapp:latest
    container_name: myapp
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - app-network
    volumes:
      - app-logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M

  db:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - app
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
  app-logs:
```

### Development Docker Compose

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app
      - /app/node_modules  # Don't override node_modules
    environment:
      - NODE_ENV=development
      - DEBUG=app:*
    ports:
      - "3000:3000"
      - "9229:9229"  # Debug port
    command: npm run dev

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=myapp_dev
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    ports:
      - "5432:5432"
```

---

## ☸️ KUBERNETES FUNDAMENTALS

### Deployment

```yaml
# ✅ GOOD - Production-ready Deployment

apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
  labels:
    app: myapp
    version: v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3000"
        prometheus.io/path: "/metrics"
    spec:
      # Security
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000

      # Service account
      serviceAccountName: myapp

      containers:
      - name: myapp
        image: myapp:v1.0.0
        imagePullPolicy: IfNotPresent

        ports:
        - name: http
          containerPort: 3000
          protocol: TCP

        # Resource limits
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"

        # Environment variables
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"

        # Load from ConfigMap
        envFrom:
        - configMapRef:
            name: myapp-config

        # Load secrets
        - secretRef:
            name: myapp-secrets

        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3

        # Graceful shutdown
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]

        # Security context
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL

        # Volumes
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/.cache

      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}

      # Node affinity
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - myapp
              topologyKey: kubernetes.io/hostname
```

---

## 🌐 SERVICE & NETWORKING

### Service Types

```yaml
# ✅ GOOD - ClusterIP Service (internal)

apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - name: http
    port: 80
    targetPort: 3000
    protocol: TCP
  sessionAffinity: ClientIP
```

```yaml
# ✅ GOOD - LoadBalancer Service (external)

apiVersion: v1
kind: Service
metadata:
  name: myapp-external
  namespace: production
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  selector:
    app: myapp
  ports:
  - name: http
    port: 80
    targetPort: 3000
  - name: https
    port: 443
    targetPort: 3000
```

### Ingress

```yaml
# ✅ GOOD - Ingress with TLS

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - myapp.com
    - www.myapp.com
    secretName: myapp-tls

  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80

  - host: www.myapp.com
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

### Network Policy

```yaml
# ✅ GOOD - Network policy for security

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp

  policyTypes:
  - Ingress
  - Egress

  ingress:
  # Allow from nginx ingress
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000

  egress:
  # Allow to database
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432

  # Allow to Redis
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379

  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

---

## 🔐 CONFIGMAPS & SECRETS

### ConfigMap

```yaml
# ✅ GOOD - ConfigMap for application config

apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: production
data:
  # Simple values
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  CACHE_TTL: "3600"

  # Configuration file
  app.conf: |
    server {
      port: 3000
      timeout: 30
    }
    cache {
      enabled: true
      ttl: 3600
    }
```

### Secrets

```yaml
# ✅ GOOD - Secrets for sensitive data

apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: production
type: Opaque
stringData:
  DATABASE_URL: "postgresql://user:password@db:5432/myapp"
  JWT_SECRET: "super-secret-key"
  API_KEY: "api-key-here"
```

```bash
# Create secret from file
kubectl create secret generic myapp-tls \
  --from-file=tls.crt=./cert.crt \
  --from-file=tls.key=./cert.key \
  --namespace=production

# Create secret from literal
kubectl create secret generic myapp-secrets \
  --from-literal=DATABASE_URL='postgresql://...' \
  --from-literal=JWT_SECRET='secret' \
  --namespace=production
```

### Using Secrets in Pods

```yaml
# ✅ GOOD - Mount secrets as files

apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: myapp:latest

    # Option 1: Environment variables
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: myapp-secrets
          key: DATABASE_URL

    # Option 2: Mount as files
    volumeMounts:
    - name: secrets
      mountPath: "/etc/secrets"
      readOnly: true

  volumes:
  - name: secrets
    secret:
      secretName: myapp-secrets
```

---

## 📊 MONITORING & SCALING

### Horizontal Pod Autoscaler (HPA)

```yaml
# ✅ GOOD - HPA based on CPU and memory

apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp

  minReplicas: 3
  maxReplicas: 10

  metrics:
  # CPU utilization
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70

  # Memory utilization
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80

  # Custom metric (requests per second)
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"

  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60

    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

### Resource Quotas

```yaml
# ✅ GOOD - Namespace resource quotas

apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "2"
```

### Pod Disruption Budget

```yaml
# ✅ GOOD - Ensure availability during maintenance

apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
  namespace: production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
```

---

## ✅ DOCKER/KUBERNETES CHECKLIST

### Docker
- [ ] Multi-stage builds used
- [ ] Alpine/slim base images
- [ ] .dockerignore file configured
- [ ] Non-root user
- [ ] Health checks defined
- [ ] Labels for metadata
- [ ] Security scanning (Trivy/Snyk)
- [ ] Image size optimized (< 500MB)

### Kubernetes
- [ ] Resource limits defined
- [ ] Health checks (liveness/readiness)
- [ ] ConfigMaps for configuration
- [ ] Secrets for sensitive data
- [ ] Network policies configured
- [ ] HPA for autoscaling
- [ ] PDB for high availability
- [ ] Monitoring labels
- [ ] Graceful shutdown
- [ ] Security context set

---

## 📚 REFERENCES

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Kubernetes Patterns](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
- [Container Security](https://kubernetes.io/docs/concepts/security/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
