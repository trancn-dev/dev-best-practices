# Rule: Database Design & SQL/NoSQL Guidelines

## Intent
Enforce database design principles, normalization rules, indexing strategies, and optimal SQL/NoSQL usage patterns. Copilot must suggest well-structured schemas, efficient queries, and appropriate database selection.

## Scope
Applies to all database schema design, query writing, indexing, SQL/NoSQL code generation, and database-related optimizations.

---

## 1. Database Selection Decision

### SQL (Relational) - When to Use

✅ **USE SQL WHEN:**
- ACID transactions required
- Complex joins needed
- Strong data consistency required
- Structured, relational data
- Financial transactions
- Audit trails and compliance
- Reporting and analytics

**Examples:** Banking, E-commerce orders, ERP, HR systems

### NoSQL - When to Use

✅ **USE NoSQL WHEN:**
- Horizontal scalability required
- Flexible schema needed
- High write throughput
- Denormalized data preferred
- Document/key-value storage
- Real-time analytics
- Caching layer

**Examples:** Social feeds, IoT data, CMS, Session storage

### Quick Comparison

| Feature | SQL | NoSQL |
|---------|-----|-------|
| Schema | Fixed | Flexible |
| Scalability | Vertical | Horizontal |
| Transactions | ACID | Eventually consistent |
| Joins | Yes | Limited/No |
| Best For | Complex queries | High throughput |

---

## 2. Schema Design Principles

### Data Types Selection

```sql
-- ✅ GOOD - Appropriate types
CREATE TABLE products (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,  -- Large IDs
    name VARCHAR(255) NOT NULL,             -- Indexed strings
    description TEXT,                       -- Long text
    price DECIMAL(10, 2) NOT NULL,         -- Exact decimals for money
    stock INT NOT NULL DEFAULT 0,
    rating DECIMAL(3, 2),                  -- e.g., 4.75
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSON,                          -- Flexible data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ❌ BAD - Wrong types
CREATE TABLE products (
    id INT,                    -- Too small for large tables
    price FLOAT,               -- Precision issues with money
    is_active VARCHAR(5),      -- Waste of space
    created_at VARCHAR(50)     -- Can't query dates properly
);
```

**Type Selection Rules:**
- ✅ **MUST** use BIGINT for auto-increment IDs
- ✅ **MUST** use DECIMAL for money (never FLOAT)
- ✅ **MUST** use BOOLEAN for true/false flags
- ✅ **MUST** use TIMESTAMP for dates with time
- ✅ **MUST** use TEXT for long content (not indexed)
- ✅ **MUST** use VARCHAR for indexed strings
- ❌ **MUST NOT** use FLOAT/DOUBLE for financial data

---

## 3. Normalization Rules

### 1NF: Eliminate Repeating Groups

```sql
-- ❌ BAD - Not 1NF (non-atomic values)
CREATE TABLE users_bad (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    emails VARCHAR(500)  -- "john@email.com, jane@email.com"
);

-- ✅ GOOD - 1NF compliant
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE user_emails (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### 2NF: Remove Partial Dependencies

```sql
-- ❌ BAD - Not 2NF
CREATE TABLE order_items_bad (
    order_id INT,
    product_id INT,
    product_name VARCHAR(100),    -- Depends only on product_id
    product_price DECIMAL(10, 2),
    quantity INT,
    PRIMARY KEY (order_id, product_id)
);

-- ✅ GOOD - 2NF compliant
CREATE TABLE products (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT NOT NULL,
    price_at_purchase DECIMAL(10, 2),  -- Snapshot
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);
```

### 3NF: Remove Transitive Dependencies

```sql
-- ❌ BAD - Not 3NF
CREATE TABLE employees_bad (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    department_id INT,
    department_name VARCHAR(100),  -- Depends on department_id
    department_head VARCHAR(100)
);

-- ✅ GOOD - 3NF compliant
CREATE TABLE departments (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    head_name VARCHAR(100)
);

CREATE TABLE employees (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(id)
);
```

---

## 4. Relationships & Foreign Keys

### One-to-One

```sql
-- ✅ GOOD
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE user_profiles (
    user_id BIGINT PRIMARY KEY,  -- PK = FK
    bio TEXT,
    avatar_url VARCHAR(500),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### One-to-Many

```sql
-- ✅ GOOD
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT
);

CREATE TABLE posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);
```

### Many-to-Many

```sql
-- ✅ GOOD - Junction table
CREATE TABLE posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL
);

CREATE TABLE tags (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE post_tags (
    post_id BIGINT,
    tag_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
```

**Foreign Key Rules:**
- ✅ **MUST** define foreign keys for referential integrity
- ✅ **MUST** specify ON DELETE action (CASCADE, SET NULL, RESTRICT)
- ✅ **MUST** index foreign key columns
- ✅ **SHOULD** use BIGINT for FK columns matching PK

---

## 5. Indexing Strategy

### Index Creation Rules

```sql
-- ✅ GOOD - Strategic indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status_created ON users(status, created_at);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Covering index (include non-indexed columns)
CREATE INDEX idx_orders_user_status_covering ON orders(user_id, status)
    INCLUDE (total_amount, created_at);

-- Partial index (PostgreSQL)
CREATE INDEX idx_active_users ON users(email)
    WHERE status = 'active';

-- ❌ BAD - Too many indexes
CREATE INDEX idx_users_first_name ON users(first_name);
CREATE INDEX idx_users_last_name ON users(last_name);
CREATE INDEX idx_users_full_name ON users(first_name, last_name);
-- Too many indexes slow down writes!
```

**Index Rules:**
- ✅ **MUST** index PRIMARY KEY (automatic)
- ✅ **MUST** index FOREIGN KEY columns
- ✅ **MUST** index columns in WHERE clauses
- ✅ **MUST** index columns in JOIN conditions
- ✅ **MUST** index columns in ORDER BY
- ✅ **SHOULD** use composite indexes for multi-column queries
- ❌ **MUST NOT** over-index (slows writes)
- ❌ **MUST NOT** index low-cardinality columns (e.g., boolean)

### Index Analysis

```sql
-- Check index usage
EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'john@example.com';

-- PostgreSQL: Check unused indexes
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0;

-- MySQL: Analyze table
ANALYZE TABLE users;
SHOW INDEX FROM users;
```

---

## 6. Query Optimization

### Query Writing Rules

```sql
-- ✅ GOOD - Optimized query
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

-- ❌ BAD - Inefficient query
SELECT *  -- Don't select all columns
FROM users
WHERE YEAR(created_at) = 2025  -- Function on indexed column
    AND (SELECT COUNT(*) FROM orders WHERE user_id = users.id) > 0;  -- Correlated subquery
```

**Query Rules:**
- ✅ **MUST** select only needed columns (not SELECT *)
- ✅ **MUST** use indexed columns in WHERE
- ✅ **MUST** avoid functions on indexed columns
- ✅ **MUST** use JOINs instead of subqueries when possible
- ✅ **MUST** use LIMIT for large result sets
- ✅ **SHOULD** use CTEs for complex queries
- ❌ **MUST NOT** use SELECT * in production
- ❌ **MUST NOT** use OFFSET for deep pagination (use cursor-based)

### Using CTEs (Common Table Expressions)

```sql
-- ✅ GOOD - Readable with CTE
WITH active_users AS (
    SELECT id, name, email
    FROM users
    WHERE status = 'active'
        AND created_at >= '2025-01-01'
),
user_orders AS (
    SELECT user_id, COUNT(*) as order_count
    FROM orders
    GROUP BY user_id
)
SELECT au.name, COALESCE(uo.order_count, 0) as orders
FROM active_users au
LEFT JOIN user_orders uo ON au.id = uo.user_id;
```

### Batch Operations

```sql
-- ✅ GOOD - Bulk insert
INSERT INTO users (name, email, created_at) VALUES
    ('User 1', 'user1@example.com', NOW()),
    ('User 2', 'user2@example.com', NOW()),
    ('User 3', 'user3@example.com', NOW());
    -- Up to 1000 rows

-- ✅ GOOD - Bulk update
UPDATE users
SET status = 'inactive',
    updated_at = NOW()
WHERE last_login < NOW() - INTERVAL '1 year';

-- ❌ BAD - Individual operations in loop
```

---

## 7. Denormalization Strategies

### When to Denormalize

✅ **DENORMALIZE WHEN:**
- Read-heavy workloads with complex joins
- Performance-critical queries
- Reporting and analytics
- Frequently accessed aggregated data

```sql
-- ✅ GOOD - Strategic denormalization
CREATE TABLE posts (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255),
    content TEXT,
    -- Denormalized counters
    comment_count INT DEFAULT 0,
    like_count INT DEFAULT 0,
    view_count INT DEFAULT 0,
    last_comment_at TIMESTAMP NULL
);

-- Update with trigger or application code
CREATE TRIGGER update_post_stats AFTER INSERT ON comments
FOR EACH ROW
    UPDATE posts
    SET comment_count = comment_count + 1,
        last_comment_at = NEW.created_at
    WHERE id = NEW.post_id;
```

---

## 8. Transaction Management

### ACID Properties

```sql
-- ✅ GOOD - Proper transaction
START TRANSACTION;

    UPDATE accounts SET balance = balance - 100 WHERE id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE id = 2;

    INSERT INTO transactions (from_account, to_account, amount)
    VALUES (1, 2, 100);

COMMIT;

-- Error handling
BEGIN;
    -- operations
    IF error THEN
        ROLLBACK;
    ELSE
        COMMIT;
    END IF;
```

**Transaction Rules:**
- ✅ **MUST** use transactions for multi-step operations
- ✅ **MUST** keep transactions short
- ✅ **MUST** handle rollback on error
- ✅ **SHOULD** use proper isolation level
- ❌ **MUST NOT** hold transactions during user input
- ❌ **MUST NOT** perform expensive operations in transactions

---

## 9. PostgreSQL Specific

### JSONB Usage

```sql
-- ✅ GOOD - JSONB with index
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    preferences JSONB
);

CREATE INDEX idx_preferences ON users USING GIN (preferences);

-- Query JSONB
SELECT * FROM users
WHERE preferences @> '{"theme": "dark"}';

-- Update JSONB
UPDATE users
SET preferences = jsonb_set(preferences, '{language}', '"en"')
WHERE id = 123;
```

### Full-Text Search

```sql
-- ✅ GOOD - Full-text search
CREATE TABLE articles (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255),
    content TEXT,
    search_vector TSVECTOR
);

CREATE INDEX idx_search ON articles USING GIN (search_vector);

-- Search
SELECT * FROM articles
WHERE search_vector @@ to_tsquery('postgresql & performance');
```

---

## 10. MongoDB Best Practices

### Schema Design

```javascript
// ✅ GOOD - Embed for One-to-Few
{
    _id: ObjectId("..."),
    name: "John Doe",
    addresses: [
        { type: "home", street: "123 Main St", city: "NYC" },
        { type: "work", street: "456 Office Blvd", city: "NYC" }
    ]
}

// ✅ GOOD - Reference for One-to-Many
// User
{ _id: ObjectId("user123"), name: "John" }

// Posts (separate collection)
{ _id: ObjectId("post456"), user_id: ObjectId("user123"), title: "Post" }

// ✅ GOOD - Denormalize frequently accessed
{
    _id: ObjectId("post456"),
    user_id: ObjectId("user123"),
    user_name: "John Doe",  // Denormalized
    user_avatar: "url",     // Denormalized
    likes_count: 42         // Denormalized counter
}
```

### Indexing

```javascript
// ✅ GOOD - Strategic indexes
db.users.createIndex({ email: 1 }, { unique: true });
db.posts.createIndex({ user_id: 1, created_at: -1 });
db.posts.createIndex({ tags: 1 });  // Array index
db.posts.createIndex({ "address.city": 1 });  // Nested field

// Compound index
db.posts.createIndex({ user_id: 1, status: 1, created_at: -1 });

// Text search
db.articles.createIndex({ title: "text", content: "text" });
db.articles.find({ $text: { $search: "mongodb performance" } });
```

### Query Optimization

```javascript
// ✅ GOOD - Projection (select specific fields)
db.users.find(
    { status: "active" },
    { name: 1, email: 1, _id: 0 }
);

// ✅ GOOD - Pagination
db.posts.find()
    .sort({ created_at: -1 })
    .skip(20)
    .limit(20);

// ✅ BETTER - Cursor-based pagination
db.posts.find({ _id: { $gt: lastId } })
    .sort({ _id: 1 })
    .limit(20);

// ✅ GOOD - Aggregation pipeline
db.orders.aggregate([
    { $match: { status: "completed" } },
    { $group: {
        _id: "$user_id",
        total: { $sum: "$amount" },
        count: { $sum: 1 }
    }},
    { $sort: { total: -1 } },
    { $limit: 10 }
]);
```

---

## 11. Redis Patterns

### Caching

```javascript
// ✅ GOOD - Cache with expiration
async function getUser(userId) {
    const cacheKey = `user:${userId}`;

    // Try cache first
    const cached = await redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    // Cache miss - fetch from DB
    const user = await db.users.findById(userId);

    // Store in cache (TTL: 1 hour)
    await redis.setex(cacheKey, 3600, JSON.stringify(user));

    return user;
}
```

### Rate Limiting

```javascript
// ✅ GOOD - Redis rate limiting
async function checkRateLimit(userId) {
    const key = `rate:${userId}`;
    const current = await redis.incr(key);

    if (current === 1) {
        await redis.expire(key, 60);  // 60 seconds
    }

    return current <= 100;  // 100 requests per minute
}
```

---

## 12. Copilot-Specific Instructions

### Schema Generation

When generating schemas, Copilot **MUST**:

1. **USE** appropriate data types (BIGINT for IDs, DECIMAL for money)
2. **CREATE** indexes for FK columns, WHERE clauses, JOIN conditions
3. **DEFINE** foreign keys with ON DELETE actions
4. **ADD** timestamps (created_at, updated_at)
5. **FOLLOW** naming conventions (snake_case for SQL)
6. **NORMALIZE** to 3NF unless denormalization justified
7. **SUGGEST** appropriate indexes based on query patterns
8. **WARN** about missing indexes or poor types

### Query Optimization

When generating queries, Copilot **MUST**:

1. **SELECT** specific columns (never SELECT *)
2. **USE** indexed columns in WHERE clauses
3. **AVOID** functions on indexed columns
4. **PREFER** JOINs over subqueries
5. **ADD** LIMIT for large results
6. **SUGGEST** CTEs for complex queries
7. **DETECT** N+1 query problems
8. **RECOMMEND** batch operations

### Response Pattern

```markdown
✅ **Schema Suggestion:**

\`\`\`sql
CREATE TABLE orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status ENUM('pending', 'completed', 'cancelled'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status_created (status, created_at)
);
\`\`\`

**Indexes Rationale:**
- `idx_user_id`: For user's orders lookup
- `idx_status_created`: For filtering/sorting by status and date

**Data Type Choices:**
- `BIGINT` for ID (supports large tables)
- `DECIMAL(10,2)` for money (exact precision)
- `ENUM` for status (better than VARCHAR)
```

---

## 13. Performance Checklist

### Schema Design
- [ ] Appropriate data types used
- [ ] Normalized to 3NF (unless justified denormalization)
- [ ] Foreign keys defined with indexes
- [ ] Timestamps included (created_at, updated_at)
- [ ] Unique constraints where needed

### Indexing
- [ ] Primary keys indexed (automatic)
- [ ] Foreign keys indexed
- [ ] WHERE clause columns indexed
- [ ] JOIN columns indexed
- [ ] Composite indexes for multi-column queries
- [ ] No over-indexing (< 5 indexes per table ideal)

### Queries
- [ ] SELECT specific columns only
- [ ] Indexed columns in WHERE
- [ ] No functions on indexed columns
- [ ] JOINs used instead of subqueries
- [ ] LIMIT used for large results
- [ ] Batch operations for bulk changes

### MongoDB
- [ ] Embedded vs referenced data chosen correctly
- [ ] Indexes created for query patterns
- [ ] Projection used to limit returned fields
- [ ] Cursor-based pagination for large datasets

---

## References

- Database Design for Mere Mortals - Michael Hernandez
- SQL Performance Explained - Markus Winand
- MongoDB Data Modeling Guide
- PostgreSQL Documentation
- Use The Index, Luke! (SQL tuning guide)

**Remember:** Good database design is 80% of performance optimization. Design schema well from the start.
