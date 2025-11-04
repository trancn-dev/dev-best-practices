# Rule: Monitoring, Logging & Observability

## Intent
Enforce comprehensive monitoring, logging, and observability practices for production systems to detect issues, debug problems, and measure performance.

## Scope
Applies to all logging statements, metrics collection, distributed tracing, and monitoring configurations.

---

## 1. Logging Best Practices

### Structured Logging

- ✅ **MUST** use structured logging (JSON format)
- ✅ **MUST** include context (userId, requestId, timestamp)
- ✅ **MUST** use appropriate log levels
- ❌ **MUST NOT** log sensitive data (passwords, tokens, PII)

```javascript
// ✅ GOOD - Structured logging
const winston = require('winston');

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.json(),
    defaultMeta: { service: 'api-server' },
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' })
    ]
});

// Log with context
logger.info('User login successful', {
    userId: user.id,
    email: user.email,
    ip: req.ip,
    userAgent: req.get('user-agent'),
    timestamp: new Date().toISOString()
});

logger.error('Database query failed', {
    error: err.message,
    stack: err.stack,
    query: query,
    duration: queryDuration,
    requestId: req.id
});

// ❌ BAD - Unstructured logging
console.log('User logged in: ' + user.email);
console.error('Error occurred', err);  // No context
```

### Log Levels

```javascript
// ✅ GOOD - Appropriate log levels
logger.error('Payment processing failed', { orderId, error });  // Needs immediate attention
logger.warn('API rate limit approaching', { currentRate: 95 });  // Warning sign
logger.info('User registered', { userId });                      // Important event
logger.debug('Cache hit for key', { key });                      // Development info
logger.trace('Function called', { function: 'processOrder' });   // Detailed tracing
```

### Security Logging

- ✅ **MUST** log authentication attempts
- ✅ **MUST** log authorization failures
- ✅ **MUST** log security-sensitive operations
- ❌ **MUST NOT** log passwords or tokens

```javascript
// ✅ GOOD - Security logging
logger.warn('Failed login attempt', {
    username: req.body.username,
    ip: req.ip,
    userAgent: req.get('user-agent'),
    timestamp: new Date().toISOString()
});

logger.info('Password changed', {
    userId: user.id,
    ip: req.ip
});

logger.error('Unauthorized access attempt', {
    userId: req.user?.id,
    resource: req.path,
    action: req.method
});
```

---

## 2. Metrics & Monitoring

### Application Metrics

```javascript
// ✅ GOOD - Prometheus metrics
const prometheus = require('prom-client');

// Counter: Increments only
const httpRequestsTotal = new prometheus.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code']
});

// Histogram: Measures duration
const httpRequestDuration = new prometheus.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.1, 0.5, 1, 2, 5]
});

// Gauge: Can go up or down
const activeConnections = new prometheus.Gauge({
    name: 'active_connections',
    help: 'Number of active database connections'
});

// Usage
app.use((req, res, next) => {
    const start = Date.now();

    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;

        httpRequestsTotal.inc({
            method: req.method,
            route: req.route?.path || req.path,
            status_code: res.statusCode
        });

        httpRequestDuration.observe({
            method: req.method,
            route: req.route?.path || req.path,
            status_code: res.statusCode
        }, duration);
    });

    next();
});
```

### Business Metrics

```javascript
// ✅ GOOD - Track business metrics
const ordersCreated = new prometheus.Counter({
    name: 'orders_created_total',
    help: 'Total number of orders created'
});

const revenueTotal = new prometheus.Counter({
    name: 'revenue_total_dollars',
    help: 'Total revenue in dollars'
});

// Track in code
async function createOrder(orderData) {
    const order = await Order.create(orderData);

    ordersCreated.inc();
    revenueTotal.inc(order.total);

    return order;
}
```

---

## 3. Distributed Tracing

### OpenTelemetry Setup

```javascript
// ✅ GOOD - Distributed tracing
const { trace } = require('@opentelemetry/api');
const tracer = trace.getTracer('api-server');

async function processOrder(orderId) {
    const span = tracer.startSpan('processOrder');
    span.setAttribute('order.id', orderId);

    try {
        // Validate order
        const validateSpan = tracer.startSpan('validateOrder', { parent: span });
        await validateOrder(orderId);
        validateSpan.end();

        // Process payment
        const paymentSpan = tracer.startSpan('processPayment', { parent: span });
        await processPayment(orderId);
        paymentSpan.end();

        span.setStatus({ code: SpanStatusCode.OK });
    } catch (error) {
        span.setStatus({
            code: SpanStatusCode.ERROR,
            message: error.message
        });
        throw error;
    } finally {
        span.end();
    }
}
```

---

## 4. Health Checks

### Liveness & Readiness Endpoints

```javascript
// ✅ GOOD - Health check endpoints
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

app.get('/ready', async (req, res) => {
    try {
        // Check dependencies
        await Promise.all([
            checkDatabase(),
            checkRedis(),
            checkExternalAPI()
        ]);

        res.status(200).json({
            status: 'ready',
            checks: {
                database: 'ok',
                redis: 'ok',
                externalAPI: 'ok'
            }
        });
    } catch (error) {
        res.status(503).json({
            status: 'not ready',
            error: error.message
        });
    }
});

async function checkDatabase() {
    await db.query('SELECT 1');
}
```

---

## 5. Error Tracking

### Sentry Integration

```javascript
// ✅ GOOD - Error tracking with context
const Sentry = require('@sentry/node');

Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV,
    release: process.env.GIT_COMMIT
});

// Capture error with context
app.use((err, req, res, next) => {
    Sentry.captureException(err, {
        user: {
            id: req.user?.id,
            email: req.user?.email
        },
        tags: {
            route: req.route?.path,
            method: req.method
        },
        extra: {
            body: req.body,
            query: req.query,
            headers: req.headers
        }
    });

    res.status(500).json({ error: 'Internal server error' });
});
```

---

## 6. Performance Monitoring

### APM (Application Performance Monitoring)

```javascript
// ✅ GOOD - New Relic APM
const newrelic = require('newrelic');

async function fetchUserData(userId) {
    return newrelic.startSegment('fetchUserData', true, async () => {
        const user = await db.users.findById(userId);
        newrelic.addCustomAttribute('userId', userId);
        return user;
    });
}
```

---

## 7. Alerting Rules

### Alert Configuration

```yaml
# ✅ GOOD - Prometheus alerts
groups:
  - name: api-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status_code=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} (>5%)"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, http_request_duration_seconds) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "95th percentile response time > 1s"

      - alert: DatabaseConnectionPoolExhausted
        expr: active_connections / max_connections > 0.9
        for: 5m
        labels:
          severity: warning
```

---

## 8. Log Aggregation

### ELK Stack (Elasticsearch, Logstash, Kibana)

```javascript
// ✅ GOOD - Structured logs for ELK
logger.info('Order processed', {
    '@timestamp': new Date().toISOString(),
    level: 'info',
    service: 'order-service',
    event: 'order.processed',
    order: {
        id: order.id,
        amount: order.total,
        items: order.items.length
    },
    user: {
        id: user.id,
        email: user.email
    },
    duration_ms: processingTime
});
```

---

## 9. Copilot Instructions

When generating monitoring code, Copilot **MUST**:

1. **ADD** structured logging with context
2. **INCLUDE** appropriate log levels
3. **IMPLEMENT** health check endpoints
4. **SUGGEST** metrics to track
5. **ADD** error tracking
6. **RECOMMEND** alerting thresholds
7. **WARN** about logging sensitive data

---

## 10. Checklist

### Logging
- [ ] Structured logging (JSON)
- [ ] Appropriate log levels
- [ ] Context included (userId, requestId)
- [ ] No sensitive data logged
- [ ] Security events logged

### Metrics
- [ ] HTTP request metrics
- [ ] Business metrics
- [ ] Resource utilization metrics
- [ ] Error rates tracked

### Monitoring
- [ ] Health check endpoints
- [ ] Liveness probe
- [ ] Readiness probe
- [ ] Dependencies monitored

### Alerting
- [ ] Error rate alerts
- [ ] Performance alerts
- [ ] Resource exhaustion alerts
- [ ] Business metric alerts

---

## References

- The Art of Monitoring - James Turnbull
- Prometheus Documentation
- OpenTelemetry Documentation

**Remember:** You can't improve what you don't measure. Monitor everything.
