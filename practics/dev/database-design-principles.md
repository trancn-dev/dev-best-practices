# Database Design Principles - Nguyên Tắc Thiết Kế Database

> Hướng dẫn chi tiết về thiết kế database, normalization, indexing, và query optimization
>
> **Mục đích**: Xây dựng database hiệu quả, scalable, maintainable và đảm bảo data integrity

---

## 📋 Mục Lục
- [Database Design Fundamentals](#database-design-fundamentals)
- [Normalization](#normalization)
- [Denormalization Strategies](#denormalization-strategies)
- [Relationships & Foreign Keys](#relationships--foreign-keys)
- [Indexing Strategies](#indexing-strategies)
- [Query Optimization](#query-optimization)
- [Transaction Management](#transaction-management)
- [Schema Design Patterns](#schema-design-patterns)
- [SQL Best Practices](#sql-best-practices)
- [NoSQL Design Patterns](#nosql-design-patterns)

---

## 🎯 DATABASE DESIGN FUNDAMENTALS

### Design Process

```
1. Requirements Analysis
   ↓
2. Conceptual Design (ER Diagram)
   ↓
3. Logical Design (Schema)
   ↓
4. Physical Design (Implementation)
   ↓
5. Optimization & Tuning
```

### Entity-Relationship (ER) Diagram

```sql
-- ✅ GOOD - Clear entity relationships

-- Users Table (Entity)
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_email (email),
    INDEX idx_username (username)
);

-- Posts Table (Entity)
CREATE TABLE posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    published_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_published_at (published_at)
);

-- Comments Table (Entity)
CREATE TABLE comments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_post_id (post_id),
    INDEX idx_user_id (user_id)
);

-- Tags Table (Entity)
CREATE TABLE tags (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_slug (slug)
);

-- Post_Tags (Many-to-Many Relationship)
CREATE TABLE post_tags (
    post_id BIGINT NOT NULL,
    tag_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
    INDEX idx_tag_id (tag_id)
);
```

### Data Types Selection

```sql
-- ✅ GOOD - Appropriate data types

-- Numeric Types
id BIGINT                          -- Large auto-increment IDs
price DECIMAL(10, 2)               -- Exact decimal (money)
quantity INT                       -- Integer counts
rating DECIMAL(3, 2)               -- e.g., 4.75
is_active BOOLEAN                  -- True/False

-- String Types
email VARCHAR(255)                 -- Variable length, indexed
username VARCHAR(50)               -- Short strings
title VARCHAR(255)                 -- Titles
content TEXT                       -- Long text (not indexed)
description MEDIUMTEXT             -- Very long text
slug VARCHAR(100)                  -- URL slugs

-- Date/Time Types
created_at TIMESTAMP               -- With timezone
updated_at TIMESTAMP               -- Auto-update
birth_date DATE                    -- Date only
event_time TIME                    -- Time only
duration INT                       -- Seconds/milliseconds

-- JSON (for flexible schema)
metadata JSON                      -- Structured data
settings JSON                      -- Configuration

-- Binary
avatar BLOB                        -- Small files (not recommended)
avatar_url VARCHAR(500)            -- ✅ Better: store URL

-- ❌ BAD - Wrong data types
id INT                             -- Too small for large tables
price FLOAT                        -- Precision issues with money
is_active VARCHAR(5)               -- Waste of space
created_at VARCHAR(50)             -- Can't query dates properly
```

---

## 📊 NORMALIZATION

### First Normal Form (1NF)

**Rule**: Eliminate repeating groups, ensure atomic values

```sql
-- ❌ BAD - Not in 1NF
CREATE TABLE users_bad (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    emails VARCHAR(500)  -- "john@email.com, jane@email.com" - Not atomic!
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
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);
```

### Second Normal Form (2NF)

**Rule**: Remove partial dependencies (all non-key attributes fully dependent on primary key)

```sql
-- ❌ BAD - Not in 2NF
CREATE TABLE order_items_bad (
    order_id INT,
    product_id INT,
    product_name VARCHAR(100),      -- Depends only on product_id
    product_price DECIMAL(10, 2),   -- Depends only on product_id
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
    price_at_purchase DECIMAL(10, 2) NOT NULL,  -- Snapshot of price
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);
```

### Third Normal Form (3NF)

**Rule**: Remove transitive dependencies (non-key attributes depend only on primary key)

```sql
-- ❌ BAD - Not in 3NF
CREATE TABLE employees_bad (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    department_id INT,
    department_name VARCHAR(100),   -- Depends on department_id, not id
    department_head VARCHAR(100)    -- Depends on department_id, not id
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

### Boyce-Codd Normal Form (BCNF)

**Rule**: Every determinant must be a candidate key

```sql
-- ✅ GOOD - BCNF example
CREATE TABLE professors (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE courses (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE course_assignments (
    professor_id INT,
    course_id INT,
    semester VARCHAR(20),
    PRIMARY KEY (professor_id, course_id, semester),
    FOREIGN KEY (professor_id) REFERENCES professors(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);
```

---

## 🔄 DENORMALIZATION STRATEGIES

### When to Denormalize

1. **Read-heavy workloads** with complex joins
2. **Performance critical** queries
3. **Reporting** and analytics
4. **Caching** frequently accessed data

```sql
-- ✅ GOOD - Strategic denormalization for performance

-- Normalized structure
CREATE TABLE posts (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255),
    content TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE comments (
    id BIGINT PRIMARY KEY,
    post_id BIGINT NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

-- Add denormalized columns for performance
ALTER TABLE posts ADD COLUMN comment_count INT DEFAULT 0;
ALTER TABLE posts ADD COLUMN last_comment_at TIMESTAMP NULL;

-- Update denormalized data with trigger
DELIMITER $$
CREATE TRIGGER update_post_stats AFTER INSERT ON comments
FOR EACH ROW
BEGIN
    UPDATE posts
    SET comment_count = comment_count + 1,
        last_comment_at = NEW.created_at
    WHERE id = NEW.post_id;
END$$
DELIMITER ;

-- Or use application-level update
-- When creating comment:
-- 1. INSERT INTO comments
-- 2. UPDATE posts SET comment_count = comment_count + 1
```

### Materialized Views

```sql
-- ✅ GOOD - Materialized view for complex aggregations
CREATE TABLE user_statistics (
    user_id BIGINT PRIMARY KEY,
    total_posts INT DEFAULT 0,
    total_comments INT DEFAULT 0,
    total_likes INT DEFAULT 0,
    last_activity_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Refresh periodically or on-demand
-- PostgreSQL example
CREATE MATERIALIZED VIEW user_post_stats AS
SELECT
    u.id as user_id,
    COUNT(DISTINCT p.id) as total_posts,
    COUNT(DISTINCT c.id) as total_comments,
    MAX(GREATEST(p.created_at, c.created_at)) as last_activity_at
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id;

-- Refresh
REFRESH MATERIALIZED VIEW user_post_stats;
```

---

## 🔗 RELATIONSHIPS & FOREIGN KEYS

### One-to-One Relationship

```sql
-- ✅ GOOD - One-to-One (User and Profile)
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL
);

CREATE TABLE user_profiles (
    user_id BIGINT PRIMARY KEY,  -- PK is also FK
    bio TEXT,
    avatar_url VARCHAR(500),
    date_of_birth DATE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### One-to-Many Relationship

```sql
-- ✅ GOOD - One-to-Many (User has many Posts)
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE posts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);
```

### Many-to-Many Relationship

```sql
-- ✅ GOOD - Many-to-Many (Students and Courses)
CREATE TABLE students (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE courses (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL
);

-- Junction/Bridge table
CREATE TABLE student_courses (
    student_id BIGINT,
    course_id BIGINT,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    grade DECIMAL(3, 2),
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    INDEX idx_course_id (course_id)
);
```

### Self-Referencing Relationship

```sql
-- ✅ GOOD - Self-referencing (Hierarchical data)
CREATE TABLE categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    parent_id BIGINT NULL,
    level INT DEFAULT 0,
    path VARCHAR(500),  -- e.g., "/1/5/12/" for breadcrumbs
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE CASCADE,
    INDEX idx_parent_id (parent_id)
);

-- Query hierarchy
WITH RECURSIVE category_tree AS (
    -- Base case: root categories
    SELECT id, name, parent_id, 0 as level, CAST(id AS CHAR(500)) as path
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive case: child categories
    SELECT c.id, c.name, c.parent_id, ct.level + 1,
           CONCAT(ct.path, '/', c.id)
    FROM categories c
    INNER JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT * FROM category_tree;
```

### Cascade Options

```sql
-- ✅ GOOD - Appropriate cascade actions
FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE           -- Delete related records
    ON UPDATE CASCADE;

FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE SET NULL          -- Set to NULL if parent deleted
    ON UPDATE CASCADE;

FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE RESTRICT          -- Prevent deletion if has children
    ON UPDATE CASCADE;
```

---

## 📇 INDEXING STRATEGIES

### Index Types

```sql
-- ✅ GOOD - Strategic index placement

-- 1. Primary Key Index (automatic)
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT
);

-- 2. Unique Index
CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_username ON users(username);

-- 3. Single Column Index
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_created_at ON posts(created_at);

-- 4. Composite Index (multiple columns)
-- Order matters! Most selective column first
CREATE INDEX idx_posts_user_status ON posts(user_id, status);
CREATE INDEX idx_posts_status_published ON posts(status, published_at);

-- 5. Covering Index (includes all columns needed)
CREATE INDEX idx_posts_user_cover ON posts(user_id, status)
    INCLUDE (title, created_at);

-- 6. Partial Index (PostgreSQL)
CREATE INDEX idx_posts_published ON posts(published_at)
    WHERE status = 'published';

-- 7. Full-Text Index
CREATE FULLTEXT INDEX idx_posts_content ON posts(title, content);

-- 8. Spatial Index (for geographic data)
CREATE SPATIAL INDEX idx_locations_point ON locations(coordinates);
```

### When to Create Indexes

```sql
-- ✅ CREATE indexes for:

-- 1. Foreign keys
CREATE INDEX idx_comments_post_id ON comments(post_id);

-- 2. Frequently queried columns
CREATE INDEX idx_users_email ON users(email);

-- 3. Columns used in WHERE clauses
CREATE INDEX idx_orders_status ON orders(status);

-- 4. Columns used in JOIN conditions
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- 5. Columns used in ORDER BY
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- 6. Columns used in GROUP BY
CREATE INDEX idx_logs_user_id ON logs(user_id);

-- ❌ DON'T create indexes on:

-- 1. Small tables (< 1000 rows)
-- 2. Columns with low cardinality (e.g., boolean, status with few values)
-- 3. Columns rarely used in queries
-- 4. Columns that are frequently updated
```

### Composite Index Guidelines

```sql
-- ✅ GOOD - Effective composite index usage

-- Query: WHERE user_id = ? AND status = ? ORDER BY created_at
CREATE INDEX idx_posts_user_status_created ON posts(
    user_id,      -- Most selective first
    status,       -- Filter condition
    created_at    -- ORDER BY
);

-- This index can be used for:
-- ✅ WHERE user_id = ?
-- ✅ WHERE user_id = ? AND status = ?
-- ✅ WHERE user_id = ? AND status = ? ORDER BY created_at

-- This index CANNOT be used for:
-- ❌ WHERE status = ?  (doesn't start with user_id)
-- ❌ WHERE created_at > ?  (doesn't start with user_id)

-- ❌ BAD - Wrong column order
CREATE INDEX idx_posts_bad ON posts(status, user_id, created_at);
-- Less efficient for queries filtering by user_id first
```

### Index Maintenance

```sql
-- Check index usage
SELECT
    table_name,
    index_name,
    seq_scan,
    idx_scan,
    idx_scan::float / (seq_scan + idx_scan) as idx_usage_ratio
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY idx_usage_ratio ASC;

-- Find unused indexes
SELECT
    schemaname || '.' || tablename as table,
    indexname as index,
    idx_scan as index_scans
FROM pg_stat_user_indexes
WHERE idx_scan = 0
    AND indexrelname NOT LIKE 'pg_%'
ORDER BY idx_scan ASC;

-- Rebuild fragmented indexes (MySQL)
OPTIMIZE TABLE users;
ALTER TABLE posts ENGINE=InnoDB;

-- Rebuild indexes (PostgreSQL)
REINDEX TABLE users;
```

---

## 🚀 QUERY OPTIMIZATION

### EXPLAIN Query Plan

```sql
-- ✅ GOOD - Use EXPLAIN to analyze queries

-- PostgreSQL
EXPLAIN ANALYZE
SELECT u.name, COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
WHERE u.created_at > '2025-01-01'
GROUP BY u.id, u.name
ORDER BY post_count DESC
LIMIT 10;

-- MySQL
EXPLAIN
SELECT u.name, COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
WHERE u.created_at > '2025-01-01'
GROUP BY u.id, u.name
ORDER BY post_count DESC
LIMIT 10;
```

### Query Optimization Techniques

```sql
-- ❌ BAD - N+1 Query Problem
-- Get all users
SELECT * FROM users;

-- For each user, get posts (N queries)
SELECT * FROM posts WHERE user_id = 1;
SELECT * FROM posts WHERE user_id = 2;
-- ... N more queries

-- ✅ GOOD - Single query with JOIN
SELECT u.*, p.*
FROM users u
LEFT JOIN posts p ON u.id = p.user_id;

-- Or use IN clause
SELECT * FROM users WHERE id IN (1, 2, 3, ...);
SELECT * FROM posts WHERE user_id IN (1, 2, 3, ...);
```

```sql
-- ❌ BAD - SELECT * (fetches unnecessary data)
SELECT * FROM users WHERE id = 1;

-- ✅ GOOD - Select only needed columns
SELECT id, name, email FROM users WHERE id = 1;
```

```sql
-- ❌ BAD - Subquery in SELECT
SELECT
    u.name,
    (SELECT COUNT(*) FROM posts WHERE user_id = u.id) as post_count
FROM users u;

-- ✅ GOOD - Use JOIN instead
SELECT
    u.name,
    COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
GROUP BY u.id, u.name;
```

```sql
-- ❌ BAD - Using functions in WHERE (prevents index usage)
SELECT * FROM users WHERE YEAR(created_at) = 2025;
SELECT * FROM users WHERE LOWER(email) = 'john@example.com';

-- ✅ GOOD - Rewrite to use index
SELECT * FROM users
WHERE created_at >= '2025-01-01' AND created_at < '2026-01-01';

SELECT * FROM users WHERE email = 'john@example.com';
-- Use functional index if needed
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
```

```sql
-- ❌ BAD - OR conditions (harder to optimize)
SELECT * FROM posts WHERE status = 'draft' OR status = 'published';

-- ✅ GOOD - Use IN instead
SELECT * FROM posts WHERE status IN ('draft', 'published');

-- ✅ BETTER - Use UNION for different conditions
SELECT * FROM posts WHERE status = 'draft'
UNION ALL
SELECT * FROM posts WHERE status = 'published';
```

```sql
-- ✅ GOOD - Use LIMIT for pagination
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 20 OFFSET 40;  -- Page 3

-- ✅ BETTER - Cursor-based pagination (more efficient)
SELECT * FROM posts
WHERE created_at < '2025-11-01 10:00:00'
ORDER BY created_at DESC
LIMIT 20;
```

### Query Caching

```sql
-- Application-level caching
-- Redis example
const cacheKey = `user:${userId}:posts`;
let posts = await redis.get(cacheKey);

if (!posts) {
    posts = await db.query('SELECT * FROM posts WHERE user_id = ?', [userId]);
    await redis.setex(cacheKey, 3600, JSON.stringify(posts));  // Cache 1 hour
}

-- Database query cache (MySQL)
-- Enabled by default for SELECT queries
-- Cache is invalidated when table is modified
```

---

## 🔒 TRANSACTION MANAGEMENT

### ACID Properties

```sql
-- ✅ GOOD - Using transactions

-- Start transaction
START TRANSACTION;

-- Atomicity: All or nothing
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

-- Check if both updates succeeded
-- If any fails, everything is rolled back
COMMIT;

-- Or rollback if error
ROLLBACK;
```

### Isolation Levels

```sql
-- Set isolation level
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  -- Dirty reads allowed
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;     -- Default in PostgreSQL
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;    -- Default in MySQL
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;       -- Strictest

-- Example with proper isolation
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;

-- Read current balance
SELECT balance FROM accounts WHERE id = 1 FOR UPDATE;  -- Lock row

-- Update based on current value
UPDATE accounts SET balance = balance - 100 WHERE id = 1;

COMMIT;
```

### Handling Deadlocks

```sql
-- ✅ GOOD - Consistent lock ordering to prevent deadlocks

-- Transaction 1 and 2 both need to update accounts 1 and 2
-- Always lock in same order (e.g., by ID ascending)

START TRANSACTION;
-- Lock account 1 first
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- Then lock account 2
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- Application-level retry on deadlock
try {
    await transferMoney(fromAccount, toAccount, amount);
} catch (error) {
    if (error.code === 'DEADLOCK_DETECTED') {
        // Wait and retry
        await sleep(random(100, 500));
        await transferMoney(fromAccount, toAccount, amount);
    }
}
```

### Optimistic Locking

```sql
-- ✅ GOOD - Version-based optimistic locking
CREATE TABLE products (
    id BIGINT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10, 2),
    stock INT,
    version INT DEFAULT 0,  -- Version number
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Update with version check
UPDATE products
SET
    stock = stock - 1,
    version = version + 1
WHERE
    id = 123
    AND version = 5;  -- Only update if version matches

-- Check affected rows
-- If 0 rows affected, someone else updated it (conflict)
-- Retry with new version
```

---

## 🎨 SCHEMA DESIGN PATTERNS

### Soft Delete Pattern

```sql
-- ✅ GOOD - Soft delete with deleted_at
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    email VARCHAR(255),
    deleted_at TIMESTAMP NULL,  -- NULL = active, timestamp = deleted

    INDEX idx_deleted_at (deleted_at)
);

-- Queries
SELECT * FROM users WHERE deleted_at IS NULL;  -- Active users
SELECT * FROM users WHERE deleted_at IS NOT NULL;  -- Deleted users

-- Soft delete
UPDATE users SET deleted_at = CURRENT_TIMESTAMP WHERE id = 123;

-- Restore
UPDATE users SET deleted_at = NULL WHERE id = 123;

-- Permanent delete (after grace period)
DELETE FROM users WHERE deleted_at < DATE_SUB(NOW(), INTERVAL 30 DAY);
```

### Audit Trail Pattern

```sql
-- ✅ GOOD - Audit log table
CREATE TABLE users (
    id BIGINT PRIMARY KEY,
    email VARCHAR(255),
    name VARCHAR(100)
);

CREATE TABLE user_audit_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    action ENUM('CREATE', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,  -- Before update
    new_values JSON,  -- After update
    changed_by BIGINT,  -- Who made the change
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),

    INDEX idx_user_id (user_id),
    INDEX idx_changed_at (changed_at)
);

-- Trigger to maintain audit log
DELIMITER $$
CREATE TRIGGER user_audit_update AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    INSERT INTO user_audit_log (user_id, action, old_values, new_values, changed_at)
    VALUES (
        OLD.id,
        'UPDATE',
        JSON_OBJECT('email', OLD.email, 'name', OLD.name),
        JSON_OBJECT('email', NEW.email, 'name', NEW.name),
        CURRENT_TIMESTAMP
    );
END$$
DELIMITER ;
```

### Polymorphic Associations

```sql
-- ✅ GOOD - Polymorphic pattern
-- Comments can belong to Posts or Videos

CREATE TABLE posts (
    id BIGINT PRIMARY KEY,
    title VARCHAR(255)
);

CREATE TABLE videos (
    id BIGINT PRIMARY KEY,
    title VARCHAR(255)
);

CREATE TABLE comments (
    id BIGINT PRIMARY KEY,
    commentable_id BIGINT NOT NULL,
    commentable_type VARCHAR(50) NOT NULL,  -- 'Post' or 'Video'
    content TEXT NOT NULL,

    INDEX idx_commentable (commentable_type, commentable_id)
);

-- Query comments for a post
SELECT * FROM comments
WHERE commentable_type = 'Post' AND commentable_id = 123;
```

### Time-Series Data Pattern

```sql
-- ✅ GOOD - Time-series table with partitioning
CREATE TABLE metrics (
    id BIGINT AUTO_INCREMENT,
    metric_name VARCHAR(100) NOT NULL,
    value DECIMAL(15, 4) NOT NULL,
    tags JSON,
    recorded_at TIMESTAMP NOT NULL,

    PRIMARY KEY (id, recorded_at),
    INDEX idx_metric_name (metric_name),
    INDEX idx_recorded_at (recorded_at)
)
PARTITION BY RANGE (UNIX_TIMESTAMP(recorded_at)) (
    PARTITION p202501 VALUES LESS THAN (UNIX_TIMESTAMP('2025-02-01')),
    PARTITION p202502 VALUES LESS THAN (UNIX_TIMESTAMP('2025-03-01')),
    PARTITION p202503 VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01')),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Benefits:
-- - Fast queries on time ranges
-- - Easy to drop old partitions
-- - Better compression
```

---

## 📝 SQL BEST PRACTICES

### Query Writing Guidelines

```sql
-- ✅ GOOD - Readable SQL formatting
SELECT
    u.id,
    u.name,
    u.email,
    COUNT(DISTINCT p.id) AS post_count,
    COUNT(DISTINCT c.id) AS comment_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id AND p.status = 'published'
LEFT JOIN comments c ON u.id = c.user_id
WHERE u.created_at >= '2025-01-01'
    AND u.is_active = TRUE
GROUP BY u.id, u.name, u.email
HAVING post_count > 0
ORDER BY post_count DESC, u.name ASC
LIMIT 10;

-- ❌ BAD - Hard to read
SELECT u.id,u.name,u.email,COUNT(DISTINCT p.id) AS post_count FROM users u LEFT JOIN posts p ON u.id=p.user_id WHERE u.created_at>='2025-01-01' GROUP BY u.id ORDER BY post_count DESC LIMIT 10;
```

### Parameterized Queries

```javascript
// ✅ GOOD - Prevent SQL injection
// Node.js with MySQL
const userId = req.params.id;
const query = 'SELECT * FROM users WHERE id = ?';
const results = await db.query(query, [userId]);

// ❌ BAD - SQL injection vulnerability
const query = `SELECT * FROM users WHERE id = ${userId}`;
```

### Bulk Operations

```sql
-- ❌ BAD - Multiple single inserts
INSERT INTO users (name, email) VALUES ('John', 'john@example.com');
INSERT INTO users (name, email) VALUES ('Jane', 'jane@example.com');
-- ... hundreds more

-- ✅ GOOD - Bulk insert
INSERT INTO users (name, email) VALUES
    ('John', 'john@example.com'),
    ('Jane', 'jane@example.com'),
    ('Bob', 'bob@example.com');
    -- ... up to 1000 rows at once

-- ✅ GOOD - Bulk update
UPDATE users
SET status = 'active'
WHERE id IN (1, 2, 3, 4, 5);
```

---

## 🗄️ NOSQL DESIGN PATTERNS

### MongoDB Schema Design

```javascript
// ✅ GOOD - Embedded documents (One-to-Few)
{
    _id: ObjectId("..."),
    name: "John Doe",
    email: "john@example.com",
    addresses: [  // Embed if few items
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

// ✅ GOOD - References (One-to-Many, Many-to-Many)
// User document
{
    _id: ObjectId("user123"),
    name: "John Doe",
    email: "john@example.com"
}

// Post documents (separate collection)
{
    _id: ObjectId("post456"),
    user_id: ObjectId("user123"),  // Reference
    title: "My Post",
    content: "..."
}

// ✅ GOOD - Denormalization for reads
{
    _id: ObjectId("post456"),
    user_id: ObjectId("user123"),
    user_name: "John Doe",  // Denormalized
    title: "My Post",
    comment_count: 42,  // Denormalized
    last_comment_at: ISODate("2025-11-01")
}
```

### Redis Patterns

```javascript
// ✅ GOOD - Redis key patterns

// String
await redis.set('user:123:name', 'John Doe');

// Hash (object)
await redis.hset('user:123', {
    name: 'John Doe',
    email: 'john@example.com',
    age: 30
});

// List (array)
await redis.lpush('user:123:notifications', 'New message');

// Set (unique items)
await redis.sadd('user:123:tags', 'developer', 'nodejs');

// Sorted Set (leaderboard)
await redis.zadd('leaderboard', 1000, 'user:123');

// Expiration
await redis.setex('session:abc123', 3600, 'session_data');  // 1 hour
```

---

## 🎯 BEST PRACTICES SUMMARY

### ✅ DO

- ✅ Normalize to 3NF by default
- ✅ Use appropriate data types
- ✅ Create indexes on foreign keys
- ✅ Use transactions for data consistency
- ✅ Use parameterized queries
- ✅ Document your schema
- ✅ Plan for scalability
- ✅ Monitor query performance
- ✅ Regular backups
- ✅ Use migrations for schema changes

### ❌ DON'T

- ❌ Store files in database (use URLs)
- ❌ Use SELECT * in production
- ❌ Create indexes on everything
- ❌ Use reserved words as column names
- ❌ Store derived/calculated data (unless denormalizing)
- ❌ Use VARCHAR for large text
- ❌ Ignore query performance
- ❌ Commit huge transactions
- ❌ Store sensitive data in plain text

---

## 📚 REFERENCES

- [Database Design Principles](https://www.postgresql.org/docs/)
- [MySQL Performance Optimization](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [PostgreSQL Query Performance](https://www.postgresql.org/docs/current/performance-tips.html)
- [MongoDB Schema Design](https://www.mongodb.com/docs/manual/data-modeling/)
- [Use The Index, Luke](https://use-the-index-luke.com/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
