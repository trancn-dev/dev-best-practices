# Rule: Testing Standards & Best Practices

## Intent
This rule defines testing standards for Laravel applications. Copilot must follow these principles when generating or reviewing test code to ensure high-quality, maintainable, and comprehensive test coverage.

## Scope
Applies to all test files in `tests/` directory, including Unit, Feature, and Integration tests.

---

## 1. Test Structure & Organization

### Directory Structure
```
tests/
├── Unit/              # Pure logic tests (no Laravel dependencies)
│   ├── Services/
│   ├── Actions/
│   └── Helpers/
├── Feature/           # HTTP tests with database
│   ├── Auth/
│   ├── Api/
│   └── Controllers/
└── TestCase.php       # Base test class
```

### Test Naming Convention
- ✅ Test class: `{ClassName}Test.php`
- ✅ Test method: `test_descriptive_name_of_what_is_tested()` or `it_descriptive_name()`
- ✅ Be descriptive and specific
- ❌ Avoid generic names like `test1()`, `testBasic()`

**Example:**
```php
// ✅ Good naming
class UserServiceTest extends TestCase
{
    public function test_can_create_user_with_valid_data(): void
    {
        // ...
    }

    public function test_throws_exception_when_email_already_exists(): void
    {
        // ...
    }
}

// ❌ Bad naming
class UserTest extends TestCase
{
    public function test1(): void
    {
        // What does this test?
    }
}
```

---

## 2. Test Anatomy - Arrange-Act-Assert (AAA)

### Always follow AAA pattern
```php
public function test_user_can_update_profile(): void
{
    // Arrange - Set up test data and dependencies
    $user = User::factory()->create();
    $newData = [
        'name' => 'Updated Name',
        'bio' => 'New bio',
    ];

    // Act - Execute the action being tested
    $this->actingAs($user)
        ->putJson("/api/profile", $newData);

    // Assert - Verify the expected outcome
    $this->assertDatabaseHas('users', [
        'id' => $user->id,
        'name' => 'Updated Name',
    ]);
}
```

---

## 3. Unit Tests

### Characteristics
- ✅ Test single unit of code (method/function)
- ✅ No external dependencies (database, API, filesystem)
- ✅ Fast execution (< 100ms)
- ✅ Use mocking for dependencies

**Example:**
```php
namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Services\PriceCalculator;
use App\Repositories\ProductRepository;
use Mockery;

class PriceCalculatorTest extends TestCase
{
    public function test_calculates_total_price_with_tax(): void
    {
        // Arrange
        $repository = Mockery::mock(ProductRepository::class);
        $repository->shouldReceive('getPrice')
            ->with(1)
            ->andReturn(100.00);

        $calculator = new PriceCalculator($repository);

        // Act
        $total = $calculator->calculateTotal(1, $quantity = 2, $taxRate = 0.1);

        // Assert
        $this->assertEquals(220.00, $total); // (100 * 2) + 10% tax
    }

    public function test_throws_exception_for_negative_quantity(): void
    {
        $repository = Mockery::mock(ProductRepository::class);
        $calculator = new PriceCalculator($repository);

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Quantity must be positive');

        $calculator->calculateTotal(1, -5, 0.1);
    }
}
```

---

## 4. Feature Tests

### Characteristics
- ✅ Test complete user flows
- ✅ Include database interactions
- ✅ Test HTTP requests/responses
- ✅ Use Laravel's testing helpers

**Example:**
```php
namespace Tests\Feature\Auth;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

class RegistrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_with_valid_data(): void
    {
        // Arrange
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
                'data' => ['id', 'name', 'email', 'created_at'],
                'token',
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }

    public function test_registration_fails_with_duplicate_email(): void
    {
        // Arrange
        User::factory()->create(['email' => 'existing@example.com']);

        $userData = [
            'name' => 'Jane Doe',
            'email' => 'existing@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        // Act
        $response = $this->postJson('/api/register', $userData);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }
}
```

---

## 5. Test Data Management

### Use Factories
- ✅ Use factories for test data creation
- ✅ Create specific states with factory states
- ✅ Keep factories simple and focused

**Example:**
```php
// database/factories/UserFactory.php
class UserFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'password' => Hash::make('password'),
            'email_verified_at' => now(),
        ];
    }

    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }

    public function admin(): static
    {
        return $this->state(fn (array $attributes) => [
            'role' => 'admin',
        ]);
    }
}

// Usage in tests
$user = User::factory()->create();
$unverified = User::factory()->unverified()->create();
$admin = User::factory()->admin()->create();
$users = User::factory()->count(10)->create();
```

### Database Management
```php
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\DatabaseTransactions;

class UserTest extends TestCase
{
    // ✅ Option 1: Refresh entire database before each test
    use RefreshDatabase;

    // ✅ Option 2: Use transactions (faster but may not work with all tests)
    // use DatabaseTransactions;
}
```

---

## 6. Mocking & Stubbing

### When to Mock
- ✅ External APIs
- ✅ Email sending
- ✅ File system operations
- ✅ Time-dependent operations
- ✅ Payment gateways

**Example:**
```php
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use App\Mail\WelcomeEmail;

public function test_sends_welcome_email_on_registration(): void
{
    // Mock email sending
    Mail::fake();

    $response = $this->postJson('/api/register', [
        'name' => 'John',
        'email' => 'john@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    Mail::assertSent(WelcomeEmail::class, function ($mail) {
        return $mail->hasTo('john@example.com');
    });
}

public function test_fetches_exchange_rate_from_api(): void
{
    // Mock HTTP request
    Http::fake([
        'api.exchangerate.com/*' => Http::response([
            'rate' => 1.2,
        ], 200),
    ]);

    $service = new ExchangeRateService();
    $rate = $service->getRate('USD', 'EUR');

    $this->assertEquals(1.2, $rate);
}
```

---

## 7. Assertions

### Common Assertions
```php
// Response assertions
$response->assertStatus(200);
$response->assertOk();
$response->assertCreated();
$response->assertNoContent();
$response->assertNotFound();
$response->assertForbidden();
$response->assertUnauthorized();

// JSON assertions
$response->assertJson(['key' => 'value']);
$response->assertJsonStructure(['data' => ['id', 'name']]);
$response->assertJsonFragment(['name' => 'John']);
$response->assertJsonCount(10, 'data');

// Database assertions
$this->assertDatabaseHas('users', ['email' => 'test@example.com']);
$this->assertDatabaseMissing('users', ['email' => 'deleted@example.com']);
$this->assertDatabaseCount('users', 5);
$this->assertSoftDeleted('users', ['id' => 1]);

// Model assertions
$this->assertTrue($user->exists);
$this->assertInstanceOf(User::class, $user);
$this->assertEquals('John', $user->name);
$this->assertNull($user->deleted_at);

// Collection assertions
$this->assertCount(3, $users);
$this->assertContains('John', $users->pluck('name'));
```

---

## 8. Test Coverage Requirements

### Coverage Goals
- ✅ Overall coverage: >= 80%
- ✅ Critical business logic: 100%
- ✅ Controllers: >= 80%
- ✅ Services/Actions: >= 90%
- ✅ Models: >= 85%

### Generate Coverage Report
```bash
# Run tests with coverage
php artisan test --coverage

# Generate HTML report
php artisan test --coverage-html coverage/

# With minimum threshold
php artisan test --coverage --min=80
```

### What to Test
- ✅ Happy path (expected success scenarios)
- ✅ Edge cases (boundary conditions)
- ✅ Error handling (exceptions, validation failures)
- ✅ Authorization (who can access what)
- ✅ Business logic (calculations, transformations)

### What NOT to Test
- ❌ Framework functionality (Laravel core)
- ❌ Third-party package internals
- ❌ Trivial getters/setters
- ❌ Database schema (covered by migrations)

---

## 9. Test Performance

### Keep Tests Fast
- ✅ Use in-memory SQLite for faster tests
- ✅ Mock external services
- ✅ Minimize database operations
- ✅ Use `RefreshDatabase` instead of migrations
- ✅ Run tests in parallel

**Configuration:**
```php
// phpunit.xml
<php>
    <env name="DB_CONNECTION" value="sqlite"/>
    <env name="DB_DATABASE" value=":memory:"/>
</php>
```

**Run parallel tests:**
```bash
php artisan test --parallel
```

---

## 10. Testing Best Practices

### DO's ✅
```php
// ✅ Test one thing per test
public function test_validates_email_format(): void
{
    $response = $this->postJson('/api/register', [
        'email' => 'invalid-email',
    ]);

    $response->assertJsonValidationErrors(['email']);
}

// ✅ Use descriptive variable names
$authenticatedUser = User::factory()->create();
$existingPost = Post::factory()->create();

// ✅ Test edge cases
public function test_handles_empty_cart_checkout(): void
{
    $user = User::factory()->create();

    $response = $this->actingAs($user)
        ->postJson('/api/checkout');

    $response->assertStatus(422)
        ->assertJson(['error' => 'Cart is empty']);
}

// ✅ Use type hints
public function test_creates_order(User $user, Product $product): void
{
    // ...
}
```

### DON'Ts ❌
```php
// ❌ Testing multiple things in one test
public function test_user_crud(): void
{
    // Create
    $user = User::create([...]);
    $this->assertDatabaseHas('users', [...]);

    // Update
    $user->update([...]);
    $this->assertEquals(...);

    // Delete
    $user->delete();
    $this->assertSoftDeleted(...);
}

// ❌ Relying on previous test state
public function test_step_1(): void
{
    $this->user = User::create([...]); // Bad!
}

public function test_step_2(): void
{
    $this->user->update([...]); // Depends on test_step_1
}

// ❌ Testing implementation details
public function test_user_service_calls_repository(): void
{
    $repo = Mockery::mock(UserRepository::class);
    $repo->shouldReceive('save')->once(); // Testing implementation, not behavior
    // ...
}
```

---

## 11. Test Documentation

### Document Complex Tests
```php
/**
 * Test that the payment refund process correctly:
 * 1. Validates refund eligibility (within 30 days)
 * 2. Processes refund through payment gateway
 * 3. Updates order status
 * 4. Sends refund confirmation email
 * 5. Creates audit log entry
 */
public function test_complete_refund_process(): void
{
    // Arrange
    $order = Order::factory()
        ->paid()
        ->create(['created_at' => now()->subDays(15)]);

    Mail::fake();

    // Act
    $response = $this->postJson("/api/orders/{$order->id}/refund");

    // Assert
    $response->assertOk();
    $this->assertEquals('refunded', $order->fresh()->status);
    Mail::assertSent(RefundConfirmationMail::class);
}
```

---

## 12. Continuous Integration

### GitHub Actions Example
```yaml
# .github/workflows/tests.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: mbstring, pdo_sqlite

      - name: Install Dependencies
        run: composer install --prefer-dist --no-progress

      - name: Run Tests
        run: php artisan test --coverage --min=80

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
```

---

## 13. Testing Checklist

### Before Committing
- [ ] All tests pass locally
- [ ] New features have tests
- [ ] Edge cases covered
- [ ] Error scenarios tested
- [ ] Coverage >= 80%
- [ ] No flaky tests
- [ ] Tests run in < 30 seconds (for small projects)

### Code Review
- [ ] Tests are clear and readable
- [ ] Test names describe what they test
- [ ] No duplicate test logic
- [ ] Mocks are used appropriately
- [ ] Assertions are meaningful

---

## 14. Common Testing Patterns

### Testing Authentication
```php
public function test_unauthenticated_user_cannot_access_dashboard(): void
{
    $response = $this->getJson('/api/dashboard');
    $response->assertUnauthorized();
}

public function test_authenticated_user_can_access_dashboard(): void
{
    $user = User::factory()->create();

    $response = $this->actingAs($user)
        ->getJson('/api/dashboard');

    $response->assertOk();
}
```

### Testing Authorization
```php
public function test_user_can_only_update_own_post(): void
{
    $user = User::factory()->create();
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($user)
        ->putJson("/api/posts/{$post->id}", ['title' => 'Hacked']);

    $response->assertForbidden();
}
```

### Testing Validation
```php
public function test_registration_requires_all_fields(): void
{
    $response = $this->postJson('/api/register', []);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['name', 'email', 'password']);
}
```

### Testing Events
```php
use Illuminate\Support\Facades\Event;
use App\Events\UserRegistered;

public function test_dispatches_user_registered_event(): void
{
    Event::fake();

    $this->postJson('/api/register', [
        'name' => 'John',
        'email' => 'john@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    Event::assertDispatched(UserRegistered::class);
}
```

---

## 15. Test Maintenance

### Refactor Tests
- ✅ Extract common setup to `setUp()` method
- ✅ Use helper methods for repeated logic
- ✅ Keep tests DRY but readable

**Example:**
```php
class PostTest extends TestCase
{
    use RefreshDatabase;

    private User $author;

    protected function setUp(): void
    {
        parent::setUp();
        $this->author = User::factory()->create();
    }

    private function createPost(array $attributes = []): Post
    {
        return Post::factory()
            ->for($this->author)
            ->create($attributes);
    }

    public function test_author_can_update_post(): void
    {
        $post = $this->createPost();

        $response = $this->actingAs($this->author)
            ->putJson("/api/posts/{$post->id}", ['title' => 'Updated']);

        $response->assertOk();
    }
}
```

---

## References

- [Laravel Testing Documentation](https://laravel.com/docs/testing)
- [PHPUnit Manual](https://phpunit.de/manual/current/en/index.html)
- [Pest PHP Documentation](https://pestphp.com/)
- [Testing Best Practices](https://github.com/goldbergyoni/javascript-testing-best-practices)
- [Test Driven Development (TDD)](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
