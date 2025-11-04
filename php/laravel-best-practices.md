# Laravel PHP - Best Practices & Coding Standards

## Mục lục
1. [Cấu trúc dự án](#cấu-trúc-dự-án)
2. [Naming Conventions](#naming-conventions)
3. [Controllers](#controllers)
4. [Models & Eloquent](#models--eloquent)
5. [Database & Migrations](#database--migrations)
6. [Validation](#validation)
7. [Routes](#routes)
8. [Views & Blade Templates](#views--blade-templates)
9. [Service Layer](#service-layer)
10. [Repository Pattern](#repository-pattern)
11. [Request & Response](#request--response)
12. [Security](#security)
13. [Performance](#performance)
14. [Testing](#testing)

---

## Cấu trúc dự án

### Tổ chức thư mục chuẩn

```
app/
├── Console/
├── Exceptions/
├── Http/
│   ├── Controllers/
│   │   ├── Api/
│   │   └── Web/
│   ├── Middleware/
│   ├── Requests/
│   └── Resources/
├── Models/
├── Services/
├── Repositories/
├── Traits/
├── Helpers/
└── Providers/
```

### Nguyên tắc tổ chức

**✅ ĐÚNG:**
```php
// Tổ chức theo feature modules
app/
├── Modules/
│   ├── User/
│   │   ├── Controllers/
│   │   ├── Models/
│   │   ├── Requests/
│   │   ├── Services/
│   │   └── Resources/
│   └── Product/
│       ├── Controllers/
│       ├── Models/
│       └── Services/
```

**❌ SAI:**
```php
// Tất cả logic trong Controllers
app/Http/Controllers/
├── UserController.php (500+ lines)
├── ProductController.php (800+ lines)
```

---

## Naming Conventions

### Controllers

**✅ ĐÚNG:**
```php
// Số ít, PascalCase, suffix "Controller"
UserController.php
ProductController.php
OrderController.php
```

**❌ SAI:**
```php
UsersController.php
user_controller.php
Usercontroller.php
```

### Models

**✅ ĐÚNG:**
```php
// Số ít, PascalCase
User.php
Product.php
OrderItem.php
```

**❌ SAI:**
```php
Users.php
product.php
Order_Item.php
```

### Methods

**✅ ĐÚNG:**
```php
// camelCase
public function getUserById($id)
public function storeProduct(Request $request)
public function updateOrderStatus($orderId)
```

**❌ SAI:**
```php
public function GetUserById($id)
public function store_product(Request $request)
public function Update_order_status($orderId)
```

### Variables

**✅ ĐÚNG:**
```php
$userName = 'John';
$productList = [];
$isActive = true;
$totalAmount = 0;
```

**❌ SAI:**
```php
$UserName = 'John';
$product_list = [];
$is_active = true;
$TotalAmount = 0;
```

---

## Controllers

### Single Responsibility Principle

**✅ ĐÚNG:**
```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreUserRequest;
use App\Services\UserService;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    public function __construct(
        private UserService $userService
    ) {}

    public function index(): JsonResponse
    {
        $users = $this->userService->getAllUsers();

        return response()->json([
            'data' => $users
        ]);
    }

    public function store(StoreUserRequest $request): JsonResponse
    {
        $user = $this->userService->createUser($request->validated());

        return response()->json([
            'data' => $user,
            'message' => 'User created successfully'
        ], 201);
    }
}
```

**❌ SAI:**
```php
<?php

class UserController extends Controller
{
    public function store(Request $request)
    {
        // Validation trong controller
        $request->validate([
            'name' => 'required',
            'email' => 'required|email'
        ]);

        // Business logic trong controller
        $user = new User();
        $user->name = $request->name;
        $user->email = $request->email;
        $user->password = bcrypt($request->password);
        $user->save();

        // Email logic trong controller
        Mail::to($user->email)->send(new WelcomeEmail($user));

        // Log trong controller
        Log::info('User created: ' . $user->id);

        return response()->json($user);
    }
}
```

### Resource Controllers

**✅ ĐÚNG:**
```php
// Sử dụng resource controllers cho CRUD operations
Route::resource('users', UserController::class);

class UserController extends Controller
{
    public function index() {} // GET /users
    public function create() {} // GET /users/create
    public function store(Request $request) {} // POST /users
    public function show($id) {} // GET /users/{id}
    public function edit($id) {} // GET /users/{id}/edit
    public function update(Request $request, $id) {} // PUT/PATCH /users/{id}
    public function destroy($id) {} // DELETE /users/{id}
}
```

### Dependency Injection

**✅ ĐÚNG:**
```php
class UserController extends Controller
{
    public function __construct(
        private UserService $userService,
        private LoggerInterface $logger
    ) {}

    public function store(StoreUserRequest $request)
    {
        try {
            $user = $this->userService->createUser($request->validated());
            $this->logger->info('User created', ['user_id' => $user->id]);

            return response()->json($user, 201);
        } catch (\Exception $e) {
            $this->logger->error('User creation failed', ['error' => $e->getMessage()]);
            throw $e;
        }
    }
}
```

---

## Models & Eloquent

### Model Structure

**✅ ĐÚNG:**
```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class User extends Model
{
    use HasFactory, SoftDeletes;

    // 1. Constants
    const STATUS_ACTIVE = 1;
    const STATUS_INACTIVE = 0;

    // 2. Properties
    protected $table = 'users';

    protected $fillable = [
        'name',
        'email',
        'password',
        'status'
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'status' => 'boolean',
        'metadata' => 'array'
    ];

    protected $dates = [
        'created_at',
        'updated_at',
        'deleted_at'
    ];

    // 3. Boot methods
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($user) {
            $user->uuid = Str::uuid();
        });
    }

    // 4. Relationships
    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }

    public function profile(): HasOne
    {
        return $this->hasOne(Profile::class);
    }

    // 5. Scopes
    public function scopeActive($query)
    {
        return $query->where('status', self::STATUS_ACTIVE);
    }

    public function scopeVerified($query)
    {
        return $query->whereNotNull('email_verified_at');
    }

    // 6. Accessors & Mutators
    public function getFullNameAttribute(): string
    {
        return "{$this->first_name} {$this->last_name}";
    }

    public function setPasswordAttribute($value): void
    {
        $this->attributes['password'] = bcrypt($value);
    }

    // 7. Business logic methods
    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }

    public function activate(): void
    {
        $this->update(['status' => self::STATUS_ACTIVE]);
    }
}
```

### Mass Assignment Protection

**✅ ĐÚNG:**
```php
// Sử dụng $fillable (whitelist approach - Recommended)
protected $fillable = [
    'name',
    'email',
    'phone'
];

// HOẶC sử dụng $guarded (blacklist approach)
protected $guarded = [
    'id',
    'is_admin',
    'created_at'
];
```

**❌ SAI:**
```php
// Không bảo vệ mass assignment
protected $guarded = [];

// Hoặc không khai báo gì cả
```

### Eloquent Query Optimization

**✅ ĐÚNG:**
```php
// Eager loading để tránh N+1 query
$users = User::with(['posts', 'profile'])->get();

// Lazy eager loading
$users = User::all();
$users->load('posts');

// Select chỉ các columns cần thiết
$users = User::select('id', 'name', 'email')->get();

// Sử dụng chunk cho large datasets
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process user
    }
});

// Sử dụng cursor cho memory efficiency
foreach (User::cursor() as $user) {
    // Process user
}
```

**❌ SAI:**
```php
// N+1 query problem
$users = User::all();
foreach ($users as $user) {
    echo $user->posts; // Mỗi iteration tạo 1 query mới
}

// Select all columns khi không cần thiết
$users = User::all();
foreach ($users as $user) {
    echo $user->name; // Chỉ cần name nhưng query tất cả columns
}
```

### Scopes

**✅ ĐÚNG:**
```php
// Local scopes
class User extends Model
{
    public function scopeActive($query)
    {
        return $query->where('status', 1);
    }

    public function scopePopular($query, $threshold = 100)
    {
        return $query->where('followers', '>', $threshold);
    }
}

// Sử dụng
$users = User::active()->popular(500)->get();

// Global scopes
class ActiveScope implements Scope
{
    public function apply(Builder $builder, Model $model)
    {
        $builder->where('active', 1);
    }
}

class User extends Model
{
    protected static function booted()
    {
        static::addGlobalScope(new ActiveScope);
    }
}
```

---

## Database & Migrations

### Migration Best Practices

**✅ ĐÚNG:**
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('name', 100);
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->boolean('is_active')->default(true);
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();

            // Indexes
            $table->index('email');
            $table->index('is_active');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
```

**❌ SAI:**
```php
// Migration không có down() method
public function down(): void
{
    // Empty
}

// Không xác định độ dài cho string columns
$table->string('name');

// Không có indexes cho columns thường xuyên query
$table->string('email')->unique(); // OK
// Nhưng thiếu index cho status, type, etc.
```

### Foreign Keys & Relationships

**✅ ĐÚNG:**
```php
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')
          ->constrained()
          ->onDelete('cascade');
    $table->string('title');
    $table->text('content');
    $table->timestamps();

    // Composite indexes
    $table->index(['user_id', 'created_at']);
});

// Hoặc
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('user_id');
    $table->string('title');
    $table->text('content');
    $table->timestamps();

    $table->foreign('user_id')
          ->references('id')
          ->on('users')
          ->onDelete('cascade');
});
```

### Seeders

**✅ ĐÚNG:**
```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Admin user
        User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'is_admin' => true,
        ]);

        // Test users
        User::factory(50)->create();
    }
}
```

---

## Validation

### Form Request Validation

**✅ ĐÚNG:**
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Hoặc kiểm tra authorization logic
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique('users')->ignore($this->user)
            ],
            'password' => [
                'required',
                'string',
                'min:8',
                'confirmed',
                'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).*$/'
            ],
            'role' => ['required', Rule::in(['admin', 'user', 'moderator'])],
            'phone' => ['nullable', 'regex:/^([0-9\s\-\+\(\)]*)$/', 'min:10'],
            'avatar' => ['nullable', 'image', 'max:2048'], // 2MB
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Tên là bắt buộc',
            'email.unique' => 'Email đã tồn tại trong hệ thống',
            'password.regex' => 'Mật khẩu phải chứa chữ hoa, chữ thường và số',
        ];
    }

    public function attributes(): array
    {
        return [
            'name' => 'tên người dùng',
            'email' => 'địa chỉ email',
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'slug' => Str::slug($this->name),
        ]);
    }
}
```

### Custom Validation Rules

**✅ ĐÚNG:**
```php
<?php

namespace App\Rules;

use Illuminate\Contracts\Validation\Rule;

class PhoneNumber implements Rule
{
    public function passes($attribute, $value): bool
    {
        return preg_match('/^0[0-9]{9}$/', $value);
    }

    public function message(): string
    {
        return 'Số điện thoại không hợp lệ. Định dạng: 0xxxxxxxxx';
    }
}

// Sử dụng
public function rules(): array
{
    return [
        'phone' => ['required', new PhoneNumber],
    ];
}
```

---

## Routes

### Route Organization

**✅ ĐÚNG:**
```php
// routes/api.php - Tổ chức theo version và resource
Route::prefix('v1')->group(function () {
    // Public routes
    Route::post('login', [AuthController::class, 'login']);
    Route::post('register', [AuthController::class, 'register']);

    // Protected routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::apiResource('users', UserController::class);
        Route::apiResource('posts', PostController::class);

        Route::prefix('profile')->group(function () {
            Route::get('/', [ProfileController::class, 'show']);
            Route::put('/', [ProfileController::class, 'update']);
            Route::post('avatar', [ProfileController::class, 'updateAvatar']);
        });
    });
});

// Hoặc sử dụng Route files riêng
// routes/api/v1/users.php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('users', [UserController::class, 'index'])->name('users.index');
    Route::post('users', [UserController::class, 'store'])->name('users.store');
    Route::get('users/{user}', [UserController::class, 'show'])->name('users.show');
    Route::put('users/{user}', [UserController::class, 'update'])->name('users.update');
    Route::delete('users/{user}', [UserController::class, 'destroy'])->name('users.destroy');
});
```

### Route Model Binding

**✅ ĐÚNG:**
```php
// Implicit binding
Route::get('users/{user}', [UserController::class, 'show']);

class UserController extends Controller
{
    public function show(User $user)
    {
        return response()->json($user);
    }
}

// Custom key binding
Route::get('users/{user:uuid}', [UserController::class, 'show']);

// Explicit binding trong RouteServiceProvider
public function boot(): void
{
    Route::model('user', User::class);

    Route::bind('user', function ($value) {
        return User::where('uuid', $value)->firstOrFail();
    });
}
```

---

## Views & Blade Templates

### Blade Components

**✅ ĐÚNG:**
```php
// resources/views/components/alert.blade.php
@props(['type' => 'info', 'message'])

<div class="alert alert-{{ $type }}" {{ $attributes }}>
    {{ $message ?? $slot }}
</div>

// Sử dụng
<x-alert type="success" message="User created successfully!" />
<x-alert type="error">
    Something went wrong!
</x-alert>
```

### Template Inheritance

**✅ ĐÚNG:**
```blade
{{-- resources/views/layouts/app.blade.php --}}
<!DOCTYPE html>
<html>
<head>
    <title>@yield('title', 'Default Title')</title>
    @stack('styles')
</head>
<body>
    <header>
        @include('partials.navigation')
    </header>

    <main>
        @yield('content')
    </main>

    <footer>
        @include('partials.footer')
    </footer>

    @stack('scripts')
</body>
</html>

{{-- resources/views/users/index.blade.php --}}
@extends('layouts.app')

@section('title', 'Users')

@push('styles')
    <link rel="stylesheet" href="/css/users.css">
@endpush

@section('content')
    <h1>Users</h1>

    @forelse($users as $user)
        <div class="user-card">
            <h2>{{ $user->name }}</h2>
            <p>{{ $user->email }}</p>
        </div>
    @empty
        <p>No users found.</p>
    @endforelse
@endsection

@push('scripts')
    <script src="/js/users.js"></script>
@endpush
```

---

## Service Layer

### Service Pattern

**✅ ĐÚNG:**
```php
<?php

namespace App\Services;

use App\Models\User;
use App\Repositories\UserRepository;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserService
{
    public function __construct(
        private UserRepository $userRepository
    ) {}

    public function createUser(array $data): User
    {
        return DB::transaction(function () use ($data) {
            $user = $this->userRepository->create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => Hash::make($data['password']),
            ]);

            // Additional business logic
            $this->assignDefaultRole($user);
            $this->sendWelcomeEmail($user);

            return $user;
        });
    }

    public function updateUser(User $user, array $data): User
    {
        return DB::transaction(function () use ($user, $data) {
            $user = $this->userRepository->update($user, $data);

            if (isset($data['role'])) {
                $this->updateUserRole($user, $data['role']);
            }

            return $user;
        });
    }

    private function assignDefaultRole(User $user): void
    {
        $user->assignRole('user');
    }

    private function sendWelcomeEmail(User $user): void
    {
        // Email logic
    }

    private function updateUserRole(User $user, string $role): void
    {
        $user->syncRoles([$role]);
    }
}
```

---

## Repository Pattern

### Repository Implementation

**✅ ĐÚNG:**
```php
<?php

namespace App\Repositories;

use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Pagination\LengthAwarePaginator;

class UserRepository
{
    public function all(): Collection
    {
        return User::all();
    }

    public function paginate(int $perPage = 15): LengthAwarePaginator
    {
        return User::paginate($perPage);
    }

    public function find(int $id): ?User
    {
        return User::find($id);
    }

    public function findOrFail(int $id): User
    {
        return User::findOrFail($id);
    }

    public function create(array $data): User
    {
        return User::create($data);
    }

    public function update(User $user, array $data): User
    {
        $user->update($data);
        return $user->fresh();
    }

    public function delete(User $user): bool
    {
        return $user->delete();
    }

    public function findByEmail(string $email): ?User
    {
        return User::where('email', $email)->first();
    }

    public function getActiveUsers(): Collection
    {
        return User::active()->get();
    }
}
```

---

## Request & Response

### API Resources

**✅ ĐÚNG:**
```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'name' => $this->name,
            'email' => $this->email,
            'avatar' => $this->avatar_url,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at->toISOString(),
            'posts_count' => $this->when($this->relationLoaded('posts'), function () {
                return $this->posts->count();
            }),
            'posts' => PostResource::collection($this->whenLoaded('posts')),
        ];
    }
}

// Resource Collection
class UserCollection extends ResourceCollection
{
    public function toArray(Request $request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'total' => $this->total(),
                'per_page' => $this->perPage(),
            ],
        ];
    }
}

// Sử dụng
return UserResource::collection($users);
return new UserResource($user);
```

### Consistent API Responses

**✅ ĐÚNG:**
```php
<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    protected function successResponse($data, string $message = null, int $code = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $code);
    }

    protected function errorResponse(string $message, int $code = 400, $errors = null): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => $errors,
        ], $code);
    }

    protected function paginatedResponse($data, string $message = null): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data->items(),
            'meta' => [
                'current_page' => $data->currentPage(),
                'last_page' => $data->lastPage(),
                'per_page' => $data->perPage(),
                'total' => $data->total(),
            ],
        ]);
    }
}

// Sử dụng trong Controller
class UserController extends Controller
{
    use ApiResponse;

    public function index()
    {
        $users = User::paginate(15);
        return $this->paginatedResponse($users, 'Users retrieved successfully');
    }

    public function store(StoreUserRequest $request)
    {
        $user = $this->userService->createUser($request->validated());
        return $this->successResponse($user, 'User created successfully', 201);
    }
}
```

---

## Security

### Authentication & Authorization

**✅ ĐÚNG:**
```php
// Sử dụng Laravel Sanctum cho API
// config/sanctum.php
'expiration' => 60 * 24, // 24 hours

// Login Controller
public function login(LoginRequest $request)
{
    $credentials = $request->only('email', 'password');

    if (!Auth::attempt($credentials)) {
        return $this->errorResponse('Invalid credentials', 401);
    }

    $user = Auth::user();
    $token = $user->createToken('api-token')->plainTextToken;

    return $this->successResponse([
        'user' => new UserResource($user),
        'token' => $token,
    ], 'Login successful');
}

// Policies
class UserPolicy
{
    public function update(User $authUser, User $user): bool
    {
        return $authUser->id === $user->id || $authUser->isAdmin();
    }

    public function delete(User $authUser, User $user): bool
    {
        return $authUser->isAdmin() && $authUser->id !== $user->id;
    }
}

// Controller with authorization
public function update(UpdateUserRequest $request, User $user)
{
    $this->authorize('update', $user);

    $updatedUser = $this->userService->updateUser($user, $request->validated());

    return $this->successResponse($updatedUser, 'User updated successfully');
}
```

### SQL Injection Prevention

**✅ ĐÚNG:**
```php
// Sử dụng Eloquent ORM
$users = User::where('email', $email)->get();

// Sử dụng Query Builder với parameter binding
$users = DB::table('users')
    ->where('email', '=', $email)
    ->get();

// Raw query với bindings
$users = DB::select('SELECT * FROM users WHERE email = ?', [$email]);
```

**❌ SAI:**
```php
// Không bao giờ concatenate user input vào query
$users = DB::select("SELECT * FROM users WHERE email = '$email'");
```

### XSS Prevention

**✅ ĐÚNG:**
```blade
{{-- Blade tự động escape --}}
{{ $user->name }}

{{-- Hiển thị HTML đã được sanitize --}}
{!! clean($content) !!}
```

**❌ SAI:**
```blade
{{-- Không escape raw HTML từ user input --}}
{!! $userInput !!}
```

### CSRF Protection

**✅ ĐÚNG:**
```blade
<form method="POST" action="/users">
    @csrf
    <!-- Form fields -->
</form>
```

---

## Performance

### Caching Strategies

**✅ ĐÚNG:**
```php
// Cache queries
$users = Cache::remember('users.active', 3600, function () {
    return User::active()->get();
});

// Cache tags (Redis, Memcached)
Cache::tags(['users', 'active'])->remember('users.active', 3600, function () {
    return User::active()->get();
});

// Invalidate cache
Cache::tags(['users'])->flush();

// Model caching
class User extends Model
{
    protected static function boot()
    {
        parent::boot();

        static::saved(function ($user) {
            Cache::forget("user.{$user->id}");
        });

        static::deleted(function ($user) {
            Cache::forget("user.{$user->id}");
        });
    }
}
```

### Database Optimization

**✅ ĐÚNG:**
```php
// Eager loading
$users = User::with(['posts', 'profile'])->get();

// Lazy eager loading
$users->load('posts');

// Select specific columns
$users = User::select('id', 'name', 'email')->get();

// Pagination
$users = User::paginate(15);

// Chunking
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process
    }
});

// Cursor (Memory efficient)
foreach (User::cursor() as $user) {
    // Process
}
```

### Queue Jobs

**✅ ĐÚNG:**
```php
<?php

namespace App\Jobs;

use App\Models\User;
use App\Mail\WelcomeEmail;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;

class SendWelcomeEmail implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public User $user
    ) {}

    public function handle(): void
    {
        Mail::to($this->user->email)->send(new WelcomeEmail($this->user));
    }

    public function failed(\Throwable $exception): void
    {
        // Handle failed job
    }
}

// Dispatch job
SendWelcomeEmail::dispatch($user);
SendWelcomeEmail::dispatch($user)->delay(now()->addMinutes(5));
SendWelcomeEmail::dispatch($user)->onQueue('emails');
```

---

## Testing

### Feature Tests

**✅ ĐÚNG:**
```php
<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_be_created(): void
    {
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'Password123',
            'password_confirmation' => 'Password123',
        ];

        $response = $this->postJson('/api/users', $userData);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'message',
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
    }

    public function test_user_cannot_be_created_with_duplicate_email(): void
    {
        User::factory()->create(['email' => 'john@example.com']);

        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'Password123',
            'password_confirmation' => 'Password123',
        ];

        $response = $this->postJson('/api/users', $userData);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_authenticated_user_can_update_own_profile(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->putJson("/api/users/{$user->id}", [
                'name' => 'Updated Name',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Name',
        ]);
    }
}
```

### Unit Tests

**✅ ĐÚNG:**
```php
<?php

namespace Tests\Unit;

use App\Models\User;
use App\Services\UserService;
use App\Repositories\UserRepository;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserServiceTest extends TestCase
{
    use RefreshDatabase;

    private UserService $userService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->userService = app(UserService::class);
    }

    public function test_user_can_be_created(): void
    {
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password',
        ];

        $user = $this->userService->createUser($userData);

        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals('John Doe', $user->name);
        $this->assertEquals('john@example.com', $user->email);
    }

    public function test_user_password_is_hashed(): void
    {
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password',
        ];

        $user = $this->userService->createUser($userData);

        $this->assertNotEquals('password', $user->password);
        $this->assertTrue(Hash::check('password', $user->password));
    }
}
```

---

## Checklist Tổng Hợp

### Code Quality
- [ ] Tuân thủ PSR-12 coding standards
- [ ] Sử dụng type hints cho parameters và return types
- [ ] Code có comments đầy đủ (PHPDoc)
- [ ] Không có code trùng lặp (DRY principle)
- [ ] Các methods không quá dài (< 50 lines)
- [ ] Các classes không quá lớn (Single Responsibility)

### Architecture
- [ ] Controllers chỉ xử lý HTTP requests/responses
- [ ] Business logic nằm trong Service layer
- [ ] Data access logic nằm trong Repository layer
- [ ] Sử dụng Dependency Injection
- [ ] Áp dụng SOLID principles

### Security
- [ ] Validation cho tất cả user inputs
- [ ] Sử dụng parameter binding cho queries
- [ ] CSRF protection enabled
- [ ] XSS protection (Blade auto-escaping)
- [ ] Authentication & Authorization đầy đủ
- [ ] Sensitive data được encrypted
- [ ] API rate limiting

### Performance
- [ ] Sử dụng eager loading tránh N+1
- [ ] Cache cho queries phức tạp
- [ ] Database indexes hợp lý
- [ ] Queue cho long-running tasks
- [ ] Pagination cho large datasets

### Testing
- [ ] Unit tests cho business logic
- [ ] Feature tests cho APIs/endpoints
- [ ] Test coverage > 80%
- [ ] Tests chạy pass trước khi commit

### Documentation
- [ ] API documentation (Swagger/OpenAPI)
- [ ] README với hướng dẫn setup
- [ ] Code comments cho logic phức tạp
- [ ] Database schema documentation

---

## Tài liệu tham khảo

- [Laravel Documentation](https://laravel.com/docs)
- [Laravel Best Practices](https://github.com/alexeymezenin/laravel-best-practices)
- [PHP The Right Way](https://phptherightway.com/)
- [PSR-12 Coding Standards](https://www.php-fig.org/psr/psr-12/)

---

**Cập nhật lần cuối:** November 1, 2025
