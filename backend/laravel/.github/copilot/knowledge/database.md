# Database Design & Standards

This document describes the database design principles, schema conventions, and query optimization strategies for the Laravel DevKit project.

---

## Table of Contents

1. [Database Design Principles](#database-design-principles)
2. [Schema Conventions](#schema-conventions)
3. [Migration Standards](#migration-standards)
4. [Relationships](#relationships)
5. [Indexing Strategy](#indexing-strategy)
6. [Query Optimization](#query-optimization)
7. [Data Integrity](#data-integrity)
8. [Seeding](#seeding)

---

## Database Design Principles

### 1. Normalization

Follow **Third Normal Form (3NF)** principles:

- **1NF**: Atomic values, no repeating groups
- **2NF**: No partial dependencies
- **3NF**: No transitive dependencies

**Example - Normalized Design**:
```
❌ Bad (denormalized):
users: id, name, email, project_name, project_status, project_deadline

✅ Good (normalized):
users: id, name, email
projects: id, user_id, name, status, deadline
```

### 2. Data Integrity

- Use foreign keys with constraints
- Define NOT NULL where appropriate
- Use UNIQUE constraints
- Set default values
- Use CHECK constraints (Laravel 10+)

### 3. Naming Conventions

- **Tables**: plural, snake_case: `users`, `project_templates`
- **Columns**: singular, snake_case: `user_id`, `created_at`
- **Primary keys**: `id` (bigint, auto-increment)
- **Foreign keys**: `{table_singular}_id` (e.g., `user_id`)
- **Timestamps**: `created_at`, `updated_at`
- **Soft deletes**: `deleted_at`
- **Pivot tables**: alphabetical order: `project_user`, not `user_project`

---

## Schema Conventions

### Standard Table Structure

```php
Schema::create('users', function (Blueprint $table) {
    // Primary key
    $table->id();

    // UUID for external references
    $table->uuid('uuid')->unique();

    // Attributes
    $table->string('name');
    $table->string('email')->unique();
    $table->string('password');
    $table->enum('role', ['admin', 'developer', 'guest'])->default('guest');
    $table->enum('status', ['active', 'suspended', 'deleted'])->default('active');

    // Nullable fields
    $table->timestamp('email_verified_at')->nullable();
    $table->string('phone')->nullable();
    $table->text('bio')->nullable();

    // Foreign keys
    $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();

    // Timestamps
    $table->timestamps();
    $table->softDeletes();

    // Indexes
    $table->index('email');
    $table->index('status');
    $table->index(['organization_id', 'role']);
});
```

### Column Types

| Laravel Type | MySQL Type | Usage |
|--------------|------------|-------|
| `id()` | BIGINT UNSIGNED | Primary key |
| `foreignId()` | BIGINT UNSIGNED | Foreign key |
| `uuid()` | CHAR(36) | UUID |
| `string($length)` | VARCHAR($length) | Short text (max 255) |
| `text()` | TEXT | Long text |
| `longText()` | LONGTEXT | Very long text |
| `integer()` | INT | Whole numbers |
| `bigInteger()` | BIGINT | Large numbers |
| `decimal($total, $places)` | DECIMAL | Money, precise decimals |
| `boolean()` | TINYINT(1) | True/false |
| `date()` | DATE | Date only |
| `datetime()` | DATETIME | Date and time |
| `timestamp()` | TIMESTAMP | Unix timestamp |
| `json()` | JSON | JSON data |
| `enum()` | ENUM | Predefined values |

### Common Patterns

#### User Table
```php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->uuid('uuid')->unique();
    $table->string('name');
    $table->string('email')->unique();
    $table->timestamp('email_verified_at')->nullable();
    $table->string('password');
    $table->enum('role', ['admin', 'developer', 'guest'])->default('guest');
    $table->enum('status', ['active', 'suspended', 'deleted'])->default('active');
    $table->rememberToken();
    $table->timestamps();
    $table->softDeletes();

    $table->index('email');
    $table->index('status');
});
```

#### Pivot Table (Many-to-Many)
```php
Schema::create('project_user', function (Blueprint $table) {
    $table->id();
    $table->foreignId('project_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->enum('role', ['owner', 'collaborator', 'viewer'])->default('viewer');
    $table->timestamps();

    $table->unique(['project_id', 'user_id']);
    $table->index('user_id');
});
```

#### Polymorphic Table
```php
Schema::create('comments', function (Blueprint $table) {
    $table->id();
    $table->morphs('commentable'); // Creates commentable_id & commentable_type
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->text('content');
    $table->timestamps();
    $table->softDeletes();

    $table->index(['commentable_type', 'commentable_id']);
});
```

#### Settings/Configuration Table
```php
Schema::create('settings', function (Blueprint $table) {
    $table->id();
    $table->string('key')->unique();
    $table->text('value')->nullable();
    $table->string('type')->default('string'); // string, integer, boolean, json
    $table->text('description')->nullable();
    $table->timestamps();

    $table->index('key');
});
```

---

## Migration Standards

### Migration Naming

```
{year}_{month}_{day}_{sequence}_{action}_{table}_table.php

Examples:
2025_10_30_000001_create_users_table.php
2025_10_30_000002_add_status_to_users_table.php
2025_10_30_000003_create_projects_table.php
2025_10_30_000004_add_foreign_keys_to_projects_table.php
```

### Migration Structure

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('projects', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('status', ['draft', 'active', 'archived'])->default('draft');
            $table->timestamps();
            $table->softDeletes();

            $table->index('user_id');
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('projects');
    }
};
```

### Adding Columns

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('phone')->nullable()->after('email');
        $table->text('bio')->nullable()->after('phone');
        $table->index('phone');
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropIndex(['phone']);
        $table->dropColumn(['phone', 'bio']);
    });
}
```

### Modifying Columns

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('name', 500)->change();
        $table->text('bio')->nullable()->change();
    });
}
```

### Foreign Keys

```php
// Add foreign key
public function up(): void
{
    Schema::table('projects', function (Blueprint $table) {
        $table->foreignId('category_id')
              ->nullable()
              ->after('user_id')
              ->constrained('categories')
              ->nullOnDelete();
    });
}

// Remove foreign key
public function down(): void
{
    Schema::table('projects', function (Blueprint $table) {
        $table->dropForeign(['category_id']);
        $table->dropColumn('category_id');
    });
}
```

### Foreign Key Actions

```php
// Cascade delete (delete related records)
$table->foreignId('user_id')->constrained()->cascadeOnDelete();

// Set null (keep record, set FK to null)
$table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();

// Restrict (prevent deletion if has related records)
$table->foreignId('user_id')->constrained()->restrictOnDelete();

// No action (database handles it)
$table->foreignId('user_id')->constrained()->noActionOnDelete();
```

---

## Relationships

### One-to-One

**Database**:
```php
Schema::create('profiles', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
    $table->string('avatar')->nullable();
    $table->text('bio')->nullable();
    $table->timestamps();
});
```

**Models**:
```php
// User model
public function profile(): HasOne
{
    return $this->hasOne(Profile::class);
}

// Profile model
public function user(): BelongsTo
{
    return $this->belongsTo(User::class);
}
```

### One-to-Many

**Database**:
```php
Schema::create('projects', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->string('name');
    $table->timestamps();

    $table->index('user_id');
});
```

**Models**:
```php
// User model
public function projects(): HasMany
{
    return $this->hasMany(Project::class);
}

// Project model
public function user(): BelongsTo
{
    return $this->belongsTo(User::class);
}
```

### Many-to-Many

**Database**:
```php
// Pivot table
Schema::create('project_user', function (Blueprint $table) {
    $table->id();
    $table->foreignId('project_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->enum('role', ['owner', 'collaborator', 'viewer'])->default('viewer');
    $table->timestamps();

    $table->unique(['project_id', 'user_id']);
});
```

**Models**:
```php
// User model
public function projects(): BelongsToMany
{
    return $this->belongsToMany(Project::class)
                ->withPivot('role')
                ->withTimestamps();
}

// Project model
public function users(): BelongsToMany
{
    return $this->belongsToMany(User::class)
                ->withPivot('role')
                ->withTimestamps();
}
```

### Polymorphic One-to-Many

**Database**:
```php
Schema::create('comments', function (Blueprint $table) {
    $table->id();
    $table->morphs('commentable'); // commentable_id, commentable_type
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->text('content');
    $table->timestamps();

    $table->index(['commentable_type', 'commentable_id']);
});
```

**Models**:
```php
// Comment model
public function commentable(): MorphTo
{
    return $this->morphTo();
}

// Project model
public function comments(): MorphMany
{
    return $this->morphMany(Comment::class, 'commentable');
}

// Post model
public function comments(): MorphMany
{
    return $this->morphMany(Comment::class, 'commentable');
}
```

### Polymorphic Many-to-Many

**Database**:
```php
Schema::create('taggables', function (Blueprint $table) {
    $table->foreignId('tag_id')->constrained()->cascadeOnDelete();
    $table->morphs('taggable');
    $table->timestamps();

    $table->unique(['tag_id', 'taggable_id', 'taggable_type']);
});
```

**Models**:
```php
// Tag model
public function projects(): MorphToMany
{
    return $this->morphedByMany(Project::class, 'taggable');
}

public function posts(): MorphToMany
{
    return $this->morphedByMany(Post::class, 'taggable');
}

// Project model
public function tags(): MorphToMany
{
    return $this->morphToMany(Tag::class, 'taggable');
}
```

---

## Indexing Strategy

### When to Add Indexes

1. **Foreign keys** - Always index
2. **Frequently queried columns** - Status, type, category
3. **Unique constraints** - Email, username, UUID
4. **Sorting columns** - created_at, name
5. **WHERE clause columns** - Filtered fields
6. **JOIN columns** - Related table keys

### Index Types

#### Single Column Index
```php
$table->index('email');
$table->index('status');
```

#### Composite Index
```php
// Query: WHERE user_id = 1 AND status = 'active'
$table->index(['user_id', 'status']);

// Order matters! First column should be most selective
```

#### Unique Index
```php
$table->unique('email');
$table->unique(['user_id', 'project_id']); // Composite unique
```

#### Full-Text Index
```php
$table->fullText('content');

// Usage
Post::whereFullText('content', 'search term')->get();
```

### Index Naming

Laravel auto-generates names, but you can specify:
```php
$table->index('email', 'idx_users_email');
$table->index(['user_id', 'status'], 'idx_users_user_status');
```

### Index Best Practices

✅ **DO**:
- Index foreign keys
- Index columns in WHERE clauses
- Index columns used in ORDER BY
- Index columns used in JOINs
- Use composite indexes for multi-column queries

❌ **DON'T**:
- Over-index (slows down writes)
- Index low-cardinality columns (boolean)
- Index columns that are rarely queried
- Create redundant indexes

### Example: Optimized Table

```php
Schema::create('orders', function (Blueprint $table) {
    $table->id();
    $table->uuid('uuid')->unique();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->foreignId('product_id')->constrained()->cascadeOnDelete();
    $table->decimal('amount', 10, 2);
    $table->enum('status', ['pending', 'paid', 'shipped', 'completed', 'cancelled'])
          ->default('pending');
    $table->timestamp('paid_at')->nullable();
    $table->timestamps();

    // Indexes
    $table->index('user_id');                      // For: WHERE user_id = ?
    $table->index('product_id');                   // For: WHERE product_id = ?
    $table->index('status');                       // For: WHERE status = ?
    $table->index(['user_id', 'status']);          // For: WHERE user_id = ? AND status = ?
    $table->index(['created_at', 'status']);       // For: ORDER BY created_at WHERE status = ?
});
```

---

## Query Optimization

### N+1 Problem

❌ **Bad** (N+1 queries):
```php
$users = User::all(); // 1 query

foreach ($users as $user) {
    echo $user->profile->bio; // N queries
}
// Total: 1 + N queries
```

✅ **Good** (Eager loading):
```php
$users = User::with('profile')->get(); // 2 queries

foreach ($users as $user) {
    echo $user->profile->bio; // No additional query
}
// Total: 2 queries
```

### Eager Loading

```php
// Single relationship
$users = User::with('profile')->get();

// Multiple relationships
$users = User::with(['profile', 'projects'])->get();

// Nested relationships
$users = User::with('projects.deployments')->get();

// Conditional eager loading
$users = User::with(['projects' => function ($query) {
    $query->where('status', 'active')
          ->orderBy('created_at', 'desc');
}])->get();
```

### Lazy Eager Loading

```php
$users = User::all();

// Later decide to load relationships
$users->load('profile');
$users->load(['projects' => function ($query) {
    $query->where('status', 'active');
}]);
```

### Query Optimization Techniques

#### 1. Select Only Needed Columns
```php
// Bad
$users = User::all(); // SELECT * FROM users

// Good
$users = User::select(['id', 'name', 'email'])->get();
```

#### 2. Use Chunking for Large Datasets
```php
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process user
    }
});

// Or use lazy collections
User::lazy()->each(function ($user) {
    // Process user
});
```

#### 3. Use whereHas vs has + with

```php
// Find users with active projects
$users = User::whereHas('projects', function ($query) {
    $query->where('status', 'active');
})->get();

// Also load the projects
$users = User::with(['projects' => function ($query) {
    $query->where('status', 'active');
}])->whereHas('projects', function ($query) {
    $query->where('status', 'active');
})->get();
```

#### 4. Use exists() for Existence Checks
```php
// Bad
if (count($user->projects) > 0) { }

// Good
if ($user->projects()->exists()) { }
```

#### 5. Use Query Scopes
```php
// Model
public function scopeActive($query)
{
    return $query->where('status', 'active');
}

public function scopeRecent($query)
{
    return $query->where('created_at', '>=', now()->subDays(7));
}

// Usage
$activeRecentUsers = User::active()->recent()->get();
```

#### 6. Use Database Transactions
```php
DB::transaction(function () {
    $user = User::create([...]);
    $user->profile()->create([...]);
    $user->projects()->create([...]);
});

// Or explicit
DB::beginTransaction();
try {
    // Operations
    DB::commit();
} catch (\Exception $e) {
    DB::rollBack();
    throw $e;
}
```

---

## Data Integrity

### Constraints

```php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('email')->unique();          // UNIQUE constraint
    $table->string('name');                      // NOT NULL (default)
    $table->foreignId('organization_id')
          ->constrained()                        // FOREIGN KEY
          ->cascadeOnDelete();                   // ON DELETE CASCADE

    // Check constraint (Laravel 10+)
    $table->integer('age');
    $table->check('age >= 18');

    $table->timestamps();
});
```

### Model Validation

```php
namespace App\Models;

class User extends Model
{
    protected $fillable = ['name', 'email', 'age'];

    // Model events for validation
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($user) {
            if ($user->age < 18) {
                throw new \InvalidArgumentException('User must be at least 18 years old');
            }
        });
    }
}
```

### Database-Level Validation

```php
Schema::create('products', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->decimal('price', 10, 2);
    $table->integer('stock')->default(0);

    // Check constraints
    $table->check('price > 0');
    $table->check('stock >= 0');

    $table->timestamps();
});
```

---

## Seeding

### Seeder Structure

```php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
            ProjectSeeder::class,
            FeatureSeeder::class,
        ]);
    }
}
```

### User Seeder Example

```php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Admin user
        User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => Hash::make('password'),
            'role' => 'admin',
            'email_verified_at' => now(),
        ]);

        // Developer user
        User::create([
            'name' => 'Developer User',
            'email' => 'developer@example.com',
            'password' => Hash::make('password'),
            'role' => 'developer',
            'email_verified_at' => now(),
        ]);

        // Generate 50 random users
        User::factory(50)->create();
    }
}
```

### Factory Example

```php
namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => Hash::make('password'),
            'role' => fake()->randomElement(['developer', 'guest']),
            'remember_token' => Str::random(10),
        ];
    }

    public function admin(): static
    {
        return $this->state(fn (array $attributes) => [
            'role' => 'admin',
        ]);
    }

    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }
}
```

---

## Database Best Practices

### 1. Always Use Migrations
Never modify the database manually.

### 2. Use UUIDs for External References
```php
$table->uuid('uuid')->unique();
```

### 3. Use Soft Deletes
```php
$table->softDeletes();
```

### 4. Add Timestamps
```php
$table->timestamps();
```

### 5. Use Enum for Fixed Values
```php
$table->enum('status', ['active', 'inactive', 'suspended']);
```

### 6. Index Foreign Keys
Always add indexes to foreign key columns.

### 7. Use Transactions
For operations that modify multiple tables.

### 8. Avoid SELECT *
Select only needed columns.

### 9. Use Eager Loading
Prevent N+1 queries.

### 10. Monitor Query Performance
Use Laravel Telescope or Debugbar.

---

## Database Checklist

- [ ] Migrations follow naming conventions
- [ ] All foreign keys have indexes
- [ ] Frequently queried columns are indexed
- [ ] Relationships properly defined in models
- [ ] Soft deletes implemented where needed
- [ ] UUIDs added for external references
- [ ] Factories created for all models
- [ ] Seeders created for initial data
- [ ] Query optimization (eager loading)
- [ ] Database transactions used appropriately
- [ ] Data integrity constraints in place
- [ ] Proper column types selected
- [ ] Timestamps added to all tables
