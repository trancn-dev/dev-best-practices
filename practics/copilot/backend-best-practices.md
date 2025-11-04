# Rule: Backend Best Practices

## Intent
Enforce backend development best practices covering API design, authentication, database operations, error handling, and system architecture.

## Scope
Applies to all backend code including REST APIs, GraphQL, authentication, database queries, and server-side logic.

---

## 1. API Development

### RESTful Design

- ✅ **MUST** use resource nouns (not verbs)
- ✅ **MUST** use proper HTTP methods
- ✅ **MUST** return appropriate status codes
- ✅ **MUST** version APIs (/api/v1/)

```javascript
// ✅ GOOD
GET    /api/v1/users
POST   /api/v1/users
PUT    /api/v1/users/:id
DELETE /api/v1/users/:id

// ❌ BAD
POST /api/getUsers
POST /api/createUser
```

### Request Validation

- ✅ **MUST** validate all input
- ✅ **MUST** sanitize user data
- ✅ **MUST** return detailed validation errors

```javascript
// ✅ GOOD - Express with validation
const { body, validationResult } = require('express-validator');

app.post('/api/users', [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }),
    body('age').optional().isInt({ min: 0, max: 150 })
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            errors: errors.array()
        });
    }

    const user = await User.create(req.body);
    res.status(201).json({ success: true, data: user });
});
```

### Response Format

```javascript
// ✅ GOOD - Consistent format
// Success
{
    "success": true,
    "data": { "id": 1, "name": "John" },
    "metadata": { "timestamp": "2025-11-01T10:00:00Z" }
}

// Error
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Invalid input",
        "details": [{ "field": "email", "message": "Invalid email" }]
    }
}
```

---

## 2. Authentication & Authorization

### JWT Best Practices

- ✅ **MUST** use short expiration (15 min access, 7 days refresh)
- ✅ **MUST** store secrets in environment variables
- ✅ **MUST** validate issuer, audience, algorithm
- ❌ **MUST NOT** store sensitive data in JWT

```javascript
// ✅ GOOD - Secure JWT
const jwt = require('jsonwebtoken');

function generateAccessToken(user) {
    return jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        {
            expiresIn: '15m',
            issuer: 'myapp',
            audience: 'myapp-api',
            algorithm: 'HS256'
        }
    );
}

function verifyToken(token) {
    return jwt.verify(token, process.env.JWT_SECRET, {
        algorithms: ['HS256'],
        issuer: 'myapp',
        audience: 'myapp-api'
    });
}
```

### Password Security

- ✅ **MUST** use bcrypt (cost factor ≥ 12)
- ✅ **MUST** enforce strong password policy
- ❌ **MUST NOT** store plain text passwords

```javascript
// ✅ GOOD
const bcrypt = require('bcrypt');

async function hashPassword(password) {
    // Validate strength
    if (password.length < 12) {
        throw new Error('Password must be at least 12 characters');
    }

    const saltRounds = 12;
    return await bcrypt.hash(password, saltRounds);
}

async function verifyPassword(password, hash) {
    return await bcrypt.compare(password, hash);
}
```

### Role-Based Access Control

```javascript
// ✅ GOOD - RBAC middleware
const PERMISSIONS = {
    'user:read': ['user', 'admin'],
    'user:write': ['admin'],
    'user:delete': ['admin']
};

function requirePermission(permission) {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized' });
        }

        if (!PERMISSIONS[permission]?.includes(req.user.role)) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        next();
    };
}

// Usage
app.delete('/api/users/:id',
    authenticate,
    requirePermission('user:delete'),
    deleteUser
);
```

---

## 3. Database Operations

### Query Optimization

- ✅ **MUST** use parameterized queries
- ✅ **MUST** avoid N+1 queries (use eager loading)
- ✅ **MUST** use pagination
- ❌ **MUST NOT** use SELECT *

```javascript
// ✅ GOOD - Optimized query
const users = await User.findAll({
    attributes: ['id', 'name', 'email'],
    include: [{
        model: Post,
        attributes: ['id', 'title']
    }],
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

### Transaction Management

- ✅ **MUST** use transactions for multi-step operations
- ✅ **MUST** rollback on error
- ✅ **MUST** keep transactions short

```javascript
// ✅ GOOD - Transaction
const sequelize = require('sequelize');

async function transferMoney(fromId, toId, amount) {
    const transaction = await sequelize.transaction();

    try {
        await Account.update(
            { balance: sequelize.literal(`balance - ${amount}`) },
            { where: { id: fromId }, transaction }
        );

        await Account.update(
            { balance: sequelize.literal(`balance + ${amount}`) },
            { where: { id: toId }, transaction }
        );

        await transaction.commit();
    } catch (error) {
        await transaction.rollback();
        throw error;
    }
}
```

---

## 4. Error Handling

### Global Error Handler

```javascript
// ✅ GOOD - Centralized error handling
class APIError extends Error {
    constructor(message, statusCode, code) {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
    }
}

app.use((err, req, res, next) => {
    // Log error
    logger.error('API Error', {
        error: err.message,
        stack: err.stack,
        url: req.url,
        userId: req.user?.id
    });

    // Handle known errors
    if (err instanceof APIError) {
        return res.status(err.statusCode).json({
            success: false,
            error: {
                code: err.code,
                message: err.message
            }
        });
    }

    // Handle unknown errors (don't leak details)
    res.status(500).json({
        success: false,
        error: {
            code: 'INTERNAL_ERROR',
            message: 'An unexpected error occurred'
        }
    });
});
```

### Async Error Handling

```javascript
// ✅ GOOD - Async wrapper
function asyncHandler(fn) {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
}

// Usage
app.get('/api/users', asyncHandler(async (req, res) => {
    const users = await User.findAll();
    res.json({ success: true, data: users });
}));
```

---

## 5. Caching

### Redis Caching

```javascript
// ✅ GOOD - Cache pattern
const redis = require('redis');
const client = redis.createClient();

async function getUser(userId) {
    const cacheKey = `user:${userId}`;

    // Try cache
    const cached = await client.get(cacheKey);
    if (cached) {
        return JSON.parse(cached);
    }

    // Cache miss - fetch from DB
    const user = await User.findById(userId);

    // Store in cache (1 hour TTL)
    await client.setex(cacheKey, 3600, JSON.stringify(user));

    return user;
}

// Invalidate on update
async function updateUser(userId, data) {
    await User.update(data, { where: { id: userId } });
    await client.del(`user:${userId}`);
}
```

### Cache Strategy

```javascript
// ✅ GOOD - Cache-aside pattern
async function getData(key) {
    // 1. Check cache
    const cached = await cache.get(key);
    if (cached) return cached;

    // 2. Fetch from database
    const data = await db.query(key);

    // 3. Store in cache
    await cache.set(key, data, 3600);

    return data;
}
```

---

## 6. Background Jobs

### Queue Processing

```javascript
// ✅ GOOD - Bull queue
const Queue = require('bull');

const emailQueue = new Queue('email', {
    redis: { host: 'localhost', port: 6379 }
});

// Add job
emailQueue.add({
    to: 'user@example.com',
    template: 'welcome',
    data: { name: 'John' }
}, {
    attempts: 3,
    backoff: { type: 'exponential', delay: 2000 }
});

// Process job
emailQueue.process(async (job) => {
    const { to, template, data } = job.data;
    await sendEmail(to, template, data);
});

// Handle failures
emailQueue.on('failed', (job, err) => {
    logger.error('Job failed', { jobId: job.id, error: err.message });
});
```

---

## 7. Rate Limiting

```javascript
// ✅ GOOD - Rate limiting
const rateLimit = require('express-rate-limit');

const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100                    // 100 requests per window
});

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    skipSuccessfulRequests: true
});

app.use('/api/', generalLimiter);
app.use('/api/auth/login', authLimiter);
```

---

## 8. Logging

### Structured Logging

```javascript
// ✅ GOOD - Winston logger
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
logger.info('User login', {
    userId: user.id,
    ip: req.ip,
    userAgent: req.get('user-agent')
});

logger.error('Database error', {
    error: err.message,
    stack: err.stack,
    query: query
});
```

---

## 9. File Upload

### Secure File Handling

```javascript
// ✅ GOOD - Multer with validation
const multer = require('multer');

const ALLOWED_TYPES = ['image/jpeg', 'image/png'];
const MAX_SIZE = 5 * 1024 * 1024;  // 5MB

const upload = multer({
    storage: multer.diskStorage({
        destination: './uploads/',
        filename: (req, file, cb) => {
            const randomName = crypto.randomBytes(16).toString('hex');
            cb(null, randomName + path.extname(file.originalname));
        }
    }),
    limits: { fileSize: MAX_SIZE },
    fileFilter: (req, file, cb) => {
        if (!ALLOWED_TYPES.includes(file.mimetype)) {
            return cb(new Error('Invalid file type'), false);
        }
        cb(null, true);
    }
});

app.post('/api/upload', upload.single('file'), async (req, res) => {
    // Verify actual file type
    const fileType = await FileType.fromFile(req.file.path);
    if (!ALLOWED_TYPES.includes(fileType.mime)) {
        fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid file' });
    }

    res.json({ filename: req.file.filename });
});
```

---

## 10. Copilot-Specific Instructions

### Code Generation Rules

When generating backend code, Copilot **MUST**:

1. **VALIDATE** all user input
2. **USE** parameterized queries
3. **IMPLEMENT** proper error handling
4. **ADD** authentication middleware
5. **INCLUDE** logging statements
6. **SUGGEST** caching for frequent queries
7. **IMPLEMENT** rate limiting for sensitive endpoints
8. **USE** transactions for multi-step operations

### Response Pattern

```markdown
✅ **API Endpoint Generated:**

\`\`\`javascript
const { body, validationResult } = require('express-validator');

app.post('/api/users', [
    body('email').isEmail(),
    body('password').isLength({ min: 8 })
], authenticate, asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    const hashedPassword = await bcrypt.hash(req.body.password, 12);
    const user = await User.create({
        email: req.body.email,
        password: hashedPassword
    });

    logger.info('User created', { userId: user.id });

    res.status(201).json({ success: true, data: user });
}));
\`\`\`

**Features:**
- ✅ Input validation
- ✅ Authentication required
- ✅ Password hashing
- ✅ Error handling
- ✅ Logging
- ✅ 201 Created status
```

---

## 11. Checklist

### API Development
- [ ] RESTful conventions followed
- [ ] Input validation implemented
- [ ] Proper status codes returned
- [ ] API versioned

### Security
- [ ] Authentication implemented
- [ ] Authorization checks in place
- [ ] Passwords hashed (bcrypt)
- [ ] Rate limiting configured
- [ ] Input sanitized

### Database
- [ ] Parameterized queries used
- [ ] No N+1 queries
- [ ] Transactions for multi-step ops
- [ ] Pagination implemented

### Performance
- [ ] Caching implemented (Redis)
- [ ] Connection pooling configured
- [ ] Background jobs for long tasks
- [ ] Queries optimized

### Observability
- [ ] Structured logging
- [ ] Error tracking
- [ ] Performance monitoring
- [ ] Health check endpoint

---

## References

- Node.js Best Practices - Goldbergyoni
- API Design Patterns - JJ Geewax
- Web Application Security - Andrew Hoffman

**Remember:** Backend is the backbone. Prioritize security, reliability, and performance.
