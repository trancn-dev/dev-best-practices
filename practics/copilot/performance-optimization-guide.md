# Rule: Performance Optimization

## Intent
Enforce performance optimization techniques across frontend, backend, and database layers. Copilot must identify performance bottlenecks and suggest optimizations.

## Scope
Applies to all code generation involving rendering, data fetching, queries, caching, bundling, and resource loading.

---

## 1. Frontend Performance

### Code Splitting & Lazy Loading

- ✅ **MUST** lazy load route components
- ✅ **MUST** code-split large dependencies
- ✅ **MUST** use dynamic imports for heavy modules
- ❌ **MUST NOT** import all components upfront

```javascript
// ✅ GOOD - Lazy loading
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const Profile = lazy(() => import('./pages/Profile'));

function App() {
    return (
        <Suspense fallback={<LoadingSpinner />}>
            <Route path="/dashboard" element={<Dashboard />} />
        </Suspense>
    );
}

// ❌ BAD - No lazy loading
import Dashboard from './pages/Dashboard';
import Profile from './pages/Profile';
```

### Image Optimization

- ✅ **MUST** use responsive images (srcset)
- ✅ **MUST** use modern formats (WebP, AVIF)
- ✅ **MUST** lazy load images below the fold
- ✅ **MUST** specify width/height to prevent CLS
- ❌ **MUST NOT** load full-size images on mobile

```html
<!-- ✅ GOOD -->
<picture>
    <source type="image/webp" srcset="image-320.webp 320w, image-640.webp 640w" />
    <img src="image-640.jpg" loading="lazy" width="640" height="480" alt="Description" />
</picture>
```

### React Performance

- ✅ **MUST** use React.memo for expensive components
- ✅ **MUST** use useMemo for expensive calculations
- ✅ **MUST** use useCallback for callback props
- ✅ **MUST** virtualize long lists (react-window)
- ❌ **MUST NOT** create functions in render

```javascript
// ✅ GOOD - Memoization
const ExpensiveList = memo(({ items, onClick }) => {
    return items.map(item => <Item key={item.id} onClick={onClick} />);
});

function Parent() {
    const handleClick = useCallback((id) => console.log(id), []);
    const sortedItems = useMemo(() => items.sort(), [items]);

    return <ExpensiveList items={sortedItems} onClick={handleClick} />;
}
```

### Bundle Optimization

- ✅ **MUST** tree-shake unused code
- ✅ **MUST** minify JS/CSS
- ✅ **MUST** split vendor bundles
- ✅ **MUST** use compression (gzip/brotli)
- ✅ **SHOULD** keep bundles < 170KB (gzipped)

```javascript
// webpack.config.js
module.exports = {
    optimization: {
        splitChunks: {
            chunks: 'all',
            cacheGroups: {
                vendor: {
                    test: /[\\/]node_modules[\\/]/,
                    name: 'vendors'
                }
            }
        },
        minimize: true
    }
};
```

---

## 2. Backend Performance

### Database Query Optimization

- ✅ **MUST** use indexes for WHERE/JOIN columns
- ✅ **MUST** select only needed columns (no SELECT *)
- ✅ **MUST** use pagination for large results
- ✅ **MUST** use connection pooling
- ❌ **MUST NOT** perform N+1 queries

```javascript
// ✅ GOOD - Optimized query with eager loading
const users = await User.findAll({
    attributes: ['id', 'name', 'email'],
    include: [{ model: Post, attributes: ['id', 'title'] }],
    where: { status: 'active' },
    limit: 20,
    offset: (page - 1) * 20
});

// ❌ BAD - N+1 problem
const users = await User.findAll();
for (const user of users) {
    user.posts = await Post.findAll({ where: { userId: user.id } });
}
```

### Caching Strategy

- ✅ **MUST** cache frequently accessed data
- ✅ **MUST** set appropriate TTL
- ✅ **MUST** invalidate cache on updates
- ✅ **SHOULD** use Redis for distributed caching

**Cache Hierarchy:**
1. Browser cache (static assets)
2. CDN cache (images, CSS, JS)
3. Application cache (Redis)
4. Database query cache

```javascript
// ✅ GOOD - Redis caching
async function getUser(userId) {
    const cacheKey = `user:${userId}`;

    // Try cache first
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    // Cache miss - fetch from DB
    const user = await User.findById(userId);

    // Store in cache (1 hour TTL)
    await redis.setex(cacheKey, 3600, JSON.stringify(user));

    return user;
}

// Invalidate on update
async function updateUser(userId, data) {
    await User.update(data, { where: { id: userId } });
    await redis.del(`user:${userId}`);
}
```

### API Response Optimization

- ✅ **MUST** use compression (gzip)
- ✅ **MUST** implement pagination
- ✅ **MUST** use ETag for caching
- ✅ **SHOULD** support field selection (?fields=id,name)
- ✅ **SHOULD** implement rate limiting

```javascript
// ✅ GOOD - Compressed, paginated response
app.use(compression());

app.get('/api/users', async (req, res) => {
    const { page = 1, limit = 20, fields } = req.query;

    const users = await User.find()
        .select(fields || 'id name email')
        .skip((page - 1) * limit)
        .limit(limit);

    const etag = generateETag(users);

    if (req.headers['if-none-match'] === etag) {
        return res.status(304).send();
    }

    res.set('ETag', etag)
        .set('Cache-Control', 'max-age=300')
        .json({ data: users });
});
```

### Async Operations

- ✅ **MUST** use async/await for I/O operations
- ✅ **MUST** use Promise.all for parallel operations
- ✅ **MUST** use background jobs for long tasks
- ❌ **MUST NOT** block event loop with CPU-intensive work

```javascript
// ✅ GOOD - Parallel operations
const [user, posts, comments] = await Promise.all([
    User.findById(userId),
    Post.find({ userId }),
    Comment.find({ userId })
]);

// ✅ GOOD - Background job for long task
import { Queue } from 'bull';
const emailQueue = new Queue('email');

emailQueue.add({ userId, template: 'welcome' });

// ❌ BAD - Blocking synchronous operation
const result = heavyCalculation();  // Blocks event loop
```

---

## 3. Database Performance

### Indexing Rules

- ✅ **MUST** index foreign key columns
- ✅ **MUST** index WHERE clause columns
- ✅ **MUST** index JOIN columns
- ✅ **SHOULD** use composite indexes for multi-column queries
- ❌ **MUST NOT** over-index (slows writes)

```sql
-- ✅ GOOD - Strategic indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
```

### Query Optimization

- ✅ **MUST** use EXPLAIN to analyze queries
- ✅ **MUST** avoid SELECT *
- ✅ **MUST** use LIMIT for large results
- ✅ **SHOULD** denormalize for read-heavy workloads

```sql
-- ✅ GOOD
SELECT id, name, email
FROM users
WHERE status = 'active'
    AND created_at >= '2025-01-01'
ORDER BY created_at DESC
LIMIT 100;

-- ❌ BAD
SELECT * FROM users;  -- No WHERE, no LIMIT
```

### Connection Pooling

```javascript
// ✅ GOOD - Connection pool
const pool = new Pool({
    host: 'localhost',
    database: 'myapp',
    max: 20,           // Max connections
    min: 5,            // Min connections
    idleTimeoutMillis: 30000
});

// Use pool
const client = await pool.connect();
try {
    const result = await client.query('SELECT * FROM users WHERE id = $1', [userId]);
    return result.rows[0];
} finally {
    client.release();
}
```

---

## 4. Performance Metrics

### Core Web Vitals

```javascript
// ✅ GOOD - Track Core Web Vitals
import { getCLS, getFID, getLCP } from 'web-vitals';

function sendToAnalytics(metric) {
    navigator.sendBeacon('/analytics', JSON.stringify(metric));
}

getCLS(sendToAnalytics);  // Cumulative Layout Shift (< 0.1)
getFID(sendToAnalytics);  // First Input Delay (< 100ms)
getLCP(sendToAnalytics);  // Largest Contentful Paint (< 2.5s)
```

### Performance Budgets

```javascript
const budgets = {
    javascript: 170,    // KB (gzipped)
    css: 50,
    images: 500,
    totalPageWeight: 1000,
    FCP: 1800,         // First Contentful Paint (ms)
    LCP: 2500,         // Largest Contentful Paint (ms)
    TTI: 3800          // Time to Interactive (ms)
};
```

---

## 5. Network Optimization

### HTTP/2 & HTTP/3

- ✅ **MUST** use HTTP/2 or HTTP/3
- ✅ **MUST** enable server push for critical resources
- ✅ **SHOULD** use CDN for static assets

### Resource Hints

```html
<!-- ✅ GOOD - Preload critical resources -->
<link rel="preload" href="critical.css" as="style">
<link rel="preload" href="font.woff2" as="font" crossorigin>

<!-- Prefetch next page -->
<link rel="prefetch" href="/page2.html">

<!-- DNS prefetch -->
<link rel="dns-prefetch" href="https://api.example.com">
```

### API Request Optimization

- ✅ **MUST** batch multiple requests
- ✅ **MUST** debounce/throttle rapid requests
- ✅ **SHOULD** use GraphQL for flexible data fetching

```javascript
// ✅ GOOD - Debounced search
import { debounce } from 'lodash';

const debouncedSearch = debounce(async (query) => {
    const results = await fetch(`/api/search?q=${query}`);
    setResults(results);
}, 300);
```

---

## 6. Copilot-Specific Instructions

### Performance Checks

When generating code, Copilot **MUST**:

1. **DETECT** N+1 query problems
2. **SUGGEST** indexes for WHERE/JOIN columns
3. **RECOMMEND** lazy loading for routes/components
4. **FLAG** SELECT * queries
5. **SUGGEST** memoization for expensive operations
6. **RECOMMEND** caching for frequently accessed data
7. **WARN** about blocking synchronous operations
8. **SUGGEST** pagination for large lists

### Response Pattern

```markdown
⚡ **Performance Issue Detected**

**Problem:** N+1 query in user posts fetching

**Current Code:**
\`\`\`javascript
const users = await User.findAll();
for (const user of users) {
    user.posts = await Post.findAll({ userId: user.id });
}
\`\`\`

**Impact:** 100 users = 101 database queries

✅ **Optimized Solution:**
\`\`\`javascript
const users = await User.findAll({
    include: [{ model: Post }]
});
\`\`\`

**Result:** 1 database query (99% faster)
```

---

## 7. Performance Checklist

### Frontend
- [ ] Code splitting implemented
- [ ] Images optimized (WebP, lazy loading)
- [ ] React components memoized
- [ ] Bundle size < 170KB gzipped
- [ ] Core Web Vitals meet targets

### Backend
- [ ] Database queries indexed
- [ ] No N+1 queries
- [ ] Caching implemented (Redis)
- [ ] API responses compressed
- [ ] Rate limiting enabled

### Database
- [ ] Indexes on FK columns
- [ ] Indexes on WHERE/JOIN columns
- [ ] Connection pooling configured
- [ ] Queries use LIMIT

### Network
- [ ] HTTP/2 enabled
- [ ] CDN configured
- [ ] Resource hints used
- [ ] Requests debounced

---

## References

- Web Vitals - Google
- High Performance Browser Networking - Ilya Grigorik
- Designing Data-Intensive Applications - Martin Kleppmann

**Remember:** Premature optimization is the root of all evil, but informed optimization is essential.
