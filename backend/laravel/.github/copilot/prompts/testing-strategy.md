# Prompt: Testing Strategy

## Purpose
Generate comprehensive testing strategies and test cases for Laravel applications.

## When to Use
- Planning test coverage for new features
- Writing test cases
- Improving existing tests
- TDD (Test-Driven Development)
- Ensuring quality before deployment

---

## Prompt Template

```
I need to test the following functionality:

**Feature**: [Feature name]
**Component**: [Controller/Service/Action/etc.]

**Code**:
[CODE_BLOCK]

Please provide:
1. **Test strategy**: What types of tests are needed?
2. **Test cases**: List all scenarios to test
3. **Test code**: Write the actual test implementations
4. **Mocking strategy**: What should be mocked?
5. **Edge cases**: What edge cases to consider?
6. **Coverage goal**: What coverage percentage should we aim for?

Include:
- Unit tests
- Feature/Integration tests
- Negative test cases
- Edge cases
- Performance tests (if applicable)
```

---

## Example Usage

### Input:
```
I need to test the following functionality:

**Feature**: User Registration
**Component**: CreateUserAction

**Code**:
class CreateUserAction
{
    public function __construct(
        private readonly UserRepository $users,
        private readonly NotificationService $notifications
    ) {}

    public function execute(CreateUserData $data): User
    {
        if ($this->users->existsByEmail($data->email)) {
            throw new DuplicateEmailException("Email already exists");
        }

        $user = DB::transaction(function () use ($data) {
            $user = $this->users->create([
                'name' => $data->name,
                'email' => $data->email,
                'password' => Hash::make($data->password),
            ]);

            Setting::create([
                'user_id' => $user->id,
                'theme' => 'light',
            ]);

            return $user;
        });

        $this->notifications->sendWelcomeEmail($user);

        event(new UserCreated($user));

        return $user;
    }
}
```

### Expected Output:

## 📋 Test Strategy

### Test Types Needed

1. **Unit Tests** (80% coverage)
   - Test action logic in isolation
   - Mock all dependencies
   - Fast execution

2. **Feature Tests** (Full flow)
   - Test complete user registration flow
   - Use real database (with transactions)
   - Test API endpoints

3. **Integration Tests** (Dependencies)
   - Test email sending
   - Test event dispatching
   - Test database transactions

---

## 🧪 Test Cases

### Happy Path (Success Scenarios)
1. ✅ User can register with valid data
2. ✅ Welcome email is sent after registration
3. ✅ Default settings are created
4. ✅ UserCreated event is dispatched
5. ✅ Password is properly hashed
6. ✅ User is stored in database

### Error Scenarios
1. ❌ Cannot register with duplicate email
2. ❌ Transaction rolls back if settings creation fails
3. ❌ Proper exception handling

### Edge Cases
1. 🔧 Email with special characters
2. 🔧 Very long name (255+ characters)
3. 🔧 Unicode characters in name
4. 🔧 Email notification failure doesn't break registration

---

## 💻 Test Implementation

### Unit Test - CreateUserActionTest.php

```php
<?php

namespace Tests\Unit\Actions;

use Tests\TestCase;
use App\Actions\User\CreateUserAction;
use App\DataTransferObjects\CreateUserData;
use App\Exceptions\DuplicateEmailException;
use App\Models\User;
use App\Repositories\UserRepository;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;

class CreateUserActionTest extends TestCase
{
    use RefreshDatabase;

    private UserRepository $mockUserRepo;
    private NotificationService $mockNotifications;
    private CreateUserAction $action;

    protected function setUp(): void
    {
        parent::setUp();

        $this->mockUserRepo = Mockery::mock(UserRepository::class);
        $this->mockNotifications = Mockery::mock(NotificationService::class);

        $this->action = new CreateUserAction(
            $this->mockUserRepo,
            $this->mockNotifications
        );
    }

    /** @test */
    public function it_creates_user_with_valid_data(): void
    {
        // Arrange
        $data = new CreateUserData(
            name: 'John Doe',
            email: 'john@example.com',
            password: 'password123'
        );

        $expectedUser = new User([
            'id' => 1,
            'name' => 'John Doe',
            'email' => 'john@example.com',
        ]);

        $this->mockUserRepo
            ->shouldReceive('existsByEmail')
            ->once()
            ->with('john@example.com')
            ->andReturn(false);

        $this->mockUserRepo
            ->shouldReceive('create')
            ->once()
            ->andReturn($expectedUser);

        $this->mockNotifications
            ->shouldReceive('sendWelcomeEmail')
            ->once()
            ->with($expectedUser);

        // Act
        $user = $this->action->execute($data);

        // Assert
        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('John Doe', $user->name);
        $this->assertEquals('john@example.com', $user->email);
    }

    /** @test */
    public function it_throws_exception_for_duplicate_email(): void
    {
        // Arrange
        $data = new CreateUserData(
            name: 'John Doe',
            email: 'existing@example.com',
            password: 'password123'
        );

        $this->mockUserRepo
            ->shouldReceive('existsByEmail')
            ->once()
            ->with('existing@example.com')
            ->andReturn(true);

        // Assert
        $this->expectException(DuplicateEmailException::class);
        $this->expectExceptionMessage('Email already exists');

        // Act
        $this->action->execute($data);
    }

    /** @test */
    public function it_hashes_password_before_storing(): void
    {
        // Arrange
        $data = new CreateUserData(
            name: 'John Doe',
            email: 'john@example.com',
            password: 'plaintext123'
        );

        $this->mockUserRepo
            ->shouldReceive('existsByEmail')
            ->andReturn(false);

        $this->mockUserRepo
            ->shouldReceive('create')
            ->once()
            ->withArgs(function ($userData) {
                return Hash::check('plaintext123', $userData['password']);
            })
            ->andReturn(new User());

        $this->mockNotifications
            ->shouldReceive('sendWelcomeEmail');

        // Act
        $this->action->execute($data);
    }
}
```

### Feature Test - UserRegistrationTest.php

```php
<?php

namespace Tests\Feature\Auth;

use Tests\TestCase;
use App\Models\User;
use App\Models\Setting;
use App\Events\UserCreated;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Hash;

class UserRegistrationTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_register_with_valid_data(): void
    {
        // Arrange
        Mail::fake();
        Event::fake();

        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ];

        // Act
        $response = $this->postJson('/api/register', $userData);

        // Assert
        $response->assertCreated()
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'name',
                    'email',
                    'created_at',
                ]
            ]);

        $this->assertDatabaseHas('users', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
        ]);

        // Verify password is hashed
        $user = User::where('email', 'john@example.com')->first();
        $this->assertTrue(Hash::check('password123', $user->password));

        // Verify settings created
        $this->assertDatabaseHas('settings', [
            'user_id' => $user->id,
            'theme' => 'light',
        ]);
    }

    /** @test */
    public function registration_fails_with_duplicate_email(): void
    {
        // Arrange
        User::factory()->create(['email' => 'existing@example.com']);

        // Act
        $response = $this->postJson('/api/register', [
            'name' => 'Jane Doe',
            'email' => 'existing@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /** @test */
    public function welcome_email_is_sent_after_registration(): void
    {
        // Arrange
        Mail::fake();

        // Act
        $this->postJson('/api/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        // Assert
        Mail::assertSent(WelcomeEmail::class, function ($mail) {
            return $mail->hasTo('john@example.com');
        });
    }

    /** @test */
    public function user_created_event_is_dispatched(): void
    {
        // Arrange
        Event::fake([UserCreated::class]);

        // Act
        $this->postJson('/api/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        // Assert
        Event::assertDispatched(UserCreated::class, function ($event) {
            return $event->user->email === 'john@example.com';
        });
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

    /** @test */
    public function password_must_be_at_least_8_characters(): void
    {
        // Act
        $response = $this->postJson('/api/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'short',
            'password_confirmation' => 'short',
        ]);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /** @test */
    public function email_must_be_valid_format(): void
    {
        // Act
        $response = $this->postJson('/api/register', [
            'name' => 'John Doe',
            'email' => 'invalid-email',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /** @test */
    public function transaction_rolls_back_if_settings_creation_fails(): void
    {
        // This test requires mocking or injecting a failing service
        // Implementation depends on your architecture
    }
}
```

### Edge Case Tests

```php
/** @test */
public function it_handles_special_characters_in_email(): void
{
    $response = $this->postJson('/api/register', [
        'name' => 'John Doe',
        'email' => 'john+test@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    $response->assertCreated();
    $this->assertDatabaseHas('users', [
        'email' => 'john+test@example.com',
    ]);
}

/** @test */
public function it_handles_unicode_characters_in_name(): void
{
    $response = $this->postJson('/api/register', [
        'name' => 'Nguyễn Văn A',
        'email' => 'nguyen@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    $response->assertCreated();
    $this->assertDatabaseHas('users', [
        'name' => 'Nguyễn Văn A',
    ]);
}

/** @test */
public function it_rejects_very_long_names(): void
{
    $longName = str_repeat('a', 256);

    $response = $this->postJson('/api/register', [
        'name' => $longName,
        'email' => 'test@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['name']);
}
```

---

## 🎯 Mocking Strategy

### Mock External Services
```php
// ✅ Mock email service
Mail::fake();

// ✅ Mock events
Event::fake();

// ✅ Mock HTTP requests
Http::fake([
    'api.example.com/*' => Http::response(['status' => 'ok'], 200),
]);

// ✅ Mock notifications
Notification::fake();

// ✅ Mock queues
Queue::fake();
```

### Mock Repositories (Unit Tests)
```php
$mockRepo = Mockery::mock(UserRepository::class);
$mockRepo->shouldReceive('create')
    ->once()
    ->andReturn(new User());
```

---

## 📊 Coverage Goals

- **Overall**: 80%+
- **Critical Business Logic**: 100%
- **Controllers**: 80%+
- **Services/Actions**: 90%+
- **Models**: 85%+
- **Repositories**: 85%+

---

## ✅ Testing Checklist

### Before Committing
- [ ] All tests pass
- [ ] New features have tests
- [ ] Edge cases covered
- [ ] Error scenarios tested
- [ ] Integration points tested

### Test Quality
- [ ] Tests are independent
- [ ] Tests are fast (< 100ms for unit tests)
- [ ] Descriptive test names
- [ ] Follows AAA pattern (Arrange-Act-Assert)
- [ ] No hardcoded values (use factories)

---

## Variations

### For TDD
```
I want to implement [FEATURE] using TDD.
Please provide:
1. Test cases to write first
2. Order of implementation
3. Refactoring steps
```

### For Existing Code
```
This code has no tests:
[CODE]

Please generate comprehensive test coverage.
```

### For Bug Prevention
```
We had this bug: [BUG_DESCRIPTION]
What tests should we add to prevent it from happening again?
```

---

## Related Prompts

- `bug-fix-assistant.md` - Fix failing tests
- `refactoring-suggestions.md` - Refactor for testability
- `code-explanation.md` - Understand code before testing
- `documentation-generation.md` - Document test strategy
