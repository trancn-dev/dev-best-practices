# Rule: Laravel PHP Best Practices

## Intent
Enforce Laravel framework-specific patterns, conventions, and best practices for building maintainable PHP applications.

## Scope
Applies to all Laravel projects including controllers, models, services, migrations, and Laravel-specific features.

---

## 1. Project Structure

### Feature Module Organization

```
app/
├── Modules/
│   ├── User/
│   │   ├── Controllers/UserController.php
│   │   ├── Models/User.php
│   │   ├── Requests/StoreUserRequest.php
│   │   ├── Services/UserService.php
│   │   ├── Repositories/UserRepository.php
│   │   └── Resources/UserResource.php
│   └── Product/
│       ├── Controllers/ProductController.php
│       ├── Models/Product.php
│       └── Services/ProductService.php
```

---

## 2. Naming Conventions

### Controllers

- ✅ **MUST** use singular noun + `Controller` suffix (PascalCase)
- ✅ **MUST** follow resource naming for CRUD operations

```php
// ✅ GOOD
UserController.php
ProductController.php
OrderController.php

// ❌ BAD
UsersController.php
user_controller.php
```

### Models

- ✅ **MUST** use singular noun (PascalCase)
- ✅ **MUST** match table name (singular model, plural table)

```php
// ✅ GOOD - Model
class User extends Model
{
    protected $table = 'users'; // Plural table name
}

// ❌ BAD
class Users extends Model // Wrong - plural model name
```

---

## 3. Controllers

### Single Responsibility

```php
// ✅ GOOD - Thin controller
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreUserRequest;
use App\Services\UserService;

class UserController extends Controller
{
    public function __construct(
        private UserService $userService
    ) {}

    public function index()
    {
        return response()->json([
            'data' => $this->userService->getAllUsers()
        ]);
    }

    public function store(StoreUserRequest $request)
    {
        $user = $this->userService->createUser($request->validated());

        return response()->json([
            'data' => $user,
            'message' => 'User created successfully'
        ], 201);
    }
}

// ❌ BAD - Fat controller with business logic
class UserController extends Controller
{
    public function store(Request $request)
    {
        // Validation in controller
        $request->validate([
            'name' => 'required',
            'email' => 'required|email'
        ]);

        // Business logic in controller
        $user = new User();
        $user->name = $request->name;
        $user->email = $request->email;
        $user->password = bcrypt($request->password);
        $user->save();

        // Email logic in controller
        Mail::to($user->email)->send(new WelcomeEmail($user));

        return response()->json($user);
    }
}
```

### Resource Controllers

```php
// ✅ GOOD - Use resource controllers for CRUD
Route::resource('users', UserController::class);

class UserController extends Controller
{
    public function index() {}      // GET /users
    public function create() {}     // GET /users/create
    public function store($request) {}  // POST /users
    public function show($id) {}    // GET /users/{id}
    public function edit($id) {}    // GET /users/{id}/edit
    public function update($request, $id) {} // PUT/PATCH /users/{id}
    public function destroy($id) {} // DELETE /users/{id}
}
```

---

## 4. Models & Eloquent

### Model Structure

```php
// ✅ GOOD - Well-organized model
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\{Model, SoftDeletes, Factories\HasFactory};
use Illuminate\Database\Eloquent\Relations\{HasMany, BelongsTo};

class User extends Model
{
    use HasFactory, SoftDeletes;

    // 1. Constants
    const STATUS_ACTIVE = 1;
    const STATUS_INACTIVE = 0;

    // 2. Properties
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

    // 5. Scopes
    public function scopeActive($query)
    {
        return $query->where('status', self::STATUS_ACTIVE);
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

    // 7. Business methods
    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }
}
```

### Query Optimization

```php
// ✅ GOOD - Eager loading (avoid N+1)
$users = User::with(['posts', 'profile'])->get();

// ✅ GOOD - Select only needed columns
$users = User::select('id', 'name', 'email')->get();

// ✅ GOOD - Chunk for large datasets
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process user
    }
});

// ❌ BAD - N+1 query problem
$users = User::all();
foreach ($users as $user) {
    echo $user->posts; // Separate query each iteration
}
```

### Scopes

```php
// ✅ GOOD - Local scopes
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

// Usage
$users = User::active()->popular(500)->get();
```

---

## 5. Service Layer

```php
// ✅ GOOD - Service layer for business logic
<?php

namespace App\Services;

use App\Models\User;
use App\Repositories\UserRepository;
use Illuminate\Support\Facades\{DB, Hash, Mail};

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
                'password' => Hash::make($data['password'])
            ]);

            Mail::to($user->email)->send(new WelcomeEmail($user));

            return $user;
        });
    }

    public function updateUser(User $user, array $data): User
    {
        return $this->userRepository->update($user, $data);
    }
}
```

---

## 6. Repository Pattern

```php
// ✅ GOOD - Repository for data access
<?php

namespace App\Repositories;

use App\Models\User;
use Illuminate\Database\Eloquent\Collection;

class UserRepository
{
    public function create(array $data): User
    {
        return User::create($data);
    }

    public function find(int $id): ?User
    {
        return User::find($id);
    }

    public function findByEmail(string $email): ?User
    {
        return User::where('email', $email)->first();
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

    public function getAllActive(): Collection
    {
        return User::active()->get();
    }
}
```

---

## 7. Validation

### Form Requests

```php
// ✅ GOOD - Form Request validation
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'email' => [
                'required',
                'email',
                Rule::unique('users')->ignore($this->user)
            ],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'role' => ['required', Rule::in(['admin', 'user'])],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Name is required',
            'email.unique' => 'Email already exists',
        ];
    }
}

// ❌ BAD - Validation in controller
public function store(Request $request)
{
    $request->validate([
        'name' => 'required',
        'email' => 'required|email|unique:users'
    ]);
}
```

---

## 8. Migrations

```php
// ✅ GOOD - Complete migration with indexes
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

### Foreign Keys

```php
// ✅ GOOD - Foreign key with cascade
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')
          ->constrained()
          ->onDelete('cascade');
    $table->string('title');
    $table->text('content');
    $table->timestamps();

    $table->index(['user_id', 'created_at']);
});
```

---

## 9. API Resources

```php
// ✅ GOOD - API Resource transformation
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at->toIso8601String(),
            'posts' => PostResource::collection($this->whenLoaded('posts')),
        ];
    }
}

// Usage in controller
return UserResource::collection($users);
return new UserResource($user);
```

---

## 10. Copilot Instructions

When generating Laravel code, Copilot **MUST**:

1. **USE** dependency injection for services
2. **CREATE** Form Requests for validation
3. **IMPLEMENT** repository pattern for data access
4. **ADD** type hints for all parameters and return types
5. **USE** eager loading to prevent N+1 queries
6. **IMPLEMENT** service layer for business logic
7. **USE** API Resources for response transformation
8. **ADD** proper indexes to migrations
9. **FOLLOW** Laravel naming conventions strictly
10. **USE** transactions for multi-step operations

---

## Checklist

### Controller
- [ ] Uses dependency injection
- [ ] Max 7 methods (standard resource actions)
- [ ] No business logic in controller
- [ ] Uses Form Requests for validation
- [ ] Returns API Resources

### Model
- [ ] Mass assignment protected ($fillable or $guarded)
- [ ] Relationships defined with type hints
- [ ] Uses $casts for type conversion
- [ ] Scopes for reusable queries
- [ ] Accessors/Mutators for data transformation

### Service Layer
- [ ] Business logic extracted from controller
- [ ] Uses repository for data access
- [ ] Uses transactions for multi-step operations
- [ ] Handles exceptions appropriately

### Migration
- [ ] Has both up() and down() methods
- [ ] Defines column lengths
- [ ] Includes indexes for foreign keys
- [ ] Uses proper foreign key constraints

---

## References

- Laravel Documentation (laravel.com/docs)
- Laravel Best Practices (github.com/alexeymezenin/laravel-best-practices)
- Spatie Laravel Guidelines (spatie.be/guidelines/laravel-php)

**Remember:** Fat models, skinny controllers, thin services with repositories.
