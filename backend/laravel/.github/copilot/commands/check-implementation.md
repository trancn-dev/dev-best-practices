---
type: command
name: check-implementation
version: 2.0
scope: project
integration:
  - laravel
  - testing
  - quality-assurance
---

# Command: Check Implementation

## Mục tiêu
Lệnh `check-implementation` được sử dụng để **kiểm tra và xác thực** việc triển khai code có đúng với requirement và design đã định không.

Mục tiêu chính:
- Đảm bảo code implement đúng requirement.
- Kiểm tra tuân thủ coding standards (PSR-12, Laravel conventions).
- Xác thực logic nghiệp vụ và edge cases.
- Đánh giá quality, performance, security.

---

## Quy trình kiểm tra

### Step 1: Chuẩn bị kiểm tra

**Pre-check Checklist:**

- [ ] Requirement document available và clear
- [ ] Design document reviewed (nếu có)
- [ ] Code đã commit và push lên branch
- [ ] Test cases đã được viết
- [ ] Environment setup correctly (local/staging)
- [ ] Dependencies installed (`composer install`)
- [ ] Database migrated (`php artisan migrate`)

---

### Step 2: Requirement Compliance Check

#### A. Functional Requirements Validation

```markdown
## Requirement Compliance Report

### Feature: [Feature Name]

**Requirement ID:** REQ-YYYY-MM-DD-XXX
**Implementation Branch:** feature/[name]
**Developer:** [Name]
**Reviewer:** [Name]

---

### User Story
> **As a** [role]
> **I want** [feature]
> **So that** [value]

**Implementation Status:** ✅ Complete | ⚠️ Partial | ❌ Not implemented

---

### Acceptance Criteria

| # | Criterion | Expected | Actual | Status | Notes |
|---|-----------|----------|--------|--------|-------|
| 1 | User can register with email | Registration form accepts email | Working as expected | ✅ Pass | - |
| 2 | Validation for invalid email | Show error message | Error shown correctly | ✅ Pass | - |
| 3 | Send welcome email | Email sent after registration | ⚠️ Email delayed | ⚠️ Partial | Queue issue |
| 4 | Redirect to dashboard | User sees dashboard | Working | ✅ Pass | - |

**Overall Compliance:** 3.5/4 (87%)
```

#### B. Edge Cases & Error Scenarios

```markdown
### Edge Cases Testing

| Scenario | Input | Expected Output | Actual Output | Status |
|----------|-------|----------------|---------------|--------|
| Empty email | `""` | Validation error | 422 with error message | ✅ |
| Invalid email format | `"invalid"` | Validation error | 422 with error message | ✅ |
| Very long email | 256+ chars | Validation error | 422 with error message | ✅ |
| SQL injection attempt | `"'; DROP TABLE--"` | Sanitized/rejected | Safely handled | ✅ |
| Duplicate email | Existing email | Unique error | 422 duplicate error | ✅ |
| Special chars in name | `"O'Brien"` | Accepted | Working correctly | ✅ |
| Unicode characters | `"名前"` | Accepted | Working correctly | ✅ |
| Concurrent requests | 2 simultaneous | Both processed | One succeeds, one fails | ✅ |

**Edge Case Coverage:** 8/8 (100%)
```

#### C. Non-Functional Requirements

```markdown
### Performance Requirements

| Metric | Requirement | Measured | Status | Notes |
|--------|-------------|----------|--------|-------|
| Response Time | < 200ms | 145ms avg | ✅ Pass | Good |
| Database Queries | < 5 per request | 3 queries | ✅ Pass | Optimized |
| Memory Usage | < 50MB | 35MB | ✅ Pass | Efficient |
| Concurrent Users | 1000 | 850 tested | ⚠️ Partial | Need load test |

### Security Requirements

| Requirement | Implementation | Status |
|-------------|----------------|--------|
| Password hashing | bcrypt with cost 10 | ✅ |
| CSRF protection | Token validation | ✅ |
| SQL injection prevention | Eloquent ORM | ✅ |
| XSS prevention | Output escaping | ✅ |
| Rate limiting | 60 req/min | ✅ |
| HTTPS enforcement | Forced in prod | ✅ |
```

---

### Step 3: Code Quality Check

#### A. Coding Standards (PSR-12 & Laravel)

```bash
# Run PHP CodeSniffer
vendor/bin/phpcs --standard=PSR12 app/

# Run PHP CS Fixer (dry-run)
vendor/bin/php-cs-fixer fix --dry-run --diff

# Run PHPStan (static analysis)
vendor/bin/phpstan analyse app/ --level=5

# Run Laravel Pint
./vendor/bin/pint --test
```

**Code Standards Checklist:**

- [ ] ✅ No PSR-12 violations
- [ ] ✅ Proper namespace declarations
- [ ] ✅ Type hints for all parameters
- [ ] ✅ Return type declarations
- [ ] ✅ Proper indentation (4 spaces)
- [ ] ✅ No trailing whitespace
- [ ] ✅ Proper docblocks (@param, @return, @throws)
- [ ] ✅ Constants in UPPER_CASE
- [ ] ✅ No unused imports

#### B. Laravel Best Practices

```markdown
### Laravel Convention Checklist

#### Controllers
- [ ] ✅ Controllers only delegate, no business logic
- [ ] ✅ Use dependency injection
- [ ] ✅ Single responsibility per controller
- [ ] ✅ RESTful naming (index, show, store, update, destroy)

#### Services/Actions
- [ ] ✅ Business logic in Service/Action classes
- [ ] ✅ Single responsibility per service
- [ ] ✅ Testable and mockable

#### Models
- [ ] ✅ Proper fillable/guarded
- [ ] ✅ Casts defined for dates/json
- [ ] ✅ Relationships defined correctly
- [ ] ✅ Scopes for reusable queries
- [ ] ✅ Accessors/Mutators where needed

#### Validation
- [ ] ✅ Use FormRequest classes
- [ ] ✅ Custom validation rules in separate classes
- [ ] ✅ Clear error messages

#### Database
- [ ] ✅ Migrations have up() and down()
- [ ] ✅ Foreign keys with proper constraints
- [ ] ✅ Indexes on frequently queried columns
- [ ] ✅ Seeders for test data

#### API Resources
- [ ] ✅ Use Resource classes for API responses
- [ ] ✅ Consistent response structure
- [ ] ✅ Proper HTTP status codes

#### Configuration
- [ ] ✅ No hard-coded values in code
- [ ] ✅ Use config() for configuration
- [ ] ✅ Environment variables in .env
```

#### C. Code Smells & Anti-patterns

```markdown
### Code Smell Detection

| Issue | Location | Severity | Recommendation |
|-------|----------|----------|----------------|
| God Class | `UserService.php` (800 lines) | 🔴 High | Split into smaller services |
| Long Method | `UserController::store()` (150 lines) | 🟡 Medium | Extract to service methods |
| Duplicate Code | `formatDate()` in 3 files | 🟡 Medium | Create helper function |
| Magic Numbers | `if ($status === 3)` | 🟢 Low | Use named constants |
| Dead Code | Unused method `oldLogin()` | 🟢 Low | Remove unused code |

**Action Items:**
- [ ] Refactor UserService into smaller services
- [ ] Extract long methods into smaller ones
- [ ] Create DateHelper for date formatting
- [ ] Replace magic numbers with constants
- [ ] Remove dead code
```

---

### Step 4: Logic & Business Rules Validation

#### A. Happy Path Testing

```markdown
## Happy Path Verification

### Scenario 1: User Registration
**Given:** New user with valid data
**When:** POST /api/register
**Then:**
- User created in database ✅
- Welcome email sent ✅
- User redirected to dashboard ✅
- Session created ✅

**Test Command:**
```bash
php artisan test tests/Feature/UserRegistrationTest.php::test_user_can_register
```

**Result:** ✅ PASSED (0.15s)

### Scenario 2: User Login
**Given:** Existing user with correct credentials
**When:** POST /api/login
**Then:**
- User authenticated ✅
- Token generated ✅
- Last login updated ✅

**Test Command:**
```bash
php artisan test tests/Feature/AuthenticationTest.php::test_user_can_login
```

**Result:** ✅ PASSED (0.12s)
```

#### B. Business Rules Validation

```markdown
### Business Rules Check

| Rule | Description | Implementation | Verified |
|------|-------------|----------------|----------|
| BR-001 | Email must be unique | Database unique constraint + validation | ✅ |
| BR-002 | Password min 8 characters | Validation rule | ✅ |
| BR-003 | User must verify email within 24h | Email verification with expiry | ✅ |
| BR-004 | Max 3 login attempts before lockout | RateLimiter on login | ✅ |
| BR-005 | Admin can't delete own account | Policy check in controller | ✅ |

**Compliance:** 5/5 (100%)
```

---

### Step 5: Security Assessment

#### A. OWASP Top 10 Check

```markdown
## Security Checklist (OWASP Top 10)

### A01: Broken Access Control
- [ ] ✅ Authorization checks on all routes
- [ ] ✅ Policy classes for resource access
- [ ] ✅ No direct object reference without validation
- [ ] ✅ Proper role/permission checks

### A02: Cryptographic Failures
- [ ] ✅ Passwords hashed with bcrypt
- [ ] ✅ Sensitive data encrypted at rest
- [ ] ✅ HTTPS enforced in production
- [ ] ✅ No sensitive data in logs

### A03: Injection
- [ ] ✅ Eloquent ORM used (no raw SQL)
- [ ] ✅ Input validation on all endpoints
- [ ] ✅ Output escaping in Blade templates
- [ ] ✅ No eval() or exec() usage

### A04: Insecure Design
- [ ] ✅ Threat modeling performed
- [ ] ✅ Security requirements documented
- [ ] ✅ Secure defaults configured

### A05: Security Misconfiguration
- [ ] ✅ Debug mode OFF in production
- [ ] ✅ Error messages don't leak info
- [ ] ✅ Unnecessary features disabled
- [ ] ✅ Security headers configured

### A06: Vulnerable Components
- [ ] ✅ Dependencies up to date
- [ ] ✅ No known vulnerabilities (composer audit)
- [ ] ✅ Regular security updates

### A07: Authentication Failures
- [ ] ✅ Strong password policy
- [ ] ✅ Multi-factor authentication available
- [ ] ✅ Session timeout configured
- [ ] ✅ Account lockout after failed attempts

### A08: Software and Data Integrity
- [ ] ✅ Code signing in CI/CD
- [ ] ✅ Composer lock file committed
- [ ] ✅ No auto-update without verification

### A09: Security Logging Failures
- [ ] ✅ Failed login attempts logged
- [ ] ✅ Access control failures logged
- [ ] ✅ Logs protected from tampering
- [ ] ✅ Log monitoring configured

### A10: Server-Side Request Forgery
- [ ] ✅ URL validation for external requests
- [ ] ✅ Whitelist of allowed domains
- [ ] ✅ No user-controlled URLs without validation

**Security Score:** 30/30 (100%) ✅
```

#### B. Laravel Security Checklist

```markdown
### Laravel-Specific Security

- [ ] ✅ APP_KEY generated and secure
- [ ] ✅ APP_DEBUG=false in production
- [ ] ✅ CSRF protection enabled
- [ ] ✅ SQL injection prevented (Eloquent)
- [ ] ✅ XSS prevented (Blade escaping)
- [ ] ✅ Mass assignment protection ($fillable/$guarded)
- [ ] ✅ Rate limiting configured
- [ ] ✅ API authentication (Sanctum/Passport)
- [ ] ✅ File upload validation
- [ ] ✅ .env not in version control
```

---

### Step 6: Performance Check

#### A. Database Query Analysis

```php
// Enable query logging
DB::enableQueryLog();

// Execute feature
$user = User::with('profile', 'posts')->find(1);

// Get queries
$queries = DB::getQueryLog();
dd($queries);
```

**Query Analysis:**

```markdown
### Query Performance Report

| Query | Time | Type | Issue | Recommendation |
|-------|------|------|-------|----------------|
| SELECT * FROM users | 0.5ms | N/A | None | ✅ Good |
| SELECT * FROM posts WHERE user_id=1 (x100) | 50ms | N+1 | ⚠️ N+1 problem | Use eager loading |
| SELECT * FROM comments | 2ms | N/A | SELECT * | ✅ Specify columns |

**Issues Found:** 1
**Action:** Add `with('posts')` to prevent N+1 query

### Optimization Applied
```php
// Before (N+1 problem)
$users = User::all();
foreach ($users as $user) {
    echo $user->posts->count(); // N queries
}

// After (Eager loading)
$users = User::with('posts')->all();
foreach ($users as $user) {
    echo $user->posts->count(); // 1 query
}
```

**Performance Improvement:** 98% faster (50ms → 1ms)
```

#### B. Caching Strategy

```markdown
### Caching Implementation

| Data Type | Cache Strategy | TTL | Status |
|-----------|----------------|-----|--------|
| User profile | Cache::remember | 1 hour | ✅ |
| Settings | Config cache | Forever | ✅ |
| API responses | HTTP cache | 5 min | ✅ |
| Database queries | Query cache | 10 min | ⚠️ Missing |

**Recommendations:**
- [ ] Add cache for expensive queries
- [ ] Implement cache tagging for related data
- [ ] Use Redis for better performance
```

#### C. Load Testing

```bash
# Using Apache Bench
ab -n 1000 -c 100 http://localhost/api/users

# Using K6
k6 run load-test.js
```

**Load Test Results:**

```markdown
### Load Test Report

**Test Configuration:**
- Total Requests: 1000
- Concurrent Users: 100
- Duration: 10 seconds

**Results:**
| Metric | Value | Status |
|--------|-------|--------|
| Requests/sec | 250 | ✅ Good |
| Avg Response Time | 145ms | ✅ Good |
| 95th Percentile | 280ms | ✅ Good |
| 99th Percentile | 450ms | ⚠️ Monitor |
| Error Rate | 0.2% | ✅ Good |
| Throughput | 2.5 MB/s | ✅ Good |

**Bottlenecks Identified:**
- Database connection pool saturated at 90+ concurrent users
- Memory usage spikes during peak load

**Recommendations:**
- [ ] Increase database connection pool size
- [ ] Implement connection pooling
- [ ] Add caching layer
```

---

### Step 7: Test Coverage Check

#### A. Run Coverage Report

```bash
# With PHPUnit
php artisan test --coverage --min=80

# Generate HTML report
php artisan test --coverage-html coverage/

# Coverage by directory
php artisan test --coverage-php coverage.php
```

**Coverage Report:**

```markdown
## Test Coverage Report

### Overall Coverage: 87%

### Coverage by Directory
| Directory | Lines | Functions | Classes | Coverage |
|-----------|-------|-----------|---------|----------|
| app/Http/Controllers | 340/400 | 28/32 | 8/8 | 85% ⚠️ |
| app/Services | 520/550 | 45/48 | 12/12 | 95% ✅ |
| app/Models | 180/190 | 38/40 | 10/10 | 95% ✅ |
| app/Actions | 220/250 | 22/25 | 8/10 | 88% ✅ |

### Files Needing Attention
1. **UserController.php** - 78% coverage
   - Missing: `destroy()` method (lines 45-52)
   - Missing: Error handling in `update()` (lines 78-85)

2. **PaymentService.php** - 82% coverage
   - Missing: Refund flow (lines 120-145)
   - Missing: Webhook validation (lines 200-215)

### Test Quality Metrics
- Total Tests: 156
- Passed: 154
- Failed: 2
- Skipped: 0
- Assertions: 687
- Average Time: 0.08s per test
```

#### B. Missing Coverage Analysis

```markdown
### Coverage Gaps

#### Gap 1: UserController::destroy()
**Current Coverage:** 0%
**Lines:** 45-52
**Priority:** High

**Recommended Test:**
```php
/** @test */
public function admin_can_delete_user(): void
{
    $admin = User::factory()->admin()->create();
    $user = User::factory()->create();

    $response = $this->actingAs($admin)
        ->deleteJson("/api/users/{$user->id}");

    $response->assertStatus(204);
    $this->assertSoftDeleted('users', ['id' => $user->id]);
}
```

#### Gap 2: PaymentService refund flow
**Current Coverage:** 0%
**Lines:** 120-145
**Priority:** Critical

**Recommended Test:**
```php
/** @test */
public function it_can_process_refund_successfully(): void
{
    $payment = Payment::factory()->completed()->create();

    $result = $this->paymentService->refund($payment->id);

    $this->assertTrue($result->success);
    $this->assertEquals('refunded', $payment->fresh()->status);
}
```
```

---

### Step 8: Documentation Check

```markdown
## Documentation Compliance

### Code Documentation
- [ ] ✅ All public methods have docblocks
- [ ] ✅ Complex logic has inline comments
- [ ] ✅ @param and @return types specified
- [ ] ✅ @throws documented for exceptions
- [ ] ⚠️ Some class-level docblocks missing

### API Documentation
- [ ] ✅ All endpoints documented in OpenAPI/Swagger
- [ ] ✅ Request/response examples provided
- [ ] ✅ Error codes documented
- [ ] ✅ Authentication requirements specified

### README & Guides
- [ ] ✅ Installation instructions clear
- [ ] ✅ Configuration documented
- [ ] ⚠️ Deployment guide needs update
- [ ] ❌ Troubleshooting guide missing
```

---

## Check Implementation Report Template

```markdown
# Implementation Check Report

**Feature:** [Feature Name]
**Branch:** feature/[name]
**Developer:** [Name]
**Reviewer:** [Name]
**Date:** [YYYY-MM-DD]

---

## Executive Summary

**Overall Status:** ✅ Approved | ⚠️ Approved with Comments | ❌ Changes Required

**Quick Stats:**
- Requirement Compliance: 95%
- Code Quality Score: 8.5/10
- Test Coverage: 87%
- Security Score: 100%
- Performance: ✅ Meets requirements

---

## Detailed Findings

### ✅ Strengths
1. Excellent test coverage (87%)
2. All security checks passed
3. Clean code architecture
4. Good performance metrics

### ⚠️ Issues Found
1. **Minor:** Some docblocks missing (Priority: Low)
2. **Minor:** One N+1 query detected (Priority: Medium)

### ❌ Critical Issues
None

---

## Checklist Summary

| Category | Score | Status |
|----------|-------|--------|
| Requirement Compliance | 95% | ✅ |
| Code Standards | 90% | ✅ |
| Security | 100% | ✅ |
| Performance | 92% | ✅ |
| Test Coverage | 87% | ✅ |
| Documentation | 85% | ⚠️ |

---

## Action Items

### Must Fix (Before Merge)
None

### Should Fix (Before Release)
- [ ] Fix N+1 query in UserController
- [ ] Add missing docblocks

### Nice to Have
- [ ] Improve documentation
- [ ] Add integration tests for payment flow

---

## Approval

**Reviewer Decision:** ✅ Approved with minor comments

**Sign-off:**
- Developer: [Name] - [Date]
- Code Reviewer: [Name] - [Date]
- QA: [Name] - [Date]

**Next Steps:**
- [ ] Merge to develop
- [ ] Deploy to staging
- [ ] Run regression tests
```

---

## Tools & Commands

```bash
# Code quality checks
vendor/bin/phpcs --standard=PSR12 app/
vendor/bin/phpstan analyse app/ --level=5
vendor/bin/pint --test

# Security audit
composer audit
php artisan security:check

# Test coverage
php artisan test --coverage --min=80

# Performance profiling
php artisan debugbar:enable
php artisan telescope:install

# Load testing
ab -n 1000 -c 100 http://localhost/api/endpoint
k6 run load-test.js
```

---

## Tham khảo

- [PSR-12: Extended Coding Style](https://www.php-fig.org/psr/psr-12/)
- [Laravel Best Practices](https://github.com/alexeymezenin/laravel-best-practices)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Code Review Best Practices](https://google.github.io/eng-practices/review/)
- [Clean Code PHP](https://github.com/jupeter/clean-code-php)
