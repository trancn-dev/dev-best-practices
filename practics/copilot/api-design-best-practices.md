# Rule: API Design Best Practices

## Intent
Enforce RESTful API design principles and patterns for consistent, scalable, and maintainable APIs. Copilot must generate well-structured APIs following REST conventions, proper HTTP semantics, and industry standards.

## Scope
Applies to all REST API, GraphQL endpoint development, API documentation, and API-related code generation.

---

## 1. RESTful Resource Design

### Resource Naming Rules

- ✅ **MUST** use plural nouns for collections
- ✅ **MUST** use kebab-case for multi-word resources
- ✅ **MUST** represent resources, not actions
- ❌ **MUST NOT** use verbs in URLs
- ❌ **MUST NOT** use file extensions (.json, .xml)

```javascript
// ✅ GOOD
GET    /api/users
GET    /api/users/{id}
GET    /api/users/{id}/posts
GET    /api/order-items
POST   /api/payment-methods

// ❌ BAD
GET    /api/getUsers
POST   /api/createUser
GET    /api/user          // Singular
GET    /api/Users_Posts   // Underscore
GET    /api/users.json    // File extension
```

### Resource Hierarchy

```javascript
// ✅ GOOD - Nested resources (max 2-3 levels)
GET    /api/users/{userId}/posts/{postId}
GET    /api/organizations/{orgId}/teams/{teamId}/members

// ❌ BAD - Too deep nesting
GET    /api/users/{id}/posts/{id}/comments/{id}/replies/{id}

// ✅ ALTERNATIVE - Use query parameters
GET    /api/comments?postId={id}&parentId={id}
```

---

## 2. HTTP Methods & Semantics

### Method Usage Rules

**GET**
- ✅ **MUST** be safe (no side effects)
- ✅ **MUST** be idempotent
- ✅ **MUST** return 200 OK or 404 Not Found
- ❌ **MUST NOT** modify data
- ❌ **MUST NOT** have request body

**POST**
- ✅ **MUST** create new resources
- ✅ **MUST** return 201 Created with Location header
- ✅ **MUST** include created resource in response
- ❌ **MUST NOT** be idempotent

**PUT**
- ✅ **MUST** replace entire resource
- ✅ **MUST** be idempotent
- ✅ **MUST** return 200 OK or 204 No Content
- ✅ **MUST** require all fields

**PATCH**
- ✅ **MUST** partially update resource
- ✅ **MUST** return 200 OK
- ✅ **MUST** accept subset of fields

**DELETE**
- ✅ **MUST** remove resource
- ✅ **MUST** be idempotent
- ✅ **MUST** return 204 No Content or 200 OK

### Status Code Rules

```typescript
// Success 2xx
200 OK                    // GET, PUT, PATCH success
201 Created               // POST success (with Location header)
202 Accepted              // Async operation started
204 No Content            // DELETE success, no response body

// Client Errors 4xx
400 Bad Request           // Invalid syntax, validation error
401 Unauthorized          // Authentication required or invalid
403 Forbidden             // Authenticated but no permission
404 Not Found             // Resource doesn't exist
405 Method Not Allowed    // HTTP method not supported
409 Conflict              // Resource state conflict
422 Unprocessable Entity  // Semantic validation error
429 Too Many Requests     // Rate limit exceeded

// Server Errors 5xx
500 Internal Server Error // Unexpected server error
502 Bad Gateway           // Invalid upstream response
503 Service Unavailable   // Temporary downtime
504 Gateway Timeout       // Upstream timeout
```

**Check:**
```typescript
// ✅ GOOD - Proper status codes
router.post('/users', async (req, res) => {
    const user = await User.create(req.body);
    res.status(201)
        .location(`/api/users/${user.id}`)
        .json(user);
});

router.delete('/users/:id', async (req, res) => {
    await User.delete(req.params.id);
    res.status(204).send();
});

// ❌ BAD - Wrong status code
router.post('/users', async (req, res) => {
    const user = await User.create(req.body);
    res.status(200).json(user);  // Should be 201
});
```

---

## 3. URL Structure & Query Parameters

### Query Parameter Conventions

**Filtering**
```bash
GET /api/products?category=electronics&brand=apple&inStock=true
GET /api/products?price[gte]=100&price[lte]=1000
```

**Sorting**
```bash
GET /api/products?sort=price           # Ascending
GET /api/products?sort=-price          # Descending (- prefix)
GET /api/products?sort=price,-rating   # Multiple fields
```

**Pagination**
```bash
# Offset-based
GET /api/products?page=2&limit=20

# Cursor-based
GET /api/posts?cursor=eyJpZCI6IjEyMyJ9&limit=20
```

**Field Selection**
```bash
GET /api/users?fields=id,name,email
```

**Search**
```bash
GET /api/products?search=laptop&searchFields=name,description
```

**Include Related**
```bash
GET /api/posts?include=author,comments
```

---

## 4. Request & Response Format

### Request Body Rules

- ✅ **MUST** use JSON format (Content-Type: application/json)
- ✅ **MUST** use camelCase for field names
- ✅ **MUST** validate all input
- ❌ **MUST NOT** accept nested objects > 3 levels deep

```json
// ✅ GOOD
{
    "name": "John Doe",
    "email": "john@example.com",
    "address": {
        "street": "123 Main St",
        "city": "New York"
    }
}
```

### Response Structure Rules

**Single Resource**
```json
{
    "data": {
        "id": "123",
        "name": "John Doe",
        "createdAt": "2025-11-01T10:00:00Z"
    }
}
```

**Collection with Pagination**
```json
{
    "data": [...],
    "meta": {
        "page": 1,
        "limit": 20,
        "total": 100,
        "totalPages": 5
    },
    "links": {
        "self": "/api/products?page=1",
        "next": "/api/products?page=2",
        "prev": null,
        "first": "/api/products?page=1",
        "last": "/api/products?page=5"
    }
}
```

**Date/Time Format**
- ✅ **MUST** use ISO 8601 format
- ✅ **MUST** include timezone (UTC recommended)

```json
{
    "createdAt": "2025-11-01T10:00:00Z",
    "updatedAt": "2025-11-01T15:30:00+00:00"
}
```

---

## 5. API Versioning

### Versioning Strategy (URL Path - Recommended)

```bash
# ✅ GOOD - Version in URL
GET /api/v1/users
GET /api/v2/users

# Major version only
/api/v1/...
/api/v2/...
```

**Implementation:**
```typescript
// ✅ GOOD
app.use('/api/v1', v1Router);
app.use('/api/v2', v2Router);

// Deprecation headers
app.use('/api/v1', (req, res, next) => {
    res.set('Warning', '299 - "API v1 deprecated. Migrate to v2 by 2026-01-01"');
    res.set('Sunset', 'Wed, 01 Jan 2026 00:00:00 GMT');
    next();
});
```

### Breaking Change Rules

- ✅ **MUST** bump major version for breaking changes
- ✅ **MUST** support old version for 6-12 months
- ✅ **MUST** document migration path
- ❌ **MUST NOT** remove fields without version bump
- ❌ **MUST NOT** change field types without version bump

**Breaking Changes:**
- Removing/renaming fields
- Changing field types
- Changing URL structure
- Removing endpoints
- Changing authentication method

**Non-Breaking Changes:**
- Adding new fields (optional)
- Adding new endpoints
- Adding new query parameters
- Adding new HTTP methods to existing resources

---

## 6. Authentication & Authorization

### Authentication Methods

**Bearer Token (JWT)**
```bash
GET /api/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**API Key**
```bash
GET /api/users
X-API-Key: your_api_key_here
```

### Security Rules

- ✅ **MUST** use HTTPS in production
- ✅ **MUST** validate tokens on every request
- ✅ **MUST** return 401 for missing/invalid auth
- ✅ **MUST** return 403 for insufficient permissions
- ✅ **MUST** implement rate limiting
- ❌ **MUST NOT** expose API keys in URLs
- ❌ **MUST NOT** return sensitive data in errors

```typescript
// ✅ GOOD - JWT middleware
async function authenticate(req, res, next) {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
        return res.status(401).json({
            error: {
                code: 'UNAUTHORIZED',
                message: 'Authentication required'
            }
        });
    }

    try {
        req.user = jwt.verify(token, process.env.JWT_SECRET);
        next();
    } catch (error) {
        return res.status(401).json({
            error: {
                code: 'INVALID_TOKEN',
                message: 'Invalid or expired token'
            }
        });
    }
}

// ✅ GOOD - Permission check
function requirePermission(permission) {
    return (req, res, next) => {
        if (!req.user?.permissions.includes(permission)) {
            return res.status(403).json({
                error: {
                    code: 'FORBIDDEN',
                    message: `Requires ${permission} permission`
                }
            });
        }
        next();
    };
}
```

---

## 7. Error Handling

### Error Response Structure

```typescript
interface APIError {
    error: {
        code: string;           // Machine-readable
        message: string;        // Human-readable
        details?: any[];        // Additional context
        timestamp?: string;
        path?: string;
        requestId?: string;
    }
}
```

### Standard Error Codes

```typescript
enum ErrorCode {
    // Auth
    UNAUTHORIZED = 'UNAUTHORIZED',
    FORBIDDEN = 'FORBIDDEN',
    INVALID_TOKEN = 'INVALID_TOKEN',
    TOKEN_EXPIRED = 'TOKEN_EXPIRED',

    // Resources
    RESOURCE_NOT_FOUND = 'RESOURCE_NOT_FOUND',
    RESOURCE_ALREADY_EXISTS = 'RESOURCE_ALREADY_EXISTS',

    // Validation
    VALIDATION_ERROR = 'VALIDATION_ERROR',
    INVALID_INPUT = 'INVALID_INPUT',
    MISSING_REQUIRED_FIELD = 'MISSING_REQUIRED_FIELD',

    // Rate Limiting
    RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',

    // Server
    INTERNAL_SERVER_ERROR = 'INTERNAL_SERVER_ERROR',
    SERVICE_UNAVAILABLE = 'SERVICE_UNAVAILABLE'
}
```

### Error Response Examples

```json
// 404 Not Found
{
    "error": {
        "code": "RESOURCE_NOT_FOUND",
        "message": "User with ID 123 not found",
        "timestamp": "2025-11-01T10:00:00Z",
        "path": "/api/users/123",
        "requestId": "abc-123"
    }
}

// 400 Validation Error
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

---

## 8. Pagination & Filtering

### Offset-Based Pagination

```typescript
// ✅ GOOD - Offset pagination
async function paginate(req, res) {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const offset = (page - 1) * limit;

    const [data, total] = await Promise.all([
        Model.find().skip(offset).limit(limit),
        Model.countDocuments()
    ]);

    res.json({
        data,
        meta: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit)
        },
        links: {
            self: `/api/resource?page=${page}&limit=${limit}`,
            next: page < Math.ceil(total / limit) ? `/api/resource?page=${page + 1}` : null,
            prev: page > 1 ? `/api/resource?page=${page - 1}` : null
        }
    });
}
```

### Cursor-Based Pagination (Real-time Data)

```typescript
// ✅ GOOD - Cursor pagination
async function cursorPaginate(req, res) {
    const limit = parseInt(req.query.limit) || 20;
    const cursor = req.query.cursor ? decodeCursor(req.query.cursor) : null;

    const query = cursor ? { _id: { $lt: cursor.id } } : {};
    const items = await Model.find(query).sort({ _id: -1 }).limit(limit + 1);

    const hasMore = items.length > limit;
    const data = hasMore ? items.slice(0, -1) : items;

    res.json({
        data,
        meta: { limit, hasMore },
        cursors: {
            next: hasMore ? encodeCursor({ id: data[data.length - 1]._id }) : null
        }
    });
}
```

### Filtering Rules

- ✅ **MUST** validate filter parameters
- ✅ **MUST** support common operators (eq, ne, gt, lt, gte, lte, in)
- ✅ **MUST** document available filters

```bash
# Range filters
GET /api/products?price[gte]=100&price[lte]=1000

# Array filters
GET /api/products?category[]=electronics&category[]=clothing

# Boolean filters
GET /api/products?inStock=true

# Date filters
GET /api/orders?createdAt[gte]=2025-01-01
```

---

## 9. Rate Limiting

### Rate Limit Rules

- ✅ **MUST** implement rate limiting for all public APIs
- ✅ **MUST** return 429 Too Many Requests when exceeded
- ✅ **MUST** include rate limit headers
- ✅ **MUST** have stricter limits for sensitive endpoints

```typescript
// ✅ GOOD - Rate limiting
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100,                   // 100 requests per window
    message: {
        error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: 'Too many requests'
        }
    },
    standardHeaders: true,      // Return RateLimit-* headers
    legacyHeaders: false
});

// Stricter for auth endpoints
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    skipSuccessfulRequests: true
});

app.use('/api/', limiter);
app.use('/api/auth/login', authLimiter);
```

### Rate Limit Headers

```bash
HTTP/1.1 429 Too Many Requests
RateLimit-Limit: 100
RateLimit-Remaining: 0
RateLimit-Reset: 1638360000
Retry-After: 900
```

---

## 10. API Documentation

### OpenAPI/Swagger Requirements

- ✅ **MUST** document all endpoints
- ✅ **MUST** include request/response examples
- ✅ **MUST** document authentication requirements
- ✅ **MUST** document error responses
- ✅ **MUST** keep documentation in sync with code

```yaml
# ✅ GOOD - OpenAPI spec
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
```

---

## 11. GraphQL Best Practices

### Schema Design Rules

- ✅ **MUST** use descriptive type names
- ✅ **MUST** implement cursor-based pagination
- ✅ **MUST** use input types for mutations
- ✅ **MUST** return payload types with error field
- ❌ **MUST NOT** expose internal IDs
- ❌ **MUST NOT** use generic names (data, info)

```graphql
# ✅ GOOD - GraphQL schema
type Query {
    user(id: ID!): User
    users(
        first: Int = 20
        after: String
        orderBy: UserOrderBy
    ): UserConnection!
}

type Mutation {
    createUser(input: CreateUserInput!): CreateUserPayload!
}

type User {
    id: ID!
    name: String!
    email: String!
    posts(first: Int, after: String): PostConnection!
}

input CreateUserInput {
    name: String!
    email: String!
}

type CreateUserPayload {
    user: User
    errors: [Error!]
}
```

### Resolver Optimization

- ✅ **MUST** use DataLoader to prevent N+1 queries
- ✅ **MUST** implement batching
- ✅ **MUST** cache frequently accessed data

```typescript
// ✅ GOOD - DataLoader usage
import DataLoader from 'dataloader';

const userLoader = new DataLoader(async (ids) => {
    const users = await User.find({ _id: { $in: ids } });
    return ids.map(id => users.find(u => u.id === id));
});

const resolvers = {
    Post: {
        author: (post) => userLoader.load(post.authorId)
    }
};
```

---

## 12. Performance & Optimization

### Performance Rules

- ✅ **MUST** implement caching for GET requests
- ✅ **MUST** use compression (gzip/brotli)
- ✅ **MUST** add database indexes for filtered fields
- ✅ **MUST** paginate large responses
- ✅ **MUST** support ETag for caching
- ❌ **MUST NOT** return entire collections without pagination
- ❌ **MUST NOT** expose N+1 query problems

```typescript
// ✅ GOOD - ETag caching
app.get('/api/users/:id', async (req, res) => {
    const user = await User.findById(req.params.id);
    const etag = generateETag(user);

    if (req.headers['if-none-match'] === etag) {
        return res.status(304).send();
    }

    res.set('ETag', etag)
        .set('Cache-Control', 'max-age=300')
        .json(user);
});
```

---

## 13. Security Best Practices

### Security Checklist

- [ ] **HTTPS** enforced in production
- [ ] **Input validation** on all endpoints
- [ ] **SQL injection** prevention (parameterized queries)
- [ ] **XSS prevention** (sanitize output)
- [ ] **CSRF protection** enabled
- [ ] **CORS** configured properly
- [ ] **Rate limiting** implemented
- [ ] **Authentication** required for protected endpoints
- [ ] **Authorization** checks for all operations
- [ ] **Sensitive data** not logged or exposed
- [ ] **API keys** stored securely (env variables)
- [ ] **Dependencies** regularly updated

---

## 14. Copilot-Specific Instructions

### Code Generation Rules

When generating API code, Copilot **MUST**:

1. **CHECK** resource naming follows conventions (plural nouns, kebab-case)
2. **ENFORCE** proper HTTP method usage
3. **RETURN** appropriate status codes
4. **IMPLEMENT** consistent error handling
5. **ADD** pagination for collection endpoints
6. **INCLUDE** request validation
7. **GENERATE** OpenAPI documentation comments
8. **APPLY** rate limiting middleware
9. **VERIFY** authentication/authorization
10. **SUGGEST** caching strategies

### Response Pattern

```markdown
✅ **Suggestion:** API Endpoint Generated

**Method:** POST /api/users
**Status Code:** 201 Created
**Authentication:** Required (Bearer token)
**Rate Limit:** 100 requests/15 minutes

**Request:**
\`\`\`json
{
    "name": "string",
    "email": "string"
}
\`\`\`

**Response:**
\`\`\`json
{
    "data": {
        "id": "123",
        "name": "John",
        "createdAt": "2025-11-01T10:00:00Z"
    }
}
\`\`\`

**Validation:**
- Email format validation
- Required field checks
- Duplicate email check

**Documentation:** OpenAPI spec generated
```

### Auto-Fix Patterns

When detecting API violations, suggest:

```typescript
// ❌ Detected Issue: Verb in URL
GET /api/getUsers

// ✅ Auto-Fix Suggestion:
GET /api/users
```

```typescript
// ❌ Detected Issue: Wrong status code
router.post('/users', async (req, res) => {
    const user = await create(req.body);
    res.status(200).json(user);
});

// ✅ Auto-Fix Suggestion:
router.post('/users', async (req, res) => {
    const user = await create(req.body);
    res.status(201)
        .location(`/api/users/${user.id}`)
        .json(user);
});
```

---

## 15. Quick Reference Checklist

### Pre-Deploy Checklist

- [ ] All endpoints return consistent JSON structure
- [ ] Status codes are semantically correct
- [ ] Error responses follow standard format
- [ ] Authentication/authorization implemented
- [ ] Rate limiting configured
- [ ] Pagination added for collections
- [ ] Input validation on all endpoints
- [ ] API documentation generated
- [ ] HTTPS enforced
- [ ] CORS configured
- [ ] Logging implemented
- [ ] Monitoring setup

### Code Review Focus

- [ ] Resource names are plural nouns
- [ ] URLs don't contain verbs
- [ ] HTTP methods used correctly
- [ ] Idempotency respected
- [ ] Proper status codes returned
- [ ] Errors handled consistently
- [ ] Security measures in place
- [ ] Performance optimized (caching, pagination)
- [ ] Documentation complete

---

## References

- REST API Design Rulebook - Mark Massé
- Microsoft REST API Guidelines
- Google API Design Guide
- OpenAPI Specification v3.0
- GraphQL Best Practices
- OWASP API Security Top 10

**Remember:** Good API design is about consistency, predictability, and developer experience. Design APIs that you would want to use yourself.
