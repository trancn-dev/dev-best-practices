# Business & Technical Constraints

This document defines all constraints, rules, requirements, and limitations for the Laravel DevKit project. These constraints ensure data integrity, business rule enforcement, and system stability.

---

## Table of Contents

1. [Data Integrity Constraints](#data-integrity-constraints)
2. [Business Rule Constraints](#business-rule-constraints)
3. [Technical Constraints](#technical-constraints)
4. [Validation Rules](#validation-rules)
5. [Performance Requirements](#performance-requirements)
6. [Security Constraints](#security-constraints)
7. [Rate Limits](#rate-limits)
8. [Resource Limits](#resource-limits)

---

## Data Integrity Constraints

### Database-Level Constraints

#### Primary Keys
- **MUST** be `bigint unsigned auto_increment`
- **MUST** be named `id`
- **CANNOT** be null
- **MUST** be unique

#### Foreign Keys
- **MUST** reference valid parent table
- **MUST** have defined action on delete (CASCADE, SET NULL, RESTRICT)
- **SHOULD** be indexed
- **MUST** follow naming: `{table_singular}_id`

#### Unique Constraints
```sql
-- Email must be unique
ALTER TABLE users ADD UNIQUE (email);

-- UUID must be unique
ALTER TABLE users ADD UNIQUE (uuid);

-- Composite unique: User can only have one role in a project
ALTER TABLE project_user ADD UNIQUE (project_id, user_id);
```

#### NOT NULL Constraints
```sql
-- Required fields
ALTER TABLE users MODIFY name VARCHAR(255) NOT NULL;
ALTER TABLE users MODIFY email VARCHAR(255) NOT NULL;
ALTER TABLE users MODIFY password VARCHAR(255) NOT NULL;
ALTER TABLE projects MODIFY user_id BIGINT UNSIGNED NOT NULL;
```

#### Check Constraints (Laravel 10+)
```php
Schema::create('products', function (Blueprint $table) {
    $table->id();
    $table->decimal('price', 10, 2);
    $table->integer('stock')->default(0);

    // Price must be positive
    $table->check('price > 0');

    // Stock cannot be negative
    $table->check('stock >= 0');
});
```

---

## Business Rule Constraints

### User Constraints

#### Registration
- **MUST** provide name (3-255 characters)
- **MUST** provide unique email
- **MUST** provide password (minimum 12 characters)
- **MUST** accept terms of service
- **CANNOT** register with existing email
- **MUST** verify email within 24 hours or account is suspended

#### Password Requirements
- **MINIMUM**: 12 characters
- **MUST** contain: uppercase letter
- **MUST** contain: lowercase letter
- **MUST** contain: number
- **MUST** contain: special character
- **CANNOT** be a commonly used password (checked against pwned passwords)
- **CANNOT** reuse last 5 passwords

#### Login Attempts
- **MAXIMUM**: 5 failed attempts
- **LOCKOUT**: 5 minutes after 5 failed attempts
- **RESET**: Successful login resets counter

#### Account Status
- **DEFAULT**: `pending` (until email verified)
- **ACTIVE**: Can access all features
- **SUSPENDED**: Cannot login, data preserved
- **DELETED**: Soft deleted, can be restored within 30 days

### Project Constraints

#### Creation
- **MUST** have name (3-255 characters)
- **MUST** have owner (user_id)
- **MAXIMUM** projects per user:
  - Free tier: 3 projects
  - Pro tier: 25 projects
  - Enterprise tier: Unlimited
- **CANNOT** create project with duplicate name for same user

#### Naming
- **MUST** be 3-255 characters
- **CAN** contain: letters, numbers, spaces, hyphens, underscores
- **CANNOT** contain: special characters (except - and _)
- **CANNOT** start or end with space

#### Status Transitions
```
draft → active → archived
  ↓       ↓
deleted ← suspended
```

**Rules**:
- **CANNOT** deploy a `draft` project
- **CANNOT** edit an `archived` project
- **CANNOT** restore a `deleted` project after 30 days
- **MUST** have at least 1 feature to move from `draft` to `active`

#### Deletion
- **SOFT DELETE**: Mark as deleted, preserve data
- **GRACE PERIOD**: 30 days to restore
- **PERMANENT DELETE**: After 30 days, data is removed
- **CASCADE**: Deleting project deletes all features, tasks, deployments

### Feature Constraints

#### Creation
- **MUST** belong to a project
- **MUST** have name (3-255 characters)
- **MUST** have priority (critical, high, medium, low)
- **DEFAULT** status: `planned`

#### Status Flow
```
planned → in_progress → testing → completed → deployed
   ↓                                ↓
cancelled ← ← ← ← ← ← ← ← ← ← ← ← ← ↓
```

**Rules**:
- **CANNOT** move to `testing` without all tasks completed
- **CANNOT** deploy without passing tests
- **CANNOT** cancel a `deployed` feature (must rollback first)

### Deployment Constraints

#### Requirements
- **MUST** have project_id
- **MUST** have environment (development, staging, production)
- **MUST** have valid repository URL
- **CANNOT** deploy to production without:
  - All tests passing
  - Code review approval
  - Staging deployment successful

#### Concurrent Deployments
- **LIMIT**: 1 deployment per project at a time
- **QUEUE**: Additional deployments are queued
- **TIMEOUT**: 30 minutes maximum deployment time

#### Rollback
- **AVAILABLE**: Last 10 deployments can be rolled back
- **AUTOMATIC**: Rollback if deployment fails health checks
- **MANUAL**: Can manually rollback successful deployment

---

## Technical Constraints

### System Requirements

#### Server Requirements
- **PHP**: >= 8.2
- **MySQL**: >= 8.0 or PostgreSQL >= 14
- **Redis**: >= 6.0
- **Node.js**: >= 18.0
- **Composer**: >= 2.5

#### PHP Extensions
- **REQUIRED**: pdo, mbstring, openssl, tokenizer, xml, ctype, json, bcmath
- **RECOMMENDED**: redis, opcache, imagick

### Code Constraints

#### Method Complexity
- **MAXIMUM**: 10 lines per method (excluding whitespace)
- **CYCLOMATIC COMPLEXITY**: Maximum 10
- **NESTING DEPTH**: Maximum 3 levels

#### Class Size
- **MAXIMUM**: 200 lines per class
- **MAXIMUM**: 10 public methods per class
- **SINGLE RESPONSIBILITY**: One reason to change

#### File Naming
- **MUST** match class name
- **MUST** use PascalCase
- **MUST** have `.php` extension
- **ONE** class per file

---

## Validation Rules

### User Validation

```php
// Registration
[
    'name' => 'required|string|min:3|max:255|regex:/^[a-zA-Z\s]+$/',
    'email' => 'required|email|max:255|unique:users,email',
    'password' => [
        'required',
        'confirmed',
        Password::min(12)
            ->letters()
            ->mixedCase()
            ->numbers()
            ->symbols()
            ->uncompromised(),
    ],
    'terms' => 'accepted',
]

// Update Profile
[
    'name' => 'required|string|min:3|max:255',
    'email' => 'required|email|max:255|unique:users,email,' . $user->id,
    'phone' => 'nullable|string|regex:/^\+?[1-9]\d{1,14}$/',
    'bio' => 'nullable|string|max:5000',
    'avatar' => 'nullable|image|mimes:jpg,jpeg,png|max:2048',
]
```

### Project Validation

```php
// Create Project
[
    'name' => 'required|string|min:3|max:255|regex:/^[a-zA-Z0-9\s\-_]+$/',
    'description' => 'nullable|string|max:5000',
    'status' => 'required|in:draft,active,archived',
    'repository' => 'nullable|url|regex:/^https:\/\/(github|gitlab)\.com/',
    'tags' => 'nullable|array|max:10',
    'tags.*' => 'string|max:50|regex:/^[a-zA-Z0-9\-]+$/',
]
```

### Feature Validation

```php
// Create Feature
[
    'project_id' => 'required|exists:projects,id',
    'name' => 'required|string|min:3|max:255',
    'description' => 'nullable|string|max:5000',
    'priority' => 'required|in:critical,high,medium,low',
    'status' => 'required|in:planned,in_progress,testing,completed,cancelled',
    'estimated_hours' => 'nullable|integer|min:1|max:1000',
    'assigned_to' => 'nullable|exists:users,id',
]
```

### File Upload Validation

```php
[
    'avatar' => [
        'required',
        'file',
        'image',
        'mimes:jpg,jpeg,png',
        'max:2048',                    // 2MB
        'dimensions:min_width=100,min_height=100,max_width=2000,max_height=2000',
    ],
    'document' => [
        'required',
        'file',
        'mimes:pdf,doc,docx',
        'max:10240',                   // 10MB
    ],
]
```

---

## Performance Requirements

### Response Time

| Endpoint Type | Target | Maximum |
|---------------|--------|---------|
| Static pages | < 200ms | 500ms |
| Dynamic pages | < 500ms | 1s |
| API endpoints | < 300ms | 800ms |
| Database queries | < 50ms | 200ms |
| Background jobs | Varies | 5 minutes |

### Database Queries

- **MAXIMUM** queries per request: 20
- **MUST** use eager loading to prevent N+1
- **MUST** use indexes on foreign keys
- **MUST** use indexes on frequently queried columns
- **SHOULD** use query caching for repeated queries

### Caching

- **MUST** cache:
  - Static content (HTML, CSS, JS)
  - API responses (with TTL)
  - Database queries (expensive operations)
  - Configuration data

- **CACHE TTL**:
  - Static content: 1 year
  - API responses: 5-60 minutes
  - Database queries: 1-10 minutes
  - Session data: 2 hours

### Memory

- **MAXIMUM** memory per request: 128MB
- **PHP memory_limit**: 256MB
- **SHOULD** use pagination for large datasets
- **SHOULD** use chunking for batch operations

---

## Security Constraints

### Authentication

- **SESSION LIFETIME**: 2 hours
- **REMEMBER ME**: 30 days maximum
- **TOKEN EXPIRY**: 24 hours
- **REFRESH TOKEN**: 7 days
- **PASSWORD RESET**: Token valid for 1 hour

### Authorization

- **MUST** check permissions on every request
- **MUST** use policies for authorization
- **CANNOT** bypass authorization checks
- **MUST** log all permission denials

### Password Security

- **HASHING**: bcrypt or argon2id
- **COST**: bcrypt cost 12+
- **SALT**: Automatic per Laravel
- **HISTORY**: Cannot reuse last 5 passwords

### API Security

- **AUTHENTICATION**: Required for all endpoints (except public)
- **RATE LIMITING**: Applied per user/IP
- **CORS**: Whitelist allowed origins
- **HTTPS**: Required in production
- **API VERSIONING**: URI-based (/api/v1/)

---

## Rate Limits

### API Endpoints

| Endpoint Category | Limit | Window |
|------------------|-------|--------|
| Authentication | 10 requests | 1 minute |
| Public API | 60 requests | 1 minute |
| Authenticated API | 120 requests | 1 minute |
| Admin API | 300 requests | 1 minute |

### Specific Operations

| Operation | Limit | Window |
|-----------|-------|--------|
| Login attempts | 5 | 5 minutes |
| Password reset | 3 | 1 hour |
| Email sending | 10 | 1 hour |
| File uploads | 20 | 1 hour |
| Deployments | 10 | 1 hour |

### Implementation

```php
// routes/api.php
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {
    Route::apiResource('users', UserController::class);
});

Route::middleware('throttle:login')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
});
```

---

## Resource Limits

### Storage Limits

| Tier | File Storage | Database Storage |
|------|-------------|------------------|
| Free | 1 GB | 100 MB |
| Pro | 50 GB | 5 GB |
| Enterprise | Unlimited | Unlimited |

### Project Limits

| Tier | Projects | Features/Project | Collaborators |
|------|----------|------------------|---------------|
| Free | 3 | 25 | 3 |
| Pro | 25 | 100 | 10 |
| Enterprise | Unlimited | Unlimited | Unlimited |

### API Limits

| Tier | Requests/Day | Concurrent Connections |
|------|-------------|----------------------|
| Free | 10,000 | 5 |
| Pro | 100,000 | 25 |
| Enterprise | Unlimited | Unlimited |

### Email Limits

| Type | Limit | Window |
|------|-------|--------|
| Welcome emails | 1 per registration | - |
| Password reset | 3 | 1 hour |
| Notifications | 50 | 1 day |
| Marketing | 5 | 1 week |

---

## Hard Constraints (CANNOT BE VIOLATED)

### Database

1. **PRIMARY KEY** must exist on all tables
2. **FOREIGN KEYS** must reference valid records
3. **UNIQUE CONSTRAINTS** must be enforced
4. **NOT NULL** fields cannot be null
5. **DATA TYPES** must match schema definition

### Business Rules

1. **CANNOT** delete a user with active projects (must archive first)
2. **CANNOT** deploy a project without tests passing
3. **CANNOT** downgrade subscription with more projects than allowed
4. **CANNOT** restore soft-deleted records after 30 days
5. **CANNOT** bypass email verification for critical operations

### Security

1. **MUST** authenticate for non-public endpoints
2. **MUST** authorize before sensitive operations
3. **MUST** validate all user input
4. **MUST** sanitize output to prevent XSS
5. **MUST** use parameterized queries to prevent SQL injection
6. **MUST** hash passwords (never store plain text)
7. **MUST** use HTTPS in production
8. **MUST** regenerate session on login

### Code Quality

1. **MUST** follow PSR-12 coding standards
2. **MUST** use type hints for all parameters and returns
3. **MUST** write tests for all business logic
4. **MUST** pass all tests before deployment
5. **MUST** maintain minimum 70% code coverage

---

## Soft Constraints (SHOULD BE FOLLOWED)

### Performance

1. **SHOULD** respond within target time (see Performance Requirements)
2. **SHOULD** use eager loading to prevent N+1
3. **SHOULD** cache expensive operations
4. **SHOULD** use pagination for large datasets
5. **SHOULD** optimize database indexes

### Code Quality

1. **SHOULD** keep methods under 20 lines
2. **SHOULD** keep classes under 200 lines
3. **SHOULD** follow Single Responsibility Principle
4. **SHOULD** use dependency injection
5. **SHOULD** write descriptive variable names

### Documentation

1. **SHOULD** have PHPDoc comments on all public methods
2. **SHOULD** document complex algorithms
3. **SHOULD** keep API documentation up to date
4. **SHOULD** include examples in documentation

---

## Constraint Enforcement

### Database Level
- Foreign key constraints
- Unique constraints
- Check constraints
- NOT NULL constraints

### Application Level
- Form Request validation
- Policy authorization
- Model events (creating, updating, deleting)
- Custom validation rules

### Middleware Level
- Authentication
- Rate limiting
- CORS
- Security headers

### Queue Level
- Job retry limits
- Job timeout limits
- Queue prioritization

---

## Constraint Violation Handling

### Database Violations
```php
try {
    $user->save();
} catch (QueryException $e) {
    // Handle constraint violation
    if ($e->getCode() === '23000') {
        // Integrity constraint violation
        return back()->withErrors(['email' => 'Email already exists']);
    }
}
```

### Validation Violations
```php
// Automatic handling via Form Requests
public function store(CreateUserRequest $request)
{
    // If validation fails, 422 response with errors
    $user = User::create($request->validated());
}
```

### Authorization Violations
```php
// Automatic handling via Policies
public function update(Project $project)
{
    $this->authorize('update', $project);
    // If fails, 403 Forbidden response
}
```

### Rate Limit Violations
```php
// Automatic handling via Throttle middleware
// Returns 429 Too Many Requests with retry-after header
```

---

## Constraint Testing

### Unit Tests
```php
public function test_user_email_must_be_unique()
{
    User::factory()->create(['email' => 'test@example.com']);

    $this->expectException(QueryException::class);
    User::factory()->create(['email' => 'test@example.com']);
}

public function test_password_must_meet_requirements()
{
    $response = $this->post('/register', [
        'email' => 'test@example.com',
        'password' => 'weak',
    ]);

    $response->assertSessionHasErrors('password');
}
```

### Feature Tests
```php
public function test_cannot_create_more_projects_than_allowed()
{
    $user = User::factory()->create(['tier' => 'free']);
    Project::factory()->count(3)->create(['user_id' => $user->id]);

    $response = $this->actingAs($user)->post('/projects', [
        'name' => 'Fourth Project',
    ]);

    $response->assertForbidden();
}
```

---

## Summary

These constraints ensure:
- ✅ Data integrity
- ✅ Business rule enforcement
- ✅ Security compliance
- ✅ Performance standards
- ✅ System stability
- ✅ Scalability
- ✅ Maintainability

**All constraints MUST be respected and enforced at appropriate levels.**
