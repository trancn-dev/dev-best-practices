# SQL & NoSQL Guidelines - Hướng Dẫn SQL & NoSQL

> Best practices cho SQL và NoSQL databases, khi nào dùng gì, và cách tối ưu
>
> **Mục đích**: Chọn đúng database, sử dụng hiệu quả, tối ưu performance

---

## 📋 Mục Lục
- [SQL vs NoSQL Decision](#sql-vs-nosql-decision)
- [SQL Best Practices](#sql-best-practices)
- [PostgreSQL Guidelines](#postgresql-guidelines)
- [MySQL Guidelines](#mysql-guidelines)
- [MongoDB Best Practices](#mongodb-best-practices)
- [Redis Usage Patterns](#redis-usage-patterns)
- [Database Selection Guide](#database-selection-guide)

---

## 🤔 SQL VS NOSQL DECISION

### When to Use SQL (Relational)

```
✅ Use SQL when you need:
- ACID transactions
- Complex queries and joins
- Data consistency and integrity
- Structured, relational data
- Strong schema enforcement
- Reporting and analytics
- Financial transactions
- Audit trails

Examples:
- Banking systems
- E-commerce orders
- HR systems
- ERP applications
```

### When to Use NoSQL

```
✅ Use NoSQL when you need:
- Horizontal scalability
- Flexible schema
- High write throughput
- Denormalized data
- Document storage
- Real-time analytics
- Caching layer
- Time-series data

Examples:
- Social media feeds
- IoT sensor data
- Content management
- Real-time analytics
- Session storage
- Message queues
```

### Comparison Table

| Feature | SQL | NoSQL |
|---------|-----|-------|
| **Schema** | Fixed, predefined | Flexible, dynamic |
| **Scalability** | Vertical (scale-up) | Horizontal (scale-out) |
| **Transactions** | ACID guaranteed | Eventually consistent |
| **Joins** | Complex joins supported | Limited or no joins |
| **Data Model** | Tables, rows, columns | Documents, key-value, graph |
| **Use Case** | Complex queries, transactions | High throughput, flexibility |

---

## 💾 SQL BEST PRACTICES

### Query Writing

```sql
-- ✅ GOOD - Specific columns, indexed WHERE
SELECT
    u.id,
    u.name,
    u.email,
    COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.created_at >= '2025-01-01'
    AND u.status = 'active'
GROUP BY u.id, u.name, u.email
ORDER BY order_count DESC
LIMIT 100;

-- ❌ BAD - SELECT *, unindexed column, subqueries
SELECT *
FROM users
WHERE YEAR(created_at) = 2025
    AND (SELECT COUNT(*) FROM orders WHERE user_id = users.id) > 0;
```

### Indexing Strategy

```sql
-- ✅ GOOD - Strategic indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status_created ON users(status, created_at);
CREATE INDEX idx_orders_user_status ON orders(user_id, status)
    INCLUDE (total_amount, created_at);

-- Analyze index usage
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'john@example.com';

-- ❌ BAD - Too many indexes
CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_users_first_name ON users(first_name);
CREATE INDEX idx_users_last_name ON users(last_name);
CREATE INDEX idx_users_full_name ON users(first_name, last_name);
-- Too many indexes slow down writes!
```

### Batch Operations

```sql
-- ✅ GOOD - Bulk insert
INSERT INTO users (name, email, created_at) VALUES
    ('User 1', 'user1@example.com', NOW()),
    ('User 2', 'user2@example.com', NOW()),
    ('User 3', 'user3@example.com', NOW());
    -- Up to 1000 rows at once

-- ✅ GOOD - Bulk update
UPDATE users
SET status = 'inactive',
    updated_at = NOW()
WHERE last_login < NOW() - INTERVAL '1 year'
    AND status = 'active';

-- ❌ BAD - Individual operations
INSERT INTO users (name, email) VALUES ('User 1', 'user1@example.com');
INSERT INTO users (name, email) VALUES ('User 2', 'user2@example.com');
-- Many individual queries
```

### Using CTEs (Common Table Expressions)

```sql
-- ✅ GOOD - Readable complex query with CTE
WITH active_users AS (
    SELECT id, name, email
    FROM users
    WHERE status = 'active'
        AND created_at >= '2025-01-01'
),
user_orders AS (
    SELECT
        user_id,
        COUNT(*) as order_count,
        SUM(total_amount) as total_spent
    FROM orders
    WHERE status = 'completed'
    GROUP BY user_id
)
SELECT
    au.name,
    au.email,
    COALESCE(uo.order_count, 0) as orders,
    COALESCE(uo.total_spent, 0) as spent
FROM active_users au
LEFT JOIN user_orders uo ON au.id = uo.user_id
ORDER BY uo.total_spent DESC NULLS LAST;
```

---

## 🐘 POSTGRESQL GUIDELINES

### Data Types Selection

```sql
-- ✅ GOOD - Appropriate types
CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,  -- Exact decimal for money
    stock INTEGER NOT NULL DEFAULT 0,
    metadata JSONB,  -- JSONB for indexed JSON
    tags TEXT[],  -- Array type
    created_at TIMESTAMPTZ DEFAULT NOW(),  -- Timezone-aware
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ❌ BAD - Wrong types
CREATE TABLE products (
    id INTEGER PRIMARY KEY,  -- Too small
    price FLOAT,  -- Imprecise for money
    created_at TIMESTAMP  -- No timezone
);
```

### JSONB Usage

```sql
-- ✅ GOOD - JSONB with indexes
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    preferences JSONB
);

-- Create GIN index for JSONB
CREATE INDEX idx_users_preferences ON users USING GIN (preferences);

-- Query JSONB
SELECT * FROM users
WHERE preferences @> '{"theme": "dark"}';

SELECT * FROM users
WHERE preferences->>'language' = 'en';

-- Update JSONB
UPDATE users
SET preferences = jsonb_set(
    preferences,
    '{notifications,email}',
    'true'
)
WHERE id = 123;
```

### Full-Text Search

```sql
-- ✅ GOOD - Full-text search setup
CREATE TABLE articles (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255),
    content TEXT,
    search_vector TSVECTOR
);

-- Create GIN index for full-text search
CREATE INDEX idx_articles_search ON articles USING GIN (search_vector);

-- Update search vector
CREATE TRIGGER articles_search_update
BEFORE INSERT OR UPDATE ON articles
FOR EACH ROW EXECUTE FUNCTION
tsvector_update_trigger(
    search_vector, 'pg_catalog.english', title, content
);

-- Search
SELECT * FROM articles
WHERE search_vector @@ to_tsquery('english', 'postgresql & performance');
```

### Partitioning

```sql
-- ✅ GOOD - Partition large tables
CREATE TABLE measurements (
    id BIGSERIAL,
    sensor_id INTEGER NOT NULL,
    value NUMERIC(10, 2),
    recorded_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

-- Create partitions
CREATE TABLE measurements_2025_01 PARTITION OF measurements
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE measurements_2025_02 PARTITION OF measurements
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- Auto-partition with pg_partman extension
```

---

## 🔵 MYSQL GUIDELINES

### Storage Engine Selection

```sql
-- ✅ GOOD - InnoDB for most cases
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Use MyISAM only for read-heavy, no-transaction tables
CREATE TABLE logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP
) ENGINE=MyISAM;
```

### Charset and Collation

```sql
-- ✅ GOOD - UTF8MB4 for full Unicode support
CREATE DATABASE myapp
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE TABLE users (
    name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
);

-- ❌ BAD - Old UTF8 (doesn't support emojis)
CREATE DATABASE myapp CHARACTER SET utf8;
```

### Query Optimization

```sql
-- ✅ GOOD - Use EXPLAIN
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';

-- Analyze table
ANALYZE TABLE users;

-- Optimize table
OPTIMIZE TABLE users;

-- Show index usage
SHOW INDEX FROM users;

-- Show slow queries
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;  -- Log queries > 1 second
```

---

## 🍃 MONGODB BEST PRACTICES

### Schema Design

```javascript
// ✅ GOOD - Embed related data (One-to-Few)
{
    _id: ObjectId("..."),
    name: "John Doe",
    email: "john@example.com",
    addresses: [
        {
            type: "home",
            street: "123 Main St",
            city: "New York"
        },
        {
            type: "work",
            street: "456 Office Blvd",
            city: "New York"
        }
    ]
}

// ✅ GOOD - Reference for One-to-Many
// User document
{
    _id: ObjectId("user123"),
    name: "John Doe",
    email: "john@example.com"
}

// Posts (separate collection)
{
    _id: ObjectId("post456"),
    user_id: ObjectId("user123"),
    title: "My Post",
    content: "..."
}

// ✅ GOOD - Denormalize frequently accessed data
{
    _id: ObjectId("post456"),
    user_id: ObjectId("user123"),
    user_name: "John Doe",  // Denormalized
    user_avatar: "https://...",  // Denormalized
    title: "My Post",
    likes_count: 42  // Denormalized counter
}
```

### Indexing

```javascript
// ✅ GOOD - Create strategic indexes
db.users.createIndex({ email: 1 }, { unique: true });
db.posts.createIndex({ user_id: 1, created_at: -1 });
db.posts.createIndex({ tags: 1 });  // Array index
db.locations.createIndex({ coordinates: "2dsphere" });  // Geo index

// Text index for search
db.articles.createIndex({
    title: "text",
    content: "text"
}, {
    weights: { title: 10, content: 5 }
});

// Compound index
db.orders.createIndex({
    user_id: 1,
    status: 1,
    created_at: -1
});

// Check index usage
db.users.aggregate([
    { $indexStats: {} }
]);
```

### Query Optimization

```javascript
// ✅ GOOD - Efficient queries
// Use projection
db.users.find(
    { status: "active" },
    { name: 1, email: 1, _id: 0 }
);

// Use limit
db.posts.find().sort({ created_at: -1 }).limit(20);

// Use explain
db.users.find({ email: "john@example.com" }).explain("executionStats");

// ❌ BAD - Inefficient queries
// No index on queried field
db.users.find({ "address.city": "New York" });

// Large skip (use cursor-based pagination instead)
db.posts.find().skip(10000).limit(20);

// Regex without index
db.users.find({ email: /.*@example.com/ });
```

### Aggregation Pipeline

```javascript
// ✅ GOOD - Optimized aggregation
db.orders.aggregate([
    // Match first (reduce documents)
    { $match: {
        status: "completed",
        created_at: { $gte: ISODate("2025-01-01") }
    }},

    // Lookup (join)
    { $lookup: {
        from: "users",
        localField: "user_id",
        foreignField: "_id",
        as: "user"
    }},

    { $unwind: "$user" },

    // Group
    { $group: {
        _id: "$user_id",
        total_orders: { $sum: 1 },
        total_amount: { $sum: "$total" }
    }},

    // Sort
    { $sort: { total_amount: -1 }},

    // Limit
    { $limit: 10 }
]);
```

### Transactions (MongoDB 4.0+)

```javascript
// ✅ GOOD - Multi-document transaction
const session = client.startSession();

try {
    await session.withTransaction(async () => {
        // Deduct from sender
        await db.accounts.updateOne(
            { _id: senderId },
            { $inc: { balance: -amount } },
            { session }
        );

        // Add to receiver
        await db.accounts.updateOne(
            { _id: receiverId },
            { $inc: { balance: amount } },
            { session }
        );

        // Log transaction
        await db.transactions.insertOne({
            from: senderId,
            to: receiverId,
            amount: amount,
            timestamp: new Date()
        }, { session });
    });
} finally {
    await session.endSession();
}
```

---

## 🔴 REDIS USAGE PATTERNS

### Data Structures

```javascript
const redis = require('redis');
const client = redis.createClient();

// ✅ GOOD - String (simple key-value)
await client.set('user:123:name', 'John Doe');
await client.setEx('session:abc', 3600, 'session_data');  // Expires in 1 hour

// Hash (object)
await client.hSet('user:123', {
    name: 'John Doe',
    email: 'john@example.com',
    age: 30
});
await client.hGetAll('user:123');

// List (queue, stack)
await client.lPush('jobs:queue', 'job1', 'job2');
await client.rPop('jobs:queue');  // FIFO
await client.lRange('recent:posts', 0, 9);  // Get 10 most recent

// Set (unique items)
await client.sAdd('user:123:interests', 'coding', 'music', 'sports');
await client.sMembers('user:123:interests');
await client.sInter('user:123:interests', 'user:456:interests');  // Common interests

// Sorted Set (leaderboard, ranking)
await client.zAdd('leaderboard', { score: 1000, value: 'player1' });
await client.zAdd('leaderboard', { score: 950, value: 'player2' });
await client.zRangeByScoreWithScores('leaderboard', 0, -1, { REV: true });  // Top scores
```

### Caching Patterns

```javascript
// ✅ GOOD - Cache-aside pattern
async function getUser(userId) {
    const cacheKey = `user:${userId}`;

    // Try cache first
    const cached = await redis.get(cacheKey);
    if (cached) {
        return JSON.parse(cached);
    }

    // Cache miss - fetch from database
    const user = await db.users.findById(userId);

    // Store in cache
    await redis.setEx(cacheKey, 3600, JSON.stringify(user));

    return user;
}

// ✅ GOOD - Write-through cache
async function updateUser(userId, data) {
    // Update database
    await db.users.update(userId, data);

    // Update cache
    const cacheKey = `user:${userId}`;
    const user = await db.users.findById(userId);
    await redis.setEx(cacheKey, 3600, JSON.stringify(user));

    return user;
}

// ✅ GOOD - Cache invalidation
async function deleteUser(userId) {
    await db.users.delete(userId);
    await redis.del(`user:${userId}`);
}
```

### Rate Limiting

```javascript
// ✅ GOOD - Rate limiting with Redis
async function checkRateLimit(userId, limit = 100, window = 3600) {
    const key = `ratelimit:${userId}`;

    const current = await redis.incr(key);

    if (current === 1) {
        await redis.expire(key, window);
    }

    if (current > limit) {
        const ttl = await redis.ttl(key);
        throw new Error(`Rate limit exceeded. Try again in ${ttl} seconds`);
    }

    return {
        remaining: limit - current,
        reset: window
    };
}
```

### Pub/Sub

```javascript
// ✅ GOOD - Real-time messaging
// Publisher
await redis.publish('notifications', JSON.stringify({
    userId: 123,
    message: 'New message received'
}));

// Subscriber
const subscriber = redis.duplicate();
await subscriber.subscribe('notifications', (message) => {
    const data = JSON.parse(message);
    console.log('Received:', data);
});
```

---

## 🗺️ DATABASE SELECTION GUIDE

### By Use Case

```
📊 Analytics & Reporting
→ PostgreSQL, ClickHouse, BigQuery

💬 Real-time Chat
→ MongoDB, Redis, Firebase

🛒 E-commerce
→ PostgreSQL (orders, inventory)
→ Redis (cart, sessions)
→ Elasticsearch (product search)

📱 Social Media
→ PostgreSQL (users, relationships)
→ MongoDB (posts, feeds)
→ Redis (cache, real-time features)
→ Cassandra (time-series data)

🎮 Gaming Leaderboards
→ Redis (sorted sets)
→ PostgreSQL (user data)

📝 Content Management
→ MongoDB (flexible schema)
→ Elasticsearch (full-text search)

💰 Financial Transactions
→ PostgreSQL (ACID compliance)

📈 Time-Series Data (IoT, Metrics)
→ TimescaleDB, InfluxDB, Cassandra

🔍 Search Engine
→ Elasticsearch, Algolia
```

### Performance Comparison

| Operation | PostgreSQL | MongoDB | Redis |
|-----------|------------|---------|-------|
| **Simple read** | ~1ms | ~1ms | ~0.1ms |
| **Complex query** | Good | Limited | N/A |
| **Write throughput** | Good | Excellent | Excellent |
| **Transactions** | Full ACID | Limited | Limited |
| **Scalability** | Vertical | Horizontal | Horizontal |
| **Use case** | Complex queries | Flexible schema | Caching |

---

## 🎯 BEST PRACTICES SUMMARY

### ✅ DO

- ✅ Choose database based on use case
- ✅ Index frequently queried columns
- ✅ Use connection pooling
- ✅ Implement caching layer
- ✅ Monitor query performance
- ✅ Use batch operations
- ✅ Regular backups
- ✅ Plan for scaling

### ❌ DON'T

- ❌ Use SELECT * in production
- ❌ Over-index tables
- ❌ Store large files in database
- ❌ Use database for caching
- ❌ Ignore query performance
- ❌ Use wrong data types
- ❌ Skip database migrations
- ❌ Forget to backup

---

## 📚 REFERENCES

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MySQL Performance Tuning](https://dev.mysql.com/doc/)
- [MongoDB Manual](https://www.mongodb.com/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Use The Index, Luke](https://use-the-index-luke.com/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
