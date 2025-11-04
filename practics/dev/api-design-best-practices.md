# API Design Best Practices - Thiết Kế API Chuẩn

> Hướng dẫn chi tiết về thiết kế RESTful API, GraphQL, và các best practices
>
> **Mục đích**: Tạo APIs dễ sử dụng, nhất quán, scalable và maintainable

---

## 📋 Mục Lục
- [RESTful API Design](#restful-api-design)
- [HTTP Methods & Status Codes](#http-methods--status-codes)
- [URL Structure & Naming](#url-structure--naming)
- [Request & Response Format](#request--response-format)
- [API Versioning](#api-versioning)
- [Authentication & Authorization](#authentication--authorization)
- [Error Handling](#error-handling)
- [Pagination & Filtering](#pagination--filtering)
- [Rate Limiting](#rate-limiting)
- [API Documentation](#api-documentation)
- [GraphQL Best Practices](#graphql-best-practices)

---

## 🎯 RESTFUL API DESIGN

### REST Principles

1. **Client-Server**: Separation of concerns
2. **Stateless**: Each request contains all information needed
3. **Cacheable**: Responses must define themselves as cacheable or not
4. **Uniform Interface**: Consistent API structure
5. **Layered System**: Client doesn't know if connected directly to server
6. **Code on Demand** (optional): Server can extend client functionality

### Resource-Oriented Design

```
✅ GOOD - Resources as nouns
GET    /api/users              # Get all users
GET    /api/users/{id}         # Get specific user
POST   /api/users              # Create user
PUT    /api/users/{id}         # Update user (full)
PATCH  /api/users/{id}         # Update user (partial)
DELETE /api/users/{id}         # Delete user

GET    /api/users/{id}/posts   # Get user's posts
GET    /api/posts/{id}/comments # Get post's comments

❌ BAD - Actions as verbs
GET    /api/getUsers
POST   /api/createUser
POST   /api/updateUser
POST   /api/deleteUser
GET    /api/getUserPosts
```

---

## 🔧 HTTP METHODS & STATUS CODES

### HTTP Methods

```javascript
// GET - Retrieve resources (Safe & Idempotent)
GET /api/users
GET /api/users/123

// POST - Create new resource (Not Idempotent)
POST /api/users
Body: { "name": "John", "email": "john@example.com" }

// PUT - Replace entire resource (Idempotent)
PUT /api/users/123
Body: { "name": "John Doe", "email": "john@example.com", "age": 30 }

// PATCH - Partial update (Not Idempotent)
PATCH /api/users/123
Body: { "email": "newemail@example.com" }

// DELETE - Remove resource (Idempotent)
DELETE /api/users/123

// HEAD - Get headers only (like GET but no body)
HEAD /api/users/123

// OPTIONS - Get available methods
OPTIONS /api/users
```

### HTTP Status Codes

```javascript
// ✅ 2xx Success
200 OK                    // GET, PUT, PATCH successful
201 Created               // POST successful
202 Accepted              // Request accepted for processing
204 No Content            // DELETE successful (no response body)

// ✅ 3xx Redirection
301 Moved Permanently     // Resource moved
304 Not Modified          // Cached version is still valid

// ❌ 4xx Client Errors
400 Bad Request           // Invalid syntax, validation error
401 Unauthorized          // Authentication required
403 Forbidden             // Authenticated but no permission
404 Not Found             // Resource doesn't exist
405 Method Not Allowed    // HTTP method not supported
409 Conflict              // Conflict with current state (e.g., duplicate)
422 Unprocessable Entity  // Validation error
429 Too Many Requests     // Rate limit exceeded

// ❌ 5xx Server Errors
500 Internal Server Error // Generic server error
502 Bad Gateway           // Invalid response from upstream
503 Service Unavailable   // Server temporarily unavailable
504 Gateway Timeout       // Upstream server timeout
```

### Implementation Example

```typescript
// ✅ GOOD - Proper status codes
import { Router, Request, Response } from 'express';

const router = Router();

// GET - 200 OK or 404 Not Found
router.get('/users/:id', async (req: Request, res: Response) => {
    const user = await User.findById(req.params.id);

    if (!user) {
        return res.status(404).json({
            error: 'User not found',
            code: 'USER_NOT_FOUND'
        });
    }

    res.status(200).json(user);
});

// POST - 201 Created or 400 Bad Request
router.post('/users', async (req: Request, res: Response) => {
    try {
        const user = await User.create(req.body);

        res.status(201)
            .location(`/api/users/${user.id}`)
            .json(user);
    } catch (error) {
        if (error.name === 'ValidationError') {
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details
            });
        }
        throw error;
    }
});

// PUT - 200 OK or 404 Not Found
router.put('/users/:id', async (req: Request, res: Response) => {
    const user = await User.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true, runValidators: true }
    );

    if (!user) {
        return res.status(404).json({
            error: 'User not found'
        });
    }

    res.status(200).json(user);
});

// DELETE - 204 No Content or 404 Not Found
router.delete('/users/:id', async (req: Request, res: Response) => {
    const user = await User.findByIdAndDelete(req.params.id);

    if (!user) {
        return res.status(404).json({
            error: 'User not found'
        });
    }

    res.status(204).send();
});
```

---

## 🏷️ URL STRUCTURE & NAMING

### URL Conventions

```bash
# ✅ GOOD
/api/users                      # Collection
/api/users/123                  # Specific resource
/api/users/123/posts            # Nested resource
/api/users/123/posts/456        # Nested specific resource

# Use plural nouns
/api/products
/api/categories
/api/orders

# Use kebab-case for multi-word resources
/api/order-items
/api/user-profiles
/api/payment-methods

# Use query parameters for filtering, sorting, pagination
/api/products?category=electronics&sort=price&page=2

# ❌ BAD
/api/user                       # Singular
/api/getUser                    # Verb in URL
/api/users/getById/123          # Verb in path
/api/users_posts                # Underscore
/api/UserProfiles               # PascalCase
```

### Query Parameters

```javascript
// ✅ GOOD - Query parameters for non-resource operations

// Filtering
GET /api/products?category=electronics&brand=apple

// Sorting
GET /api/products?sort=price          // Ascending
GET /api/products?sort=-price         // Descending (- prefix)
GET /api/products?sort=price,-rating  // Multiple fields

// Pagination
GET /api/products?page=2&limit=20
GET /api/products?offset=20&limit=20

// Searching
GET /api/products?search=laptop&fields=name,description

// Field selection (sparse fieldsets)
GET /api/users?fields=id,name,email

// Including related resources
GET /api/posts?include=author,comments

// Date ranges
GET /api/orders?startDate=2025-01-01&endDate=2025-12-31
```

### Implementation

```typescript
// ✅ GOOD - Query parameter handling
interface QueryParams {
    page?: number;
    limit?: number;
    sort?: string;
    filter?: Record<string, any>;
    search?: string;
    fields?: string[];
    include?: string[];
}

async function getProducts(req: Request, res: Response) {
    const {
        page = 1,
        limit = 20,
        sort = '-createdAt',
        category,
        search,
        fields,
        minPrice,
        maxPrice
    } = req.query;

    // Build query
    const query: any = {};

    // Filtering
    if (category) {
        query.category = category;
    }

    if (minPrice || maxPrice) {
        query.price = {};
        if (minPrice) query.price.$gte = Number(minPrice);
        if (maxPrice) query.price.$lte = Number(maxPrice);
    }

    // Search
    if (search) {
        query.$text = { $search: search };
    }

    // Pagination
    const skip = (Number(page) - 1) * Number(limit);

    // Field selection
    const projection = fields
        ? fields.split(',').join(' ')
        : null;

    // Execute query
    const products = await Product
        .find(query)
        .select(projection)
        .sort(sort)
        .skip(skip)
        .limit(Number(limit));

    const total = await Product.countDocuments(query);

    res.json({
        data: products,
        meta: {
            page: Number(page),
            limit: Number(limit),
            total,
            totalPages: Math.ceil(total / Number(limit))
        }
    });
}
```

---

## 📦 REQUEST & RESPONSE FORMAT

### Request Format

```javascript
// ✅ GOOD - Request body structure
POST /api/users
Content-Type: application/json

{
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30,
    "address": {
        "street": "123 Main St",
        "city": "New York",
        "country": "USA"
    }
}

// ✅ GOOD - Bulk operations
POST /api/users/bulk
{
    "users": [
        { "name": "John", "email": "john@example.com" },
        { "name": "Jane", "email": "jane@example.com" }
    ]
}
```

### Response Format

```typescript
// ✅ GOOD - Consistent response structure
interface APIResponse<T> {
    data?: T;
    meta?: {
        page?: number;
        limit?: number;
        total?: number;
        totalPages?: number;
    };
    error?: {
        code: string;
        message: string;
        details?: any;
    };
    links?: {
        self: string;
        next?: string;
        prev?: string;
        first?: string;
        last?: string;
    };
}

// Single resource
{
    "data": {
        "id": "123",
        "name": "John Doe",
        "email": "john@example.com",
        "createdAt": "2025-11-01T10:00:00Z"
    }
}

// Collection with pagination
{
    "data": [
        { "id": "1", "name": "Product 1" },
        { "id": "2", "name": "Product 2" }
    ],
    "meta": {
        "page": 1,
        "limit": 20,
        "total": 100,
        "totalPages": 5
    },
    "links": {
        "self": "/api/products?page=1",
        "next": "/api/products?page=2",
        "last": "/api/products?page=5"
    }
}

// Error response
{
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Invalid input data",
        "details": [
            {
                "field": "email",
                "message": "Invalid email format"
            }
        ]
    }
}
```

### Timestamps & Date Format

```javascript
// ✅ GOOD - Use ISO 8601 format
{
    "createdAt": "2025-11-01T10:00:00Z",
    "updatedAt": "2025-11-01T15:30:00Z",
    "publishedAt": "2025-11-01T12:00:00Z"
}

// Include timezone info
{
    "scheduledAt": "2025-11-01T10:00:00-05:00"  // EST
}
```

### Null vs Missing Fields

```javascript
// ✅ GOOD - Be explicit about null values
{
    "name": "John",
    "middleName": null,      // Explicitly null
    "email": "john@example.com"
    // lastName is omitted (unknown/not applicable)
}
```

---

## 🔢 API VERSIONING

### 1️⃣ URL Path Versioning (Recommended)

```bash
# ✅ GOOD - Version in URL path
GET /api/v1/users
GET /api/v2/users

# Pros: Clear, easy to test, simple routing
# Cons: URL changes with version
```

```typescript
// Implementation
import express from 'express';
import v1Router from './routes/v1';
import v2Router from './routes/v2';

const app = express();

app.use('/api/v1', v1Router);
app.use('/api/v2', v2Router);

// Redirect to latest version
app.get('/api/users', (req, res) => {
    res.redirect('/api/v2/users');
});
```

### 2️⃣ Header Versioning

```bash
# Version in Accept header
GET /api/users
Accept: application/vnd.myapp.v1+json

# Or custom header
GET /api/users
API-Version: 1
```

```typescript
// Implementation
app.use('/api', (req, res, next) => {
    const version = req.headers['api-version'] || '2';

    if (version === '1') {
        return v1Handler(req, res);
    } else if (version === '2') {
        return v2Handler(req, res);
    } else {
        return res.status(400).json({
            error: 'Unsupported API version'
        });
    }
});
```

### 3️⃣ Query Parameter Versioning

```bash
GET /api/users?version=1
GET /api/users?api-version=2
```

### Version Management

```typescript
// ✅ GOOD - Deprecation notice
app.use('/api/v1', (req, res, next) => {
    res.set('Warning', '299 - "API v1 is deprecated. Please migrate to v2 by 2026-01-01"');
    res.set('Sunset', 'Wed, 01 Jan 2026 00:00:00 GMT');
    next();
});

// Support multiple versions
const apiVersions = {
    '1': {
        deprecated: true,
        sunsetDate: '2026-01-01',
        handler: v1Router
    },
    '2': {
        deprecated: false,
        handler: v2Router
    }
};
```

---

## 🔐 AUTHENTICATION & AUTHORIZATION

### API Key Authentication

```typescript
// ✅ GOOD - API Key in header
GET /api/users
X-API-Key: your_api_key_here

// Middleware
function apiKeyAuth(req: Request, res: Response, next: NextFunction) {
    const apiKey = req.headers['x-api-key'];

    if (!apiKey) {
        return res.status(401).json({
            error: 'API key required'
        });
    }

    const validKey = validateAPIKey(apiKey);
    if (!validKey) {
        return res.status(401).json({
            error: 'Invalid API key'
        });
    }

    req.apiKey = validKey;
    next();
}
```

### Bearer Token (JWT)

```typescript
// ✅ GOOD - JWT in Authorization header
GET /api/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

// Middleware
import jwt from 'jsonwebtoken';

function jwtAuth(req: Request, res: Response, next: NextFunction) {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            error: 'Bearer token required'
        });
    }

    const token = authHeader.substring(7);

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({
            error: 'Invalid or expired token'
        });
    }
}
```

### OAuth 2.0

```typescript
// ✅ GOOD - OAuth flow
// 1. Get authorization code
GET /oauth/authorize?
    client_id=your_client_id&
    redirect_uri=https://yourapp.com/callback&
    response_type=code&
    scope=read:users write:posts

// 2. Exchange code for token
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
code=AUTH_CODE&
client_id=YOUR_CLIENT_ID&
client_secret=YOUR_CLIENT_SECRET&
redirect_uri=https://yourapp.com/callback

// Response
{
    "access_token": "ACCESS_TOKEN",
    "token_type": "Bearer",
    "expires_in": 3600,
    "refresh_token": "REFRESH_TOKEN"
}

// 3. Use access token
GET /api/users
Authorization: Bearer ACCESS_TOKEN
```

### Permission-Based Authorization

```typescript
// ✅ GOOD - Check permissions
enum Permission {
    READ_USERS = 'read:users',
    WRITE_USERS = 'write:users',
    DELETE_USERS = 'delete:users'
}

function requirePermission(permission: Permission) {
    return (req: Request, res: Response, next: NextFunction) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        if (!req.user.permissions.includes(permission)) {
            return res.status(403).json({
                error: 'Insufficient permissions',
                required: permission
            });
        }

        next();
    };
}

// Usage
router.get('/users',
    jwtAuth,
    requirePermission(Permission.READ_USERS),
    getUsers
);

router.delete('/users/:id',
    jwtAuth,
    requirePermission(Permission.DELETE_USERS),
    deleteUser
);
```

---

## ⚠️ ERROR HANDLING

### Error Response Structure

```typescript
// ✅ GOOD - Consistent error format
interface APIError {
    error: {
        code: string;           // Machine-readable error code
        message: string;        // Human-readable message
        details?: any;          // Additional context
        timestamp?: string;     // When error occurred
        path?: string;          // Request path
        requestId?: string;     // For tracking
    };
}

// Examples
{
    "error": {
        "code": "RESOURCE_NOT_FOUND",
        "message": "User with ID 123 not found",
        "timestamp": "2025-11-01T10:00:00Z",
        "path": "/api/users/123",
        "requestId": "abc-123-def"
    }
}

{
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Validation failed",
        "details": [
            {
                "field": "email",
                "message": "Invalid email format",
                "value": "invalid-email"
            },
            {
                "field": "age",
                "message": "Must be at least 18",
                "value": 15
            }
        ]
    }
}
```

### Error Codes

```typescript
// ✅ GOOD - Define error codes
enum ErrorCode {
    // Authentication & Authorization
    UNAUTHORIZED = 'UNAUTHORIZED',
    FORBIDDEN = 'FORBIDDEN',
    INVALID_TOKEN = 'INVALID_TOKEN',
    TOKEN_EXPIRED = 'TOKEN_EXPIRED',

    // Resource Errors
    RESOURCE_NOT_FOUND = 'RESOURCE_NOT_FOUND',
    RESOURCE_ALREADY_EXISTS = 'RESOURCE_ALREADY_EXISTS',

    // Validation Errors
    VALIDATION_ERROR = 'VALIDATION_ERROR',
    INVALID_INPUT = 'INVALID_INPUT',
    MISSING_REQUIRED_FIELD = 'MISSING_REQUIRED_FIELD',

    // Rate Limiting
    RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',

    // Server Errors
    INTERNAL_SERVER_ERROR = 'INTERNAL_SERVER_ERROR',
    SERVICE_UNAVAILABLE = 'SERVICE_UNAVAILABLE',
    DATABASE_ERROR = 'DATABASE_ERROR'
}

class APIError extends Error {
    constructor(
        public code: ErrorCode,
        public message: string,
        public statusCode: number,
        public details?: any
    ) {
        super(message);
        this.name = 'APIError';
    }
}

// Usage
throw new APIError(
    ErrorCode.RESOURCE_NOT_FOUND,
    'User not found',
    404,
    { userId: '123' }
);
```

### Global Error Handler

```typescript
// ✅ GOOD - Centralized error handling
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    // Log error
    logger.error('API Error', {
        error: err.message,
        stack: err.stack,
        url: req.url,
        method: req.method,
        userId: req.user?.id,
        requestId: req.id
    });

    // Handle known errors
    if (err instanceof APIError) {
        return res.status(err.statusCode).json({
            error: {
                code: err.code,
                message: err.message,
                details: err.details,
                timestamp: new Date().toISOString(),
                path: req.path,
                requestId: req.id
            }
        });
    }

    // Handle validation errors
    if (err.name === 'ValidationError') {
        return res.status(400).json({
            error: {
                code: ErrorCode.VALIDATION_ERROR,
                message: 'Validation failed',
                details: err.details
            }
        });
    }

    // Handle unknown errors (don't leak sensitive info)
    res.status(500).json({
        error: {
            code: ErrorCode.INTERNAL_SERVER_ERROR,
            message: 'An unexpected error occurred',
            requestId: req.id
        }
    });
});
```

---

## 📄 PAGINATION & FILTERING

### Offset-Based Pagination

```typescript
// ✅ GOOD - Offset pagination
GET /api/products?page=2&limit=20

// Response
{
    "data": [...],
    "meta": {
        "page": 2,
        "limit": 20,
        "total": 100,
        "totalPages": 5
    },
    "links": {
        "self": "/api/products?page=2&limit=20",
        "first": "/api/products?page=1&limit=20",
        "prev": "/api/products?page=1&limit=20",
        "next": "/api/products?page=3&limit=20",
        "last": "/api/products?page=5&limit=20"
    }
}

// Implementation
async function getProducts(req: Request, res: Response) {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = (page - 1) * limit;

    const [products, total] = await Promise.all([
        Product.find().skip(offset).limit(limit),
        Product.countDocuments()
    ]);

    const totalPages = Math.ceil(total / limit);

    res.json({
        data: products,
        meta: { page, limit, total, totalPages },
        links: generatePaginationLinks(req, page, totalPages)
    });
}
```

### Cursor-Based Pagination

```typescript
// ✅ GOOD - Cursor pagination (for real-time data)
GET /api/posts?cursor=eyJpZCI6IjEyMyJ9&limit=20

// Response
{
    "data": [...],
    "meta": {
        "limit": 20,
        "hasMore": true
    },
    "cursors": {
        "next": "eyJpZCI6IjE0MyJ9",
        "prev": "eyJpZCI6IjEwMyJ9"
    }
}

// Implementation
async function getPosts(req: Request, res: Response) {
    const limit = parseInt(req.query.limit as string) || 20;
    const cursor = req.query.cursor
        ? decodeCursor(req.query.cursor as string)
        : null;

    const query = cursor
        ? { _id: { $lt: cursor.id } }
        : {};

    const posts = await Post
        .find(query)
        .sort({ _id: -1 })
        .limit(limit + 1);  // Fetch one extra to check if more exists

    const hasMore = posts.length > limit;
    const data = hasMore ? posts.slice(0, -1) : posts;

    res.json({
        data,
        meta: { limit, hasMore },
        cursors: {
            next: hasMore ? encodeCursor({ id: data[data.length - 1]._id }) : null,
            prev: cursor ? encodeCursor({ id: data[0]._id }) : null
        }
    });
}
```

### Filtering & Sorting

```typescript
// ✅ GOOD - Advanced filtering
GET /api/products?
    category=electronics&
    minPrice=100&
    maxPrice=1000&
    brand[]=apple&brand[]=samsung&
    inStock=true&
    sort=-price,name&
    fields=id,name,price

// Implementation
interface ProductFilter {
    category?: string;
    minPrice?: number;
    maxPrice?: number;
    brand?: string[];
    inStock?: boolean;
}

async function getProducts(req: Request, res: Response) {
    const filter: any = {};

    // Simple filters
    if (req.query.category) {
        filter.category = req.query.category;
    }

    if (req.query.inStock) {
        filter.inStock = req.query.inStock === 'true';
    }

    // Range filters
    if (req.query.minPrice || req.query.maxPrice) {
        filter.price = {};
        if (req.query.minPrice) filter.price.$gte = Number(req.query.minPrice);
        if (req.query.maxPrice) filter.price.$lte = Number(req.query.maxPrice);
    }

    // Array filters
    if (req.query.brand) {
        const brands = Array.isArray(req.query.brand)
            ? req.query.brand
            : [req.query.brand];
        filter.brand = { $in: brands };
    }

    // Sorting
    const sort = req.query.sort
        ? (req.query.sort as string).replace(',', ' ')
        : '-createdAt';

    // Field selection
    const fields = req.query.fields
        ? (req.query.fields as string).replace(',', ' ')
        : null;

    const products = await Product
        .find(filter)
        .select(fields)
        .sort(sort);

    res.json({ data: products });
}
```

---

## ⏱️ RATE LIMITING

```typescript
// ✅ GOOD - Rate limiting implementation
import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { createClient } from 'redis';

const redisClient = createClient();

// General rate limit
const generalLimiter = rateLimit({
    store: new RedisStore({
        client: redisClient,
        prefix: 'rl:general:'
    }),
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100,  // 100 requests per window
    message: {
        error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: 'Too many requests, please try again later'
        }
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        res.status(429).json({
            error: {
                code: 'RATE_LIMIT_EXCEEDED',
                message: 'Too many requests',
                retryAfter: req.rateLimit.resetTime
            }
        });
    }
});

// Stricter limit for sensitive endpoints
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    skipSuccessfulRequests: true  // Only count failed attempts
});

// Apply limiters
app.use('/api/', generalLimiter);
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);

// Custom rate limit by user
async function userRateLimit(req: Request, res: Response, next: NextFunction) {
    const userId = req.user?.id;
    if (!userId) return next();

    const key = `rl:user:${userId}`;
    const limit = req.user.plan === 'premium' ? 1000 : 100;

    const current = await redisClient.incr(key);
    if (current === 1) {
        await redisClient.expire(key, 3600);  // 1 hour
    }

    if (current > limit) {
        return res.status(429).json({
            error: 'Rate limit exceeded',
            limit,
            reset: await redisClient.ttl(key)
        });
    }

    res.set('X-RateLimit-Limit', limit.toString());
    res.set('X-RateLimit-Remaining', (limit - current).toString());

    next();
}
```

---

## 📚 API DOCUMENTATION

### OpenAPI/Swagger

```yaml
# ✅ GOOD - OpenAPI 3.0 specification
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
  description: API for managing users
  contact:
    email: api@example.com

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://staging-api.example.com/v1
    description: Staging

paths:
  /users:
    get:
      summary: List all users
      tags:
        - Users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            minimum: 1
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  meta:
                    $ref: '#/components/schemas/PaginationMeta'

    post:
      summary: Create a new user
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
          example: "123"
        name:
          type: string
          example: "John Doe"
        email:
          type: string
          format: email
          example: "john@example.com"
        createdAt:
          type: string
          format: date-time

    CreateUserRequest:
      type: object
      required:
        - name
        - email
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
        email:
          type: string
          format: email

    Error:
      type: object
      properties:
        error:
          type: object
          properties:
            code:
              type: string
            message:
              type: string
            details:
              type: object

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - bearerAuth: []
```

### Code Documentation

```typescript
/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Get list of users
 *     tags: [Users]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number
 *     responses:
 *       200:
 *         description: List of users
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/User'
 */
router.get('/users', getUsers);
```

---

## 🎨 GRAPHQL BEST PRACTICES

### Schema Design

```graphql
# ✅ GOOD - Well-structured schema
type Query {
    # Get single resource
    user(id: ID!): User

    # List resources with pagination
    users(
        first: Int = 20
        after: String
        orderBy: UserOrderBy
        filter: UserFilter
    ): UserConnection!

    # Search
    searchUsers(query: String!): [User!]!
}

type Mutation {
    # Create
    createUser(input: CreateUserInput!): CreateUserPayload!

    # Update
    updateUser(id: ID!, input: UpdateUserInput!): UpdateUserPayload!

    # Delete
    deleteUser(id: ID!): DeleteUserPayload!
}

# Types
type User {
    id: ID!
    name: String!
    email: String!
    posts(first: Int, after: String): PostConnection!
    createdAt: DateTime!
}

# Input types
input CreateUserInput {
    name: String!
    email: String!
    password: String!
}

input UpdateUserInput {
    name: String
    email: String
}

# Payloads
type CreateUserPayload {
    user: User!
    errors: [Error!]
}

# Pagination
type UserConnection {
    edges: [UserEdge!]!
    pageInfo: PageInfo!
    totalCount: Int!
}

type UserEdge {
    node: User!
    cursor: String!
}

type PageInfo {
    hasNextPage: Boolean!
    hasPreviousPage: Boolean!
    startCursor: String
    endCursor: String
}

# Enums
enum UserOrderBy {
    NAME_ASC
    NAME_DESC
    CREATED_AT_ASC
    CREATED_AT_DESC
}
```

### Resolver Implementation

```typescript
// ✅ GOOD - Efficient resolvers with DataLoader
import DataLoader from 'dataloader';

// Batch loading to prevent N+1 queries
const userLoader = new DataLoader(async (userIds: string[]) => {
    const users = await User.find({ _id: { $in: userIds } });
    return userIds.map(id =>
        users.find(user => user.id === id)
    );
});

const resolvers = {
    Query: {
        user: async (_: any, { id }: { id: string }) => {
            return userLoader.load(id);
        },

        users: async (_: any, args: PaginationArgs) => {
            const { first = 20, after, orderBy, filter } = args;

            // Build query
            const query = buildFilterQuery(filter);
            const sort = buildSortQuery(orderBy);

            // Cursor-based pagination
            if (after) {
                const cursor = decodeCursor(after);
                query._id = { $gt: cursor.id };
            }

            // Fetch one extra to determine hasNextPage
            const users = await User
                .find(query)
                .sort(sort)
                .limit(first + 1);

            const hasNextPage = users.length > first;
            const nodes = hasNextPage ? users.slice(0, -1) : users;

            return {
                edges: nodes.map(node => ({
                    node,
                    cursor: encodeCursor({ id: node.id })
                })),
                pageInfo: {
                    hasNextPage,
                    endCursor: nodes.length > 0
                        ? encodeCursor({ id: nodes[nodes.length - 1].id })
                        : null
                },
                totalCount: await User.countDocuments(query)
            };
        }
    },

    Mutation: {
        createUser: async (_: any, { input }: { input: CreateUserInput }) => {
            try {
                const user = await User.create(input);
                return { user, errors: [] };
            } catch (error) {
                return {
                    user: null,
                    errors: [{ message: error.message }]
                };
            }
        }
    },

    User: {
        // Nested resolver with DataLoader
        posts: async (user: User, args: PaginationArgs) => {
            return postLoader.load({ userId: user.id, ...args });
        }
    }
};
```

---

## 🎯 BEST PRACTICES SUMMARY

### ✅ DO

- ✅ Use nouns for resources, not verbs
- ✅ Use HTTP methods correctly
- ✅ Return appropriate status codes
- ✅ Version your API
- ✅ Use consistent naming (camelCase or snake_case)
- ✅ Implement pagination for collections
- ✅ Provide filtering and sorting
- ✅ Use proper authentication
- ✅ Implement rate limiting
- ✅ Document your API (OpenAPI/Swagger)
- ✅ Use HTTPS in production
- ✅ Handle errors consistently
- ✅ Include timestamps (ISO 8601)
- ✅ Support CORS properly
- ✅ Log API usage

### ❌ DON'T

- ❌ Use verbs in URLs
- ❌ Return HTML from JSON API
- ❌ Expose internal IDs unnecessarily
- ❌ Return different structures for same endpoint
- ❌ Use GET for operations that change state
- ❌ Ignore security (auth, rate limiting, validation)
- ❌ Return sensitive data in responses
- ❌ Use synchronous operations for long tasks
- ❌ Break backwards compatibility without versioning
- ❌ Leak error details in production

---

## 📚 REFERENCES

- [REST API Tutorial](https://restfulapi.net/)
- [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines)
- [Google API Design Guide](https://cloud.google.com/apis/design)
- [OpenAPI Specification](https://swagger.io/specification/)
- [GraphQL Best Practices](https://graphql.org/learn/best-practices/)
- [JSON:API](https://jsonapi.org/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
