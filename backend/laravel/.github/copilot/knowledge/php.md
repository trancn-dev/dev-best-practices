# PHP & Laravel Development Guide

## PHP Version Requirements

**Minimum PHP Version**: [PHP_VERSION]
**Recommended PHP Version**: [PHP_VERSION] or higher

### PHP [PHP_VERSION] Features Used

- **Enums**: Type-safe enumerations
- **Readonly Properties**: Immutable object properties
- **Union Types**: Multiple type declarations
- **Named Arguments**: Clearer function calls
- **Match Expression**: Improved switch statements
- **Nullsafe Operator**: `?->` for safe property access
- **Constructor Property Promotion**: Shorter class definitions
- **First-class Callable Syntax**: `$callback(...)`
- **Intersection Types**: Multiple type constraints

---

## Laravel Framework

**Framework**: [FRAMEWORK] [FRAMEWORK_VERSION]
**Architecture**: MVC with additional patterns

### Core Concepts

#### 1. Service Container (Dependency Injection)

```php
// Automatic resolution
app(UserService::class)->createUser($data);

// Binding in service provider
$this->app->bind(UserRepositoryInterface::class, UserRepository::class);
$this->app->singleton(CacheService::class);

// Contextual binding
$this->app->when(OrderController::class)
    ->needs(PaymentGateway::class)
    ->give(StripeGateway::class);
```

#### 2. Eloquent ORM

```php
// Model definition
class User extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['name', 'email'];
    protected $casts = [
        'email_verified_at' => 'datetime',
        'settings' => 'array',
    ];

    // Relationships
    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }
}

// Queries
User::with('posts')->where('active', true)->get();
User::whereHas('posts', function ($query) {
    $query->where('published', true);
})->paginate(20);
```

#### 3. Routing

```php
// API routes (routes/api.php)
Route::apiResource('users', UserController::class);
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [ProfileController::class, 'show']);
});

// Web routes (routes/web.php)
Route::get('/', HomeController::class);
Route::controller(PostController::class)->group(function () {
    Route::get('/posts', 'index');
    Route::get('/posts/{post}', 'show');
});
```

#### 4. Middleware

```php
class EnsureUserIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->user()?->is_active) {
            abort(403, 'Account is inactive');
        }

        return $next($request);
    }
}
```

#### 5. Form Requests (Validation)

```php
class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', User::class);
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users'],
            'password' => ['required', 'min:8', 'confirmed'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.unique' => 'This email is already registered.',
        ];
    }
}
```

#### 6. API Resources

```php
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'posts' => PostResource::collection($this->whenLoaded('posts')),
            'created_at' => $this->created_at->toISOString(),
        ];
    }
}

// Usage
return UserResource::collection(User::paginate());
return new UserResource($user->load('posts'));
```

#### 7. Actions (Single Responsibility)

```php
class CreateUserAction
{
    public function __construct(
        private readonly UserRepository $users,
        private readonly HashService $hash,
    ) {}

    public function execute(CreateUserData $data): User
    {
        DB::beginTransaction();

        try {
            $user = $this->users->create([
                'name' => $data->name,
                'email' => $data->email,
                'password' => $this->hash->make($data->password),
            ]);

            event(new UserCreated($user));

            DB::commit();
            return $user;
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }
}
```

#### 8. Services (Business Logic)

```php
class PaymentService
{
    public function __construct(
        private readonly PaymentGateway $gateway,
        private readonly OrderRepository $orders,
    ) {}

    public function processPayment(Order $order, PaymentData $data): Payment
    {
        $result = $this->gateway->charge(
            $order->total,
            $data->token
        );

        if ($result->successful()) {
            $order->markAsPaid();
            return $result->payment;
        }

        throw new PaymentFailedException($result->message);
    }
}
```

#### 9. Events & Listeners

```php
// Event
class UserCreated
{
    public function __construct(
        public readonly User $user,
    ) {}
}

// Listener
class SendWelcomeEmail
{
    public function handle(UserCreated $event): void
    {
        Mail::to($event->user)->send(new WelcomeMail($event->user));
    }
}

// Register in EventServiceProvider
protected $listen = [
    UserCreated::class => [
        SendWelcomeEmail::class,
        CreateUserProfile::class,
    ],
];
```

#### 10. Jobs (Queue)

```php
class ProcessVideoUpload implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public readonly Video $video,
    ) {}

    public function handle(VideoProcessor $processor): void
    {
        $processor->process($this->video);
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('Video processing failed', [
            'video_id' => $this->video->id,
            'error' => $exception->getMessage(),
        ]);
    }
}

// Dispatch
ProcessVideoUpload::dispatch($video)
    ->onQueue('video-processing')
    ->delay(now()->addMinutes(5));
```

#### 11. Policies (Authorization)

```php
class PostPolicy
{
    public function view(?User $user, Post $post): bool
    {
        return $post->published || $user?->id === $post->author_id;
    }

    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->author_id;
    }

    public function delete(User $user, Post $post): bool
    {
        return $user->id === $post->author_id
            || $user->hasRole('admin');
    }
}

// Usage in controller
$this->authorize('update', $post);
Gate::allows('update', $post);
```

---

## Laravel Best Practices

### 1. Controller Best Practices

```php
class UserController extends Controller
{
    // ✅ GOOD: Thin controllers, delegate to services
    public function store(StoreUserRequest $request, CreateUserAction $action)
    {
        $user = $action->execute(
            CreateUserData::fromRequest($request)
        );

        return new UserResource($user);
    }

    // ❌ BAD: Fat controllers with business logic
    public function store(Request $request)
    {
        $validated = $request->validate([...]);
        $user = User::create([
            'password' => Hash::make($validated['password']),
            ...
        ]);
        event(new UserCreated($user));
        return response()->json($user);
    }
}
```

### 2. Model Best Practices

```php
class User extends Model
{
    // ✅ Always define fillable or guarded
    protected $fillable = ['name', 'email', 'password'];

    // ✅ Use casts for type safety
    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_admin' => 'boolean',
        'settings' => 'array',
        'status' => UserStatus::class, // Enum casting
    ];

    // ✅ Use accessor/mutator attributes (Laravel 11+)
    protected function password(): Attribute
    {
        return Attribute::make(
            set: fn ($value) => bcrypt($value),
        );
    }

    // ✅ Define relationship return types
    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }

    // ✅ Scope queries
    public function scopeActive(Builder $query): void
    {
        $query->where('active', true);
    }
}
```

### 3. Query Optimization

```php
// ✅ GOOD: Eager loading
$users = User::with(['posts', 'comments'])->get();

// ❌ BAD: N+1 problem
$users = User::all();
foreach ($users as $user) {
    echo $user->posts; // Triggers query for each user
}

// ✅ GOOD: Select only needed columns
User::select(['id', 'name', 'email'])->get();

// ✅ GOOD: Chunking for large datasets
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process user
    }
});

// ✅ GOOD: Use lazy loading for memory efficiency
User::lazy()->each(function ($user) {
    // Process user
});
```

### 4. Database Transactions

```php
// ✅ GOOD: Wrap related operations
DB::transaction(function () {
    $order = Order::create($data);
    $order->items()->createMany($items);
    $order->customer->decrement('balance', $order->total);
});

// ✅ GOOD: Manual transaction control
DB::beginTransaction();
try {
    // Operations
    DB::commit();
} catch (\Exception $e) {
    DB::rollBack();
    throw $e;
}
```

### 5. Caching Strategies

```php
// ✅ Remember pattern
$users = Cache::remember('users.all', 3600, function () {
    return User::all();
});

// ✅ Cache tags (Redis/Memcached only)
Cache::tags(['users', 'posts'])->put('key', $value, 3600);
Cache::tags(['users'])->flush();

// ✅ Model caching with events
class User extends Model
{
    protected static function booted()
    {
        static::saved(function () {
            Cache::forget('users.all');
        });
    }
}
```

### 6. Error Handling

```php
// ✅ Custom exceptions
class InsufficientBalanceException extends Exception
{
    public function render(Request $request)
    {
        return response()->json([
            'error' => 'Insufficient balance',
            'message' => $this->getMessage(),
        ], 400);
    }
}

// ✅ Handler customization
class Handler extends ExceptionHandler
{
    public function render($request, Throwable $e)
    {
        if ($e instanceof ModelNotFoundException) {
            return response()->json([
                'error' => 'Resource not found',
            ], 404);
        }

        return parent::render($request, $e);
    }
}
```

### 7. Testing

```php
// Feature test
class UserTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_be_created(): void
    {
        $response = $this->postJson('/api/users', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => ['id', 'name', 'email'],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }
}

// Unit test
class UserServiceTest extends TestCase
{
    public function test_creates_user_with_hashed_password(): void
    {
        $service = new UserService(
            new UserRepository(),
            new HashService()
        );

        $user = $service->createUser([
            'name' => 'John',
            'password' => 'secret',
        ]);

        $this->assertNotEquals('secret', $user->password);
        $this->assertTrue(Hash::check('secret', $user->password));
    }
}
```

---

## Common Patterns

### Repository Pattern

```php
interface UserRepositoryInterface
{
    public function find(int $id): ?User;
    public function create(array $data): User;
    public function update(int $id, array $data): User;
    public function delete(int $id): bool;
}

class UserRepository implements UserRepositoryInterface
{
    public function find(int $id): ?User
    {
        return User::find($id);
    }

    public function create(array $data): User
    {
        return User::create($data);
    }
}
```

### Data Transfer Objects (DTOs)

```php
readonly class CreateUserData
{
    public function __construct(
        public string $name,
        public string $email,
        public string $password,
    ) {}

    public static function fromRequest(Request $request): self
    {
        return new self(
            name: $request->input('name'),
            email: $request->input('email'),
            password: $request->input('password'),
        );
    }

    public static function fromArray(array $data): self
    {
        return new self(
            name: $data['name'],
            email: $data['email'],
            password: $data['password'],
        );
    }
}
```

### Enums

```php
enum UserStatus: string
{
    case Active = 'active';
    case Inactive = 'inactive';
    case Suspended = 'suspended';

    public function label(): string
    {
        return match($this) {
            self::Active => 'Active',
            self::Inactive => 'Inactive',
            self::Suspended => 'Suspended',
        };
    }

    public function canLogin(): bool
    {
        return $this === self::Active;
    }
}

// Usage in model
class User extends Model
{
    protected $casts = [
        'status' => UserStatus::class,
    ];
}
```

### Service Layer with Interface

```php
interface PaymentServiceInterface
{
    public function charge(float $amount, string $token): PaymentResult;
    public function refund(Payment $payment): bool;
}

class StripePaymentService implements PaymentServiceInterface
{
    public function __construct(
        private readonly StripeClient $stripe,
    ) {}

    public function charge(float $amount, string $token): PaymentResult
    {
        $result = $this->stripe->charges->create([
            'amount' => $amount * 100,
            'currency' => 'usd',
            'source' => $token,
        ]);

        return new PaymentResult($result);
    }

    public function refund(Payment $payment): bool
    {
        $this->stripe->refunds->create([
            'charge' => $payment->stripe_charge_id,
        ]);

        return true;
    }
}
```

---

## Security Best Practices

### 1. Mass Assignment Protection

```php
class User extends Model
{
    // ✅ Option 1: Whitelist
    protected $fillable = ['name', 'email'];

    // ✅ Option 2: Blacklist
    protected $guarded = ['id', 'password', 'remember_token'];
}
```

### 2. SQL Injection Prevention

```php
// ✅ GOOD: Query builder / Eloquent
User::where('email', $email)->first();

// ✅ GOOD: Parameter binding
DB::select('SELECT * FROM users WHERE email = ?', [$email]);

// ❌ BAD: Raw queries without binding
DB::select("SELECT * FROM users WHERE email = '{$email}'");
```

### 3. XSS Prevention

```php
// ✅ Blade auto-escapes
{{ $user->name }}

// ❌ Only use for trusted HTML
{!! $trustedHtml !!}

// ✅ Use purifier for user HTML
{{ Purifier::clean($userHtml) }}
```

### 4. CSRF Protection

```php
// ✅ Always include in forms
<form method="POST">
    @csrf
    ...
</form>

// ✅ Verify in API
Route::middleware('throttle:api')->group(function () {
    // API routes
});
```

---

## Performance Optimization

### 1. Database Indexing

```php
Schema::table('users', function (Blueprint $table) {
    $table->index('email');
    $table->index(['status', 'created_at']);
    $table->unique('username');
});
```

### 2. Query Optimization

```php
// ✅ Select specific columns
User::select(['id', 'name'])->get();

// ✅ Use exists instead of count
User::where('active', true)->exists();

// ✅ Use cursor for large datasets
foreach (User::cursor() as $user) {
    // Memory efficient
}
```

### 3. Caching

```php
// ✅ Cache expensive queries
$statistics = Cache::remember('stats', 3600, function () {
    return [
        'users' => User::count(),
        'posts' => Post::count(),
        'revenue' => Order::sum('total'),
    ];
});
```

---

## Code Style (PSR-12)

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use App\Repositories\UserRepository;
use Illuminate\Support\Facades\Hash;

class UserService
{
    public function __construct(
        private readonly UserRepository $repository,
    ) {}

    public function createUser(array $data): User
    {
        return $this->repository->create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
        ]);
    }
}
```

---

## Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Laravel Best Practices](https://github.com/alexeymezenin/laravel-best-practices)
- [PSR-12 Coding Standard](https://www.php-fig.org/psr/psr-12/)
- [PHP The Right Way](https://phptherightway.com/)
