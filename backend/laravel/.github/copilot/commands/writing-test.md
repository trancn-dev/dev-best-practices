---
type: command
name: writing-test
version: 2.0
scope: project
integration:
  - laravel
  - testing
  - phpunit
---

# Command: Writing Test

## Mục tiêu
Lệnh `writing-test` được sử dụng để **viết test cases** cho feature mới hoặc code hiện có.

Mục tiêu chính:
- Đảm bảo test coverage >= 80%.
- Test all critical paths, edge cases, và error scenarios.
- Tạo test có thể maintain và mở rộng.
- Document test scenarios rõ ràng.

---

## Quy trình viết test

### 1. Gather Context

**Câu hỏi cần trả lời:**

#### A. Feature Information
- Feature name và branch?
- Summary của thay đổi (link tới design & requirements docs)?
- Target environment (backend, frontend, full-stack)?

#### B. Existing Test Suites
- Unit tests hiện có?
- Integration tests hiện có?
- E2E tests hiện có?
- Any flaky hoặc slow tests cần tránh?

#### C. Coverage Goals
- Coverage target: [X]%
- Priority areas cần test?
- Known edge cases?

---

### 2. Analyze Testing Template

Review `docs/ai/testing/feature-{name}.md` (nếu có) và xác định:

- Required sections (unit, integration, manual verification)
- Success criteria từ requirements & design docs
- Edge cases từ requirements
- Mocks/stubs hoặc fixtures đã available

---

### 3. Unit Tests (Aim for 100% coverage)

#### A. Identify Test Scenarios

Cho mỗi module/function, list:

```markdown
## Unit Test Plan: [ClassName/FunctionName]

### Happy Path Scenarios
1. [Scenario 1]: When [condition], expect [result]
2. [Scenario 2]: When [condition], expect [result]

### Edge Cases
1. [Edge case 1]: When [unusual condition], expect [result]
2. [Edge case 2]: When [boundary condition], expect [result]

### Error Handling
1. [Error 1]: When [error condition], expect [exception/error response]
2. [Error 2]: When [validation fails], expect [validation error]
```

#### B. Write Unit Tests

**Template cho Laravel/PHPUnit:**

```php
<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Services\UserService;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserServiceTest extends TestCase
{
    use RefreshDatabase;

    protected UserService $userService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->userService = app(UserService::class);
    }

    /** @test */
    public function it_can_create_user_with_valid_data(): void
    {
        // Arrange
        $data = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
        ];

        // Act
        $user = $this->userService->create($data);

        // Assert
        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('John Doe', $user->name);
        $this->assertEquals('john@example.com', $user->email);
        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }

    /** @test */
    public function it_throws_exception_when_email_already_exists(): void
    {
        // Arrange
        User::factory()->create(['email' => 'john@example.com']);
        $data = [
            'name' => 'Jane Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
        ];

        // Assert & Act
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Email already exists');

        $this->userService->create($data);
    }

    /** @test */
    public function it_validates_email_format(): void
    {
        // Arrange
        $data = [
            'name' => 'John Doe',
            'email' => 'invalid-email',
            'password' => 'password123',
        ];

        // Assert & Act
        $this->expectException(\InvalidArgumentException::class);

        $this->userService->create($data);
    }
}
```

#### C. Coverage Checklist

- [ ] All public methods tested
- [ ] All branches covered (if/else, switch/case)
- [ ] Exception handling tested
- [ ] Edge cases covered
- [ ] Boundary values tested
- [ ] Null/empty input tested

---

### 4. Integration Tests

#### A. Identify Integration Scenarios

```markdown
## Integration Test Plan: [Feature Name]

### Critical Flows
1. **User Registration Flow**
   - Input: User data via API
   - Process: Validation → Create user → Send email → Return response
   - Output: 201 Created with user data
   - Dependencies: Database, Mail service

2. **Authentication Flow**
   - Input: Email + Password
   - Process: Validate → Check credentials → Generate token
   - Output: 200 OK with token
   - Dependencies: Database, Cache
```

#### B. Write Integration Tests

**Template cho Laravel Feature Test:**

```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use App\Mail\WelcomeEmail;

class UserRegistrationTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_register_with_valid_data(): void
    {
        // Arrange
        Mail::fake();

        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        // Act
        $response = $this->postJson('/api/register', $userData);

        // Assert
        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'name',
                    'email',
                    'created_at',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);

        Mail::assertSent(WelcomeEmail::class, function ($mail) use ($userData) {
            return $mail->hasTo($userData['email']);
        });
    }

    /** @test */
    public function registration_fails_with_duplicate_email(): void
    {
        // Arrange
        User::factory()->create(['email' => 'john@example.com']);

        $userData = [
            'name' => 'Jane Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        // Act
        $response = $this->postJson('/api/register', $userData);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /** @test */
    public function registration_requires_all_fields(): void
    {
        // Act
        $response = $this->postJson('/api/register', []);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'email', 'password']);
    }
}
```

#### C. Setup/Teardown Strategy

```php
protected function setUp(): void
{
    parent::setUp();

    // Setup test database
    $this->artisan('migrate:fresh');

    // Seed necessary data
    $this->seed(TestDataSeeder::class);

    // Mock external services
    $this->mockExternalAPI();
}

protected function tearDown(): void
{
    // Clean up resources
    Cache::flush();

    parent::tearDown();
}

private function mockExternalAPI(): void
{
    Http::fake([
        'api.example.com/*' => Http::response([
            'status' => 'success',
        ], 200),
    ]);
}
```

---

### 5. Coverage Strategy

#### A. Run Coverage Report

```bash
# Với PHPUnit
php artisan test --coverage

# Với coverage HTML report
php artisan test --coverage-html coverage/

# Với minimum threshold
php artisan test --coverage --min=80
```

#### B. Coverage Analysis

```markdown
## Coverage Report

### Overall Coverage: 85%

### By Directory
| Directory | Coverage | Status |
|-----------|----------|--------|
| app/Services | 92% | ✅ Good |
| app/Actions | 88% | ✅ Good |
| app/Http/Controllers | 78% | ⚠️ Below target |
| app/Models | 95% | ✅ Excellent |

### Files Needing Coverage
1. `app/Http/Controllers/UserController.php` - 65%
   - Missing: `destroy()` method
   - Missing: Error handling in `update()`

2. `app/Services/PaymentService.php` - 70%
   - Missing: Refund flow
   - Missing: Webhook validation
```

#### C. Improve Coverage

**Suggest additional tests:**

```markdown
### Additional Tests Needed

1. **UserController::destroy()**
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

2. **PaymentService refund flow**
   ```php
   /** @test */
   public function it_can_process_refund(): void
   {
       // Test implementation
   }
   ```
```

---

### 6. Manual & Exploratory Testing

#### A. Manual Test Checklist

```markdown
## Manual Testing Checklist

### UI/UX Testing
- [ ] Forms display correctly
- [ ] Validation messages clear and helpful
- [ ] Loading states shown appropriately
- [ ] Success/error notifications work
- [ ] Responsive on mobile/tablet/desktop

### Accessibility
- [ ] Keyboard navigation works
- [ ] Screen reader compatible
- [ ] Proper ARIA labels
- [ ] Color contrast meets WCAG standards

### Browser Compatibility
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)

### Error Handling
- [ ] Network errors handled gracefully
- [ ] Server errors show user-friendly messages
- [ ] Validation errors highlighted correctly
- [ ] 404/403/500 pages work
```

#### B. Exploratory Testing Scenarios

```markdown
## Exploratory Testing

### Session 1: User Registration (30 min)
**Goal:** Find edge cases in registration flow

**Scenarios to explore:**
- Register with very long name (>255 chars)
- Register with special characters in name
- Register with + in email (john+test@example.com)
- Multiple rapid registration attempts
- Browser back button during registration
- Session timeout during registration

**Findings:**
- [Document any issues found]
```

---

### 7. Update Documentation & TODOs

#### A. Test Documentation

Create `docs/ai/testing/feature-{name}.md`:

```markdown
# Testing: [Feature Name]

**Feature:** [Name]
**Branch:** feature/[name]
**Date:** [YYYY-MM-DD]
**Coverage:** [X]%

---

## Test Summary

### Unit Tests
- Total: [X] tests
- Passed: [Y] tests
- Coverage: [Z]%

### Integration Tests
- Total: [X] tests
- Passed: [Y] tests
- Coverage: [Z]%

### Manual Tests
- Total scenarios: [X]
- Passed: [Y]
- Issues found: [Z]

---

## Test Cases

### Unit Test Cases
1. **Test:** `it_can_create_user_with_valid_data`
   - **Purpose:** Verify user creation with valid input
   - **Status:** ✅ Passed

2. **Test:** `it_throws_exception_when_email_already_exists`
   - **Purpose:** Verify duplicate email handling
   - **Status:** ✅ Passed

### Integration Test Cases
[List integration tests...]

---

## Known Issues

1. **Issue:** Slow test in `UserServiceTest::it_sends_welcome_email`
   - **Impact:** Test suite takes 2s longer
   - **Solution:** Mock email service instead of real send
   - **Status:** ⏳ Pending

---

## TODO

- [ ] Add E2E tests for checkout flow
- [ ] Improve coverage in PaymentController (currently 70%)
- [ ] Refactor slow tests using database transactions
```

#### B. Update Test TODOs

In your test files:

```php
/**
 * @test
 * @todo Add test for concurrent user creation
 * @todo Test with different timezones
 */
public function it_handles_concurrent_requests(): void
{
    $this->markTestIncomplete('Need to implement concurrent testing');
}
```

---

## Test Best Practices

### Do's ✅

- **Arrange-Act-Assert pattern**: Tổ chức test rõ ràng
- **One assertion per test**: Mỗi test kiểm tra một điều
- **Descriptive test names**: `it_can_create_user_with_valid_data` thay vì `test1`
- **Use factories**: Tạo test data dễ dàng và consistent
- **Mock external services**: Không phụ thuộc vào external API/database
- **Test isolation**: Mỗi test độc lập, không ảnh hưởng lẫn nhau
- **Fast tests**: Aim for <100ms per test

### Don'ts ❌

- **Don't test framework code**: Không test code của Laravel
- **Don't test third-party packages**: Trust package tests
- **Don't use production data**: Luôn dùng test data
- **Don't skip cleanup**: Luôn cleanup sau test
- **Don't test implementation details**: Test behavior, không phải implementation
- **Don't ignore flaky tests**: Fix hoặc remove flaky tests

---

## Output Template

```markdown
## Test Writing Summary

**Feature:** [Name]
**Branch:** [branch-name]
**Date:** [YYYY-MM-DD]

### Tests Added
- Unit tests: [X] tests
- Integration tests: [Y] tests
- Total: [Z] tests

### Coverage
- Before: [A]%
- After: [B]%
- Improvement: +[C]%

### Files Modified
- `tests/Unit/UserServiceTest.php` - Added 5 tests
- `tests/Feature/UserRegistrationTest.php` - Added 3 tests

### Test Results
✅ All [Z] tests passed
⏱️ Test suite runtime: [X]s

### Next Steps
- [ ] Review with team
- [ ] Add to CI pipeline
- [ ] Update documentation

📄 Test documentation: `docs/ai/testing/feature-[name].md`
```

---

## Tools & Commands

```bash
# Run all tests
php artisan test

# Run specific test file
php artisan test tests/Unit/UserServiceTest.php

# Run specific test method
php artisan test --filter=it_can_create_user_with_valid_data

# Run with coverage
php artisan test --coverage --min=80

# Run parallel tests (faster)
php artisan test --parallel

# Run tests và stop on failure
php artisan test --stop-on-failure

# Watch mode (re-run on file changes)
php artisan test --watch
```

---

## Tham khảo

- [Laravel Testing Documentation](https://laravel.com/docs/testing)
- [PHPUnit Best Practices](https://phpunit.de/best-practices.html)
- [Test Driven Development](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Testing Best Practices](https://github.com/goldbergyoni/javascript-testing-best-practices)
