# System Architecture & Design

This document describes the architectural patterns, design principles, and structural conventions for the Laravel DevKit project.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Layer Structure](#layer-structure)
3. [Design Patterns](#design-patterns)
4. [Folder Structure](#folder-structure)
5. [Dependencies](#dependencies)
6. [Design Principles](#design-principles)

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Blade   │  │   API    │  │  Inertia │  │  Livewire│   │
│  │  Views   │  │Resources │  │   Pages  │  │Components│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Controllers│ │  Actions  │  │   Form   │  │  Events  │   │
│  │          │  │          │  │ Requests │  │ Listeners│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                        Domain Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Services │  │  Domain  │  │   Data   │  │  Value   │   │
│  │          │  │  Models  │  │  Objects │  │  Objects │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Repository│  │  Cache   │  │  Queue   │  │  External│   │
│  │          │  │  Store   │  │  Jobs    │  │   APIs   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Persistence Layer                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Eloquent │  │  Query   │  │   File   │  │  Redis   │   │
│  │  Models  │  │ Builder  │  │  Storage │  │  Cache   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Architecture Type
**Layered Architecture with Domain-Driven Design (DDD) principles**

---

## Layer Structure

### 1. Presentation Layer

**Responsibility**: Handle user interface and user interactions

**Components**:
- **Blade Views**: Server-side rendered templates
- **API Resources**: JSON response transformers
- **Inertia Pages**: SPA-style components
- **Livewire Components**: Reactive components

**Rules**:
- No business logic in views
- Only display data and capture user input
- Use view composers for shared data
- Validate presentation logic only

**Example**:
```php
// resources/views/users/index.blade.php
@foreach($users as $user)
    <div>{{ $user->name }}</div>
@endforeach
```

---

### 2. Application Layer

**Responsibility**: Coordinate application flow and user requests

**Components**:

#### Controllers
```php
namespace App\Http\Controllers;

class UserController extends Controller
{
    public function __construct(
        private UserService $userService
    ) {}

    public function store(CreateUserRequest $request)
    {
        $user = $this->userService->createUser($request->validated());
        return redirect()->route('users.show', $user);
    }
}
```

**Rules**:
- Thin controllers (max 20 lines per method)
- Delegate to services
- Handle HTTP concerns only
- Use form requests for validation

#### Form Requests
```php
namespace App\Http\Requests;

class CreateUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:12|confirmed',
        ];
    }
}
```

#### Actions
```php
namespace App\Actions;

class CreateUserAction
{
    public function execute(array $data): User
    {
        return DB::transaction(function () use ($data) {
            $user = User::create($data);
            $user->assignRole('user');
            event(new UserCreated($user));
            return $user;
        });
    }
}
```

---

### 3. Domain Layer

**Responsibility**: Core business logic and domain rules

**Components**:

#### Services
```php
namespace App\Services;

class UserService
{
    public function __construct(
        private UserRepository $userRepository,
        private NotificationService $notificationService
    ) {}

    public function createUser(array $data): User
    {
        $user = $this->userRepository->create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
        ]);

        $this->notificationService->sendWelcomeEmail($user);

        return $user;
    }

    public function suspendUser(User $user, string $reason): void
    {
        if ($user->isAdmin()) {
            throw new CannotSuspendAdminException();
        }

        $user->update(['status' => 'suspended', 'suspended_reason' => $reason]);
        $this->notificationService->sendSuspensionNotification($user);
    }
}
```

**Rules**:
- All business logic here
- No HTTP concerns
- No database queries (use repositories)
- Type-hint everything
- Return domain objects

#### Data Transfer Objects (DTOs)
```php
namespace App\DataTransferObjects;

class UserData
{
    public function __construct(
        public readonly string $name,
        public readonly string $email,
        public readonly ?string $password = null,
        public readonly array $roles = [],
    ) {}

    public static function fromRequest(Request $request): self
    {
        return new self(
            name: $request->input('name'),
            email: $request->input('email'),
            password: $request->input('password'),
            roles: $request->input('roles', []),
        );
    }
}
```

#### Value Objects
```php
namespace App\ValueObjects;

class Email
{
    private string $value;

    public function __construct(string $email)
    {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidEmailException($email);
        }
        $this->value = strtolower($email);
    }

    public function getValue(): string
    {
        return $this->value;
    }

    public function getDomain(): string
    {
        return substr($this->value, strpos($this->value, '@') + 1);
    }
}
```

---

### 4. Infrastructure Layer

**Responsibility**: External integrations and technical implementations

**Components**:

#### Repositories
```php
namespace App\Repositories;

interface UserRepositoryInterface
{
    public function findById(int $id): ?User;
    public function create(array $data): User;
    public function update(User $user, array $data): User;
    public function delete(User $user): bool;
}

class UserRepository implements UserRepositoryInterface
{
    public function findById(int $id): ?User
    {
        return User::find($id);
    }

    public function findByEmail(string $email): ?User
    {
        return User::where('email', $email)->first();
    }

    public function create(array $data): User
    {
        return User::create($data);
    }
}
```

**Rules**:
- Abstract data access
- Return domain objects
- Use interfaces
- No business logic

#### External API Clients
```php
namespace App\Services\External;

class PaymentGatewayClient
{
    public function __construct(
        private HttpClient $client,
        private string $apiKey
    ) {}

    public function charge(int $amount, string $token): PaymentResult
    {
        $response = $this->client->post('/charges', [
            'amount' => $amount,
            'token' => $token,
        ]);

        return PaymentResult::fromResponse($response);
    }
}
```

---

### 5. Persistence Layer

**Responsibility**: Data storage and retrieval

**Components**:

#### Eloquent Models
```php
namespace App\Models;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    // Relationships
    public function profile(): HasOne
    {
        return $this->hasOne(Profile::class);
    }

    public function projects(): HasMany
    {
        return $this->hasMany(Project::class);
    }

    // Scopes
    public function scopeActive(Builder $query): void
    {
        $query->where('status', 'active');
    }

    // Accessors & Mutators
    protected function name(): Attribute
    {
        return Attribute::make(
            get: fn (string $value) => ucwords($value),
            set: fn (string $value) => strtolower($value),
        );
    }
}
```

**Rules**:
- Models represent tables
- Minimal logic (only data-related)
- Use relationships
- Use accessors/mutators for data transformation
- Use scopes for common queries

---

## Design Patterns

### 1. Repository Pattern

**Purpose**: Abstract data access layer

**Implementation**:
```php
// Interface
interface UserRepositoryInterface
{
    public function all(): Collection;
    public function findById(int $id): ?User;
    public function create(array $data): User;
}

// Implementation
class EloquentUserRepository implements UserRepositoryInterface
{
    public function all(): Collection
    {
        return User::all();
    }
}

// Binding in AppServiceProvider
$this->app->bind(
    UserRepositoryInterface::class,
    EloquentUserRepository::class
);
```

### 2. Service Pattern

**Purpose**: Encapsulate business logic

**Implementation**:
```php
class UserService
{
    public function __construct(
        private UserRepository $users,
        private RoleRepository $roles
    ) {}

    public function createUser(array $data): User
    {
        return DB::transaction(function () use ($data) {
            $user = $this->users->create($data);
            $role = $this->roles->findByName('user');
            $user->roles()->attach($role);
            return $user;
        });
    }
}
```

### 3. Action Pattern

**Purpose**: Single-purpose executable classes

**Implementation**:
```php
class SendWelcomeEmailAction
{
    public function __construct(
        private MailService $mailService
    ) {}

    public function execute(User $user): void
    {
        $this->mailService->send(
            to: $user->email,
            template: 'emails.welcome',
            data: ['user' => $user]
        );
    }
}
```

### 4. Factory Pattern

**Purpose**: Create complex objects

**Implementation**:
```php
class UserFactory
{
    public function createFromRequest(Request $request): User
    {
        return User::create([
            'name' => $request->input('name'),
            'email' => $request->input('email'),
            'password' => Hash::make($request->input('password')),
        ]);
    }

    public function createFromSocialProvider(SocialUser $socialUser): User
    {
        return User::create([
            'name' => $socialUser->getName(),
            'email' => $socialUser->getEmail(),
            'provider' => $socialUser->getProvider(),
            'provider_id' => $socialUser->getId(),
        ]);
    }
}
```

### 5. Strategy Pattern

**Purpose**: Interchangeable algorithms

**Implementation**:
```php
interface PaymentStrategy
{
    public function pay(int $amount): PaymentResult;
}

class CreditCardPayment implements PaymentStrategy
{
    public function pay(int $amount): PaymentResult
    {
        // Credit card payment logic
    }
}

class PayPalPayment implements PaymentStrategy
{
    public function pay(int $amount): PaymentResult
    {
        // PayPal payment logic
    }
}

class PaymentService
{
    public function processPayment(PaymentStrategy $strategy, int $amount): PaymentResult
    {
        return $strategy->pay($amount);
    }
}
```

### 6. Observer Pattern

**Purpose**: Event-driven architecture

**Implementation**:
```php
// Event
class UserCreated
{
    public function __construct(public User $user) {}
}

// Listener
class SendWelcomeEmail
{
    public function handle(UserCreated $event): void
    {
        Mail::to($event->user)->send(new WelcomeEmail($event->user));
    }
}

// Register in EventServiceProvider
protected $listen = [
    UserCreated::class => [
        SendWelcomeEmail::class,
        CreateUserProfile::class,
        AssignDefaultRole::class,
    ],
];
```

---

## Folder Structure

### Standard Laravel Structure

```
app/
├── Actions/                    # Single-purpose executable classes
│   ├── User/
│   │   ├── CreateUserAction.php
│   │   ├── UpdateUserAction.php
│   │   └── DeleteUserAction.php
│   └── Project/
│       ├── CreateProjectAction.php
│       └── DeployProjectAction.php
│
├── Console/                    # Artisan commands
│   ├── Commands/
│   │   ├── SendReminderEmails.php
│   │   └── CleanupOldData.php
│   └── Kernel.php
│
├── DataTransferObjects/        # DTOs
│   ├── UserData.php
│   ├── ProjectData.php
│   └── DeploymentData.php
│
├── Exceptions/                 # Custom exceptions
│   ├── User/
│   │   ├── UserNotFoundException.php
│   │   └── InvalidUserException.php
│   └── Handler.php
│
├── Http/
│   ├── Controllers/           # HTTP controllers
│   │   ├── Api/
│   │   │   └── V1/
│   │   │       ├── UserController.php
│   │   │       └── ProjectController.php
│   │   └── Web/
│   │       ├── DashboardController.php
│   │       └── ProfileController.php
│   │
│   ├── Middleware/            # HTTP middleware
│   │   ├── EnsureUserIsActive.php
│   │   └── LogRequests.php
│   │
│   ├── Requests/              # Form requests
│   │   ├── User/
│   │   │   ├── CreateUserRequest.php
│   │   │   └── UpdateUserRequest.php
│   │   └── Project/
│   │       └── CreateProjectRequest.php
│   │
│   └── Resources/             # API resources
│       ├── UserResource.php
│       ├── UserCollection.php
│       └── ProjectResource.php
│
├── Models/                    # Eloquent models
│   ├── User.php
│   ├── Project.php
│   ├── Deployment.php
│   └── Feature.php
│
├── Policies/                  # Authorization policies
│   ├── UserPolicy.php
│   └── ProjectPolicy.php
│
├── Providers/                 # Service providers
│   ├── AppServiceProvider.php
│   ├── AuthServiceProvider.php
│   ├── EventServiceProvider.php
│   └── RepositoryServiceProvider.php
│
├── Repositories/              # Data repositories
│   ├── Contracts/
│   │   ├── UserRepositoryInterface.php
│   │   └── ProjectRepositoryInterface.php
│   ├── Eloquent/
│   │   ├── UserRepository.php
│   │   └── ProjectRepository.php
│   └── Cache/
│       └── CachedUserRepository.php
│
├── Services/                  # Business logic services
│   ├── User/
│   │   ├── UserService.php
│   │   └── UserAuthenticationService.php
│   ├── Project/
│   │   ├── ProjectService.php
│   │   └── DeploymentService.php
│   └── External/
│       ├── PaymentGatewayService.php
│       └── CloudStorageService.php
│
├── ValueObjects/              # Value objects
│   ├── Email.php
│   ├── Money.php
│   └── PhoneNumber.php
│
└── Events/                    # Domain events
    ├── User/
    │   ├── UserCreated.php
    │   └── UserDeleted.php
    └── Project/
        └── ProjectDeployed.php
```

---

## Dependencies

### Dependency Flow

```
Controllers → Services → Repositories → Models
     ↓           ↓            ↓
  Requests    Actions      Queries
```

**Rules**:
1. **Upper layers depend on lower layers** (never reverse)
2. **Use interfaces** for dependencies
3. **Inject dependencies** via constructor
4. **No circular dependencies**
5. **Use dependency inversion** for flexibility

### Dependency Injection

```php
// Good: Constructor injection
class UserController extends Controller
{
    public function __construct(
        private UserService $userService,
        private NotificationService $notificationService
    ) {}
}

// Bad: Direct instantiation
class UserController extends Controller
{
    public function store()
    {
        $service = new UserService(); // ❌ Don't do this
    }
}
```

---

## Design Principles

### SOLID Principles

#### 1. Single Responsibility Principle (SRP)
Each class should have one reason to change.

```php
// Good: Separate responsibilities
class UserService
{
    public function createUser(array $data): User { }
}

class UserNotificationService
{
    public function sendWelcomeEmail(User $user): void { }
}

// Bad: Multiple responsibilities
class UserService
{
    public function createUser(array $data): User { }
    public function sendWelcomeEmail(User $user): void { }  // ❌
}
```

#### 2. Open/Closed Principle (OCP)
Open for extension, closed for modification.

```php
// Good: Use inheritance/interfaces
interface PaymentProcessor
{
    public function process(int $amount): bool;
}

class StripePayment implements PaymentProcessor { }
class PayPalPayment implements PaymentProcessor { }
```

#### 3. Liskov Substitution Principle (LSP)
Derived classes must be substitutable for base classes.

```php
interface UserRepositoryInterface
{
    public function find(int $id): ?User;
}

class EloquentUserRepository implements UserRepositoryInterface
{
    public function find(int $id): ?User
    {
        return User::find($id);
    }
}

class CachedUserRepository implements UserRepositoryInterface
{
    public function find(int $id): ?User
    {
        return Cache::remember("user.{$id}", 3600, fn() => User::find($id));
    }
}
```

#### 4. Interface Segregation Principle (ISP)
Many specific interfaces are better than one general interface.

```php
// Good: Specific interfaces
interface Readable
{
    public function read(): array;
}

interface Writable
{
    public function write(array $data): bool;
}

// Bad: Fat interface
interface Repository
{
    public function read(): array;
    public function write(array $data): bool;
    public function update(array $data): bool;
    public function delete(int $id): bool;
}
```

#### 5. Dependency Inversion Principle (DIP)
Depend on abstractions, not concretions.

```php
// Good: Depend on interface
class UserService
{
    public function __construct(
        private UserRepositoryInterface $userRepository
    ) {}
}

// Bad: Depend on concrete class
class UserService
{
    public function __construct(
        private EloquentUserRepository $userRepository  // ❌
    ) {}
}
```

---

## Best Practices

### 1. Use Type Hints
```php
public function createUser(array $data): User
{
    // Type-hinted parameters and return types
}
```

### 2. Use Named Arguments
```php
$this->userService->createUser(
    name: 'John Doe',
    email: 'john@example.com',
    password: 'secret'
);
```

### 3. Use Readonly Properties (PHP 8.1+)
```php
class UserData
{
    public function __construct(
        public readonly string $name,
        public readonly string $email,
    ) {}
}
```

### 4. Use Enums (PHP 8.1+)
```php
enum UserStatus: string
{
    case ACTIVE = 'active';
    case SUSPENDED = 'suspended';
    case DELETED = 'deleted';
}
```

### 5. Use Collections
```php
$activeUsers = User::where('status', 'active')
    ->get()
    ->filter(fn($user) => $user->hasVerifiedEmail())
    ->map(fn($user) => $user->name)
    ->sort();
```

---

## Architecture Constraints

### Hard Rules

1. **Controllers MUST be thin** (< 20 lines per method)
2. **Services MUST NOT know about HTTP**
3. **Models MUST NOT contain business logic**
4. **Repositories MUST return domain objects**
5. **No static calls** except facades
6. **All dependencies MUST be injected**
7. **Use interfaces** for all repositories
8. **Event-driven** for cross-domain communication

### Performance Considerations

1. **Eager load relationships** to avoid N+1
2. **Use query scopes** for reusable queries
3. **Cache expensive operations**
4. **Use queue for async tasks**
5. **Optimize database indexes**
6. **Use database transactions** for consistency

---

## Testing Architecture

### Test Structure
```
tests/
├── Unit/
│   ├── Services/
│   │   └── UserServiceTest.php
│   └── ValueObjects/
│       └── EmailTest.php
│
├── Feature/
│   ├── Api/
│   │   └── UserApiTest.php
│   └── Web/
│       └── UserManagementTest.php
│
└── Integration/
    └── UserRepositoryTest.php
```

### Testing Layers
- **Unit Tests**: Services, Value Objects, DTOs
- **Feature Tests**: Controllers, API endpoints
- **Integration Tests**: Repositories, External APIs

---

## Summary

This architecture provides:
- ✅ Clear separation of concerns
- ✅ Testable components
- ✅ Maintainable codebase
- ✅ Scalable structure
- ✅ SOLID principles
- ✅ Laravel best practices
