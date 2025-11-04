# CI/CD Best Practices - Thực Hành Tốt Nhất CI/CD

> Comprehensive guide for Continuous Integration and Continuous Deployment
>
> **Mục đích**: Tự động hóa testing, building, và deployment process

---

## 📋 Mục Lục
- [CI/CD Fundamentals](#cicd-fundamentals)
- [Pipeline Design](#pipeline-design)
- [Testing Strategy](#testing-strategy)
- [Build Optimization](#build-optimization)
- [Deployment Strategies](#deployment-strategies)
- [Security in CI/CD](#security-in-cicd)
- [Monitoring & Rollback](#monitoring--rollback)
- [Popular CI/CD Tools](#popular-cicd-tools)

---

## 🎯 CI/CD FUNDAMENTALS

### Core Principles

```yaml
# ✅ GOOD - CI/CD Principles

Continuous Integration:
- Commit code frequently (daily)
- Automate builds
- Make builds fast (< 10 minutes)
- Test in production-like environment
- Everyone sees build results
- Fix broken builds immediately

Continuous Deployment:
- Automate deployment process
- Deploy to production frequently
- Make deployment low-risk
- Enable quick rollback
- Monitor after deployment
- Use feature flags
```

### CI/CD vs CD vs CD

```
CI (Continuous Integration)
→ Automated testing on every commit
→ Build artifacts automatically

CD (Continuous Delivery)
→ Automated deployment to staging
→ Manual approval for production

CD (Continuous Deployment)
→ Fully automated to production
→ No manual approval needed
```

---

## 🔄 PIPELINE DESIGN

### GitHub Actions Pipeline

```yaml
# ✅ GOOD - Comprehensive GitHub Actions workflow
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '18.x'
  REGISTRY: ghcr.io

jobs:
  # Stage 1: Code Quality
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Run Prettier
        run: npm run format:check

  # Stage 2: Testing
  test:
    runs-on: ubuntu-latest
    needs: lint

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run unit tests
        run: npm run test:unit

      - name: Run integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
          REDIS_URL: redis://localhost:6379

      - name: Generate coverage report
        run: npm run test:coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json

  # Stage 3: Security Scanning
  security:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v3

      - name: Run Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

      - name: Run npm audit
        run: npm audit --audit-level=high

      - name: OWASP Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        with:
          project: 'myapp'
          path: '.'
          format: 'HTML'

  # Stage 4: Build
  build:
    runs-on: ubuntu-latest
    needs: [test, security]
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build
          path: dist/
          retention-days: 7

  # Stage 5: Docker Build & Push
  docker:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'

    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=sha,prefix={{branch}}-
            type=semver,pattern={{version}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ github.repository }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ github.repository }}:buildcache,mode=max

  # Stage 6: Deploy to Staging
  deploy-staging:
    runs-on: ubuntu-latest
    needs: docker
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.myapp.com

    steps:
      - name: Deploy to staging
        run: |
          curl -X POST ${{ secrets.STAGING_WEBHOOK_URL }} \
            -H "Authorization: Bearer ${{ secrets.DEPLOY_TOKEN }}" \
            -d '{"image": "${{ env.REGISTRY }}/${{ github.repository }}:${{ github.sha }}"}'

  # Stage 7: Deploy to Production
  deploy-production:
    runs-on: ubuntu-latest
    needs: docker
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://myapp.com

    steps:
      - name: Deploy to production
        run: |
          curl -X POST ${{ secrets.PRODUCTION_WEBHOOK_URL }} \
            -H "Authorization: Bearer ${{ secrets.DEPLOY_TOKEN }}" \
            -d '{"image": "${{ env.REGISTRY }}/${{ github.repository }}:${{ github.sha }}"}'

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Deployment to production completed",
              "commit": "${{ github.sha }}",
              "author": "${{ github.actor }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### GitLab CI Pipeline

```yaml
# ✅ GOOD - GitLab CI/CD configuration
stages:
  - lint
  - test
  - build
  - deploy

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  NODE_VERSION: "18"

# Cache dependencies
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .npm/

# Lint stage
lint:
  stage: lint
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npm run lint
    - npm run format:check
  only:
    - merge_requests
    - main
    - develop

# Test stage
test:unit:
  stage: test
  image: node:${NODE_VERSION}
  services:
    - postgres:15
    - redis:7
  variables:
    POSTGRES_DB: test
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    DATABASE_URL: postgresql://postgres:postgres@postgres:5432/test
    REDIS_URL: redis://redis:6379
  script:
    - npm ci
    - npm run test:unit
    - npm run test:integration
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

# Security scanning
security:
  stage: test
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npm audit --audit-level=high
  allow_failure: true

# Build stage
build:
  stage: build
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  only:
    - main
    - develop

# Docker build
docker:build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $DOCKER_IMAGE .
    - docker push $DOCKER_IMAGE
  only:
    - main
    - develop

# Deploy to staging
deploy:staging:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - |
      curl -X POST $STAGING_WEBHOOK_URL \
        -H "Authorization: Bearer $DEPLOY_TOKEN" \
        -d "{\"image\": \"$DOCKER_IMAGE\"}"
  environment:
    name: staging
    url: https://staging.myapp.com
  only:
    - develop

# Deploy to production (manual)
deploy:production:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache curl
  script:
    - |
      curl -X POST $PRODUCTION_WEBHOOK_URL \
        -H "Authorization: Bearer $DEPLOY_TOKEN" \
        -d "{\"image\": \"$DOCKER_IMAGE\"}"
  environment:
    name: production
    url: https://myapp.com
  when: manual
  only:
    - main
```

---

## 🧪 TESTING STRATEGY

### Test Pyramid

```
            /\
           /  \     E2E Tests (5%)
          /    \    - Slow, expensive
         /------\   - Critical user flows
        /        \
       /          \ Integration Tests (15%)
      /            \ - API tests
     /--------------\ - Database tests
    /                \
   /                  \ Unit Tests (80%)
  /____________________\ - Fast, cheap
                         - Pure functions
```

### Automated Testing in CI

```javascript
// ✅ GOOD - Comprehensive test setup

// package.json
{
  "scripts": {
    "test": "npm run test:unit && npm run test:integration && npm run test:e2e",
    "test:unit": "jest --testPathPattern=unit",
    "test:integration": "jest --testPathPattern=integration",
    "test:e2e": "playwright test",
    "test:coverage": "jest --coverage",
    "test:watch": "jest --watch"
  }
}

// jest.config.js
module.exports = {
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  collectCoverageFrom: [
    'src/**/*.{js,ts}',
    '!src/**/*.test.{js,ts}',
    '!src/**/*.spec.{js,ts}'
  ]
};
```

### Parallel Testing

```yaml
# ✅ GOOD - Run tests in parallel
test:
  strategy:
    matrix:
      node-version: [16, 18, 20]
      os: [ubuntu-latest, windows-latest]
  runs-on: ${{ matrix.os }}
  steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.node-version }}
    - run: npm ci
    - run: npm test
```

---

## 🏗️ BUILD OPTIMIZATION

### Caching Dependencies

```yaml
# ✅ GOOD - Cache npm dependencies
- name: Cache node modules
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-

- name: Install dependencies
  run: npm ci
```

### Docker Layer Caching

```dockerfile
# ✅ GOOD - Optimized Dockerfile for caching

FROM node:18-alpine AS dependencies

WORKDIR /app

# Copy only package files first (cached layer)
COPY package*.json ./
RUN npm ci --only=production

# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine AS production

WORKDIR /app

# Copy dependencies from first stage
COPY --from=dependencies /app/node_modules ./node_modules

# Copy built application
COPY --from=builder /app/dist ./dist
COPY package*.json ./

ENV NODE_ENV=production

USER node

CMD ["node", "dist/index.js"]

# ❌ BAD - No layer caching
FROM node:18-alpine
WORKDIR /app
COPY . .  # Everything in one layer
RUN npm install
RUN npm run build
CMD ["node", "dist/index.js"]
```

### Build Artifacts

```yaml
# ✅ GOOD - Share artifacts between jobs
build:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - run: npm ci
    - run: npm run build

    # Upload artifacts
    - uses: actions/upload-artifact@v3
      with:
        name: build-output
        path: dist/
        retention-days: 7

deploy:
  needs: build
  runs-on: ubuntu-latest
  steps:
    # Download artifacts
    - uses: actions/download-artifact@v3
      with:
        name: build-output
        path: dist/

    - run: ./deploy.sh
```

---

## 🚀 DEPLOYMENT STRATEGIES

### Blue-Green Deployment

```yaml
# ✅ GOOD - Blue-Green deployment script

# deploy-blue-green.sh
#!/bin/bash

set -e

# Deploy to blue environment
kubectl apply -f k8s/deployment-blue.yaml
kubectl rollout status deployment/myapp-blue

# Test blue environment
if curl -f https://blue.myapp.com/health; then
    echo "Blue deployment healthy"

    # Switch traffic to blue
    kubectl apply -f k8s/service-blue.yaml

    # Wait for traffic to settle
    sleep 30

    # Scale down green
    kubectl scale deployment/myapp-green --replicas=0
else
    echo "Blue deployment failed health check"
    kubectl delete deployment myapp-blue
    exit 1
fi
```

### Canary Deployment

```yaml
# ✅ GOOD - Canary deployment with Istio

apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
    - myapp.com
  http:
    - match:
        - headers:
            user-agent:
              regex: ".*Mobile.*"
      route:
        - destination:
            host: myapp
            subset: v2
          weight: 100
    - route:
        - destination:
            host: myapp
            subset: v1
          weight: 90  # 90% to stable version
        - destination:
            host: myapp
            subset: v2
          weight: 10  # 10% to canary
```

### Rolling Deployment

```yaml
# ✅ GOOD - Kubernetes rolling update

apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max 1 pod above desired
      maxUnavailable: 1  # Max 1 pod unavailable
  template:
    spec:
      containers:
        - name: myapp
          image: myapp:v2
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 10
```

---

## 🔒 SECURITY IN CI/CD

### Secrets Management

```yaml
# ✅ GOOD - Using GitHub Secrets

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        env:
          API_KEY: ${{ secrets.API_KEY }}
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          ./deploy.sh

# ❌ BAD - Hardcoded secrets
env:
  API_KEY: "sk_live_abc123def456"  # Never do this!
```

### SAST (Static Application Security Testing)

```yaml
# ✅ GOOD - Security scanning in CI

security-scan:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3

    # SonarQube
    - name: SonarQube Scan
      uses: sonarsource/sonarqube-scan-action@master
      env:
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

    # Snyk
    - name: Run Snyk
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

    # CodeQL
    - name: Initialize CodeQL
      uses: github/codeql-action/init@v2
      with:
        languages: javascript

    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2
```

### Container Scanning

```yaml
# ✅ GOOD - Scan Docker images for vulnerabilities

- name: Build image
  run: docker build -t myapp:${{ github.sha }} .

- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'

- name: Upload Trivy results
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results.sarif'
```

---

## 📊 MONITORING & ROLLBACK

### Deployment Monitoring

```yaml
# ✅ GOOD - Monitor deployment health

- name: Deploy application
  run: ./deploy.sh

- name: Wait for deployment
  run: kubectl rollout status deployment/myapp

- name: Check application health
  run: |
    for i in {1..30}; do
      if curl -f https://myapp.com/health; then
        echo "Application is healthy"
        exit 0
      fi
      echo "Waiting for application... ($i/30)"
      sleep 10
    done
    echo "Application failed health check"
    exit 1

- name: Rollback on failure
  if: failure()
  run: kubectl rollout undo deployment/myapp
```

### Automatic Rollback

```javascript
// ✅ GOOD - Automated rollback script

const axios = require('axios');

async function deployWithRollback(version) {
    try {
        // Deploy new version
        await deploy(version);

        // Monitor metrics for 5 minutes
        const metrics = await monitorDeployment(300);

        // Check success criteria
        if (metrics.errorRate > 0.05 || metrics.p99Latency > 1000) {
            console.log('Deployment metrics exceeded threshold');
            await rollback(version);
            throw new Error('Automatic rollback triggered');
        }

        console.log('Deployment successful');
    } catch (error) {
        console.error('Deployment failed:', error);
        await rollback(version);
        throw error;
    }
}

async function monitorDeployment(durationSeconds) {
    const errorRates = [];
    const latencies = [];

    for (let i = 0; i < durationSeconds / 10; i++) {
        const metrics = await getMetrics();
        errorRates.push(metrics.errorRate);
        latencies.push(metrics.p99Latency);

        await sleep(10000);
    }

    return {
        errorRate: Math.max(...errorRates),
        p99Latency: Math.max(...latencies)
    };
}
```

---

## 🛠️ POPULAR CI/CD TOOLS

### Tool Comparison

| Tool | Best For | Pricing | Ease of Use |
|------|----------|---------|-------------|
| **GitHub Actions** | GitHub repos, simple workflows | Free for public repos | ⭐⭐⭐⭐⭐ |
| **GitLab CI** | GitLab repos, complex pipelines | Free tier available | ⭐⭐⭐⭐ |
| **Jenkins** | Self-hosted, customization | Free (self-hosted) | ⭐⭐⭐ |
| **CircleCI** | Fast builds, Docker support | Free tier available | ⭐⭐⭐⭐ |
| **Travis CI** | Open source projects | Free for OSS | ⭐⭐⭐⭐ |
| **Azure Pipelines** | Azure integration | Free tier available | ⭐⭐⭐ |

---

## ✅ CI/CD CHECKLIST

### Pipeline Setup
- [ ] Automated builds on every commit
- [ ] Automated tests (unit, integration, e2e)
- [ ] Code quality checks (linting, formatting)
- [ ] Security scanning (SAST, dependency check)
- [ ] Build artifacts stored
- [ ] Docker images built and tagged
- [ ] Deployment automated

### Testing
- [ ] Unit tests (>80% coverage)
- [ ] Integration tests
- [ ] E2E tests for critical flows
- [ ] Performance tests
- [ ] Security tests
- [ ] Tests run in parallel
- [ ] Failing tests block deployment

### Security
- [ ] Secrets stored securely
- [ ] Container images scanned
- [ ] Dependency vulnerabilities checked
- [ ] SAST scanning enabled
- [ ] Access controls configured
- [ ] Audit logs enabled

### Deployment
- [ ] Staging environment exists
- [ ] Production deployment gated
- [ ] Health checks configured
- [ ] Rollback plan documented
- [ ] Zero-downtime deployment
- [ ] Canary/blue-green strategy
- [ ] Monitoring in place

### Monitoring
- [ ] Deployment notifications
- [ ] Error tracking
- [ ] Performance monitoring
- [ ] Automated rollback on failure
- [ ] Post-deployment verification
- [ ] Incident response plan

---

## 📚 REFERENCES

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [Jenkins User Documentation](https://www.jenkins.io/doc/)
- [The Twelve-Factor App](https://12factor.net/)
- [Continuous Delivery by Jez Humble](https://continuousdelivery.com/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
