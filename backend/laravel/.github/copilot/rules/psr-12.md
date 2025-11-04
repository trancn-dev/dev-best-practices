# Rule: PSR-12 Extended Coding Style Guide

## Intent
This rule enforces the official PSR-12 Extended Coding Style Guide for PHP. Copilot must follow these conventions when generating or reviewing PHP code to ensure consistent, readable, and maintainable codebases across the Laravel application.

## Scope
Applies to all `.php` files including controllers, models, services, commands, migrations, seeders, tests, and any PHP-based files in the project.

---

## 1. General Rules

### File Formatting
- ✅ Use only `<?php` tags (no short tags)
- ✅ Files MUST use UTF-8 without BOM encoding
- ✅ Files MUST end with a single blank line
- ✅ Lines MUST NOT exceed 120 characters (soft limit 80)
- ❌ No closing `?>` tag in pure PHP files
- ❌ No trailing whitespace

**Example:**
```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;

class UserService
{
    // Code here
}
// ← Single blank line at end of file
```

---

## 2. Namespace & Use Declarations

### Rules
- ✅ One `namespace` declaration per file
- ✅ One blank line after `namespace`
- ✅ One `use` statement per line
- ✅ Alphabetically ordered imports
- ✅ Group imports by type (external, app, aliases)
- ✅ One blank line after all `use` declarations

**Example:**
```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Actions\User\CreateUserAction;
use App\Http\Requests\CreateUserRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    // Controller code
}
```

---

## 3. Classes & Properties

### Class Declaration
- ✅ Opening brace `{` on new line after class name
- ✅ Closing brace `}` on new line by itself
- ✅ One class per file
- ✅ Class name in PascalCase
- ✅ Always declare visibility (`public`, `protected`, `private`)

**Example:**
```php
<?php

namespace App\Services;

use App\Repositories\UserRepository;
use Illuminate\Support\Facades\Hash;

class UserService
{
    // Properties
    private UserRepository $users;
    private int $maxAttempts = 5;

    // Constructor
    public function __construct(UserRepository $users)
    {
        $this->users = $users;
    }

    // Methods
    public function createUser(array $data): User
    {
        // Implementation
    }
}
```

### Property Declaration
- ✅ Declare visibility for all properties
- ✅ Use type hints (PHP 7.4+)
- ✅ Use readonly modifier when appropriate (PHP 8.1+)
- ❌ Don't use `var` keyword
- ❌ Don't prefix with underscore for private/protected

**Example:**
```php
// ✅ Good - Proper property declaration
class Post
{
    private int $id;
    protected string $title;
    public array $tags = [];
    private readonly User $author; // PHP 8.1+

    // Constructor property promotion (PHP 8.0+)
    public function __construct(
        private string $content,
        private PostStatus $status
    ) {}
}

// ❌ Bad - Improper declaration
class Post
{
    var $id; // Don't use 'var'
    private $_title; // Don't use underscore prefix
    $tags; // Missing visibility
}
```

---

## 4. Methods & Functions

### Method Declaration
- ✅ Opening brace `{` on same line as method signature
- ✅ One space before opening brace
- ✅ Closing brace `}` on new line
- ✅ Always declare visibility
- ✅ One blank line between methods
- ✅ Type hints for parameters and return types

**Example:**
```php
class UserService
{
    public function createUser(string $name, string $email, string $password): User
    {
        $user = new User();
        $user->name = $name;
        $user->email = $email;
        $user->password = Hash::make($password);
        $user->save();

        return $user;
    }

    protected function validateEmail(string $email): bool
    {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }

    private function sendWelcomeEmail(User $user): void
    {
        // Implementation
    }
}
```

### Method Arguments
- ✅ No space before comma
- ✅ One space after comma
- ✅ Break long argument lists across multiple lines
- ✅ One parameter per line when multi-line
- ✅ Closing parenthesis and opening brace on same line

**Example:**
```php
// ✅ Good - Single line
public function update(User $user, string $name, string $email): bool
{
    // Implementation
}

// ✅ Good - Multi-line arguments
public function createOrder(
    User $user,
    array $items,
    string $shippingAddress,
    PaymentMethod $paymentMethod,
    ?string $couponCode = null
): Order {
    // Implementation
}

// ❌ Bad - Inconsistent spacing
public function update(User $user,string $name , string $email): bool
{
    // Implementation
}
```

---

## 5. Control Structures

### General Rules
- ✅ One space after control structure keyword
- ✅ No space after opening parenthesis
- ✅ No space before closing parenthesis
- ✅ Opening brace `{` on same line as condition
- ✅ Closing brace `}` on new line
- ✅ Always use braces, even for single-line bodies

### If/Else Statements
```php
// ✅ Good
if ($user->isActive()) {
    $this->processUser($user);
} elseif ($user->isPending()) {
    $this->sendReminder($user);
} else {
    $this->archiveUser($user);
}

// ✅ Good - Multi-line condition
if (
    $user->isActive()
    && $user->hasVerifiedEmail()
    && $user->hasPaidSubscription()
) {
    $this->grantAccess($user);
}

// ❌ Bad - No braces
if ($user->isActive())
    $this->processUser($user); // Avoid this

// ❌ Bad - Incorrect spacing
if( $user->isActive() ){
    $this->processUser($user);
}
```

### Switch Statements
```php
// ✅ Good
switch ($status) {
    case UserStatus::Active:
        $this->activateUser($user);
        break;

    case UserStatus::Pending:
        $this->sendReminder($user);
        break;

    case UserStatus::Suspended:
        $this->notifySuspension($user);
        // no break - intentional fallthrough

    default:
        $this->archiveUser($user);
        break;
}
```

### Loops
```php
// ✅ Good - for loop
for ($i = 0; $i < 10; $i++) {
    echo $i;
}

// ✅ Good - foreach loop
foreach ($users as $user) {
    $this->processUser($user);
}

// ✅ Good - while loop
while ($user = $this->getNextUser()) {
    $this->processUser($user);
}

// ✅ Good - do-while loop
do {
    $this->attempt();
    $attempts++;
} while ($attempts < 3 && !$this->isSuccessful());
```

### Try-Catch
```php
// ✅ Good
try {
    $user = $this->createUser($data);
    $this->sendWelcomeEmail($user);
} catch (DuplicateEmailException $e) {
    Log::warning('Duplicate email attempt', ['email' => $data['email']]);
    throw $e;
} catch (\Exception $e) {
    Log::error('User creation failed', ['error' => $e->getMessage()]);
    throw new UserCreationException('Failed to create user', 0, $e);
} finally {
    $this->cleanupTempFiles();
}
```

---

## 6. Operators & Expressions

### Binary Operators
- ✅ One space on both sides of binary operators

```php
// Arithmetic
$total = $price + $tax - $discount;
$result = $a * $b / $c;

// Comparison
if ($age >= 18 && $age <= 65) {
    // Process
}

if ($status === 'active' || $status === 'pending') {
    // Process
}

// Assignment
$name = 'John';
$count += 5;
$total *= 1.1;

// Concatenation
$fullName = $firstName . ' ' . $lastName;
```

### Ternary Operator
```php
// ✅ Good - Simple ternary
$status = $isActive ? 'active' : 'inactive';

// ✅ Good - Multi-line ternary
$message = $user->isVerified()
    ? 'Welcome back!'
    : 'Please verify your email';

// ✅ Better - Null coalescing operator (PHP 7+)
$name = $user->name ?? 'Guest';
$email = $request->input('email') ?? $user->email ?? 'noreply@example.com';
```

### Unary Operators
- ✅ No space between operator and operand

```php
// Increment/Decrement
$i++;
++$i;
$i--;
--$i;

// Negation
$isInvalid = !$isValid;
$negative = -$positive;

// Type casting
$int = (int) $string;
$array = (array) $object;
```

---

## 7. Anonymous Functions (Closures)

### Closure Declaration
```php
// ✅ Good - Simple closure
$callback = function ($item) {
    return $item * 2;
};

// ✅ Good - Closure with use
$multiplier = 10;
$callback = function ($item) use ($multiplier) {
    return $item * $multiplier;
};

// ✅ Good - Multi-line closure
$users = array_filter($allUsers, function ($user) use ($minAge, $maxAge) {
    return $user->age >= $minAge
        && $user->age <= $maxAge
        && $user->isActive();
});

// ✅ Good - Arrow function (PHP 7.4+)
$doubled = array_map(fn($x) => $x * 2, $numbers);

$filtered = array_filter(
    $users,
    fn($user) => $user->isActive() && $user->hasVerifiedEmail()
);
```

---

## 8. Comments & Documentation

### PHPDoc Blocks
```php
/**
 * Create a new user in the system.
 *
 * This method creates a user record, sends a welcome email,
 * and initializes default settings for the user account.
 *
 * @param  string  $name  The full name of the user
 * @param  string  $email  The email address (must be unique)
 * @param  string  $password  The plain text password (will be hashed)
 * @return User  The newly created user instance
 * @throws DuplicateEmailException  If the email already exists
 * @throws \Exception  If user creation fails
 */
public function createUser(string $name, string $email, string $password): User
{
    // Implementation
}
```

### Inline Comments
```php
// ✅ Good - Explain why, not what
// Retry failed payments up to 3 times before marking as failed
for ($attempt = 1; $attempt <= 3; $attempt++) {
    if ($this->processPayment($order)) {
        break;
    }
}

// ❌ Bad - Obvious comment
// Loop from 1 to 3
for ($attempt = 1; $attempt <= 3; $attempt++) {
    // Process payment
    if ($this->processPayment($order)) {
        // Break the loop
        break;
    }
}
```

---

## 9. Arrays

### Array Declaration
```php
// ✅ Good - Short array syntax (PHP 5.4+)
$users = [];
$config = ['key' => 'value'];

// ✅ Good - Multi-line array
$user = [
    'name' => 'John Doe',
    'email' => 'john@example.com',
    'age' => 30,
    'active' => true,
];

// ✅ Good - Nested arrays
$config = [
    'database' => [
        'host' => 'localhost',
        'port' => 3306,
        'name' => 'mydb',
    ],
    'cache' => [
        'driver' => 'redis',
        'ttl' => 3600,
    ],
];

// ❌ Bad - Old array syntax
$users = array(); // Use [] instead
$config = array('key' => 'value'); // Use [] instead
```

---

## 10. Type Declarations

### Strict Types
```php
<?php

declare(strict_types=1);

namespace App\Services;

class Calculator
{
    public function add(int $a, int $b): int
    {
        return $a + $b;
    }
}
```

### Nullable Types
```php
// ✅ Good - Nullable type (PHP 7.1+)
public function findUser(?int $id): ?User
{
    if ($id === null) {
        return null;
    }

    return User::find($id);
}

// ✅ Good - Union types (PHP 8.0+)
public function process(int|float $number): int|float
{
    return $number * 2;
}

// ✅ Good - Mixed type (PHP 8.0+)
public function getData(): mixed
{
    return $this->data;
}
```

---

## 11. Modern PHP Features (8.0+)

### Named Arguments
```php
// ✅ Good - Named arguments
$user = createUser(
    name: 'John Doe',
    email: 'john@example.com',
    age: 30
);
```

### Constructor Property Promotion
```php
// ✅ Good - Constructor promotion (PHP 8.0+)
class UserService
{
    public function __construct(
        private UserRepository $users,
        private NotificationService $notifications,
        private readonly LoggerInterface $logger
    ) {}
}

// Old way (still valid)
class UserService
{
    private UserRepository $users;
    private NotificationService $notifications;

    public function __construct(
        UserRepository $users,
        NotificationService $notifications
    ) {
        $this->users = $users;
        $this->notifications = $notifications;
    }
}
```

### Match Expression
```php
// ✅ Good - Match expression (PHP 8.0+)
$status = match ($code) {
    200, 201 => 'success',
    400, 404 => 'client_error',
    500, 503 => 'server_error',
    default => 'unknown',
};
```

### Attributes (Annotations)
```php
// ✅ Good - PHP 8.0+ attributes
#[Route('/api/users', methods: ['GET'])]
#[Middleware('auth:sanctum')]
public function index(): JsonResponse
{
    // Implementation
}
```

---

## 12. Code Examples - Complete Class

### Compliant PSR-12 Class
```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\DataTransferObjects\CreateUserData;
use App\Events\UserCreated;
use App\Exceptions\DuplicateEmailException;
use App\Models\User;
use App\Repositories\UserRepository;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Psr\Log\LoggerInterface;

/**
 * Service for managing user operations.
 *
 * This service handles user creation, updates, and related business logic.
 */
class UserService
{
    /**
     * Create a new UserService instance.
     */
    public function __construct(
        private readonly UserRepository $users,
        private readonly LoggerInterface $logger
    ) {}

    /**
     * Create a new user.
     *
     * @param  CreateUserData  $data  The user data
     * @return User  The created user
     * @throws DuplicateEmailException  If email already exists
     * @throws \Exception  If creation fails
     */
    public function createUser(CreateUserData $data): User
    {
        // Check for duplicate email
        if ($this->users->existsByEmail($data->email)) {
            $this->logger->warning('Duplicate email attempt', [
                'email' => $data->email,
            ]);

            throw new DuplicateEmailException(
                "Email {$data->email} already exists"
            );
        }

        try {
            DB::beginTransaction();

            // Create user
            $user = $this->users->create([
                'name' => $data->name,
                'email' => $data->email,
                'password' => Hash::make($data->password),
                'status' => UserStatus::Active,
            ]);

            // Trigger event
            event(new UserCreated($user));

            DB::commit();

            $this->logger->info('User created successfully', [
                'user_id' => $user->id,
            ]);

            return $user;
        } catch (\Exception $e) {
            DB::rollBack();

            $this->logger->error('User creation failed', [
                'error' => $e->getMessage(),
                'data' => $data->toArray(),
            ]);

            throw $e;
        }
    }

    /**
     * Update user information.
     *
     * @param  User  $user  The user to update
     * @param  array  $data  The update data
     * @return bool  True if updated successfully
     */
    public function updateUser(User $user, array $data): bool
    {
        return $this->users->update($user, $data);
    }

    /**
     * Soft delete a user.
     *
     * @param  User  $user  The user to delete
     * @return bool  True if deleted successfully
     */
    public function deleteUser(User $user): bool
    {
        return $this->users->delete($user);
    }
}
```

---

## 13. Common Violations to Avoid

### ❌ Bad Practices
```php
// ❌ Missing visibility
function getData() {}

// ❌ Missing type hints
public function process($data) {}

// ❌ No spaces around operators
$total=$price+$tax;

// ❌ Opening brace on wrong line
public function test()
{ // Should be on same line
}

// ❌ Multiple statements on one line
$a = 1; $b = 2; $c = 3;

// ❌ No braces for single-line if
if ($condition)
    doSomething();

// ❌ Incorrect spacing in control structures
if( $condition ){
}

// ❌ Using var keyword
var $property;

// ❌ Closing PHP tag in pure PHP file
?>
```

---

## 14. PSR-12 Checklist

### File Structure
- [ ] UTF-8 encoding without BOM
- [ ] `declare(strict_types=1)` at top
- [ ] Correct namespace declaration
- [ ] Alphabetically ordered imports
- [ ] No closing `?>` tag

### Classes & Methods
- [ ] Opening brace on new line for classes
- [ ] Opening brace on same line for methods
- [ ] Visibility declared for all properties/methods
- [ ] Type hints for parameters and returns
- [ ] One blank line between methods

### Code Style
- [ ] 4 spaces indentation (no tabs)
- [ ] One space after control structure keywords
- [ ] Braces for all control structures
- [ ] Spaces around binary operators
- [ ] No trailing whitespace
- [ ] File ends with single blank line

### Documentation
- [ ] PHPDoc for public methods
- [ ] Parameter and return type documentation
- [ ] Exception documentation
- [ ] Meaningful inline comments

---

## References

- [PSR-12: Extended Coding Style Guide](https://www.php-fig.org/psr/psr-12/)
- [PSR-1: Basic Coding Standard](https://www.php-fig.org/psr/psr-1/)
- [PHP The Right Way](https://phptherightway.com/)
- [Laravel Coding Style](https://laravel.com/docs/contributions#coding-style)
- [PHP-CS-Fixer](https://github.com/FriendsOfPHP/PHP-CS-Fixer)

- Laravel Style Guide and conventions
