# Testing Standards & Best Practices

This document describes the testing strategies, patterns, and best practices for the Laravel DevKit project.

---

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Test Types](#test-types)
3. [Testing Structure](#testing-structure)
4. [Unit Testing](#unit-testing)
5. [Feature Testing](#feature-testing)
6. [Integration Testing](#integration-testing)
7. [Test Doubles](#test-doubles)
8. [Database Testing](#database-testing)
9. [API Testing](#api-testing)
10. [Testing Best Practices](#testing-best-practices)

---

## Testing Philosophy

### Test Pyramid

```
        /\
       /  \        E2E Tests (Few)
      /────\
     /      \      Integration Tests (Some)
    /────────\
   /          \    Unit Tests (Many)
  /────────────\
```

### Testing Principles

1. **Fast**: Tests should run quickly
2. **Independent**: Tests don't depend on each other
3. **Repeatable**: Same result every time
4. **Self-Validating**: Pass or fail, no manual verification
5. **Timely**: Written alongside or before code (TDD)

### Test Coverage Goals

- **Minimum**: 70% code coverage
- **Target**: 80% code coverage
- **Critical paths**: 100% coverage (authentication, payments, etc.)

---

## Test Types

### 1. Unit Tests
Test individual classes/methods in isolation.

**Location**: `tests/Unit/`

**Example**:
```php
tests/Unit/Services/UserServiceTest.php
tests/Unit/ValueObjects/EmailTest.php
```

### 2. Feature Tests
Test application features through HTTP requests.

**Location**: `tests/Feature/`

**Example**:
```php
tests/Feature/UserManagementTest.php
tests/Feature/ProjectCreationTest.php
```

### 3. Integration Tests
Test multiple components working together.

**Location**: `tests/Integration/`

**Example**:
```php
tests/Integration/UserRepositoryTest.php
tests/Integration/PaymentProcessingTest.php
```

---

## Testing Structure

### Directory Structure

```
tests/
├── TestCase.php                    # Base test case
├── CreatesApplication.php          # Application bootstrap
│
├── Unit/                          # Unit tests
│   ├── Services/
│   │   ├── UserServiceTest.php
│   │   └── ProjectServiceTest.php
│   ├── ValueObjects/
│   │   ├── EmailTest.php
│   │   └── MoneyTest.php
│   └── Actions/
│       └── CreateUserActionTest.php
│
├── Feature/                       # Feature tests
│   ├── Auth/
│   │   ├── LoginTest.php
│   │   └── RegistrationTest.php
│   ├── Api/
│   │   ├── UserApiTest.php
│   │   └── ProjectApiTest.php
│   └── Web/
│       ├── DashboardTest.php
│       └── ProjectManagementTest.php
│
└── Integration/                   # Integration tests
    ├── Repositories/
    │   └── UserRepositoryTest.php
    └── External/
        └── PaymentGatewayTest.php
```

### Base Test Case

```php
// tests/TestCase.php
namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;

    protected function setUp(): void
    {
        parent::setUp();

        // Default setup for all tests
        $this->withoutVite();
    }

    protected function signIn($user = null)
    {
        $user = $user ?: User::factory()->create();
        $this->actingAs($user);
        return $user;
    }

    protected function signInAdmin()
    {
        return $this->signIn(User::factory()->admin()->create());
    }
}
```

---

## Unit Testing

### Testing Services

```php
namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Services\UserService;
use App\Repositories\UserRepository;
use App\Services\NotificationService;
use Mockery;

class UserServiceTest extends TestCase
{
    private UserService $userService;
    private $userRepository;
    private $notificationService;

    protected function setUp(): void
    {
        parent::setUp();

        // Create mocks
        $this->userRepository = Mockery::mock(UserRepository::class);
        $this->notificationService = Mockery::mock(NotificationService::class);

        // Inject mocks
        $this->userService = new UserService(
            $this->userRepository,
            $this->notificationService
        );
    }

    public function test_can_create_user()
    {
        // Arrange
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
        ];

        $expectedUser = new User($userData);

        $this->userRepository
            ->shouldReceive('create')
            ->once()
            ->with(Mockery::on(function ($arg) use ($userData) {
                return $arg['name'] === $userData['name']
                    && $arg['email'] === $userData['email'];
            }))
            ->andReturn($expectedUser);

        $this->notificationService
            ->shouldReceive('sendWelcomeEmail')
            ->once()
            ->with($expectedUser);

        // Act
        $user = $this->userService->createUser($userData);

        // Assert
        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('John Doe', $user->name);
        $this->assertEquals('john@example.com', $user->email);
    }

    public function test_cannot_suspend_admin_user()
    {
        // Arrange
        $adminUser = User::factory()->make(['role' => 'admin']);

        // Act & Assert
        $this->expectException(CannotSuspendAdminException::class);
        $this->userService->suspendUser($adminUser, 'Test reason');
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }
}
```

### Testing Value Objects

```php
namespace Tests\Unit\ValueObjects;

use Tests\TestCase;
use App\ValueObjects\Email;
use App\Exceptions\InvalidEmailException;

class EmailTest extends TestCase
{
    public function test_can_create_valid_email()
    {
        $email = new Email('john@example.com');

        $this->assertEquals('john@example.com', $email->getValue());
    }

    public function test_email_is_normalized_to_lowercase()
    {
        $email = new Email('John@EXAMPLE.COM');

        $this->assertEquals('john@example.com', $email->getValue());
    }

    public function test_invalid_email_throws_exception()
    {
        $this->expectException(InvalidEmailException::class);

        new Email('invalid-email');
    }

    public function test_can_get_domain_from_email()
    {
        $email = new Email('john@example.com');

        $this->assertEquals('example.com', $email->getDomain());
    }

    /**
     * @dataProvider invalidEmailProvider
     */
    public function test_rejects_invalid_emails(string $invalidEmail)
    {
        $this->expectException(InvalidEmailException::class);

        new Email($invalidEmail);
    }

    public function invalidEmailProvider(): array
    {
        return [
            ['invalid'],
            ['@example.com'],
            ['user@'],
            [''],
            ['user name@example.com'],
        ];
    }
}
```

---

## Feature Testing

### Testing Authentication

```php
namespace Tests\Feature\Auth;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

class LoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_with_valid_credentials()
    {
        // Arrange
        $user = User::factory()->create([
            'email' => 'john@example.com',
            'password' => bcrypt('password'),
        ]);

        // Act
        $response = $this->post('/login', [
            'email' => 'john@example.com',
            'password' => 'password',
        ]);

        // Assert
        $response->assertRedirect('/dashboard');
        $this->assertAuthenticatedAs($user);
    }

    public function test_user_cannot_login_with_invalid_password()
    {
        $user = User::factory()->create([
            'email' => 'john@example.com',
            'password' => bcrypt('password'),
        ]);

        $response = $this->post('/login', [
            'email' => 'john@example.com',
            'password' => 'wrong-password',
        ]);

        $response->assertSessionHasErrors('email');
        $this->assertGuest();
    }

    public function test_user_is_redirected_when_already_authenticated()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->get('/login');

        $response->assertRedirect('/dashboard');
    }

    public function test_login_is_throttled_after_too_many_attempts()
    {
        $user = User::factory()->create();

        // Make 5 failed login attempts
        for ($i = 0; $i < 5; $i++) {
            $this->post('/login', [
                'email' => $user->email,
                'password' => 'wrong-password',
            ]);
        }

        // 6th attempt should be throttled
        $response = $this->post('/login', [
            'email' => $user->email,
            'password' => 'wrong-password',
        ]);

        $response->assertStatus(429); // Too Many Requests
    }
}
```

### Testing CRUD Operations

```php
namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Project;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ProjectManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_create_project()
    {
        $user = $this->signIn();

        $projectData = [
            'name' => 'Test Project',
            'description' => 'Test description',
            'status' => 'draft',
        ];

        $response = $this->post('/projects', $projectData);

        $response->assertRedirect();
        $this->assertDatabaseHas('projects', [
            'name' => 'Test Project',
            'user_id' => $user->id,
        ]);
    }

    public function test_guest_cannot_create_project()
    {
        $response = $this->post('/projects', [
            'name' => 'Test Project',
        ]);

        $response->assertRedirect('/login');
    }

    public function test_user_can_view_own_project()
    {
        $user = $this->signIn();
        $project = Project::factory()->create(['user_id' => $user->id]);

        $response = $this->get("/projects/{$project->id}");

        $response->assertOk();
        $response->assertSee($project->name);
    }

    public function test_user_cannot_view_others_project()
    {
        $this->signIn();
        $otherProject = Project::factory()->create();

        $response = $this->get("/projects/{$otherProject->id}");

        $response->assertForbidden();
    }

    public function test_user_can_update_own_project()
    {
        $user = $this->signIn();
        $project = Project::factory()->create(['user_id' => $user->id]);

        $response = $this->put("/projects/{$project->id}", [
            'name' => 'Updated Name',
            'description' => 'Updated description',
            'status' => 'active',
        ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('projects', [
            'id' => $project->id,
            'name' => 'Updated Name',
        ]);
    }

    public function test_user_can_delete_own_project()
    {
        $user = $this->signIn();
        $project = Project::factory()->create(['user_id' => $user->id]);

        $response = $this->delete("/projects/{$project->id}");

        $response->assertRedirect();
        $this->assertSoftDeleted('projects', ['id' => $project->id]);
    }

    public function test_project_name_is_required()
    {
        $this->signIn();

        $response = $this->post('/projects', [
            'description' => 'Description without name',
        ]);

        $response->assertSessionHasErrors('name');
    }
}
```

---

## Integration Testing

### Testing Repositories

```php
namespace Tests\Integration\Repositories;

use Tests\TestCase;
use App\Models\User;
use App\Repositories\UserRepository;
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserRepositoryTest extends TestCase
{
    use RefreshDatabase;

    private UserRepository $repository;

    protected function setUp(): void
    {
        parent::setUp();
        $this->repository = new UserRepository();
    }

    public function test_can_create_user()
    {
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password'),
        ];

        $user = $this->repository->create($userData);

        $this->assertInstanceOf(User::class, $user);
        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }

    public function test_can_find_user_by_email()
    {
        $user = User::factory()->create(['email' => 'john@example.com']);

        $foundUser = $this->repository->findByEmail('john@example.com');

        $this->assertNotNull($foundUser);
        $this->assertEquals($user->id, $foundUser->id);
    }

    public function test_can_get_active_users()
    {
        User::factory()->count(3)->create(['status' => 'active']);
        User::factory()->count(2)->create(['status' => 'suspended']);

        $activeUsers = $this->repository->getActiveUsers();

        $this->assertCount(3, $activeUsers);
    }
}
```

---

## Test Doubles

### Mocking

```php
use Mockery;

$mock = Mockery::mock(UserRepository::class);
$mock->shouldReceive('find')
     ->once()
     ->with(1)
     ->andReturn(new User());
```

### Spying

```php
$spy = Mockery::spy(NotificationService::class);

// ... code that uses the spy

$spy->shouldHaveReceived('sendEmail')->once();
```

### Faking

```php
// Mail fake
Mail::fake();

// ... code that sends mail

Mail::assertSent(WelcomeEmail::class, function ($mail) use ($user) {
    return $mail->hasTo($user->email);
});

// Queue fake
Queue::fake();

// ... code that dispatches jobs

Queue::assertPushed(ProcessPayment::class);

// Event fake
Event::fake();

// ... code that fires events

Event::assertDispatched(UserCreated::class);

// Storage fake
Storage::fake('public');

// ... code that stores files

Storage::disk('public')->assertExists('avatar.jpg');
```

---

## Database Testing

### Using RefreshDatabase

```php
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserTest extends TestCase
{
    use RefreshDatabase;

    public function test_example()
    {
        // Database is migrated and refreshed before each test
    }
}
```

### Using Transactions (Faster)

```php
use Illuminate\Foundation\Testing\DatabaseTransactions;

class UserTest extends TestCase
{
    use DatabaseTransactions;

    public function test_example()
    {
        // Changes are rolled back after each test
    }
}
```

### Database Assertions

```php
// Assert record exists
$this->assertDatabaseHas('users', [
    'email' => 'john@example.com',
]);

// Assert record doesn't exist
$this->assertDatabaseMissing('users', [
    'email' => 'deleted@example.com',
]);

// Assert soft deleted
$this->assertSoftDeleted('users', [
    'id' => $user->id,
]);

// Assert count
$this->assertDatabaseCount('users', 5);
```

### Factories

```php
// Create one
$user = User::factory()->create();

// Create multiple
$users = User::factory()->count(10)->create();

// With specific attributes
$admin = User::factory()->create(['role' => 'admin']);

// With state
$admin = User::factory()->admin()->create();

// With relationships
$user = User::factory()
    ->has(Project::factory()->count(3))
    ->create();
```

---

## API Testing

### Testing API Endpoints

```php
namespace Tests\Feature\Api;

use Tests\TestCase;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_list_users()
    {
        Sanctum::actingAs(User::factory()->create());

        User::factory()->count(3)->create();

        $response = $this->getJson('/api/v1/users');

        $response->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'name', 'email', 'created_at']
                ],
                'meta',
                'links',
            ]);
    }

    public function test_can_create_user()
    {
        Sanctum::actingAs(User::factory()->admin()->create());

        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'SecurePassword123!',
            'password_confirmation' => 'SecurePassword123!',
        ];

        $response = $this->postJson('/api/v1/users', $userData);

        $response->assertCreated()
            ->assertJsonPath('data.email', 'john@example.com');

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }

    public function test_validation_errors_return_422()
    {
        Sanctum::actingAs(User::factory()->create());

        $response = $this->postJson('/api/v1/users', [
            'name' => '',
            'email' => 'invalid-email',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'email']);
    }

    public function test_unauthenticated_request_returns_401()
    {
        $response = $this->getJson('/api/v1/users');

        $response->assertUnauthorized();
    }

    public function test_pagination_works_correctly()
    {
        Sanctum::actingAs(User::factory()->create());

        User::factory()->count(25)->create();

        $response = $this->getJson('/api/v1/users?per_page=10');

        $response->assertOk()
            ->assertJsonPath('meta.per_page', 10)
            ->assertJsonPath('meta.current_page', 1)
            ->assertJsonPath('meta.total', 26);
    }
}
```

---

## Testing Best Practices

### 1. Arrange-Act-Assert Pattern

```php
public function test_example()
{
    // Arrange: Set up test data
    $user = User::factory()->create();

    // Act: Perform the action
    $response = $this->actingAs($user)->get('/dashboard');

    // Assert: Verify the result
    $response->assertOk();
}
```

### 2. One Assertion Per Test (Ideally)

```php
// Good
public function test_user_name_is_displayed()
{
    $user = $this->signIn(['name' => 'John']);
    $response = $this->get('/profile');
    $response->assertSee('John');
}

public function test_user_email_is_displayed()
{
    $user = $this->signIn(['email' => 'john@example.com']);
    $response = $this->get('/profile');
    $response->assertSee('john@example.com');
}
```

### 3. Use Descriptive Test Names

```php
// Bad
public function test_user() { }

// Good
public function test_authenticated_user_can_view_dashboard() { }
public function test_guest_is_redirected_to_login() { }
```

### 4. Test Edge Cases

```php
public function test_handles_empty_name() { }
public function test_handles_very_long_name() { }
public function test_handles_special_characters_in_name() { }
public function test_handles_null_value() { }
```

### 5. Use Data Providers

```php
/**
 * @dataProvider invalidEmailProvider
 */
public function test_rejects_invalid_emails(string $email)
{
    $response = $this->post('/register', ['email' => $email]);
    $response->assertSessionHasErrors('email');
}

public function invalidEmailProvider(): array
{
    return [
        ['invalid'],
        ['@example.com'],
        ['user@'],
        [''],
    ];
}
```

### 6. Don't Test Framework Code

```php
// Bad: Testing Laravel's behavior
public function test_user_has_projects_relationship()
{
    $user = User::factory()->create();
    $this->assertInstanceOf(HasMany::class, $user->projects());
}

// Good: Test your business logic
public function test_user_can_create_project()
{
    $user = User::factory()->create();
    $project = $user->projects()->create(['name' => 'Test']);
    $this->assertTrue($user->projects->contains($project));
}
```

### 7. Keep Tests Independent

```php
// Bad: Tests depend on each other
public function test_create_user()
{
    self::$user = User::create([...]);
}

public function test_update_user()
{
    self::$user->update([...]); // Depends on previous test
}

// Good: Each test is independent
public function test_can_update_user()
{
    $user = User::factory()->create();
    $user->update(['name' => 'New Name']);
    $this->assertEquals('New Name', $user->fresh()->name);
}
```

---

## Running Tests

### Run All Tests
```bash
php artisan test
```

### Run Specific Test File
```bash
php artisan test tests/Feature/UserTest.php
```

### Run Specific Test Method
```bash
php artisan test --filter test_user_can_login
```

### Run Tests in Parallel
```bash
php artisan test --parallel
```

### Generate Coverage Report
```bash
php artisan test --coverage
php artisan test --coverage --min=80
```

---

## Testing Checklist

- [ ] All services have unit tests
- [ ] All API endpoints have feature tests
- [ ] All form requests have validation tests
- [ ] Critical paths have 100% coverage
- [ ] Tests use factories instead of manual data
- [ ] Tests are independent (no shared state)
- [ ] Tests have descriptive names
- [ ] Edge cases are tested
- [ ] Database changes use RefreshDatabase
- [ ] External services are mocked/faked
- [ ] Tests run in under 60 seconds
- [ ] Code coverage meets minimum (70%)
