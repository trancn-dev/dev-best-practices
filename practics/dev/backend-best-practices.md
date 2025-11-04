# 🖥️ Backend Best Practices - Thực Hành Tốt Nhất Phát Triển Backend

> **Mục đích**: Hướng dẫn chi tiết về các best practices khi phát triển backend applications
>
> **Đối tượng**: Backend Developers, Full-stack Developers, System Architects
>
> **Cập nhật**: 2025-11-01

---

## 📋 MỤC LỤC

1. [API Design & Development](#1-api-design--development)
2. [Authentication & Authorization](#2-authentication--authorization)
3. [Database Operations](#3-database-operations)
4. [Error Handling & Logging](#4-error-handling--logging)
5. [Security Best Practices](#5-security-best-practices)
6. [Performance & Optimization](#6-performance--optimization)
7. [Caching Strategies](#7-caching-strategies)
8. [Background Jobs & Task Queues](#8-background-jobs--task-queues)
9. [File Upload & Storage](#9-file-upload--storage)
10. [Email & Notifications](#10-email--notifications)
11. [Rate Limiting & Throttling](#11-rate-limiting--throttling)
12. [Testing Backend APIs](#12-testing-backend-apis)
13. [Monitoring & Observability](#13-monitoring--observability)
14. [Configuration Management](#14-configuration-management)
15. [Code Organization](#15-code-organization)

---

## 1. API Design & Development

### 1.1 RESTful API Design

#### ✅ **DO: Follow REST Conventions**

```javascript
// Good: RESTful endpoints
GET    /api/v1/users           // Get all users
GET    /api/v1/users/:id       // Get user by ID
POST   /api/v1/users           // Create new user
PUT    /api/v1/users/:id       // Update user (full)
PATCH  /api/v1/users/:id       // Update user (partial)
DELETE /api/v1/users/:id       // Delete user

// Nested resources
GET    /api/v1/users/:id/posts        // Get user's posts
POST   /api/v1/users/:id/posts        // Create post for user
GET    /api/v1/users/:id/posts/:postId // Get specific post
```

#### ❌ **DON'T: Use Non-RESTful Endpoints**

```javascript
// Bad: RPC-style endpoints
POST /api/getUserById
POST /api/createNewUser
POST /api/updateUserInfo
POST /api/deleteUser
```

### 1.2 Request/Response Format

#### ✅ **DO: Consistent Response Structure**

```javascript
// Success Response
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  },
  "metadata": {
    "timestamp": "2025-11-01T10:30:00Z",
    "version": "v1"
  }
}

// List Response with Pagination
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}

// Error Response
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address"
      }
    ]
  },
  "metadata": {
    "timestamp": "2025-11-01T10:30:00Z",
    "requestId": "abc-123-def"
  }
}
```

### 1.3 HTTP Status Codes

```javascript
// Success Codes
200 OK              // GET, PUT, PATCH successful
201 Created         // POST successful
204 No Content      // DELETE successful

// Client Error Codes
400 Bad Request     // Invalid request data
401 Unauthorized    // Authentication required
403 Forbidden       // Insufficient permissions
404 Not Found       // Resource not found
409 Conflict        // Duplicate resource
422 Unprocessable   // Validation error
429 Too Many Requests // Rate limit exceeded

// Server Error Codes
500 Internal Server Error
502 Bad Gateway
503 Service Unavailable
504 Gateway Timeout
```

### 1.4 API Versioning

```javascript
// Option 1: URL Versioning (Recommended)
app.use('/api/v1', v1Routes);
app.use('/api/v2', v2Routes);

// Option 2: Header Versioning
app.use((req, res, next) => {
  const version = req.headers['api-version'] || 'v1';
  req.apiVersion = version;
  next();
});

// Option 3: Query Parameter
// /api/users?version=2
```

---

## 2. Authentication & Authorization

### 2.1 JWT Authentication

#### ✅ **DO: Secure JWT Implementation**

```javascript
// Good: Secure JWT configuration
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

// Token Generation
function generateTokens(user) {
  const accessToken = jwt.sign(
    {
      userId: user.id,
      email: user.email,
      role: user.role
    },
    process.env.JWT_SECRET,
    {
      expiresIn: '15m',
      issuer: 'your-app-name',
      audience: 'your-app-users'
    }
  );

  const refreshToken = jwt.sign(
    { userId: user.id },
    process.env.REFRESH_TOKEN_SECRET,
    { expiresIn: '7d' }
  );

  return { accessToken, refreshToken };
}

// Token Verification Middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({
      success: false,
      error: { message: 'Access token required' }
    });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({
        success: false,
        error: { message: 'Invalid or expired token' }
      });
    }
    req.user = user;
    next();
  });
}
```

#### ❌ **DON'T: Weak JWT Practices**

```javascript
// Bad: Weak secret
const token = jwt.sign(data, 'secret123'); // Too simple

// Bad: No expiration
const token = jwt.sign(data, secret); // Never expires

// Bad: Storing sensitive data
const token = jwt.sign({
  userId: user.id,
  password: user.password, // Don't store passwords!
  creditCard: user.card    // Don't store sensitive data!
}, secret);
```

### 2.2 Password Handling

```javascript
// Good: Secure password hashing
const bcrypt = require('bcrypt');

async function hashPassword(password) {
  const saltRounds = 12;
  return await bcrypt.hash(password, saltRounds);
}

async function verifyPassword(password, hash) {
  return await bcrypt.compare(password, hash);
}

// User Registration
async function registerUser(userData) {
  // Validate password strength
  if (!isStrongPassword(userData.password)) {
    throw new Error('Password must be at least 8 characters with uppercase, lowercase, number and special character');
  }

  const hashedPassword = await hashPassword(userData.password);

  const user = await User.create({
    ...userData,
    password: hashedPassword
  });

  // Don't return password in response
  const { password, ...userWithoutPassword } = user.toJSON();
  return userWithoutPassword;
}
```

### 2.3 Role-Based Access Control (RBAC)

```javascript
// Define roles and permissions
const ROLES = {
  ADMIN: 'admin',
  USER: 'user',
  MODERATOR: 'moderator'
};

const PERMISSIONS = {
  READ_USERS: 'read:users',
  WRITE_USERS: 'write:users',
  DELETE_USERS: 'delete:users',
  READ_POSTS: 'read:posts',
  WRITE_POSTS: 'write:posts'
};

// Role permissions mapping
const rolePermissions = {
  [ROLES.ADMIN]: Object.values(PERMISSIONS),
  [ROLES.MODERATOR]: [
    PERMISSIONS.READ_USERS,
    PERMISSIONS.READ_POSTS,
    PERMISSIONS.WRITE_POSTS
  ],
  [ROLES.USER]: [
    PERMISSIONS.READ_POSTS,
    PERMISSIONS.WRITE_POSTS
  ]
};

// Authorization Middleware
function authorize(...requiredPermissions) {
  return (req, res, next) => {
    const userRole = req.user.role;
    const userPermissions = rolePermissions[userRole] || [];

    const hasPermission = requiredPermissions.every(
      permission => userPermissions.includes(permission)
    );

    if (!hasPermission) {
      return res.status(403).json({
        success: false,
        error: { message: 'Insufficient permissions' }
      });
    }

    next();
  };
}

// Usage
router.delete('/users/:id',
  authenticateToken,
  authorize(PERMISSIONS.DELETE_USERS),
  deleteUser
);
```

### 2.4 Session Management

```javascript
// Good: Secure session configuration
const session = require('express-session');
const RedisStore = require('connect-redis')(session);
const redis = require('redis');

const redisClient = redis.createClient({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT
});

app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production', // HTTPS only in production
    httpOnly: true,  // Prevent XSS
    maxAge: 1000 * 60 * 60 * 24, // 24 hours
    sameSite: 'strict' // CSRF protection
  }
}));
```

---

## 3. Database Operations

### 3.1 Query Optimization

#### ✅ **DO: Efficient Queries**

```javascript
// Good: Use indexes and select only needed fields
const users = await User.find(
  { status: 'active', role: 'user' },
  'id name email createdAt' // Only select needed fields
)
  .limit(100)
  .lean(); // Return plain objects instead of Mongoose documents

// Good: Use pagination
async function getUsers(page = 1, limit = 20) {
  const skip = (page - 1) * limit;

  const [users, total] = await Promise.all([
    User.find()
      .skip(skip)
      .limit(limit)
      .lean(),
    User.countDocuments()
  ]);

  return {
    data: users,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit)
    }
  };
}

// Good: Use database-level aggregation
const stats = await Order.aggregate([
  { $match: { status: 'completed' } },
  { $group: {
    _id: '$userId',
    totalOrders: { $sum: 1 },
    totalAmount: { $sum: '$amount' }
  }},
  { $sort: { totalAmount: -1 } },
  { $limit: 10 }
]);
```

#### ❌ **DON'T: Inefficient Queries**

```javascript
// Bad: N+1 queries
const users = await User.find();
for (const user of users) {
  // Bad: Separate query for each user
  user.posts = await Post.find({ userId: user.id });
}

// Good: Use joins/population
const users = await User.find().populate('posts');

// Bad: Fetch all then filter in memory
const allUsers = await User.find(); // Get ALL users
const activeUsers = allUsers.filter(u => u.status === 'active');

// Good: Filter at database level
const activeUsers = await User.find({ status: 'active' });
```

### 3.2 Transactions

```javascript
// Good: Use transactions for multiple related operations
const mongoose = require('mongoose');

async function transferMoney(fromUserId, toUserId, amount) {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Deduct from sender
    const sender = await User.findByIdAndUpdate(
      fromUserId,
      { $inc: { balance: -amount } },
      { session, new: true }
    );

    if (sender.balance < 0) {
      throw new Error('Insufficient balance');
    }

    // Add to receiver
    await User.findByIdAndUpdate(
      toUserId,
      { $inc: { balance: amount } },
      { session }
    );

    // Create transaction record
    await Transaction.create([{
      from: fromUserId,
      to: toUserId,
      amount,
      timestamp: new Date()
    }], { session });

    await session.commitTransaction();
    return { success: true };
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
}
```

### 3.3 Connection Pooling

```javascript
// Good: Configure connection pool
const mongoose = require('mongoose');

mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  maxPoolSize: 10,        // Maximum connections
  minPoolSize: 2,         // Minimum connections
  socketTimeoutMS: 45000,
  serverSelectionTimeoutMS: 5000,
  family: 4
});

// Monitor connection
mongoose.connection.on('connected', () => {
  console.log('MongoDB connected');
});

mongoose.connection.on('error', (err) => {
  console.error('MongoDB connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('MongoDB disconnected');
});
```

---

## 4. Error Handling & Logging

### 4.1 Centralized Error Handling

```javascript
// Error Classes
class AppError extends Error {
  constructor(message, statusCode, code) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message, details) {
    super(message, 422, 'VALIDATION_ERROR');
    this.details = details;
  }
}

class NotFoundError extends AppError {
  constructor(resource) {
    super(`${resource} not found`, 404, 'NOT_FOUND');
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

// Global Error Handler Middleware
function errorHandler(err, req, res, next) {
  // Log error
  logger.error({
    message: err.message,
    stack: err.stack,
    requestId: req.id,
    url: req.url,
    method: req.method,
    userId: req.user?.id
  });

  // Operational errors (expected)
  if (err.isOperational) {
    return res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
        details: err.details || undefined
      },
      metadata: {
        requestId: req.id,
        timestamp: new Date().toISOString()
      }
    });
  }

  // Programming errors (unexpected)
  console.error('UNEXPECTED ERROR:', err);

  return res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: process.env.NODE_ENV === 'production'
        ? 'An unexpected error occurred'
        : err.message
    },
    metadata: {
      requestId: req.id,
      timestamp: new Date().toISOString()
    }
  });
}

// Usage in controllers
async function getUser(req, res, next) {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      throw new NotFoundError('User');
    }

    res.json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
}
```

### 4.2 Async Error Handling

```javascript
// Async wrapper to catch errors
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

// Usage
router.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id);
  if (!user) {
    throw new NotFoundError('User');
  }
  res.json({ success: true, data: user });
}));

// Or use express-async-errors
require('express-async-errors');

// Now you can use async/await without try-catch
router.get('/users/:id', async (req, res) => {
  const user = await User.findById(req.params.id);
  if (!user) {
    throw new NotFoundError('User');
  }
  res.json({ success: true, data: user });
});
```

### 4.3 Structured Logging

```javascript
// Good: Use structured logging with Winston
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'user-service',
    environment: process.env.NODE_ENV
  },
  transports: [
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error'
    }),
    new winston.transports.File({
      filename: 'logs/combined.log'
    })
  ]
});

// Console logging in development
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }));
}

// Usage
logger.info('User logged in', {
  userId: user.id,
  email: user.email,
  ip: req.ip
});

logger.error('Payment failed', {
  userId: user.id,
  orderId: order.id,
  error: error.message,
  stack: error.stack
});

// Request logging middleware
function requestLogger(req, res, next) {
  const startTime = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - startTime;

    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip,
      userAgent: req.get('user-agent'),
      userId: req.user?.id
    });
  });

  next();
}
```

---

## 5. Security Best Practices

### 5.1 Input Validation & Sanitization

```javascript
// Good: Use validation library
const Joi = require('joi');
const validator = require('validator');

// Define validation schema
const userSchema = Joi.object({
  name: Joi.string().min(2).max(50).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(8).pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/),
  age: Joi.number().integer().min(18).max(120),
  website: Joi.string().uri()
});

// Validation middleware
function validateRequest(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      const details = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));

      return res.status(422).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid request data',
          details
        }
      });
    }

    req.validatedData = value;
    next();
  };
}

// Sanitize input
const sanitizeHtml = require('sanitize-html');

function sanitizeInput(req, res, next) {
  // Sanitize strings to prevent XSS
  Object.keys(req.body).forEach(key => {
    if (typeof req.body[key] === 'string') {
      req.body[key] = sanitizeHtml(req.body[key], {
        allowedTags: [],
        allowedAttributes: {}
      });
    }
  });
  next();
}

// Usage
router.post('/users',
  sanitizeInput,
  validateRequest(userSchema),
  createUser
);
```

### 5.2 SQL Injection Prevention

```javascript
// Good: Use parameterized queries
const mysql = require('mysql2/promise');

// Bad: String concatenation
const userId = req.params.id;
const query = `SELECT * FROM users WHERE id = ${userId}`; // Vulnerable!

// Good: Parameterized query
const [users] = await connection.execute(
  'SELECT * FROM users WHERE id = ?',
  [userId]
);

// Good: Named parameters
const [users] = await connection.execute(
  'SELECT * FROM users WHERE email = :email AND status = :status',
  { email: userEmail, status: 'active' }
);

// For ORMs (Sequelize)
const users = await User.findAll({
  where: {
    email: userEmail,
    status: 'active'
  }
});
```

### 5.3 CORS Configuration

```javascript
// Good: Secure CORS configuration
const cors = require('cors');

const corsOptions = {
  origin: function (origin, callback) {
    const allowedOrigins = process.env.ALLOWED_ORIGINS.split(',');

    // Allow requests with no origin (mobile apps, Postman)
    if (!origin) return callback(null, true);

    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  exposedHeaders: ['X-Total-Count', 'X-Page-Number'],
  maxAge: 86400 // 24 hours
};

app.use(cors(corsOptions));
```

### 5.4 Security Headers

```javascript
// Good: Use helmet for security headers
const helmet = require('helmet');

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  noSniff: true,
  xssFilter: true,
  referrerPolicy: { policy: 'same-origin' }
}));
```

### 5.5 Rate Limiting

```javascript
// Good: Implement rate limiting
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const redis = require('redis');

const redisClient = redis.createClient({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT
});

// General rate limiter
const generalLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:general:'
  }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

// Strict limiter for authentication
const authLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:auth:'
  }),
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 attempts per 15 minutes
  skipSuccessfulRequests: true,
  message: 'Too many login attempts, please try again later.'
});

app.use('/api/', generalLimiter);
app.use('/api/auth/', authLimiter);
```

---

## 6. Performance & Optimization

### 6.1 Database Query Optimization

```javascript
// Good: Use indexes
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, index: true },
  username: { type: String, required: true, index: true },
  status: { type: String, index: true },
  createdAt: { type: Date, default: Date.now, index: true }
});

// Compound index for common queries
userSchema.index({ status: 1, createdAt: -1 });

// Good: Use lean() for read-only queries
const users = await User.find({ status: 'active' })
  .lean()  // Returns plain JS objects (faster)
  .select('name email')
  .limit(100);

// Good: Use projection to limit fields
const user = await User.findById(userId)
  .select('name email profile')
  .lean();
```

### 6.2 Response Compression

```javascript
// Good: Enable compression
const compression = require('compression');

app.use(compression({
  level: 6,  // Compression level (0-9)
  threshold: 1024,  // Only compress responses > 1KB
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  }
}));
```

### 6.3 Database Connection Pooling

```javascript
// Good: Configure connection pool
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,                    // Maximum connections
  min: 5,                     // Minimum connections
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 2000
});

// Use pool for queries
async function getUser(userId) {
  const client = await pool.connect();
  try {
    const result = await client.query(
      'SELECT * FROM users WHERE id = $1',
      [userId]
    );
    return result.rows[0];
  } finally {
    client.release();
  }
}
```

---

## 7. Caching Strategies

### 7.1 Redis Caching

```javascript
// Good: Implement caching layer
const redis = require('redis');
const client = redis.createClient({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT
});

// Cache middleware
function cacheMiddleware(duration = 300) {
  return async (req, res, next) => {
    const key = `cache:${req.originalUrl}`;

    try {
      const cachedData = await client.get(key);

      if (cachedData) {
        return res.json({
          success: true,
          data: JSON.parse(cachedData),
          cached: true
        });
      }

      // Store original res.json
      const originalJson = res.json.bind(res);

      // Override res.json
      res.json = (data) => {
        // Cache the response
        client.setex(key, duration, JSON.stringify(data));
        return originalJson(data);
      };

      next();
    } catch (error) {
      console.error('Cache error:', error);
      next();
    }
  };
}

// Usage
router.get('/products', cacheMiddleware(600), getProducts);

// Cache invalidation
async function updateProduct(req, res) {
  const product = await Product.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true }
  );

  // Invalidate cache
  await client.del(`cache:/api/products`);
  await client.del(`cache:/api/products/${product.id}`);

  res.json({ success: true, data: product });
}
```

### 7.2 In-Memory Caching

```javascript
// Good: Use node-cache for simple caching
const NodeCache = require('node-cache');
const cache = new NodeCache({
  stdTTL: 600,  // Default TTL: 10 minutes
  checkperiod: 120  // Check for expired keys every 2 minutes
});

async function getUserWithCache(userId) {
  const cacheKey = `user:${userId}`;

  // Try to get from cache
  let user = cache.get(cacheKey);

  if (user) {
    return user;
  }

  // Fetch from database
  user = await User.findById(userId).lean();

  // Store in cache
  cache.set(cacheKey, user, 300); // 5 minutes

  return user;
}
```

---

## 8. Background Jobs & Task Queues

### 8.1 Bull Queue Implementation

```javascript
// Good: Use Bull for background jobs
const Queue = require('bull');
const emailQueue = new Queue('email', {
  redis: {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
  }
});

// Define job processor
emailQueue.process(async (job) => {
  const { to, subject, body } = job.data;

  try {
    await sendEmail(to, subject, body);
    return { success: true };
  } catch (error) {
    console.error('Email job failed:', error);
    throw error;
  }
});

// Add job to queue
async function sendWelcomeEmail(user) {
  await emailQueue.add(
    {
      to: user.email,
      subject: 'Welcome!',
      body: `Welcome ${user.name}!`
    },
    {
      attempts: 3,  // Retry 3 times
      backoff: {
        type: 'exponential',
        delay: 5000
      },
      removeOnComplete: true,
      removeOnFail: false
    }
  );
}

// Monitor queue
emailQueue.on('completed', (job, result) => {
  console.log(`Job ${job.id} completed`);
});

emailQueue.on('failed', (job, err) => {
  console.error(`Job ${job.id} failed:`, err);
});
```

### 8.2 Scheduled Jobs

```javascript
// Good: Use node-cron for scheduled tasks
const cron = require('node-cron');

// Run cleanup every day at midnight
cron.schedule('0 0 * * *', async () => {
  console.log('Running daily cleanup...');

  try {
    // Delete old logs
    await Log.deleteMany({
      createdAt: { $lt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
    });

    // Clean temporary files
    await cleanTempFiles();

    console.log('Cleanup completed');
  } catch (error) {
    console.error('Cleanup failed:', error);
  }
});

// Send weekly reports every Monday at 9 AM
cron.schedule('0 9 * * 1', async () => {
  await sendWeeklyReports();
});
```

---

## 9. File Upload & Storage

### 9.1 File Upload with Multer

```javascript
// Good: Secure file upload configuration
const multer = require('multer');
const path = require('path');
const crypto = require('crypto');

// Storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueName = crypto.randomBytes(16).toString('hex');
    const ext = path.extname(file.originalname);
    cb(null, `${uniqueName}${ext}`);
  }
});

// File filter
const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPEG, PNG and GIF allowed.'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max
    files: 5  // Maximum 5 files
  }
});

// Upload routes
router.post('/upload/single',
  authenticateToken,
  upload.single('image'),
  async (req, res) => {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: { message: 'No file uploaded' }
      });
    }

    res.json({
      success: true,
      data: {
        filename: req.file.filename,
        path: `/uploads/${req.file.filename}`,
        size: req.file.size
      }
    });
  }
);

router.post('/upload/multiple',
  authenticateToken,
  upload.array('images', 5),
  async (req, res) => {
    const files = req.files.map(file => ({
      filename: file.filename,
      path: `/uploads/${file.filename}`,
      size: file.size
    }));

    res.json({ success: true, data: files });
  }
);
```

### 9.2 Cloud Storage (AWS S3)

```javascript
// Good: Upload to S3
const AWS = require('aws-sdk');
const multer = require('multer');
const multerS3 = require('multer-s3');

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY,
  secretAccessKey: process.env.AWS_SECRET_KEY,
  region: process.env.AWS_REGION
});

const uploadS3 = multer({
  storage: multerS3({
    s3: s3,
    bucket: process.env.S3_BUCKET,
    acl: 'public-read',
    metadata: (req, file, cb) => {
      cb(null, { fieldName: file.fieldname });
    },
    key: (req, file, cb) => {
      const uniqueName = `${Date.now()}-${crypto.randomBytes(8).toString('hex')}`;
      const ext = path.extname(file.originalname);
      cb(null, `uploads/${uniqueName}${ext}`);
    }
  }),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error('Only images are allowed'));
  }
});

// Delete from S3
async function deleteFileFromS3(fileKey) {
  const params = {
    Bucket: process.env.S3_BUCKET,
    Key: fileKey
  };

  try {
    await s3.deleteObject(params).promise();
    console.log(`File deleted: ${fileKey}`);
  } catch (error) {
    console.error('S3 delete error:', error);
    throw error;
  }
}
```

---

## 10. Email & Notifications

### 10.1 Email Service

```javascript
// Good: Email service with templates
const nodemailer = require('nodemailer');
const handlebars = require('handlebars');
const fs = require('fs').promises;
const path = require('path');

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT,
      secure: true,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      }
    });
  }

  async sendEmail({ to, subject, template, data }) {
    try {
      // Load template
      const templatePath = path.join(__dirname, 'templates', `${template}.hbs`);
      const templateContent = await fs.readFile(templatePath, 'utf-8');

      // Compile template
      const compiledTemplate = handlebars.compile(templateContent);
      const html = compiledTemplate(data);

      // Send email
      const info = await this.transporter.sendMail({
        from: `"${process.env.APP_NAME}" <${process.env.SMTP_FROM}>`,
        to,
        subject,
        html
      });

      logger.info('Email sent', {
        messageId: info.messageId,
        to,
        subject
      });

      return { success: true, messageId: info.messageId };
    } catch (error) {
      logger.error('Email sending failed', {
        error: error.message,
        to,
        subject
      });
      throw error;
    }
  }

  async sendWelcomeEmail(user) {
    return this.sendEmail({
      to: user.email,
      subject: 'Welcome to Our Platform!',
      template: 'welcome',
      data: {
        name: user.name,
        verificationLink: `${process.env.APP_URL}/verify/${user.verificationToken}`
      }
    });
  }

  async sendPasswordResetEmail(user, resetToken) {
    return this.sendEmail({
      to: user.email,
      subject: 'Password Reset Request',
      template: 'password-reset',
      data: {
        name: user.name,
        resetLink: `${process.env.APP_URL}/reset-password/${resetToken}`,
        expiresIn: '1 hour'
      }
    });
  }
}

module.exports = new EmailService();
```

### 10.2 Push Notifications

```javascript
// Good: Firebase Cloud Messaging
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
  })
});

async function sendPushNotification(deviceToken, notification) {
  const message = {
    notification: {
      title: notification.title,
      body: notification.body
    },
    data: notification.data || {},
    token: deviceToken
  };

  try {
    const response = await admin.messaging().send(message);
    logger.info('Push notification sent', { messageId: response });
    return { success: true, messageId: response };
  } catch (error) {
    logger.error('Push notification failed', { error: error.message });
    throw error;
  }
}

// Send to multiple devices
async function sendToMultipleDevices(deviceTokens, notification) {
  const message = {
    notification: {
      title: notification.title,
      body: notification.body
    },
    data: notification.data || {},
    tokens: deviceTokens
  };

  try {
    const response = await admin.messaging().sendMulticast(message);
    logger.info('Multicast notification sent', {
      successCount: response.successCount,
      failureCount: response.failureCount
    });
    return response;
  } catch (error) {
    logger.error('Multicast notification failed', { error: error.message });
    throw error;
  }
}
```

---

## 11. Rate Limiting & Throttling

### 11.1 Advanced Rate Limiting

```javascript
// Good: Custom rate limiter with different limits per endpoint
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

// Create rate limiter factory
function createRateLimiter(options) {
  return rateLimit({
    store: new RedisStore({
      client: redisClient,
      prefix: `rl:${options.name}:`
    }),
    windowMs: options.windowMs,
    max: options.max,
    message: options.message || 'Too many requests',
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => {
      // Skip rate limiting for admin users
      return req.user?.role === 'admin';
    },
    keyGenerator: (req) => {
      // Use user ID if authenticated, otherwise IP
      return req.user?.id || req.ip;
    }
  });
}

// Different limits for different endpoints
const apiLimiter = createRateLimiter({
  name: 'api',
  windowMs: 15 * 60 * 1000,
  max: 100
});

const authLimiter = createRateLimiter({
  name: 'auth',
  windowMs: 15 * 60 * 1000,
  max: 5
});

const uploadLimiter = createRateLimiter({
  name: 'upload',
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: 'Too many uploads, please try again later'
});

// Apply limiters
app.use('/api/', apiLimiter);
app.use('/api/auth/login', authLimiter);
app.use('/api/upload', uploadLimiter);
```

### 11.2 Request Throttling

```javascript
// Good: Implement request throttling
const { RateLimiterRedis } = require('rate-limiter-flexible');

const rateLimiter = new RateLimiterRedis({
  storeClient: redisClient,
  keyPrefix: 'throttle',
  points: 10, // Number of points
  duration: 1, // Per second
  blockDuration: 60 // Block for 60 seconds if exceeded
});

async function throttleMiddleware(req, res, next) {
  try {
    await rateLimiter.consume(req.ip);
    next();
  } catch (rejRes) {
    res.status(429).json({
      success: false,
      error: {
        message: 'Too many requests',
        retryAfter: Math.ceil(rejRes.msBeforeNext / 1000)
      }
    });
  }
}

app.use('/api/', throttleMiddleware);
```

---

## 12. Testing Backend APIs

### 12.1 Unit Tests

```javascript
// Good: Comprehensive unit tests
const request = require('supertest');
const app = require('../app');
const User = require('../models/User');
const jwt = require('jsonwebtoken');

describe('User API', () => {
  let authToken;
  let userId;

  beforeAll(async () => {
    // Setup test database
    await connectTestDB();
  });

  afterAll(async () => {
    // Cleanup
    await User.deleteMany({});
    await disconnectTestDB();
  });

  beforeEach(async () => {
    // Create test user
    const user = await User.create({
      name: 'Test User',
      email: 'test@example.com',
      password: 'Password123!'
    });
    userId = user.id;
    authToken = jwt.sign({ userId: user.id }, process.env.JWT_SECRET);
  });

  afterEach(async () => {
    await User.deleteMany({});
  });

  describe('GET /api/users/:id', () => {
    it('should return user when authenticated', async () => {
      const response = await request(app)
        .get(`/api/users/${userId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('name', 'Test User');
      expect(response.body.data).not.toHaveProperty('password');
    });

    it('should return 401 when not authenticated', async () => {
      const response = await request(app)
        .get(`/api/users/${userId}`)
        .expect(401);

      expect(response.body.success).toBe(false);
    });

    it('should return 404 when user not found', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const response = await request(app)
        .get(`/api/users/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('NOT_FOUND');
    });
  });

  describe('POST /api/users', () => {
    it('should create user with valid data', async () => {
      const userData = {
        name: 'New User',
        email: 'new@example.com',
        password: 'Password123!'
      };

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data.email).toBe(userData.email);
    });

    it('should return 422 with invalid email', async () => {
      const userData = {
        name: 'New User',
        email: 'invalid-email',
        password: 'Password123!'
      };

      const response = await request(app)
        .post('/api/users')
        .send(userData)
        .expect(422);

      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });
  });
});
```

### 12.2 Integration Tests

```javascript
// Good: Integration tests
describe('User Registration Flow', () => {
  it('should complete full registration process', async () => {
    // 1. Register user
    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Integration Test User',
        email: 'integration@example.com',
        password: 'Password123!'
      })
      .expect(201);

    expect(registerResponse.body.success).toBe(true);
    const { userId, verificationToken } = registerResponse.body.data;

    // 2. Verify email
    const verifyResponse = await request(app)
      .get(`/api/auth/verify/${verificationToken}`)
      .expect(200);

    expect(verifyResponse.body.success).toBe(true);

    // 3. Login
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'integration@example.com',
        password: 'Password123!'
      })
      .expect(200);

    expect(loginResponse.body.success).toBe(true);
    expect(loginResponse.body.data).toHaveProperty('accessToken');
    const { accessToken } = loginResponse.body.data;

    // 4. Access protected route
    const profileResponse = await request(app)
      .get('/api/users/profile')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(profileResponse.body.success).toBe(true);
    expect(profileResponse.body.data.email).toBe('integration@example.com');
  });
});
```

---

## 13. Monitoring & Observability

### 13.1 Health Check Endpoint

```javascript
// Good: Comprehensive health check
router.get('/health', async (req, res) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    services: {}
  };

  // Check database
  try {
    await mongoose.connection.db.admin().ping();
    health.services.database = { status: 'ok' };
  } catch (error) {
    health.status = 'degraded';
    health.services.database = {
      status: 'error',
      message: error.message
    };
  }

  // Check Redis
  try {
    await redisClient.ping();
    health.services.cache = { status: 'ok' };
  } catch (error) {
    health.status = 'degraded';
    health.services.cache = {
      status: 'error',
      message: error.message
    };
  }

  // Check external services
  try {
    await axios.get('https://api.external-service.com/health', {
      timeout: 5000
    });
    health.services.externalAPI = { status: 'ok' };
  } catch (error) {
    health.status = 'degraded';
    health.services.externalAPI = {
      status: 'error',
      message: error.message
    };
  }

  const statusCode = health.status === 'ok' ? 200 : 503;
  res.status(statusCode).json(health);
});
```

### 13.2 Metrics Collection

```javascript
// Good: Prometheus metrics
const promClient = require('prom-client');

// Create metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

// Middleware to collect metrics
function metricsMiddleware(req, res, next) {
  const start = Date.now();

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route?.path || req.path;

    httpRequestDuration
      .labels(req.method, route, res.statusCode)
      .observe(duration);

    httpRequestTotal
      .labels(req.method, route, res.statusCode)
      .inc();
  });

  next();
}

app.use(metricsMiddleware);

// Metrics endpoint
router.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});
```

---

## 14. Configuration Management

### 14.1 Environment Variables

```javascript
// Good: Structured configuration
require('dotenv').config();

const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000'),

  database: {
    url: process.env.DATABASE_URL,
    options: {
      maxPoolSize: parseInt(process.env.DB_POOL_SIZE || '10'),
      minPoolSize: parseInt(process.env.DB_POOL_MIN || '2')
    }
  },

  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
    password: process.env.REDIS_PASSWORD
  },

  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    refreshSecret: process.env.REFRESH_TOKEN_SECRET,
    refreshExpiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || '7d'
  },

  email: {
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587'),
    user: process.env.SMTP_USER,
    password: process.env.SMTP_PASSWORD,
    from: process.env.SMTP_FROM
  },

  aws: {
    accessKeyId: process.env.AWS_ACCESS_KEY,
    secretAccessKey: process.env.AWS_SECRET_KEY,
    region: process.env.AWS_REGION,
    s3Bucket: process.env.S3_BUCKET
  },

  security: {
    bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '12'),
    rateLimitWindow: parseInt(process.env.RATE_LIMIT_WINDOW || '900000'),
    rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX || '100')
  }
};

// Validate required configs
const required = [
  'DATABASE_URL',
  'JWT_SECRET',
  'REFRESH_TOKEN_SECRET'
];

required.forEach(key => {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
});

module.exports = config;
```

---

## 15. Code Organization

### 15.1 Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js
│   │   ├── redis.js
│   │   └── index.js
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── user.controller.js
│   │   └── product.controller.js
│   ├── middleware/
│   │   ├── auth.middleware.js
│   │   ├── validation.middleware.js
│   │   ├── error.middleware.js
│   │   └── logging.middleware.js
│   ├── models/
│   │   ├── User.model.js
│   │   ├── Product.model.js
│   │   └── Order.model.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── user.routes.js
│   │   └── index.js
│   ├── services/
│   │   ├── email.service.js
│   │   ├── auth.service.js
│   │   └── payment.service.js
│   ├── utils/
│   │   ├── logger.js
│   │   ├── validators.js
│   │   └── helpers.js
│   ├── jobs/
│   │   ├── email.job.js
│   │   └── cleanup.job.js
│   └── app.js
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── .env.example
├── .gitignore
├── package.json
└── server.js
```

### 15.2 Clean Architecture Example

```javascript
// controllers/user.controller.js
class UserController {
  constructor(userService) {
    this.userService = userService;
  }

  async getUser(req, res, next) {
    try {
      const user = await this.userService.getUserById(req.params.id);
      res.json({ success: true, data: user });
    } catch (error) {
      next(error);
    }
  }

  async createUser(req, res, next) {
    try {
      const user = await this.userService.createUser(req.validatedData);
      res.status(201).json({ success: true, data: user });
    } catch (error) {
      next(error);
    }
  }
}

// services/user.service.js
class UserService {
  constructor(userRepository, emailService) {
    this.userRepository = userRepository;
    this.emailService = emailService;
  }

  async getUserById(userId) {
    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new NotFoundError('User');
    }
    return user;
  }

  async createUser(userData) {
    // Hash password
    const hashedPassword = await hashPassword(userData.password);

    // Create user
    const user = await this.userRepository.create({
      ...userData,
      password: hashedPassword
    });

    // Send welcome email (async)
    this.emailService.sendWelcomeEmail(user).catch(err => {
      logger.error('Failed to send welcome email', { error: err });
    });

    return user;
  }
}

// repositories/user.repository.js
class UserRepository {
  constructor(model) {
    this.model = model;
  }

  async findById(userId) {
    return await this.model.findById(userId).lean();
  }

  async create(userData) {
    const user = new this.model(userData);
    return await user.save();
  }

  async update(userId, updates) {
    return await this.model.findByIdAndUpdate(
      userId,
      updates,
      { new: true }
    ).lean();
  }

  async delete(userId) {
    return await this.model.findByIdAndDelete(userId);
  }
}
```

---

## 📊 CHECKLIST

### ✅ **Before Deployment**

- [ ] All environment variables configured
- [ ] Database migrations completed
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] Health check endpoint working
- [ ] CORS properly configured
- [ ] SSL/TLS certificates installed
- [ ] Backup strategy in place
- [ ] Monitoring tools configured
- [ ] Load testing completed
- [ ] Documentation updated

### ✅ **Code Quality**

- [ ] Input validation on all endpoints
- [ ] Error handling in all controllers
- [ ] Consistent response format
- [ ] No sensitive data in responses
- [ ] Passwords properly hashed
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF protection
- [ ] Authentication implemented
- [ ] Authorization checked
- [ ] Tests written and passing
- [ ] Code reviewed

---

## 📚 REFERENCES

### Books
- **RESTful Web APIs** - Leonard Richardson
- **Building Microservices** - Sam Newman
- **Designing Data-Intensive Applications** - Martin Kleppmann
- **Node.js Design Patterns** - Mario Casciaro

### Documentation
- [Express.js Best Practices](https://expressjs.com/en/advanced/best-practice-performance.html)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [REST API Tutorial](https://restfulapi.net/)
- [OWASP API Security](https://owasp.org/www-project-api-security/)

### Tools
- **Postman** - API testing
- **Swagger/OpenAPI** - API documentation
- **Winston** - Logging
- **Joi** - Validation
- **Bull** - Job queues
- **Helmet** - Security headers

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
*Maintained by: Backend Development Team*

---

## 🎯 NEXT STEPS

1. Review your current backend code against these practices
2. Implement missing security measures
3. Add comprehensive error handling
4. Set up monitoring and logging
5. Write tests for critical endpoints
6. Document your APIs
7. Optimize database queries
8. Implement caching strategy

**Remember**: Backend is the backbone of your application. Prioritize security, performance, and reliability! 🚀
