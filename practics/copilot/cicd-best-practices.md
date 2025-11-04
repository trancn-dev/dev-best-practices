# Rule: CI/CD Best Practices

## Intent
Enforce continuous integration and deployment best practices for automated testing, building, and deployment pipelines.

## Scope
Applies to all CI/CD configurations including GitHub Actions, GitLab CI, Jenkins, and deployment workflows.

---

## 1. Pipeline Structure

### Pipeline Stages

```yaml
# ✅ GOOD - Clear stages
stages:
  - lint          # Code quality checks
  - test          # Unit & integration tests
  - build         # Build artifacts
  - security      # Security scans
  - deploy        # Deployment

# ❌ BAD - Everything in one step
```

### GitHub Actions Example

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm test
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm ci
      - run: npm run build
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: build
          path: dist/

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: |
          # Deployment commands
```

---

## 2. Testing in CI

### Test Requirements

- ✅ **MUST** run all tests on every commit
- ✅ **MUST** fail build if tests fail
- ✅ **MUST** track code coverage (≥ 80%)
- ✅ **SHOULD** run tests in parallel

```yaml
# ✅ GOOD - Comprehensive testing
test:
  script:
    - npm run test:unit
    - npm run test:integration
    - npm run test:e2e
  coverage: '/Coverage: \d+\.\d+%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
```

### Test Matrix

```yaml
# ✅ GOOD - Test multiple versions
strategy:
  matrix:
    node: [16, 18, 20]
    os: [ubuntu-latest, windows-latest, macos-latest]

steps:
  - uses: actions/setup-node@v3
    with:
      node-version: ${{ matrix.node }}
  - run: npm test
```

---

## 3. Security Scanning

### Dependency Scanning

```yaml
# ✅ GOOD - Security checks
security:
  script:
    - npm audit --audit-level=moderate
    - npm run snyk:test
    - npm run trivy:scan
```

### Secret Detection

```yaml
# ✅ GOOD - Detect secrets in code
- name: Secret scanning
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: main
```

---

## 4. Build Optimization

### Caching

```yaml
# ✅ GOOD - Cache dependencies
- name: Cache node modules
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

### Docker Layer Caching

```dockerfile
# ✅ GOOD - Optimize Docker builds
FROM node:18-alpine

WORKDIR /app

# Copy package files first (cached layer)
COPY package*.json ./
RUN npm ci --only=production

# Copy source code (changes frequently)
COPY . .
RUN npm run build

CMD ["npm", "start"]
```

---

## 5. Deployment Strategies

### Blue-Green Deployment

```yaml
# ✅ GOOD - Zero-downtime deployment
deploy:
  script:
    - kubectl apply -f k8s/deployment-blue.yml
    - kubectl wait --for=condition=ready pod -l version=blue
    - kubectl patch service myapp -p '{"spec":{"selector":{"version":"blue"}}}'
    - kubectl delete deployment myapp-green
```

### Canary Deployment

```yaml
# ✅ GOOD - Gradual rollout
deploy:
  script:
    # Deploy canary (10% traffic)
    - kubectl apply -f k8s/deployment-canary.yml
    - kubectl set image deployment/myapp-canary myapp=myapp:$CI_COMMIT_SHA
    - sleep 300  # Monitor for 5 minutes
    # If successful, rollout to 100%
    - kubectl apply -f k8s/deployment-stable.yml
```

---

## 6. Environment Management

### Environment Variables

```yaml
# ✅ GOOD - Secure secrets
deploy:
  script:
    - echo "API_KEY=$API_KEY" > .env
    - docker build --secret id=env,src=.env .
  environment:
    name: production
    url: https://app.example.com
  only:
    - main
```

### Multi-Environment

```yaml
# ✅ GOOD - Separate environments
.deploy_template: &deploy
  script:
    - npm run build
    - npm run deploy

deploy:staging:
  <<: *deploy
  environment:
    name: staging
  only:
    - develop

deploy:production:
  <<: *deploy
  environment:
    name: production
  when: manual
  only:
    - main
```

---

## 7. Rollback Strategy

```yaml
# ✅ GOOD - Automated rollback
deploy:
  script:
    - kubectl apply -f k8s/deployment.yml
    - kubectl rollout status deployment/myapp
  on_failure:
    - kubectl rollout undo deployment/myapp
    - slack-notify "Deployment failed, rolled back"
```

---

## 8. Notifications

```yaml
# ✅ GOOD - Notify on status change
.notify: &notify
  script:
    - |
      curl -X POST https://hooks.slack.com/services/XXX \
        -d "text=Pipeline $CI_PIPELINE_STATUS: $CI_PROJECT_NAME"

success_notification:
  <<: *notify
  when: on_success

failure_notification:
  <<: *notify
  when: on_failure
```

---

## 9. Best Practices

### Pipeline Rules

- ✅ **MUST** run on every push/PR
- ✅ **MUST** fail fast (stop on first error)
- ✅ **MUST** be idempotent (same result every time)
- ✅ **MUST** be reproducible
- ✅ **SHOULD** complete in < 10 minutes
- ❌ **MUST NOT** deploy directly to production without approval

### Security

- ✅ **MUST** use secrets management (not hardcoded)
- ✅ **MUST** scan for vulnerabilities
- ✅ **MUST** sign commits/images
- ❌ **MUST NOT** expose secrets in logs

---

## 10. Copilot Instructions

When generating CI/CD configs, Copilot **MUST**:

1. **INCLUDE** lint, test, build, deploy stages
2. **ADD** security scanning
3. **IMPLEMENT** caching for dependencies
4. **CONFIGURE** multiple environments
5. **ADD** rollback mechanism
6. **INCLUDE** notifications
7. **USE** matrix strategy for multi-version testing
8. **SUGGEST** deployment strategies (blue-green, canary)

---

## Checklist

- [ ] All tests run on every commit
- [ ] Code coverage tracked (≥ 80%)
- [ ] Security scanning enabled
- [ ] Dependencies cached
- [ ] Multiple environments configured
- [ ] Rollback strategy defined
- [ ] Notifications configured
- [ ] Deployment requires approval for production
- [ ] Secrets managed securely
- [ ] Pipeline completes in < 10 minutes

---

## References

- The DevOps Handbook
- Continuous Delivery - Jez Humble
- GitHub Actions Documentation
- GitLab CI/CD Documentation
