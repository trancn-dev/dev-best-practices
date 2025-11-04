---# Command: Code Review

type: command

name: code-review## Mục tiêu

version: 2.0Lệnh `code-review` được sử dụng để đánh giá chất lượng mã nguồn.

scope: projectMục đích là đảm bảo code:

integration:- Đúng chức năng (functional correctness)

  - laravel- Tuân thủ chuẩn mã hóa PSR-12

  - php- Đảm bảo tính nhất quán với kiến trúc Laravel

  - quality-assurance- An toàn, dễ bảo trì và có thể mở rộng

---

---

# Command: Code Review

## Hướng dẫn Review

## Mục tiêu

Lệnh `code-review` được sử dụng để **đánh giá chất lượng code** trước khi merge vào branch chính.### 1. Kiểm tra cú pháp & chuẩn mã hóa

- Tuân thủ PSR-12:

Mục tiêu chính:  - 4 spaces indent

- Đảm bảo code đúng chức năng và requirement.  - Class và Method có khoảng trắng hợp lý

- Tuân thủ coding standards (PSR-12, Laravel conventions).  - Không có trailing spaces hoặc dòng trống dư

- Phát hiện bugs, security issues, performance problems.- Đảm bảo tên biến, phương thức, class đúng convention:

- Đảm bảo code maintainable và testable.  - Class: PascalCase

  - Method: camelCase

---  - Constant: UPPER_CASE

- Đảm bảo có type-hint đầy đủ cho parameters và return types.

## Quy trình review

### 2. Kiểm tra cấu trúc Laravel

### Step 1: Chuẩn bị review- **Controller** chỉ nên gọi Service hoặc Action, không nên chứa logic nghiệp vụ.

- **Service / Action** nên xử lý business logic, không chứa query trực tiếp.

**Pre-review Checklist:**- **Repository** nên chịu trách nhiệm truy cập dữ liệu (Eloquent hoặc Query Builder).

- Không nên truy cập model trực tiếp trong Controller.

- [ ] Code đã commit và push lên branch- Dùng **Form Request** cho validation và **Resource** cho output JSON.

- [ ] PR/MR description rõ ràng

- [ ] Link đến requirement/design document### 3. Kiểm tra bảo mật

- [ ] Tests đã pass- Không sử dụng `eval()`, `unserialize()` hoặc truy cập file trực tiếp.

- [ ] CI/CD pipeline success- Escape toàn bộ output HTML bằng `e()`.

- Kiểm tra CSRF, Validation, Authorization (Policy / Gate).

---- Không expose dữ liệu nhạy cảm (`password`, `token`, `api_key`, ...).



### Step 2: Functional Correctness### 4. Kiểm tra hiệu suất

- Dùng eager loading (`with()`) để tránh N+1 query.

```markdown- Sử dụng `Cache::remember()` cho các query tĩnh.

## Kiểm tra chức năng- Tránh logic nặng trong vòng lặp.

- Tối ưu migration và index database.

### Requirements Compliance

- [ ] Code implement đúng requirement### 5. Kiểm tra test coverage

- [ ] Acceptance criteria được thỏa mãn- Kiểm tra có test case cho các logic quan trọng chưa.

- [ ] Edge cases được xử lý- Các test nên độc lập, dễ đọc, không phụ thuộc môi trường ngoài.

- [ ] Error scenarios được cover- Khuyến khích sử dụng **Pest** hoặc **PHPUnit**.



### Logic Validation### 6. Kiểm tra maintainability

- [ ] Business logic đúng- Mỗi hàm nên có **một nhiệm vụ duy nhất (Single Responsibility)**.

- [ ] Calculations chính xác- Không lồng quá 3 cấp `if` hoặc `foreach`.

- [ ] Data transformations hợp lý- Tên hàm, biến, class rõ nghĩa, mô tả đúng chức năng.

- [ ] State transitions correct- Có docblock mô tả ý nghĩa và tham số.

```

---

---

## Mẫu phản hồi đánh giá

### Step 3: Code Standards (PSR-12 & Laravel)

**Tổng quan:**

#### A. PSR-12 Compliance> Code hoạt động đúng nhưng có thể cải thiện về format, dependency injection và hiệu suất.



```markdown**Chi tiết:**

### PSR-12 Checklist- ⚠️ Vi phạm PSR-12: Dấu `{` phải nằm trên dòng mới sau khai báo class.

- ⚠️ Chưa có type-hint cho `$id` trong `show($id)`.

#### File Structure- ✅ Tách logic xử lý ra Service class là hợp lý.

- [ ] Files use only `<?php` tag- 💡 Có thể cache kết quả query bằng `Cache::remember()` để tăng hiệu suất.

- [ ] Files end with single blank line

- [ ] No closing `?>` tag**Đề xuất cải thiện:**

- [ ] UTF-8 without BOM- Thêm test case cho phương thức `store()`.

- Di chuyển logic validate sang `FormRequest`.

#### Formatting- Thêm docblock cho các public function.

- [ ] 4 spaces indentation (no tabs)

- [ ] No trailing whitespace---

- [ ] Line length <= 120 characters

- [ ] One blank line after namespace## Output mong đợi

- [ ] One blank line after use blockKhi chạy lệnh `code-review`, AI nên trả về:

1. **Đánh giá tổng quan:** về code style, kiến trúc, và logic.

#### Naming2. **Danh sách lỗi cụ thể:** vị trí, mô tả, và khuyến nghị.

- [ ] Classes: PascalCase3. **Đề xuất cải thiện:** hướng dẫn cách refactor hoặc tối ưu.

- [ ] Methods: camelCase

- [ ] Constants: UPPER_CASE---

- [ ] Variables: camelCase

**Nguồn tham khảo:**

#### Structure- [PSR-12 Standard](https://www.php-fig.org/psr/psr-12/)

- [ ] Opening brace on new line for classes- [Laravel Best Practices](https://github.com/alexeymezenin/laravel-best-practices)

- [ ] Opening brace on same line for methods- [OWASP PHP Security Guide](https://owasp.org/www-community/attacks/PHP_Object_Injection)

- [ ] One space after control structure keywords
- [ ] No space after opening parenthesis
```

#### B. Laravel Conventions

```markdown
### Laravel Best Practices

#### Controllers
- [ ] Controllers only delegate (no business logic)
- [ ] Use dependency injection
- [ ] RESTful method names (index, show, store, update, destroy)
- [ ] Type hints for all parameters
- [ ] Return types declared

#### Services/Actions
- [ ] Business logic in Service/Action classes
- [ ] Single responsibility
- [ ] Proper error handling
- [ ] Testable (mockable dependencies)

#### Models
- [ ] $fillable or $guarded defined
- [ ] $casts for dates/json
- [ ] Relationships defined correctly
- [ ] Scopes for reusable queries
- [ ] Accessors/Mutators where needed

#### Validation
- [ ] Use FormRequest classes
- [ ] Custom rules in separate classes
- [ ] Clear error messages

#### Database
- [ ] Migrations have up() and down()
- [ ] Foreign keys with constraints
- [ ] Indexes on queried columns
- [ ] No raw SQL (use Query Builder/Eloquent)

#### API
- [ ] Use Resource classes
- [ ] Consistent response structure
- [ ] Proper HTTP status codes
- [ ] Pagination for lists
```

---

### Step 4: Security Review

```markdown
## Security Checklist (OWASP Top 10)

### Input Validation
- [ ] All inputs validated
- [ ] Type checking enforced
- [ ] SQL injection prevented (Eloquent)
- [ ] XSS prevented (Blade escaping)
- [ ] File upload validated

### Authentication & Authorization
- [ ] Routes protected with middleware
- [ ] Policies/Gates for authorization
- [ ] Password hashing (bcrypt/argon2)
- [ ] No sensitive data in logs

### Data Protection
- [ ] Sensitive data encrypted
- [ ] No hardcoded credentials
- [ ] Environment variables used
- [ ] CSRF protection enabled

### API Security
- [ ] Rate limiting configured
- [ ] API authentication (Sanctum/Passport)
- [ ] CORS policy defined
- [ ] Input sanitization

### Common Vulnerabilities
- [ ] No eval() or exec() usage
- [ ] No unserialize() on user input
- [ ] No direct file access
- [ ] No SQL injection vectors
- [ ] No XXE vulnerabilities
```

---

### Step 5: Performance Review

```markdown
## Performance Checklist

### Database Queries
- [ ] No N+1 queries (use with())
- [ ] Proper indexes defined
- [ ] Avoid SELECT * (specify columns)
- [ ] Pagination for large datasets
- [ ] Use chunk() for batch processing

### Caching
- [ ] Cache static/slow queries
- [ ] Cache::remember() used appropriately
- [ ] Cache invalidation on updates
- [ ] Proper cache tags/keys

### Resource Usage
- [ ] No memory leaks
- [ ] File handles closed
- [ ] Database connections released
- [ ] Large operations queued

### Code Efficiency
- [ ] No unnecessary loops
- [ ] Efficient algorithms
- [ ] Lazy loading where appropriate
- [ ] Avoid premature optimization
```

---

### Step 6: Code Quality & Maintainability

```markdown
## Code Quality Checklist

### SOLID Principles
- [ ] Single Responsibility Principle
- [ ] Open/Closed Principle
- [ ] Liskov Substitution Principle
- [ ] Interface Segregation Principle
- [ ] Dependency Inversion Principle

### Clean Code
- [ ] Self-documenting code
- [ ] Meaningful names
- [ ] Functions < 20 lines
- [ ] Max 3 levels of nesting
- [ ] DRY (Don't Repeat Yourself)

### Documentation
- [ ] Docblocks for public methods
- [ ] @param and @return tags
- [ ] @throws for exceptions
- [ ] Complex logic commented
- [ ] README updated if needed

### Error Handling
- [ ] Try-catch where appropriate
- [ ] Custom exceptions for business logic
- [ ] Proper error messages
- [ ] Logging for debugging
- [ ] Graceful degradation
```

---

### Step 7: Testing Review

```markdown
## Testing Checklist

### Test Coverage
- [ ] Unit tests for business logic
- [ ] Feature tests for user flows
- [ ] Test coverage >= 80%
- [ ] Critical paths covered

### Test Quality
- [ ] Tests are independent
- [ ] Arrange-Act-Assert pattern
- [ ] Descriptive test names
- [ ] No test duplication
- [ ] Fast execution (< 100ms per test)

### Edge Cases
- [ ] Empty/null inputs tested
- [ ] Boundary values tested
- [ ] Error scenarios tested
- [ ] Concurrent operations tested
```

---

## Code Review Report Template

```markdown
# Code Review Report

**PR/MR:** #[Number]
**Author:** [Name]
**Reviewer:** [Name]
**Date:** [YYYY-MM-DD]

---

## Summary

**Overall Status:** ✅ Approved | ⚠️ Approved with Comments | ❌ Changes Required

**Quick Assessment:**
- Functional correctness: [Score]/10
- Code quality: [Score]/10
- Security: [Score]/10
- Performance: [Score]/10
- Test coverage: [X]%

---

## Detailed Findings

### ✅ Strengths
1. Clean code structure with good separation of concerns
2. Comprehensive test coverage (92%)
3. Proper error handling
4. Good documentation

### 🔴 Critical Issues (Must Fix)
**Issue #1: SQL Injection Vulnerability**
- **Location:** `UserController.php:45`
- **Problem:** Using raw SQL with user input
  ```php
  DB::select("SELECT * FROM users WHERE email = '$email'"); // ❌
  ```
- **Solution:** Use Eloquent or parameterized queries
  ```php
  User::where('email', $email)->first(); // ✅
  ```

### 🟡 Important Issues (Should Fix)
**Issue #2: N+1 Query Problem**
- **Location:** `PostController.php:index()`
- **Problem:** Loading comments in loop
  ```php
  foreach ($posts as $post) {
      $post->comments; // N+1 query
  }
  ```
- **Solution:** Use eager loading
  ```php
  $posts = Post::with('comments')->get(); // ✅
  ```

**Issue #3: Missing Type Hints**
- **Location:** `UserService.php:createUser()`
- **Problem:** Parameters lack type hints
- **Solution:** Add type hints and return type
  ```php
  public function createUser(array $data): User // ✅
  ```

### 🟢 Minor Issues (Nice to Fix)
**Issue #4: Code Duplication**
- **Location:** `OrderService.php` and `InvoiceService.php`
- **Problem:** Duplicate tax calculation logic
- **Solution:** Extract to helper or trait

---

## Security Review

| Check | Status | Notes |
|-------|--------|-------|
| Input Validation | ✅ Pass | All inputs validated |
| SQL Injection | ❌ Fail | Found in UserController |
| XSS Prevention | ✅ Pass | Blade escaping used |
| CSRF Protection | ✅ Pass | Tokens verified |
| Authorization | ✅ Pass | Policies enforced |

---

## Performance Review

| Check | Status | Notes |
|-------|--------|-------|
| N+1 Queries | ⚠️ Warning | Found in PostController |
| Caching | ✅ Pass | Proper cache usage |
| Indexes | ✅ Pass | All foreign keys indexed |
| Query Optimization | ✅ Pass | Efficient queries |

---

## Test Coverage

| Type | Coverage | Status |
|------|----------|--------|
| Unit Tests | 92% | ✅ Excellent |
| Feature Tests | 85% | ✅ Good |
| Integration Tests | 78% | ⚠️ Could improve |
| Overall | 87% | ✅ Good |

**Missing Coverage:**
- `UserController::destroy()` - No tests
- `PaymentService::refund()` - No tests

---

## Recommendations

### Before Merge (Required)
1. ✅ Fix SQL injection in UserController
2. ✅ Fix N+1 query in PostController
3. ✅ Add type hints to UserService methods

### After Merge (Optional)
1. Refactor duplicate tax calculation code
2. Add tests for missing methods
3. Improve integration test coverage

---

## Action Items

- [ ] Developer: Fix critical issues
- [ ] Developer: Add missing tests
- [ ] Developer: Update PR with fixes
- [ ] Reviewer: Re-review after fixes
- [ ] QA: Test on staging environment

---

## Approval

**Decision:** ⚠️ Approved with mandatory changes

**Conditions:**
- Must fix critical issues before merge
- Should address important issues
- Optional to fix minor issues now

**Sign-off:**
- Code Author: [Name] - [Date]
- Code Reviewer: [Name] - [Date]
- Tech Lead: [Name] - [Date]
```

---

## Review Commands

```bash
# Run code style check
vendor/bin/phpcs --standard=PSR12 app/

# Run static analysis
vendor/bin/phpstan analyse app/ --level=5

# Run tests with coverage
php artisan test --coverage --min=80

# Run security audit
composer audit

# Format code
vendor/bin/pint

# Check for N+1 queries
php artisan debugbar:clear
```

---

## Quick Review Checklist

```markdown
## 5-Minute Quick Check

### Must Check
- [ ] ✅ Code works (tests pass)
- [ ] ✅ No security vulnerabilities
- [ ] ✅ Follows PSR-12
- [ ] ✅ Laravel conventions followed
- [ ] ✅ No obvious bugs

### Should Check
- [ ] ⚠️ Performance optimized
- [ ] ⚠️ Test coverage adequate
- [ ] ⚠️ Documentation updated
- [ ] ⚠️ Error handling proper

### Red Flags (Reject if found)
- [ ] 🔴 Security vulnerabilities
- [ ] 🔴 Hardcoded credentials
- [ ] 🔴 SQL injection vectors
- [ ] 🔴 No tests for critical logic
- [ ] 🔴 Breaks existing functionality
```

---

## Common Issues & Solutions

### Issue 1: SQL Injection
```php
// ❌ Bad
DB::select("SELECT * FROM users WHERE id = $id");

// ✅ Good
User::find($id);
// or
DB::select("SELECT * FROM users WHERE id = ?", [$id]);
```

### Issue 2: N+1 Query
```php
// ❌ Bad
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->author->name; // N+1
}

// ✅ Good
$posts = Post::with('author')->get();
foreach ($posts as $post) {
    echo $post->author->name;
}
```

### Issue 3: Mass Assignment
```php
// ❌ Bad
User::create($request->all()); // Vulnerable

// ✅ Good
User::create($request->validated());
// or define $fillable in model
```

### Issue 4: Missing Type Hints
```php
// ❌ Bad
public function getUser($id) {
    return User::find($id);
}

// ✅ Good
public function getUser(int $id): ?User {
    return User::find($id);
}
```

---

## Tham khảo

- [PSR-12: Extended Coding Style](https://www.php-fig.org/psr/psr-12/)
- [Laravel Best Practices](https://github.com/alexeymezenin/laravel-best-practices)
- [OWASP PHP Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/PHP_Configuration_Cheat_Sheet.html)
- [Clean Code PHP](https://github.com/jupeter/clean-code-php)
- [Code Review Best Practices](https://google.github.io/eng-practices/review/)
