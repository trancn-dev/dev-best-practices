# Performance Optimization Guide - Hướng Dẫn Tối Ưu Hiệu Năng

> Comprehensive guide for optimizing application performance across frontend, backend, and database
>
> **Mục đích**: Giảm latency, tăng throughput, cải thiện user experience

---

## 📋 Mục Lục
- [Performance Metrics](#performance-metrics)
- [Frontend Optimization](#frontend-optimization)
- [Backend Optimization](#backend-optimization)
- [Database Optimization](#database-optimization)
- [Caching Strategies](#caching-strategies)
- [API Optimization](#api-optimization)
- [Network Optimization](#network-optimization)
- [Profiling & Monitoring](#profiling--monitoring)

---

## 📊 PERFORMANCE METRICS

### Key Performance Indicators

```javascript
// ✅ GOOD - Track important metrics

const metrics = {
    // Frontend metrics
    FCP: 1800,      // First Contentful Paint (< 1.8s)
    LCP: 2500,      // Largest Contentful Paint (< 2.5s)
    FID: 100,       // First Input Delay (< 100ms)
    CLS: 0.1,       // Cumulative Layout Shift (< 0.1)
    TTI: 3800,      // Time to Interactive (< 3.8s)
    TTFB: 600,      // Time to First Byte (< 600ms)

    // Backend metrics
    responseTime: 200,      // API response time (< 200ms)
    throughput: 1000,       // Requests per second
    errorRate: 0.01,        // Error rate (< 1%)

    // Database metrics
    queryTime: 50,          // Query execution time (< 50ms)
    connectionPoolUsage: 70 // Connection pool usage (< 80%)
};

// Web Vitals tracking
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

function sendToAnalytics(metric) {
    const body = JSON.stringify(metric);
    navigator.sendBeacon('/analytics', body);
}

getCLS(sendToAnalytics);
getFID(sendToAnalytics);
getFCP(sendToAnalytics);
getLCP(sendToAnalytics);
getTTFB(sendToAnalytics);
```

### Performance Budgets

```javascript
// ✅ GOOD - Set performance budgets

const performanceBudgets = {
    javascript: 170,      // KB (gzipped)
    css: 50,              // KB (gzipped)
    images: 500,          // KB (total)
    fonts: 100,           // KB (total)
    totalPageWeight: 1000, // KB
    requests: 50,         // Total HTTP requests

    metrics: {
        FCP: 1800,
        LCP: 2500,
        TTI: 3800
    }
};

// Webpack config to enforce budgets
module.exports = {
    performance: {
        maxAssetSize: 250000,
        maxEntrypointSize: 250000,
        hints: 'error'
    }
};
```

---

## 🎨 FRONTEND OPTIMIZATION

### Code Splitting & Lazy Loading

```javascript
// ✅ GOOD - Code splitting with React
import React, { lazy, Suspense } from 'react';

// Lazy load components
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Profile = lazy(() => import('./pages/Profile'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
    return (
        <Router>
            <Suspense fallback={<LoadingSpinner />}>
                <Routes>
                    <Route path="/dashboard" element={<Dashboard />} />
                    <Route path="/profile" element={<Profile />} />
                    <Route path="/settings" element={<Settings />} />
                </Routes>
            </Suspense>
        </Router>
    );
}

// ✅ GOOD - Dynamic imports
async function loadModule() {
    const module = await import('./heavy-module.js');
    module.doSomething();
}

// ❌ BAD - Import everything upfront
import Dashboard from './pages/Dashboard';
import Profile from './pages/Profile';
import Settings from './pages/Settings';
import HeavyChart from './components/HeavyChart';
```

### Image Optimization

```html
<!-- ✅ GOOD - Responsive images with modern formats -->
<picture>
    <!-- WebP for modern browsers -->
    <source
        type="image/webp"
        srcset="
            image-320.webp 320w,
            image-640.webp 640w,
            image-1280.webp 1280w
        "
        sizes="(max-width: 640px) 100vw, 640px"
    />
    <!-- Fallback to JPEG -->
    <img
        src="image-640.jpg"
        srcset="
            image-320.jpg 320w,
            image-640.jpg 640w,
            image-1280.jpg 1280w
        "
        sizes="(max-width: 640px) 100vw, 640px"
        alt="Description"
        loading="lazy"
        width="640"
        height="480"
    />
</picture>

<!-- ✅ GOOD - Native lazy loading -->
<img src="image.jpg" loading="lazy" alt="Description" />

<!-- ✅ GOOD - Low quality image placeholder (LQIP) -->
<img
    src="tiny-placeholder.jpg"
    data-src="full-image.jpg"
    class="lazyload blur"
    alt="Description"
/>
```

```javascript
// ✅ GOOD - Progressive image loading
class ProgressiveImage extends React.Component {
    state = { currentSrc: this.props.placeholder };

    componentDidMount() {
        const img = new Image();
        img.src = this.props.src;
        img.onload = () => {
            this.setState({ currentSrc: this.props.src });
        };
    }

    render() {
        return (
            <img
                src={this.state.currentSrc}
                alt={this.props.alt}
                className={this.state.currentSrc === this.props.placeholder ? 'blur' : ''}
            />
        );
    }
}

// Usage
<ProgressiveImage
    placeholder="tiny-10x10.jpg"
    src="full-image.jpg"
    alt="Description"
/>
```

### Bundle Optimization

```javascript
// ✅ GOOD - Webpack optimization
// webpack.config.js
module.exports = {
    optimization: {
        splitChunks: {
            chunks: 'all',
            cacheGroups: {
                // Separate vendor bundle
                vendor: {
                    test: /[\\/]node_modules[\\/]/,
                    name: 'vendors',
                    priority: 10
                },
                // Separate common code
                common: {
                    minChunks: 2,
                    priority: 5,
                    reuseExistingChunk: true
                }
            }
        },
        // Minimize code
        minimize: true,
        minimizer: [
            new TerserPlugin({
                terserOptions: {
                    compress: {
                        drop_console: true,
                        dead_code: true
                    }
                }
            })
        ],
        // Generate module IDs deterministically
        moduleIds: 'deterministic',
        runtimeChunk: 'single'
    },

    // Tree shaking
    mode: 'production',

    // Source maps for production debugging
    devtool: 'source-map'
};
```

### React Performance

```javascript
// ✅ GOOD - Memoization
import React, { memo, useMemo, useCallback } from 'react';

// Memo component to prevent unnecessary re-renders
const ExpensiveComponent = memo(({ data }) => {
    return <div>{/* Expensive rendering */}</div>;
});

function ParentComponent({ items }) {
    // Memoize expensive calculations
    const sortedItems = useMemo(() => {
        return items.sort((a, b) => b.score - a.score);
    }, [items]);

    // Memoize callbacks
    const handleClick = useCallback((id) => {
        console.log('Clicked:', id);
    }, []);

    return (
        <div>
            {sortedItems.map(item => (
                <ExpensiveComponent
                    key={item.id}
                    data={item}
                    onClick={handleClick}
                />
            ))}
        </div>
    );
}

// ✅ GOOD - Virtualization for long lists
import { FixedSizeList } from 'react-window';

function VirtualizedList({ items }) {
    const Row = ({ index, style }) => (
        <div style={style}>
            {items[index].name}
        </div>
    );

    return (
        <FixedSizeList
            height={600}
            itemCount={items.length}
            itemSize={50}
            width="100%"
        >
            {Row}
        </FixedSizeList>
    );
}

// ❌ BAD - Rendering 10,000 items directly
function BadList({ items }) {
    return (
        <div>
            {items.map(item => (
                <div key={item.id}>{item.name}</div>
            ))}
        </div>
    );
}
```

### Web Workers

```javascript
// ✅ GOOD - Offload heavy computation to Web Worker

// worker.js
self.addEventListener('message', (e) => {
    const { data } = e;

    // Heavy computation
    const result = processLargeDataset(data);

    self.postMessage(result);
});

function processLargeDataset(data) {
    // Complex calculations
    return data.map(item => ({
        ...item,
        processed: complexCalculation(item)
    }));
}

// main.js
const worker = new Worker('worker.js');

worker.postMessage(largeDataset);

worker.addEventListener('message', (e) => {
    const result = e.data;
    updateUI(result);
});
```

---

## ⚙️ BACKEND OPTIMIZATION

### Database Query Optimization

```javascript
// ✅ GOOD - Efficient queries with indexes
// Create indexes
await db.query(`
    CREATE INDEX idx_users_email ON users(email);
    CREATE INDEX idx_orders_user_created ON orders(user_id, created_at);
`);

// Use indexes effectively
async function getActiveUsers(limit = 100) {
    // Select only needed columns
    const query = `
        SELECT id, name, email, created_at
        FROM users
        WHERE status = 'active'
        ORDER BY created_at DESC
        LIMIT $1
    `;

    return await db.query(query, [limit]);
}

// ✅ GOOD - Use connection pooling
const { Pool } = require('pg');

const pool = new Pool({
    max: 20,                    // Maximum connections
    min: 5,                     // Minimum connections
    idleTimeoutMillis: 30000,   // Close idle connections after 30s
    connectionTimeoutMillis: 2000
});

// ❌ BAD - N+1 query problem
async function getUsersWithOrders() {
    const users = await db.query('SELECT * FROM users');

    for (const user of users) {
        // BAD: Separate query for each user
        user.orders = await db.query(
            'SELECT * FROM orders WHERE user_id = $1',
            [user.id]
        );
    }

    return users;
}

// ✅ GOOD - Join or batch query
async function getUsersWithOrdersOptimized() {
    const query = `
        SELECT
            u.id, u.name, u.email,
            json_agg(
                json_build_object(
                    'id', o.id,
                    'total', o.total,
                    'created_at', o.created_at
                )
            ) as orders
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        GROUP BY u.id, u.name, u.email
    `;

    return await db.query(query);
}
```

### Async Processing

```javascript
// ✅ GOOD - Use message queue for heavy tasks
const Bull = require('bull');

const emailQueue = new Bull('email', {
    redis: { host: 'localhost', port: 6379 }
});

// Add job to queue
app.post('/api/register', async (req, res) => {
    const user = await createUser(req.body);

    // Don't block response waiting for email
    await emailQueue.add('welcome', {
        userId: user.id,
        email: user.email
    });

    res.json({ success: true, userId: user.id });
});

// Process jobs in background
emailQueue.process('welcome', async (job) => {
    await sendWelcomeEmail(job.data.email);
});

// ❌ BAD - Blocking operation
app.post('/api/register', async (req, res) => {
    const user = await createUser(req.body);

    // This blocks the response
    await sendWelcomeEmail(user.email);
    await generateReport(user.id);
    await notifyAdmins(user);

    res.json({ success: true });
});
```

### Response Compression

```javascript
// ✅ GOOD - Enable compression
const compression = require('compression');

app.use(compression({
    level: 6,              // Compression level (0-9)
    threshold: 1024,       // Only compress responses > 1KB
    filter: (req, res) => {
        if (req.headers['x-no-compression']) {
            return false;
        }
        return compression.filter(req, res);
    }
}));

// ✅ GOOD - Stream large responses
app.get('/api/export', async (req, res) => {
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=export.csv');

    const cursor = db.collection('users').find().stream();

    cursor.on('data', (doc) => {
        res.write(`${doc.id},${doc.name},${doc.email}\n`);
    });

    cursor.on('end', () => {
        res.end();
    });
});
```

### Rate Limiting

```javascript
// ✅ GOOD - Rate limiting to prevent abuse
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

const limiter = rateLimit({
    store: new RedisStore({
        client: redisClient
    }),
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100,                   // Max 100 requests per window
    message: 'Too many requests, please try again later',
    standardHeaders: true,
    legacyHeaders: false
});

app.use('/api/', limiter);

// Different limits for different endpoints
const strictLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 5
});

app.post('/api/login', strictLimiter, loginHandler);
```

---

## 💾 DATABASE OPTIMIZATION

### Indexing Strategy

```sql
-- ✅ GOOD - Strategic indexes

-- Single column index (frequent WHERE clause)
CREATE INDEX idx_users_email ON users(email);

-- Composite index (multiple columns in WHERE)
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Covering index (includes SELECT columns)
CREATE INDEX idx_orders_user_summary ON orders(user_id, status)
    INCLUDE (total_amount, created_at);

-- Partial index (filtered)
CREATE INDEX idx_active_users ON users(email)
    WHERE status = 'active';

-- Index for sorting
CREATE INDEX idx_posts_created ON posts(created_at DESC);

-- Check index usage
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'user@example.com';
```

### Query Optimization

```sql
-- ✅ GOOD - Optimized queries

-- Use EXISTS instead of COUNT
SELECT id, name FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.user_id = u.id
);

-- Instead of:
SELECT id, name FROM users u
WHERE (SELECT COUNT(*) FROM orders WHERE user_id = u.id) > 0;

-- Use LIMIT to reduce result set
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 20 OFFSET 0;

-- Use specific columns instead of *
SELECT id, title, author_id, created_at
FROM posts
WHERE status = 'published';

-- Avoid functions in WHERE clause (prevents index usage)
-- ❌ BAD
SELECT * FROM users WHERE YEAR(created_at) = 2025;

-- ✅ GOOD
SELECT * FROM users
WHERE created_at >= '2025-01-01'
  AND created_at < '2026-01-01';
```

### Connection Pooling

```javascript
// ✅ GOOD - Proper connection pool configuration

// PostgreSQL
const { Pool } = require('pg');

const pool = new Pool({
    host: 'localhost',
    database: 'myapp',
    max: 20,                    // Max connections
    min: 5,                     // Min connections
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,

    // Logging
    log: (msg) => console.log('PG:', msg)
});

// MongoDB
const { MongoClient } = require('mongodb');

const client = new MongoClient(uri, {
    maxPoolSize: 50,
    minPoolSize: 10,
    maxIdleTimeMS: 30000,
    serverSelectionTimeoutMS: 5000
});

// ❌ BAD - Creating new connection per request
app.get('/users', async (req, res) => {
    const client = new Client();
    await client.connect();  // Slow!
    const result = await client.query('SELECT * FROM users');
    await client.end();
    res.json(result.rows);
});
```

---

## 🚀 CACHING STRATEGIES

### Cache Layers

```javascript
// ✅ GOOD - Multi-layer caching
class CacheService {
    constructor() {
        this.memoryCache = new Map();
        this.redisClient = redis.createClient();
    }

    async get(key) {
        // Layer 1: Memory cache (fastest)
        if (this.memoryCache.has(key)) {
            return this.memoryCache.get(key);
        }

        // Layer 2: Redis cache
        const cached = await this.redisClient.get(key);
        if (cached) {
            const value = JSON.parse(cached);
            this.memoryCache.set(key, value);
            return value;
        }

        // Layer 3: Database
        const value = await this.fetchFromDatabase(key);

        // Store in all layers
        this.memoryCache.set(key, value);
        await this.redisClient.setEx(key, 3600, JSON.stringify(value));

        return value;
    }

    async set(key, value, ttl = 3600) {
        this.memoryCache.set(key, value);
        await this.redisClient.setEx(key, ttl, JSON.stringify(value));
    }

    async invalidate(key) {
        this.memoryCache.delete(key);
        await this.redisClient.del(key);
    }
}
```

### Cache Patterns

```javascript
// ✅ GOOD - Cache-Aside pattern
async function getUser(userId) {
    const cacheKey = `user:${userId}`;

    // Try cache first
    let user = await cache.get(cacheKey);

    if (!user) {
        // Cache miss - fetch from database
        user = await db.users.findById(userId);

        if (user) {
            // Store in cache
            await cache.set(cacheKey, user, 3600);
        }
    }

    return user;
}

// ✅ GOOD - Write-Through cache
async function updateUser(userId, data) {
    // Update database
    const user = await db.users.update(userId, data);

    // Update cache
    const cacheKey = `user:${userId}`;
    await cache.set(cacheKey, user, 3600);

    return user;
}

// ✅ GOOD - Cache invalidation on write
async function deleteUser(userId) {
    await db.users.delete(userId);
    await cache.invalidate(`user:${userId}`);
}
```

### HTTP Caching

```javascript
// ✅ GOOD - HTTP cache headers
app.get('/api/posts/:id', async (req, res) => {
    const post = await getPost(req.params.id);

    // Cache for 5 minutes
    res.set('Cache-Control', 'public, max-age=300');
    res.set('ETag', generateETag(post));

    // Check if client has cached version
    if (req.headers['if-none-match'] === generateETag(post)) {
        return res.status(304).end();
    }

    res.json(post);
});

// ✅ GOOD - Vary header for different responses
app.get('/api/data', (req, res) => {
    res.set('Cache-Control', 'public, max-age=3600');
    res.set('Vary', 'Accept-Encoding, Accept-Language');
    res.json(data);
});

// Static assets with long cache
app.use('/static', express.static('public', {
    maxAge: '1y',
    immutable: true
}));
```

---

## 🌐 API OPTIMIZATION

### Pagination

```javascript
// ✅ GOOD - Cursor-based pagination
app.get('/api/posts', async (req, res) => {
    const limit = parseInt(req.query.limit) || 20;
    const cursor = req.query.cursor;

    let query = db.posts
        .select('id', 'title', 'created_at')
        .orderBy('created_at', 'desc')
        .limit(limit + 1);

    if (cursor) {
        query = query.where('created_at', '<', cursor);
    }

    const posts = await query;
    const hasMore = posts.length > limit;

    if (hasMore) {
        posts.pop();
    }

    res.json({
        data: posts,
        pagination: {
            hasMore,
            nextCursor: hasMore ? posts[posts.length - 1].created_at : null
        }
    });
});

// ❌ BAD - Offset pagination (slow for large offsets)
app.get('/api/posts', async (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = 20;
    const offset = (page - 1) * limit;

    // Slow when offset is large
    const posts = await db.posts
        .select()
        .limit(limit)
        .offset(offset);

    res.json(posts);
});
```

### Data Projection

```javascript
// ✅ GOOD - Field selection (GraphQL-style)
app.get('/api/users/:id', async (req, res) => {
    const fields = req.query.fields?.split(',') || ['id', 'name', 'email'];

    const user = await db.users
        .select(...fields)
        .where({ id: req.params.id })
        .first();

    res.json(user);
});

// Usage: /api/users/123?fields=id,name,email
```

### Batch Requests

```javascript
// ✅ GOOD - DataLoader for batching
const DataLoader = require('dataloader');

const userLoader = new DataLoader(async (userIds) => {
    const users = await db.users
        .whereIn('id', userIds)
        .select();

    // Return in same order as requested
    const userMap = new Map(users.map(u => [u.id, u]));
    return userIds.map(id => userMap.get(id));
});

// Usage in GraphQL resolver
async function getPost(postId) {
    const post = await db.posts.findById(postId);

    // This batches multiple user requests
    post.author = await userLoader.load(post.author_id);

    return post;
}
```

---

## 📈 PROFILING & MONITORING

### Performance Profiling

```javascript
// ✅ GOOD - Node.js profiling
const { performance } = require('perf_hooks');

function measurePerformance(fn, label) {
    return async (...args) => {
        const start = performance.now();
        const result = await fn(...args);
        const duration = performance.now() - start;

        console.log(`${label} took ${duration.toFixed(2)}ms`);

        return result;
    };
}

// Usage
const getUser = measurePerformance(async (id) => {
    return await db.users.findById(id);
}, 'getUser');

// Chrome DevTools CPU profiling
node --inspect app.js
// Open chrome://inspect

// Flame graphs
node --prof app.js
node --prof-process isolate-*.log > profile.txt
```

### Application Monitoring

```javascript
// ✅ GOOD - Custom metrics with Prometheus
const client = require('prom-client');

// Create metrics
const httpRequestDuration = new client.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code']
});

const dbQueryDuration = new client.Histogram({
    name: 'db_query_duration_seconds',
    help: 'Duration of database queries',
    labelNames: ['query_type']
});

// Middleware to track request duration
app.use((req, res, next) => {
    const start = Date.now();

    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        httpRequestDuration
            .labels(req.method, req.route?.path || req.path, res.statusCode)
            .observe(duration);
    });

    next();
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
});
```

---

## ✅ OPTIMIZATION CHECKLIST

### Frontend
- [ ] Code splitting implemented
- [ ] Images optimized and lazy-loaded
- [ ] CSS and JS minified
- [ ] Gzip/Brotli compression enabled
- [ ] HTTP/2 or HTTP/3 used
- [ ] CDN for static assets
- [ ] Service Worker for offline support
- [ ] Tree shaking enabled
- [ ] Critical CSS inlined
- [ ] Web fonts optimized

### Backend
- [ ] Database queries optimized
- [ ] Indexes created for frequent queries
- [ ] Connection pooling configured
- [ ] Caching implemented (Redis/Memcached)
- [ ] Response compression enabled
- [ ] Rate limiting in place
- [ ] Async processing for heavy tasks
- [ ] API pagination implemented
- [ ] N+1 queries eliminated

### Database
- [ ] Proper indexes created
- [ ] Query execution plans reviewed
- [ ] Slow query log monitored
- [ ] Connection pool sized correctly
- [ ] Database partitioning if needed
- [ ] Regular VACUUM/ANALYZE (PostgreSQL)
- [ ] Query cache enabled (if applicable)

### Monitoring
- [ ] Performance metrics tracked
- [ ] Error monitoring (Sentry, etc.)
- [ ] APM tool integrated
- [ ] Real user monitoring (RUM)
- [ ] Alerts configured
- [ ] Regular performance audits

---

## 📚 REFERENCES

- [Web.dev Performance](https://web.dev/performance/)
- [Google PageSpeed Insights](https://pagespeed.web.dev/)
- [WebPageTest](https://www.webpagetest.org/)
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci)
- [Node.js Performance Best Practices](https://nodejs.org/en/docs/guides/simple-profiling/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
