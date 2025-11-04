# Coding Conventions & Standards

This document describes the coding conventions, naming standards, and style guidelines for the Laravel DevKit project.

---

## Table of Contents

1. [PHP Standards](#php-standards)
2. [Laravel Conventions](#laravel-conventions)
3. [Naming Conventions](#naming-conventions)
4. [Code Style](#code-style)
5. [Documentation](#documentation)
6. [Best Practices](#best-practices)

---

## PHP Standards

### PSR-12: Extended Coding Style

**Follow PSR-12 strictly**

#### Indentation
- Use **4 spaces** for indentation (no tabs)

#### Line Length
- **Soft limit**: 120 characters
- **Hard limit**: None (but keep readable)

#### Files
- Must use `<?php` tag
- Must use UTF-8 without BOM
- Must end with a newline

#### Namespaces
```php
<?php

namespace App\Services\User;

use App\Models\User;
use App\Repositories\UserRepository;
use Illuminate\Support\Facades\Hash;

class UserService
{
    // ...
}
```

#### Classes

```php
<?php

namespace App\Services;

use App\Repositories\UserRepository;
use App\Services\NotificationService;

class UserService
{
    public function __construct(
        private UserRepository $userRepository,
        private NotificationService $notificationService
    ) {}

    public function createUser(array $data): User
    {
        // Method body
    }
}
```

#### Methods

```php
public function createUser(
    string $name,
    string $email,
    string $password
): User {
    return User::create([
        'name' => $name,
        'email' => $email,
        'password' => Hash::make($password),
    ]);
}
```

#### Control Structures

```php
// if statement
if ($condition) {
    // code
} elseif ($anotherCondition) {
    // code
} else {
    // code
}

// for loop
for ($i = 0; $i < 10; $i++) {
    // code
}

// foreach loop
foreach ($items as $item) {
    // code
}

// while loop
while ($condition) {
    // code
}

// switch statement
switch ($variable) {
    case 'value1':
        // code
        break;
    case 'value2':
        // code
        break;
    default:
        // code
}
```

---

## Laravel Conventions

### Directory Structure

```
app/
├── Actions/              # Single-purpose actions
├── Console/              # Artisan commands
├── DataTransferObjects/  # DTOs
├── Exceptions/           # Custom exceptions
├── Http/
│   ├── Controllers/     # HTTP controllers
│   ├── Middleware/      # HTTP middleware
│   ├── Requests/        # Form requests
│   └── Resources/       # API resources
├── Models/              # Eloquent models
├── Policies/            # Authorization policies
├── Providers/           # Service providers
├── Repositories/        # Data repositories
├── Services/            # Business logic
└── ValueObjects/        # Value objects
```

### Controller Conventions

```php
namespace App\Http\Controllers;

use App\Http\Requests\CreateUserRequest;
use App\Http\Requests\UpdateUserRequest;
use App\Models\User;
use App\Services\UserService;

class UserController extends Controller
{
    public function __construct(
        private UserService $userService
    ) {}

    /**
     * Display a listing of users.
     */
    public function index()
    {
        $users = User::paginate(15);
        return view('users.index', compact('users'));
    }

    /**
     * Show the form for creating a new user.
     */
    public function create()
    {
        return view('users.create');
    }

    /**
     * Store a newly created user.
     */
    public function store(CreateUserRequest $request)
    {
        $user = $this->userService->createUser($request->validated());
        return redirect()->route('users.show', $user)
            ->with('success', 'User created successfully.');
    }

    /**
     * Display the specified user.
     */
    public function show(User $user)
    {
        return view('users.show', compact('user'));
    }

    /**
     * Show the form for editing the user.
     */
    public function edit(User $user)
    {
        return view('users.edit', compact('user'));
    }

    /**
     * Update the specified user.
     */
    public function update(UpdateUserRequest $request, User $user)
    {
        $this->userService->updateUser($user, $request->validated());
        return redirect()->route('users.show', $user)
            ->with('success', 'User updated successfully.');
    }

    /**
     * Remove the specified user.
     */
    public function destroy(User $user)
    {
        $this->userService->deleteUser($user);
        return redirect()->route('users.index')
            ->with('success', 'User deleted successfully.');
    }
}
```

### Model Conventions

```php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Project extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'name',
        'description',
        'status',
        'user_id',
    ];

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    /**
     * Get the user that owns the project.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the features for the project.
     */
    public function features(): HasMany
    {
        return $this->hasMany(Feature::class);
    }

    /**
     * Scope a query to only include active projects.
     */
    public function scopeActive(Builder $query): void
    {
        $query->where('status', 'active');
    }

    /**
     * Determine if the project is active.
     */
    public function isActive(): bool
    {
        return $this->status === 'active';
    }
}
```

---

## Naming Conventions

### Classes

| Type | Convention | Example |
|------|------------|---------|
| Models | Singular, PascalCase | `User`, `Project`, `ProjectTemplate` |
| Controllers | Singular + Controller | `UserController`, `ProjectController` |
| Services | Singular + Service | `UserService`, `PaymentService` |
| Repositories | Singular + Repository | `UserRepository`, `ProjectRepository` |
| Actions | Verb + Noun + Action | `CreateUserAction`, `SendEmailAction` |
| Requests | Verb + Noun + Request | `CreateUserRequest`, `UpdateProjectRequest` |
| Resources | Singular + Resource | `UserResource`, `ProjectResource` |
| Policies | Singular + Policy | `UserPolicy`, `ProjectPolicy` |
| Middleware | Descriptive Name | `EnsureUserIsActive`, `LogRequests` |
| Exceptions | Descriptive + Exception | `UserNotFoundException`, `InvalidEmailException` |
| Jobs | Verb + Noun | `SendEmailNotification`, `ProcessPayment` |
| Events | Past Tense Verb + Noun | `UserCreated`, `ProjectDeployed` |
| Listeners | Verb + Noun | `SendWelcomeEmail`, `LogUserActivity` |

### Methods

| Type | Convention | Example |
|------|------------|---------|
| CRUD | index, create, store, show, edit, update, destroy | `index()`, `store()` |
| Getters | get + Property | `getName()`, `getEmail()` |
| Setters | set + Property | `setName()`, `setEmail()` |
| Boolean | is/has/can + Adjective | `isActive()`, `hasPermission()`, `canEdit()` |
| Actions | Verb + Noun | `createUser()`, `sendEmail()`, `deployProject()` |

### Variables

```php
// Use camelCase for variables
$userName = 'John Doe';
$userEmail = 'john@example.com';
$isActive = true;

// Use descriptive names
// Bad
$u = User::find(1);
$p = $u->projects;

// Good
$user = User::find(1);
$projects = $user->projects;

// Collections should be plural
$users = User::all();
$activeProjects = Project::where('status', 'active')->get();

// Single items should be singular
$user = User::first();
$project = Project::find(1);
```

### Constants

```php
// Use UPPER_CASE with underscores
class User extends Model
{
    public const STATUS_ACTIVE = 'active';
    public const STATUS_SUSPENDED = 'suspended';
    public const STATUS_DELETED = 'deleted';

    public const ROLE_ADMIN = 'admin';
    public const ROLE_DEVELOPER = 'developer';
    public const ROLE_GUEST = 'guest';
}
```

### Routes

```php
// Use kebab-case for URLs
Route::get('/user-profile', [ProfileController::class, 'show']);
Route::get('/project-templates', [ProjectTemplateController::class, 'index']);

// Use plural nouns for resources
Route::resource('users', UserController::class);
Route::resource('projects', ProjectController::class);

// Use descriptive names for actions
Route::post('/projects/{project}/deploy', [ProjectController::class, 'deploy'])
    ->name('projects.deploy');
```

### Views

```php
// Use kebab-case with dot notation
resources/views/users/index.blade.php       -> 'users.index'
resources/views/projects/create.blade.php   -> 'projects.create'
resources/views/admin/dashboard.blade.php   -> 'admin.dashboard'
```

### Database

```php
// Tables: plural, snake_case
users
projects
project_templates

// Columns: singular, snake_case
user_id
created_at
email_verified_at

// Pivot tables: alphabetical order
project_user (not user_project)
feature_tag
```

### Configuration Files

```php
// Use snake_case
config/auth.php
config/database.php
config/mail.php
```

---

## Code Style

### Type Hints

**Always use type hints**:

```php
// Good
public function createUser(string $name, string $email): User
{
    return User::create(['name' => $name, 'email' => $email]);
}

// Bad
public function createUser($name, $email)
{
    return User::create(['name' => $name, 'email' => $email]);
}
```

### Readonly Properties (PHP 8.1+)

```php
class UserData
{
    public function __construct(
        public readonly string $name,
        public readonly string $email,
        public readonly ?string $phone = null,
    ) {}
}
```

### Constructor Property Promotion (PHP 8.0+)

```php
// Good (PHP 8.0+)
class UserService
{
    public function __construct(
        private UserRepository $userRepository,
        private NotificationService $notificationService
    ) {}
}

// Old style
class UserService
{
    private UserRepository $userRepository;
    private NotificationService $notificationService;

    public function __construct(
        UserRepository $userRepository,
        NotificationService $notificationService
    ) {
        $this->userRepository = $userRepository;
        $this->notificationService = $notificationService;
    }
}
```

### Enums (PHP 8.1+)

```php
enum UserStatus: string
{
    case ACTIVE = 'active';
    case SUSPENDED = 'suspended';
    case DELETED = 'deleted';

    public function label(): string
    {
        return match($this) {
            self::ACTIVE => 'Active',
            self::SUSPENDED => 'Suspended',
            self::DELETED => 'Deleted',
        };
    }
}

// Usage
$user->status = UserStatus::ACTIVE;
```

### Match Expression (PHP 8.0+)

```php
// Good (PHP 8.0+)
$result = match($status) {
    'active' => 'User is active',
    'suspended' => 'User is suspended',
    'deleted' => 'User is deleted',
    default => 'Unknown status',
};

// Old style
switch ($status) {
    case 'active':
        $result = 'User is active';
        break;
    case 'suspended':
        $result = 'User is suspended';
        break;
    case 'deleted':
        $result = 'User is deleted';
        break;
    default:
        $result = 'Unknown status';
}
```

### Null Coalescing Operator

```php
// Good
$name = $user->name ?? 'Guest';
$config = $request->input('config') ?? [];

// Bad
$name = isset($user->name) ? $user->name : 'Guest';
```

### Null Safe Operator (PHP 8.0+)

```php
// Good
$city = $user?->profile?->address?->city;

// Bad
$city = null;
if ($user && $user->profile && $user->profile->address) {
    $city = $user->profile->address->city;
}
```

### Array Destructuring

```php
// Good
[$name, $email] = $user;
['name' => $userName, 'email' => $userEmail] = $user->toArray();

// In foreach
foreach ($users as ['name' => $name, 'email' => $email]) {
    // Use $name and $email
}
```

### Arrow Functions (PHP 7.4+)

```php
// Good for simple operations
$names = array_map(fn($user) => $user->name, $users);
$activeUsers = array_filter($users, fn($user) => $user->isActive());

// Use regular closures for complex operations
$processed = array_map(function ($user) {
    $user->load('projects');
    $user->transform();
    return $user;
}, $users);
```

### Collections

```php
// Use Laravel Collections for data manipulation
$activeUserNames = User::all()
    ->filter(fn($user) => $user->isActive())
    ->map(fn($user) => $user->name)
    ->sort()
    ->values();

// Chain methods for readability
$summary = Project::query()
    ->where('status', 'active')
    ->get()
    ->groupBy('user_id')
    ->map(fn($projects) => [
        'count' => $projects->count(),
        'total_size' => $projects->sum('size'),
    ]);
```

---

## Documentation

### PHPDoc Comments

```php
/**
 * Create a new user.
 *
 * This method creates a new user with the provided data,
 * sends a welcome email, and assigns default permissions.
 *
 * @param  array  $data  The user data
 * @return \App\Models\User
 *
 * @throws \App\Exceptions\InvalidEmailException
 * @throws \App\Exceptions\DuplicateEmailException
 */
public function createUser(array $data): User
{
    // Method implementation
}
```

### Class Documentation

```php
/**
 * User service for managing user operations.
 *
 * This service handles all business logic related to user management,
 * including creation, updates, suspension, and deletion.
 *
 * @package App\Services
 */
class UserService
{
    // Class implementation
}
```

### Method Documentation

```php
/**
 * Get active users.
 *
 * @return \Illuminate\Database\Eloquent\Collection<int, \App\Models\User>
 */
public function getActiveUsers(): Collection
{
    return User::where('status', 'active')->get();
}

/**
 * Find user by email.
 *
 * @param  string  $email
 * @return \App\Models\User|null
 */
public function findByEmail(string $email): ?User
{
    return User::where('email', $email)->first();
}
```

### Inline Comments

```php
// Good: Explain WHY, not WHAT
// Suspend user instead of deleting to preserve audit trail
$user->update(['status' => 'suspended']);

// Bad: Obvious comment
// Set status to suspended
$user->update(['status' => 'suspended']);

// Good: Complex logic explanation
// Calculate discount based on user tier and purchase history
// Tier 1: 5% base + 1% per year of membership
// Tier 2: 10% base + 2% per year of membership
$discount = $this->calculateDiscount($user);
```

---

## Best Practices

### 1. Single Responsibility Principle

```php
// Bad: Class does too much
class UserService
{
    public function createUser() { }
    public function sendEmail() { }
    public function processPayment() { }
}

// Good: Separate concerns
class UserService
{
    public function createUser() { }
}

class EmailService
{
    public function sendEmail() { }
}

class PaymentService
{
    public function processPayment() { }
}
```

### 2. Dependency Injection

```php
// Bad: Direct instantiation
class UserController
{
    public function store()
    {
        $service = new UserService();
        $service->createUser([...]);
    }
}

// Good: Dependency injection
class UserController
{
    public function __construct(
        private UserService $userService
    ) {}

    public function store()
    {
        $this->userService->createUser([...]);
    }
}
```

### 3. Early Returns

```php
// Bad: Nested conditions
public function canEdit(User $user, Project $project)
{
    if ($user->isAdmin()) {
        return true;
    } else {
        if ($user->id === $project->user_id) {
            if ($project->status === 'active') {
                return true;
            }
        }
    }
    return false;
}

// Good: Early returns
public function canEdit(User $user, Project $project): bool
{
    if ($user->isAdmin()) {
        return true;
    }

    if ($user->id !== $project->user_id) {
        return false;
    }

    return $project->status === 'active';
}
```

### 4. Avoid Magic Numbers

```php
// Bad
if ($user->login_attempts > 5) {
    // Lock account
}

// Good
class User extends Model
{
    public const MAX_LOGIN_ATTEMPTS = 5;
}

if ($user->login_attempts > User::MAX_LOGIN_ATTEMPTS) {
    // Lock account
}
```

### 5. Use Eloquent Relationships

```php
// Bad
$projects = DB::table('projects')
    ->where('user_id', $user->id)
    ->get();

// Good
$projects = $user->projects;
```

### 6. Avoid N+1 Queries

```php
// Bad (N+1 problem)
$users = User::all();
foreach ($users as $user) {
    echo $user->profile->bio;
}

// Good (Eager loading)
$users = User::with('profile')->get();
foreach ($users as $user) {
    echo $user->profile->bio;
}
```

### 7. Use Form Requests

```php
// Bad: Validation in controller
public function store(Request $request)
{
    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users',
    ]);
}

// Good: Form Request
public function store(CreateUserRequest $request)
{
    $validated = $request->validated();
}
```

### 8. Use Policies for Authorization

```php
// Bad: Authorization in controller
public function update(Request $request, Project $project)
{
    if (auth()->user()->id !== $project->user_id) {
        abort(403);
    }
}

// Good: Use policies
public function update(UpdateProjectRequest $request, Project $project)
{
    $this->authorize('update', $project);
}
```

---

## Code Review Checklist

- [ ] Follows PSR-12 coding standards
- [ ] Uses type hints for all parameters and returns
- [ ] Has proper PHPDoc comments
- [ ] Uses dependency injection
- [ ] Single responsibility per class/method
- [ ] No magic numbers (use constants)
- [ ] No N+1 queries
- [ ] Proper error handling
- [ ] Follows Laravel conventions
- [ ] Descriptive naming
- [ ] No code duplication
- [ ] Tests included
