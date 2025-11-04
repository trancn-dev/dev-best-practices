# Rule: Laravel Coding Standards & Best Practices

## Intent
This rule defines Laravel-specific coding standards and architectural patterns. Copilot must follow these conventions when generating or reviewing Laravel application code to ensure maintainable, scalable, and idiomatic Laravel applications.

## Scope
Applies to all Laravel PHP files including controllers, models, services, actions, repositories, middleware, commands, jobs, and events.

---

## 1. Project Structure & Organization

### Module Organization
- ✅ Organize by domain/feature rather than by type
- ✅ Keep related functionality together
- ✅ Use clear, descriptive folder names
- ❌ Don't put everything directly in `app/`

**Recommended Structure:**
```
app/
├── Actions/                    # Single-purpose action classes
│   └── User/
│       ├── CreateUserAction.php
│       ├── UpdateUserAction.php
│       └── DeleteUserAction.php
├── Services/                   # Business logic services
│   ├── PaymentService.php
│   ├── NotificationService.php
│   └── ReportService.php
├── Repositories/               # Data access layer
│   ├── UserRepository.php
│   └── PostRepository.php
├── DataTransferObjects/        # DTOs for data transfer
│   └── CreateUserData.php
├── Enums/                      # PHP 8.1+ enums
│   ├── UserStatus.php
│   └── OrderStatus.php
├── Http/
│   ├── Controllers/
│   │   ├── Api/
│   │   │   └── UserController.php
│   │   └── Web/
│   │       └── DashboardController.php
│   ├── Middleware/
│   ├── Requests/
│   │   └── CreateUserRequest.php
│   └── Resources/
│       └── UserResource.php
├── Models/
│   ├── User.php
│   └── Post.php
├── Policies/
│   └── PostPolicy.php
├── Observers/
│   └── UserObserver.php
└── Events/
    └── UserRegistered.php
```

### Controller Best Practices
- ✅ Controllers should only orchestrate (delegate work)
- ✅ Keep controllers thin (< 7 public methods)
- ✅ Use dependency injection
- ❌ Don't put business logic in controllers
- ❌ Don't use Eloquent queries directly in controllers

**Examples:**
```php
// ❌ Bad - Fat controller with business logic
class UserController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        // Send welcome email
        Mail::to($user)->send(new WelcomeEmail($user));

        // Create default settings
        Setting::create([
            'user_id' => $user->id,
            'theme' => 'light',
            'notifications' => true,
        ]);

        // Log activity
        Log::info('User registered', ['user_id' => $user->id]);

        return response()->json($user, 201);
    }
}

// ✅ Good - Thin controller with delegation
class UserController extends Controller
{
    public function __construct(
        private readonly CreateUserAction $createUserAction
    ) {}

    public function store(CreateUserRequest $request): JsonResponse
    {
        $user = $this->createUserAction->execute(
            CreateUserData::fromRequest($request)
        );

        return new UserResource($user);
    }
}

// Action class handles business logic
class CreateUserAction
{
    public function __construct(
        private readonly UserRepository $users,
        private readonly NotificationService $notifications
    ) {}

    public function execute(CreateUserData $data): User
    {
        $user = $this->users->create([
            'name' => $data->name,
            'email' => $data->email,
            'password' => Hash::make($data->password),
        ]);

        $this->notifications->sendWelcomeEmail($user);

        event(new UserRegistered($user));

        return $user;
    }
}
```

---

## 2. Eloquent Models

### Model Configuration
- ✅ Always define `$fillable` or `$guarded`
- ✅ Use `$casts` for type casting
- ✅ Define relationships clearly
- ✅ Use accessors/mutators for data transformation
- ❌ Don't put business logic in models (use Services/Actions)
- ❌ Don't use `$guarded = []` in production

**Examples:**
```php
// ✅ Good - Well-configured model
class Post extends Model
{
    use HasFactory, SoftDeletes;

    // Mass assignment protection
    protected $fillable = [
        'user_id',
        'title',
        'slug',
        'content',
        'status',
        'published_at',
    ];

    // Type casting
    protected $casts = [
        'published_at' => 'datetime',
        'is_featured' => 'boolean',
        'meta' => 'array',
        'status' => PostStatus::class, // Enum casting
    ];

    // Hidden from JSON
    protected $hidden = [
        'deleted_at',
    ];

    // Appended attributes
    protected $appends = [
        'excerpt',
    ];

    // Relationships
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(Tag::class)
            ->withTimestamps();
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }

    // Accessor
    public function getExcerptAttribute(): string
    {
        return Str::limit($this->content, 150);
    }

    // Mutator
    public function setTitleAttribute(string $value): void
    {
        $this->attributes['title'] = $value;
        $this->attributes['slug'] = Str::slug($value);
    }

    // Query Scopes
    public function scopePublished($query)
    {
        return $query->where('status', PostStatus::Published)
            ->where('published_at', '<=', now());
    }

    public function scopeByAuthor($query, User $user)
    {
        return $query->where('user_id', $user->id);
    }
}

// ❌ Bad - Poorly configured model
class Post extends Model
{
    protected $guarded = []; // Dangerous!
    // No relationships defined
    // No type casting
    // Business logic mixed in model

    public function publish()
    {
        // Business logic should be in Service/Action
        $this->status = 'published';
        $this->published_at = now();
        $this->save();

        Mail::to($this->user)->send(new PostPublished($this));
    }
}
```

---

## 3. Service Layer Pattern

### When to Use Services
- ✅ Complex business logic
- ✅ Multiple model interactions
- ✅ External API integrations
- ✅ Logic used across multiple controllers

**Example:**
```php
// app/Services/OrderService.php
class OrderService
{
    public function __construct(
        private readonly OrderRepository $orders,
        private readonly PaymentService $payments,
        private readonly InventoryService $inventory,
        private readonly NotificationService $notifications
    ) {}

    public function createOrder(User $user, array $items): Order
    {
        DB::transaction(function () use ($user, $items) {
            // Check inventory
            $this->inventory->checkAvailability($items);

            // Create order
            $order = $this->orders->create([
                'user_id' => $user->id,
                'total' => $this->calculateTotal($items),
                'status' => OrderStatus::Pending,
            ]);

            // Add items
            foreach ($items as $item) {
                $order->items()->create($item);
            }

            // Reserve inventory
            $this->inventory->reserve($items);

            // Send confirmation
            $this->notifications->sendOrderConfirmation($order);

            return $order;
        });
    }

    private function calculateTotal(array $items): float
    {
        return collect($items)->sum(fn($item) => $item['price'] * $item['quantity']);
    }
}
```

---

## 4. Repository Pattern

### When to Use Repositories
- ✅ Abstract database queries from business logic
- ✅ Make testing easier (mockable)
- ✅ Reusable query logic
- ✅ Consistent data access layer

**Example:**
```php
// app/Repositories/UserRepository.php
class UserRepository
{
    public function __construct(
        private readonly User $model
    ) {}

    public function findById(int $id): ?User
    {
        return $this->model->find($id);
    }

    public function findByEmail(string $email): ?User
    {
        return $this->model->where('email', $email)->first();
    }

    public function create(array $data): User
    {
        return $this->model->create($data);
    }

    public function getActiveUsers(): Collection
    {
        return $this->model
            ->where('status', UserStatus::Active)
            ->orderBy('name')
            ->get();
    }

    public function searchUsers(string $query): Collection
    {
        return $this->model
            ->where('name', 'like', "%{$query}%")
            ->orWhere('email', 'like', "%{$query}%")
            ->limit(50)
            ->get();
    }
}

// Usage in Service/Action
class CreateUserAction
{
    public function __construct(
        private readonly UserRepository $users
    ) {}

    public function execute(array $data): User
    {
        // Check if email exists
        if ($this->users->findByEmail($data['email'])) {
            throw new DuplicateEmailException();
        }

        return $this->users->create($data);
    }
}
```

---

## 5. Request Validation

### Form Request Classes
- ✅ One FormRequest per endpoint/action
- ✅ Include authorization logic
- ✅ Custom error messages
- ✅ Use Rule objects for complex validation

**Example:**
```php
// app/Http/Requests/CreatePostRequest.php
class CreatePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Check if user can create posts
        return $this->user()->can('create', Post::class);
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255', 'unique:posts,title'],
            'content' => ['required', 'string', 'min:100'],
            'status' => ['required', new Enum(PostStatus::class)],
            'tags' => ['nullable', 'array', 'max:5'],
            'tags.*' => ['integer', 'exists:tags,id'],
            'published_at' => ['nullable', 'date', 'after:now'],
            'featured_image' => ['nullable', 'image', 'max:2048'],
        ];
    }

    public function messages(): array
    {
        return [
            'title.required' => 'Vui lòng nhập tiêu đề bài viết.',
            'content.min' => 'Nội dung phải có ít nhất 100 ký tự.',
            'tags.max' => 'Bạn chỉ có thể chọn tối đa 5 thẻ.',
        ];
    }

    public function attributes(): array
    {
        return [
            'title' => 'tiêu đề',
            'content' => 'nội dung',
            'tags' => 'thẻ',
        ];
    }

    // Custom validation logic
    protected function prepareForValidation(): void
    {
        $this->merge([
            'slug' => Str::slug($this->title),
        ]);
    }
}
```

---

## 6. API Resources

### Resource Classes for JSON Responses
- ✅ Use for consistent API responses
- ✅ Control what data is exposed
- ✅ Handle nested relationships efficiently

**Example:**
```php
// app/Http/Resources/PostResource.php
class PostResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'excerpt' => $this->excerpt,
            'content' => $this->when(
                $request->user()?->can('view', $this->resource),
                $this->content
            ),
            'status' => $this->status->value,
            'featured_image' => $this->featured_image,

            // Relationships
            'author' => new UserResource($this->whenLoaded('user')),
            'tags' => TagResource::collection($this->whenLoaded('tags')),

            // Counts
            'comments_count' => $this->when(
                $this->relationLoaded('comments'),
                $this->comments_count
            ),

            // Timestamps
            'published_at' => $this->published_at?->toIso8601String(),
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}

// Usage in Controller
class PostController extends Controller
{
    public function index()
    {
        $posts = Post::with(['user', 'tags'])
            ->published()
            ->paginate(15);

        return PostResource::collection($posts);
    }

    public function show(Post $post)
    {
        $post->load(['user', 'tags', 'comments']);

        return new PostResource($post);
    }
}
```

---

## 7. Route Organization

### Route Naming & Organization
- ✅ Use resource routes when possible
- ✅ Group related routes
- ✅ Use route names for URL generation
- ✅ Prefix API routes with version

**Example:**
```php
// routes/api.php
Route::prefix('v1')->group(function () {
    // Public routes
    Route::post('/register', [AuthController::class, 'register'])
        ->name('api.v1.register');
    Route::post('/login', [AuthController::class, 'login'])
        ->name('api.v1.login');

    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout'])
            ->name('api.v1.logout');

        // Posts
        Route::apiResource('posts', PostController::class)
            ->names([
                'index' => 'api.v1.posts.index',
                'store' => 'api.v1.posts.store',
                'show' => 'api.v1.posts.show',
                'update' => 'api.v1.posts.update',
                'destroy' => 'api.v1.posts.destroy',
            ]);

        // Custom actions
        Route::post('posts/{post}/publish', [PostController::class, 'publish'])
            ->name('api.v1.posts.publish');
        Route::post('posts/{post}/archive', [PostController::class, 'archive'])
            ->name('api.v1.posts.archive');
    });
});

// routes/web.php
Route::middleware(['web', 'auth'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])
        ->name('dashboard');

    Route::prefix('admin')->middleware('can:access-admin')->group(function () {
        Route::resource('users', Admin\UserController::class);
        Route::resource('posts', Admin\PostController::class);
    });
});
```

---

## 8. Dependency Injection

### Constructor Injection (Preferred)
- ✅ Use constructor injection for dependencies
- ✅ Type-hint interfaces when possible
- ✅ Use Laravel's service container
- ❌ Avoid using Facades when DI is better

**Example:**
```php
// ✅ Good - Constructor injection
class PostController extends Controller
{
    public function __construct(
        private readonly PostService $postService,
        private readonly UserRepository $users
    ) {}

    public function store(CreatePostRequest $request): JsonResponse
    {
        $post = $this->postService->createPost(
            $request->user(),
            $request->validated()
        );

        return new PostResource($post);
    }
}

// ❌ Bad - Using Facades everywhere
class PostController extends Controller
{
    public function store(Request $request)
    {
        $post = Post::create($request->all());
        Mail::to($request->user())->send(new PostCreated($post));
        Cache::forget('posts');
        return response()->json($post);
    }
}

// Interface binding in AppServiceProvider
class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            UserRepositoryInterface::class,
            UserRepository::class
        );

        $this->app->singleton(
            PaymentGatewayInterface::class,
            StripePaymentGateway::class
        );
    }
}
```

---

## 9. Naming Conventions

### Laravel Naming Standards

| Component | Convention | Example |
|-----------|-----------|---------|
| Controller | PascalCase + Controller | `UserController`, `PostApiController` |
| Model | PascalCase (singular) | `User`, `Post`, `OrderItem` |
| Table | snake_case (plural) | `users`, `posts`, `order_items` |
| Column | snake_case | `user_id`, `created_at`, `is_active` |
| Foreign Key | singular_table_id | `user_id`, `post_id`, `category_id` |
| Route Name | dot.notation | `posts.index`, `api.v1.users.show` |
| Method | camelCase | `store()`, `updateProfile()`, `deleteAccount()` |
| Variable | camelCase | `$userName`, `$postData`, `$isActive` |
| Constant | UPPER_SNAKE_CASE | `MAX_UPLOAD_SIZE`, `DEFAULT_TIMEOUT` |
| Trait | PascalCase | `Searchable`, `Auditable`, `Publishable` |
| Interface | PascalCase + Interface | `PaymentGatewayInterface` |
| Action | PascalCase + Action | `CreateUserAction`, `SendEmailAction` |
| Job | PascalCase + Job | `ProcessPaymentJob`, `SendEmailJob` |
| Event | PascalCase (past tense) | `UserRegistered`, `OrderPlaced` |
| Listener | PascalCase + Listener | `SendWelcomeEmailListener` |
| Request | PascalCase + Request | `CreatePostRequest`, `UpdateUserRequest` |
| Resource | PascalCase + Resource | `UserResource`, `PostResource` |
| Collection | PascalCase + Collection | `PostCollection` |
| Enum | PascalCase | `UserStatus`, `OrderStatus`, `PaymentMethod` |

---

## 10. Query Optimization

### Eager Loading
```php
// ❌ Bad - N+1 Query Problem
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->user->name; // N queries
}

// ✅ Good - Eager Loading
$posts = Post::with('user')->get();
foreach ($posts as $post) {
    echo $post->user->name; // Just 2 queries
}

// ✅ Good - Nested Eager Loading
$posts = Post::with(['user', 'comments.user', 'tags'])->get();

// ✅ Good - Conditional Eager Loading
$posts = Post::when($includeUser, fn($q) => $q->with('user'))->get();
```

### Query Scopes
```php
// Model
class Post extends Model
{
    public function scopePublished($query)
    {
        return $query->where('status', PostStatus::Published);
    }

    public function scopeRecent($query, int $days = 7)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }
}

// Usage
$posts = Post::published()->recent(30)->get();
```

---

## 11. Events & Listeners

### Use Events for Decoupling
```php
// app/Events/UserRegistered.php
class UserRegistered
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly User $user
    ) {}
}

// app/Listeners/SendWelcomeEmail.php
class SendWelcomeEmail
{
    public function handle(UserRegistered $event): void
    {
        Mail::to($event->user)->send(new WelcomeEmail($event->user));
    }
}

// app/Listeners/CreateDefaultSettings.php
class CreateDefaultSettings
{
    public function handle(UserRegistered $event): void
    {
        Setting::create([
            'user_id' => $event->user->id,
            'theme' => 'light',
            'notifications' => true,
        ]);
    }
}

// EventServiceProvider
protected $listen = [
    UserRegistered::class => [
        SendWelcomeEmail::class,
        CreateDefaultSettings::class,
        LogUserRegistration::class,
    ],
];

// Dispatch event
event(new UserRegistered($user));
```

---

## 12. Jobs & Queues

### Queue Heavy Operations
```php
// app/Jobs/ProcessVideoUpload.php
class ProcessVideoUpload implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $tries = 3;
    public $timeout = 300;

    public function __construct(
        public readonly Video $video,
        public readonly string $filePath
    ) {}

    public function handle(VideoProcessor $processor): void
    {
        $processor->transcode($this->video, $this->filePath);

        $this->video->update([
            'status' => VideoStatus::Processed,
            'processed_at' => now(),
        ]);
    }

    public function failed(Throwable $exception): void
    {
        $this->video->update([
            'status' => VideoStatus::Failed,
            'error' => $exception->getMessage(),
        ]);
    }
}

// Dispatch job
ProcessVideoUpload::dispatch($video, $filePath)
    ->onQueue('videos')
    ->delay(now()->addMinutes(5));
```

---

## 13. Testing Standards

### Feature Tests
```php
// tests/Feature/PostTest.php
class PostTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_post(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/posts', [
                'title' => 'Test Post',
                'content' => 'This is test content that is long enough to pass validation rules.',
                'status' => 'published',
            ]);

        $response->assertCreated()
            ->assertJsonStructure([
                'data' => ['id', 'title', 'content', 'status']
            ]);

        $this->assertDatabaseHas('posts', [
            'title' => 'Test Post',
            'user_id' => $user->id,
        ]);
    }
}
```

---

## 14. Security Best Practices

### Essential Security Measures
```php
// ✅ Always validate input
class CreateUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8|confirmed',
        ];
    }
}

// ✅ Use mass assignment protection
class User extends Model
{
    protected $fillable = ['name', 'email', 'password'];
}

// ✅ Hash passwords
$user->password = Hash::make($request->password);

// ✅ Use policies for authorization
class PostPolicy
{
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}

// ✅ Escape output in Blade
{{ $user->bio }} // Auto-escaped
{!! $trustedHtml !!} // Not escaped (careful!)

// ✅ Use CSRF protection
<form method="POST">
    @csrf
    <!-- form fields -->
</form>
```

---

## 15. Performance Optimization

### Caching
```php
// ✅ Cache expensive queries
$posts = Cache::remember('posts:published', 3600, function () {
    return Post::with('user')
        ->published()
        ->orderBy('created_at', 'desc')
        ->get();
});

// ✅ Cache tags for easier invalidation
Cache::tags(['posts', 'homepage'])
    ->remember('homepage:posts', 3600, fn() => Post::latest()->take(10)->get());

Cache::tags(['posts'])->flush(); // Clear all posts cache
```

### Pagination
```php
// ✅ Always paginate large datasets
$posts = Post::paginate(15);

// ✅ Cursor pagination for large tables
$posts = Post::cursorPaginate(50);
```

---

## 16. Documentation & Comments

### PHPDoc Standards
```php
/**
 * Create a new user in the system.
 *
 * This method creates a new user with the provided data, sends a welcome email,
 * and creates default settings for the user.
 *
 * @param  CreateUserData  $data  The user data transfer object
 * @return User  The newly created user instance
 * @throws DuplicateEmailException  If the email already exists
 * @throws \Exception  If user creation fails
 */
public function createUser(CreateUserData $data): User
{
    // Implementation
}
```

---

## 17. Laravel Best Practices Checklist

### Development
- [ ] Use FormRequests for validation
- [ ] Implement API Resources for JSON responses
- [ ] Use Policies for authorization
- [ ] Eager load relationships to avoid N+1
- [ ] Use transactions for multi-step operations
- [ ] Queue heavy operations (emails, file processing)
- [ ] Cache expensive queries
- [ ] Use Enums for fixed sets of values (PHP 8.1+)

### Architecture
- [ ] Keep controllers thin
- [ ] Extract business logic to Services/Actions
- [ ] Use Repository pattern for complex queries
- [ ] Use Events for decoupled features
- [ ] Follow single responsibility principle
- [ ] Use dependency injection over Facades

### Security
- [ ] Validate all user input
- [ ] Use mass assignment protection
- [ ] Hash passwords with bcrypt/argon2
- [ ] Implement CSRF protection
- [ ] Use policies for authorization
- [ ] Never expose sensitive data in APIs
- [ ] Set `APP_DEBUG=false` in production

### Performance
- [ ] Use indexes on frequently queried columns
- [ ] Implement caching strategy
- [ ] Paginate large result sets
- [ ] Optimize database queries
- [ ] Use queue for heavy operations
- [ ] Enable opcache in production

---

## References

- [Laravel Documentation](https://laravel.com/docs)
- [Laravel Best Practices](https://github.com/alexeymezenin/laravel-best-practices)
- [Spatie Laravel Guidelines](https://spatie.be/guidelines/laravel-php)
- [Laravel Beyond CRUD](https://laravel-beyond-crud.com/)
- [Laravel Package Development](https://laravel.com/docs/packages)

