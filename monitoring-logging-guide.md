# Monitoring & Logging Guide - Hướng Dẫn Monitoring & Logging

> Best practices for application monitoring, logging, and observability
>
> **Mục đích**: Theo dõi hệ thống, phát hiện lỗi sớm, debug hiệu quả

---

## 📋 Mục Lục
- [Observability Pillars](#observability-pillars)
- [Structured Logging](#structured-logging)
- [Application Monitoring](#application-monitoring)
- [Distributed Tracing](#distributed-tracing)
- [Metrics Collection](#metrics-collection)
- [Alerting](#alerting)
- [Log Aggregation](#log-aggregation)
- [APM Tools](#apm-tools)

---

## 🔭 OBSERVABILITY PILLARS

### Three Pillars of Observability

```
1. LOGS
   - What happened?
   - Discrete events
   - Debugging information

2. METRICS
   - How much/how many?
   - Aggregated data
   - System health

3. TRACES
   - Where did it go?
   - Request flow
   - Latency analysis
```

### Observability Strategy

```javascript
// ✅ GOOD - Comprehensive observability

class ObservabilityService {
    constructor() {
        this.logger = new Logger();
        this.metrics = new MetricsCollector();
        this.tracer = new Tracer();
    }

    async handleRequest(req, res) {
        // Start trace
        const span = this.tracer.startSpan('handleRequest');

        // Log request
        this.logger.info('Request received', {
            method: req.method,
            path: req.path,
            userId: req.user?.id,
            traceId: span.context().traceId
        });

        // Track metrics
        const timer = this.metrics.startTimer('request_duration');
        this.metrics.increment('requests_total');

        try {
            const result = await this.processRequest(req, span);

            // Success metrics
            this.metrics.increment('requests_success');
            this.logger.info('Request completed', {
                traceId: span.context().traceId,
                duration: timer.stop()
            });

            return result;
        } catch (error) {
            // Error tracking
            this.metrics.increment('requests_error');
            this.logger.error('Request failed', {
                error: error.message,
                stack: error.stack,
                traceId: span.context().traceId
            });

            span.setTag('error', true);
            span.log({ event: 'error', message: error.message });

            throw error;
        } finally {
            span.finish();
            timer.stop();
        }
    }
}
```

---

## 📝 STRUCTURED LOGGING

### Winston Logger Setup

```javascript
// ✅ GOOD - Structured logging with Winston

const winston = require('winston');

const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: {
        service: 'myapp',
        environment: process.env.NODE_ENV,
        version: process.env.APP_VERSION
    },
    transports: [
        // Console output
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            )
        }),

        // File output - errors
        new winston.transports.File({
            filename: 'logs/error.log',
            level: 'error',
            maxsize: 10485760, // 10MB
            maxFiles: 5
        }),

        // File output - all logs
        new winston.transports.File({
            filename: 'logs/combined.log',
            maxsize: 10485760,
            maxFiles: 10
        })
    ]
});

// Development-friendly format
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.combine(
            winston.format.colorize(),
            winston.format.printf(({ level, message, timestamp, ...meta }) => {
                return `${timestamp} [${level}]: ${message} ${
                    Object.keys(meta).length ? JSON.stringify(meta, null, 2) : ''
                }`;
            })
        )
    }));
}

module.exports = logger;
```

### Contextual Logging

```javascript
// ✅ GOOD - Add context to logs

const logger = require('./logger');

// Request context middleware
app.use((req, res, next) => {
    // Generate request ID
    req.id = req.headers['x-request-id'] || generateId();

    // Create child logger with context
    req.logger = logger.child({
        requestId: req.id,
        userId: req.user?.id,
        method: req.method,
        path: req.path,
        ip: req.ip
    });

    next();
});

// Usage in route handlers
app.get('/api/users/:id', async (req, res) => {
    req.logger.info('Fetching user', { userId: req.params.id });

    try {
        const user = await getUser(req.params.id);
        req.logger.info('User fetched successfully');
        res.json(user);
    } catch (error) {
        req.logger.error('Failed to fetch user', {
            error: error.message,
            stack: error.stack
        });
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ❌ BAD - No context
console.log('User fetched');
console.error('Error:', error);
```

### Log Levels

```javascript
// ✅ GOOD - Appropriate log levels

// ERROR - Application errors that need attention
logger.error('Database connection failed', {
    error: error.message,
    host: dbConfig.host
});

// WARN - Potential issues that don't break functionality
logger.warn('High memory usage detected', {
    usage: process.memoryUsage().heapUsed / 1024 / 1024,
    threshold: 500
});

// INFO - Important business events
logger.info('User registered', {
    userId: user.id,
    email: user.email
});

// HTTP - HTTP requests (access logs)
logger.http('Request completed', {
    method: req.method,
    path: req.path,
    statusCode: res.statusCode,
    duration: duration
});

// DEBUG - Detailed debugging information
logger.debug('Cache hit', {
    key: cacheKey,
    ttl: 3600
});

// ❌ BAD - Wrong log levels
logger.error('User logged in');  // Not an error!
logger.info('SQL query: SELECT * FROM users WHERE id = ?', [userId]);  // Too verbose for INFO
```

### Sensitive Data Filtering

```javascript
// ✅ GOOD - Filter sensitive data from logs

const sensitiveFields = ['password', 'ssn', 'credit_card', 'token', 'secret'];

function sanitizeObject(obj) {
    if (typeof obj !== 'object' || obj === null) {
        return obj;
    }

    const sanitized = Array.isArray(obj) ? [] : {};

    for (const [key, value] of Object.entries(obj)) {
        if (sensitiveFields.some(field => key.toLowerCase().includes(field))) {
            sanitized[key] = '***REDACTED***';
        } else if (typeof value === 'object') {
            sanitized[key] = sanitizeObject(value);
        } else {
            sanitized[key] = value;
        }
    }

    return sanitized;
}

// Custom format to sanitize logs
const sanitizeFormat = winston.format((info) => {
    info = sanitizeObject(info);
    return info;
});

logger.format = winston.format.combine(
    sanitizeFormat(),
    winston.format.json()
);

// ❌ BAD - Logging sensitive data
logger.info('User login', { email: 'user@example.com', password: 'password123' });
```

---

## 📊 APPLICATION MONITORING

### Custom Metrics with Prometheus

```javascript
// ✅ GOOD - Prometheus metrics

const client = require('prom-client');

// Create a Registry
const register = new client.Registry();

// Add default metrics
client.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new client.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new client.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code']
});

const activeConnections = new client.Gauge({
    name: 'active_connections',
    help: 'Number of active connections'
});

const dbQueryDuration = new client.Summary({
    name: 'db_query_duration_seconds',
    help: 'Duration of database queries',
    labelNames: ['query_type'],
    percentiles: [0.5, 0.9, 0.95, 0.99]
});

// Register metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(activeConnections);
register.registerMetric(dbQueryDuration);

// Middleware to track metrics
app.use((req, res, next) => {
    const start = Date.now();

    // Track active connections
    activeConnections.inc();

    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        const route = req.route?.path || req.path;

        httpRequestDuration
            .labels(req.method, route, res.statusCode)
            .observe(duration);

        httpRequestTotal
            .labels(req.method, route, res.statusCode)
            .inc();

        activeConnections.dec();
    });

    next();
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});

// Track database queries
async function executeQuery(sql, params) {
    const end = dbQueryDuration.startTimer({ query_type: 'select' });

    try {
        const result = await db.query(sql, params);
        return result;
    } finally {
        end();
    }
}
```

### Health Check Endpoint

```javascript
// ✅ GOOD - Comprehensive health check

app.get('/health', async (req, res) => {
    const health = {
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        checks: {}
    };

    try {
        // Database check
        const dbStart = Date.now();
        await db.query('SELECT 1');
        health.checks.database = {
            status: 'up',
            responseTime: Date.now() - dbStart
        };
    } catch (error) {
        health.status = 'degraded';
        health.checks.database = {
            status: 'down',
            error: error.message
        };
    }

    try {
        // Redis check
        const redisStart = Date.now();
        await redis.ping();
        health.checks.redis = {
            status: 'up',
            responseTime: Date.now() - redisStart
        };
    } catch (error) {
        health.status = 'degraded';
        health.checks.redis = {
            status: 'down',
            error: error.message
        };
    }

    // Memory check
    const memUsage = process.memoryUsage();
    health.checks.memory = {
        heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024),
        heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024),
        rss: Math.round(memUsage.rss / 1024 / 1024)
    };

    const statusCode = health.status === 'ok' ? 200 : 503;
    res.status(statusCode).json(health);
});

// Readiness check (for Kubernetes)
app.get('/ready', async (req, res) => {
    try {
        await db.query('SELECT 1');
        res.status(200).json({ status: 'ready' });
    } catch (error) {
        res.status(503).json({ status: 'not ready' });
    }
});
```

---

## 🔍 DISTRIBUTED TRACING

### OpenTelemetry Setup

```javascript
// ✅ GOOD - OpenTelemetry tracing

const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { registerInstrumentations } = require('@opentelemetry/instrumentation');
const { HttpInstrumentation } = require('@opentelemetry/instrumentation-http');
const { ExpressInstrumentation } = require('@opentelemetry/instrumentation-express');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');

// Create tracer provider
const provider = new NodeTracerProvider({
    resource: new Resource({
        [SemanticResourceAttributes.SERVICE_NAME]: 'myapp',
        [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0'
    })
});

// Configure Jaeger exporter
const exporter = new JaegerExporter({
    endpoint: 'http://localhost:14268/api/traces'
});

provider.addSpanProcessor(
    new BatchSpanProcessor(exporter)
);

provider.register();

// Auto-instrument HTTP and Express
registerInstrumentations({
    instrumentations: [
        new HttpInstrumentation(),
        new ExpressInstrumentation()
    ]
});

// Manual instrumentation
const tracer = provider.getTracer('myapp');

async function processOrder(orderId) {
    const span = tracer.startSpan('processOrder');
    span.setAttribute('order.id', orderId);

    try {
        // Child span for database operation
        const dbSpan = tracer.startSpan('database.query', {
            parent: span
        });
        const order = await db.orders.findById(orderId);
        dbSpan.end();

        // Child span for payment processing
        const paymentSpan = tracer.startSpan('payment.process', {
            parent: span
        });
        await processPayment(order);
        paymentSpan.end();

        span.setStatus({ code: SpanStatusCode.OK });
        return order;
    } catch (error) {
        span.setStatus({
            code: SpanStatusCode.ERROR,
            message: error.message
        });
        span.recordException(error);
        throw error;
    } finally {
        span.end();
    }
}
```

### Correlation IDs

```javascript
// ✅ GOOD - Track requests across services

const { v4: uuidv4 } = require('uuid');

// Middleware to add correlation ID
app.use((req, res, next) => {
    // Use existing correlation ID or generate new one
    req.correlationId = req.headers['x-correlation-id'] || uuidv4();

    // Add to response headers
    res.setHeader('x-correlation-id', req.correlationId);

    // Add to logger context
    req.logger = logger.child({ correlationId: req.correlationId });

    next();
});

// Propagate correlation ID to downstream services
async function callDownstreamService(url, data) {
    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-correlation-id': req.correlationId  // Propagate!
        },
        body: JSON.stringify(data)
    });

    return response.json();
}
```

---

## 📈 METRICS COLLECTION

### Key Metrics to Track

```javascript
// ✅ GOOD - Business and technical metrics

// Business metrics
const ordersTotal = new client.Counter({
    name: 'orders_total',
    help: 'Total number of orders',
    labelNames: ['status']
});

const revenue = new client.Counter({
    name: 'revenue_total',
    help: 'Total revenue in USD'
});

// Technical metrics
const cacheHits = new client.Counter({
    name: 'cache_hits_total',
    help: 'Number of cache hits'
});

const cacheMisses = new client.Counter({
    name: 'cache_misses_total',
    help: 'Number of cache misses'
});

const queueSize = new client.Gauge({
    name: 'queue_size',
    help: 'Number of items in queue',
    labelNames: ['queue_name']
});

// Track metrics in business logic
async function createOrder(orderData) {
    const order = await db.orders.create(orderData);

    ordersTotal.labels('created').inc();
    revenue.inc(order.total);

    return order;
}

async function getCachedData(key) {
    const cached = await redis.get(key);

    if (cached) {
        cacheHits.inc();
        return JSON.parse(cached);
    }

    cacheMisses.inc();
    const data = await fetchFromDatabase(key);
    await redis.setEx(key, 3600, JSON.stringify(data));

    return data;
}
```

### RED Method (Rate, Errors, Duration)

```javascript
// ✅ GOOD - RED metrics for services

class REDMetrics {
    constructor(serviceName) {
        // Rate - requests per second
        this.requestRate = new client.Counter({
            name: `${serviceName}_requests_total`,
            help: 'Total number of requests',
            labelNames: ['method', 'endpoint']
        });

        // Errors - failed requests per second
        this.errorRate = new client.Counter({
            name: `${serviceName}_errors_total`,
            help: 'Total number of errors',
            labelNames: ['method', 'endpoint', 'error_type']
        });

        // Duration - latency distribution
        this.duration = new client.Histogram({
            name: `${serviceName}_request_duration_seconds`,
            help: 'Request duration in seconds',
            labelNames: ['method', 'endpoint'],
            buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5]
        });
    }

    trackRequest(method, endpoint) {
        const start = Date.now();
        this.requestRate.labels(method, endpoint).inc();

        return {
            success: () => {
                const duration = (Date.now() - start) / 1000;
                this.duration.labels(method, endpoint).observe(duration);
            },
            error: (errorType) => {
                const duration = (Date.now() - start) / 1000;
                this.errorRate.labels(method, endpoint, errorType).inc();
                this.duration.labels(method, endpoint).observe(duration);
            }
        };
    }
}
```

---

## 🚨 ALERTING

### Alert Rules (Prometheus)

```yaml
# ✅ GOOD - Prometheus alert rules

groups:
  - name: application
    interval: 30s
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          rate(http_requests_total{status_code=~"5.."}[5m])
          / rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"

      # Slow response time
      - alert: SlowResponseTime
        expr: |
          histogram_quantile(0.95,
            rate(http_request_duration_seconds_bucket[5m])
          ) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Slow response time"
          description: "95th percentile is {{ $value }}s"

      # High memory usage
      - alert: HighMemoryUsage
        expr: |
          (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
          / node_memory_MemTotal_bytes > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }}"

      # Database connection pool exhaustion
      - alert: DatabasePoolExhausted
        expr: db_connections_active / db_connections_max > 0.9
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Database connection pool nearly exhausted"
          description: "{{ $value | humanizePercentage }} of connections in use"
```

### Alert Notification

```javascript
// ✅ GOOD - Send alerts to multiple channels

class AlertManager {
    async sendAlert(alert) {
        const { level, title, message, metadata } = alert;

        // Log alert
        logger.error('Alert triggered', {
            level,
            title,
            message,
            ...metadata
        });

        // Send to Slack
        if (level === 'critical' || level === 'error') {
            await this.sendSlackAlert(alert);
        }

        // Send to PagerDuty for critical alerts
        if (level === 'critical') {
            await this.sendPagerDutyAlert(alert);
        }

        // Send email
        await this.sendEmailAlert(alert);
    }

    async sendSlackAlert(alert) {
        const webhook = process.env.SLACK_WEBHOOK_URL;

        await fetch(webhook, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                text: `🚨 ${alert.title}`,
                attachments: [{
                    color: alert.level === 'critical' ? 'danger' : 'warning',
                    fields: [
                        { title: 'Level', value: alert.level, short: true },
                        { title: 'Service', value: alert.metadata.service, short: true },
                        { title: 'Message', value: alert.message, short: false }
                    ]
                }]
            })
        });
    }
}
```

---

## 📦 LOG AGGREGATION

### ELK Stack (Elasticsearch, Logstash, Kibana)

```javascript
// ✅ GOOD - Send logs to Elasticsearch

const { ElasticsearchTransport } = require('winston-elasticsearch');

const esTransport = new ElasticsearchTransport({
    level: 'info',
    clientOpts: {
        node: process.env.ELASTICSEARCH_URL,
        auth: {
            username: process.env.ES_USERNAME,
            password: process.env.ES_PASSWORD
        }
    },
    index: 'logs',
    transformer: (logData) => {
        return {
            '@timestamp': new Date(),
            message: logData.message,
            level: logData.level,
            service: 'myapp',
            environment: process.env.NODE_ENV,
            ...logData.meta
        };
    }
});

logger.add(esTransport);
```

### Grafana Loki

```javascript
// ✅ GOOD - Send logs to Loki

const LokiTransport = require('winston-loki');

logger.add(new LokiTransport({
    host: process.env.LOKI_URL,
    labels: {
        app: 'myapp',
        environment: process.env.NODE_ENV
    },
    json: true,
    format: winston.format.json(),
    replaceTimestamp: true,
    onConnectionError: (err) => console.error(err)
}));
```

---

## 🛠️ APM TOOLS

### Tool Comparison

| Tool | Best For | Pricing | Features |
|------|----------|---------|----------|
| **New Relic** | Full-stack monitoring | Paid | APM, Infrastructure, Logs |
| **Datadog** | Cloud infrastructure | Paid | APM, Metrics, Logs, Traces |
| **Elastic APM** | Self-hosted | Free/Paid | APM, Logs, Metrics |
| **Jaeger** | Distributed tracing | Free | Traces only |
| **Prometheus + Grafana** | Metrics & dashboards | Free | Metrics, Alerting |
| **Sentry** | Error tracking | Free tier | Errors, Performance |

---

## ✅ MONITORING CHECKLIST

- [ ] Structured logging implemented
- [ ] Log levels used appropriately
- [ ] Sensitive data filtered from logs
- [ ] Correlation IDs for request tracking
- [ ] Metrics exposed (Prometheus format)
- [ ] Health check endpoints
- [ ] Distributed tracing configured
- [ ] Alerts configured for critical metrics
- [ ] Log aggregation (ELK/Loki)
- [ ] Dashboards created (Grafana)
- [ ] APM tool integrated
- [ ] Error tracking (Sentry)
- [ ] Performance monitoring
- [ ] Real user monitoring (RUM)

---

## 📚 REFERENCES

- [The Twelve-Factor App - Logs](https://12factor.net/logs)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Grafana Loki Documentation](https://grafana.com/docs/loki/)
- [Google SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
