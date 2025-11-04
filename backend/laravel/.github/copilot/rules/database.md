# Rule: Database & Migration Standards

## Intent
This rule defines database design and migration standards for Laravel applications. Copilot must follow these principles when generating or reviewing database-related code to ensure data integrity, performance, and maintainability.

## Scope
Applies to migrations, models, database queries, and schema design.

---

## 1. Migration Best Practices

### Naming Conventions
- ✅ Use descriptive names: `create_users_table`, `add_status_to_posts_table`
- ✅ Follow Laravel naming pattern: `{action}_{table}_{suffix}`
- ✅ Use timestamps in filename: `2025_01_28_100000_create_posts_table.php`

**Examples:**
```bash
# ✅ Good migration names
php artisan make:migration create_posts_table
php artisan make:migration add_published_at_to_posts_table
php artisan make:migration create_post_tag_pivot_table
php artisan make:migration rename_title_column_in_posts_table

# ❌ Bad migration names
php artisan make:migration posts
php artisan make:migration update_table
php artisan make:migration fix_bug
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
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('content');
            $table->enum('status', ['draft', 'published', 'archived'])->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Indexes
            $table->index('status');
            $table->index('published_at');
            $table->index(['user_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
```

---

## 2. Column Types & Naming

### Column Naming Conventions
- ✅ Use snake_case: `user_id`, `created_at`, `first_name`
- ✅ Foreign keys: `{table}_id` (e.g., `user_id`, `post_id`)
- ✅ Boolean: prefix with `is_`, `has_`, `can_` (e.g., `is_active`, `has_verified`)
- ✅ Timestamps: `{action}_at` (e.g., `published_at`, `deleted_at`)

### Common Column Types
```php
// ✅ Primary Key
$table->id(); // BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY

// ✅ Foreign Keys
$table->foreignId('user_id')->constrained();
$table->foreignId('category_id')->constrained()->onDelete('cascade');
$table->foreignId('author_id')->constrained('users')->onDelete('set null');

// ✅ Strings
$table->string('name'); // VARCHAR(255)
$table->string('email', 100); // VARCHAR(100)
$table->text('description'); // TEXT
$table->longText('content'); // LONGTEXT

// ✅ Numbers
$table->integer('count'); // INT
$table->bigInteger('views'); // BIGINT
$table->decimal('price', 8, 2); // DECIMAL(8,2)
$table->float('rating', 8, 2); // FLOAT

// ✅ Boolean
$table->boolean('is_active')->default(true);
$table->boolean('has_verified')->default(false);

// ✅ Dates & Times
$table->date('birth_date');
$table->time('start_time');
$table->dateTime('scheduled_at');
$table->timestamp('published_at')->nullable();
$table->timestamps(); // created_at, updated_at
$table->softDeletes(); // deleted_at

// ✅ JSON
$table->json('meta');
$table->jsonb('settings'); // PostgreSQL

// ✅ Enum (Laravel 11+ / PHP 8.1+)
$table->enum('status', ['pending', 'approved', 'rejected']);

// ✅ UUID
$table->uuid('id')->primary();
```

---

## 3. Indexes & Performance

### When to Add Indexes
- ✅ Primary keys (automatic)
- ✅ Foreign keys
- ✅ Columns used in WHERE clauses
- ✅ Columns used in ORDER BY
- ✅ Columns used in JOIN conditions
- ✅ Unique constraints

**Examples:**
```php
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained();
    $table->string('slug')->unique();
    $table->string('title');
    $table->enum('status', ['draft', 'published']);
    $table->timestamp('published_at')->nullable();
    $table->timestamps();

    // ✅ Single column indexes
    $table->index('status');
    $table->index('published_at');

    // ✅ Composite indexes (order matters!)
    $table->index(['user_id', 'status']); // For queries: WHERE user_id = ? AND status = ?
    $table->index(['status', 'published_at']); // For queries: WHERE status = ? ORDER BY published_at

    // ✅ Full-text search index
    $table->fullText(['title', 'content']);
});
```

### Index Best Practices
```php
// ✅ Good - Specific index
$table->index(['category_id', 'status', 'published_at'], 'idx_posts_category_status_date');

// ❌ Bad - Too many indexes (slows down writes)
$table->index('title');
$table->index('content');
$table->index('excerpt');
$table->index('meta');

// ✅ Good - Limit indexes to frequently queried columns
$table->index(['status', 'published_at']);
```

---

## 4. Foreign Key Constraints

### Define Relationships
```php
// ✅ Good - With cascade delete
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')
        ->constrained()
        ->onDelete('cascade'); // Delete posts when user is deleted
    $table->timestamps();
});

// ✅ Good - With set null
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('editor_id')
        ->nullable()
        ->constrained('users')
        ->onDelete('set null'); // Set to null when editor is deleted
    $table->timestamps();
});

// ✅ Good - With restrict (prevent deletion)
Schema::create('orders', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')
        ->constrained()
        ->onDelete('restrict'); // Prevent user deletion if orders exist
    $table->timestamps();
});

// ⚠️ Careful - Without constraint (not recommended)
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('user_id'); // No foreign key constraint
    $table->timestamps();
});
```

---

## 5. Pivot Tables (Many-to-Many)

### Naming Convention
- ✅ Alphabetical order: `post_tag`, `role_user`
- ✅ Singular table names: `post_tag` (not `posts_tags`)

**Example:**
```php
// Many-to-Many: Posts <-> Tags
Schema::create('post_tag', function (Blueprint $table) {
    $table->id();
    $table->foreignId('post_id')->constrained()->onDelete('cascade');
    $table->foreignId('tag_id')->constrained()->onDelete('cascade');
    $table->timestamps(); // Optional, for tracking

    // ✅ Ensure unique combinations
    $table->unique(['post_id', 'tag_id']);
});

// Model usage
class Post extends Model
{
    public function tags()
    {
        return $this->belongsToMany(Tag::class)
            ->withTimestamps(); // Include created_at, updated_at
    }
}
```

### Pivot with Extra Columns
```php
Schema::create('project_user', function (Blueprint $table) {
    $table->id();
    $table->foreignId('project_id')->constrained()->onDelete('cascade');
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->enum('role', ['owner', 'member', 'viewer'])->default('member');
    $table->timestamp('joined_at')->useCurrent();
    $table->timestamps();

    $table->unique(['project_id', 'user_id']);
});

// Model
class Project extends Model
{
    public function users()
    {
        return $this->belongsToMany(User::class)
            ->withPivot('role', 'joined_at')
            ->withTimestamps();
    }
}
```

---

## 6. Modifying Existing Tables

### Adding Columns
```php
Schema::table('posts', function (Blueprint $table) {
    $table->string('subtitle')->nullable()->after('title');
    $table->integer('view_count')->default(0);
});
```

### Modifying Columns
```php
use Illuminate\Database\Schema\Blueprint;

Schema::table('users', function (Blueprint $table) {
    // Change column type
    $table->string('name', 100)->change();

    // Make nullable
    $table->string('phone')->nullable()->change();

    // Change default
    $table->boolean('is_active')->default(true)->change();
});
```

### Renaming Columns
```php
Schema::table('posts', function (Blueprint $table) {
    $table->renameColumn('old_name', 'new_name');
});
```

### Dropping Columns
```php
Schema::table('posts', function (Blueprint $table) {
    $table->dropColumn('old_column');
    $table->dropColumn(['column1', 'column2']);
});
```

### Adding Indexes Later
```php
Schema::table('posts', function (Blueprint $table) {
    $table->index('status');
    $table->unique('slug');
    $table->index(['user_id', 'status'], 'idx_user_status');
});
```

---

## 7. Soft Deletes

### Implementation
```php
// Migration
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->string('title');
    $table->timestamps();
    $table->softDeletes(); // Adds deleted_at column
});

// Model
use Illuminate\Database\Eloquent\SoftDeletes;

class Post extends Model
{
    use SoftDeletes;

    protected $dates = ['deleted_at'];
}

// Usage
$post->delete(); // Soft delete (sets deleted_at)
$post->forceDelete(); // Permanent delete
$post->restore(); // Restore soft-deleted record

// Queries
Post::withTrashed()->get(); // Include soft-deleted
Post::onlyTrashed()->get(); // Only soft-deleted
Post::where('status', 'published')->get(); // Excludes soft-deleted (default)
```

---

## 8. Database Seeding

### Seeder Structure
```php
// database/seeders/UserSeeder.php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // ✅ Create specific records
        User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => Hash::make('password'),
            'role' => 'admin',
        ]);

        // ✅ Use factories for bulk data
        User::factory()
            ->count(50)
            ->create();
    }
}

// Register in DatabaseSeeder
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
            PostSeeder::class,
            TagSeeder::class,
        ]);
    }
}
```

### Run Seeders
```bash
php artisan db:seed
php artisan db:seed --class=UserSeeder
php artisan migrate:fresh --seed
```

---

## 9. Query Optimization

### N+1 Query Problem
```php
// ❌ Bad - N+1 queries
$posts = Post::all(); // 1 query
foreach ($posts as $post) {
    echo $post->author->name; // N queries (one per post)
}

// ✅ Good - Eager loading
$posts = Post::with('author')->get(); // 2 queries total
foreach ($posts as $post) {
    echo $post->author->name;
}

// ✅ Good - Nested eager loading
$posts = Post::with(['author', 'tags', 'comments.user'])->get();

// ✅ Good - Lazy eager loading
$posts = Post::all();
$posts->load('author');
```

### Chunking Large Datasets
```php
// ✅ Good - Process large datasets in chunks
Post::chunk(100, function ($posts) {
    foreach ($posts as $post) {
        // Process post
    }
});

// ✅ Good - Chunk by ID (safer for updates)
Post::chunkById(100, function ($posts) {
    foreach ($posts as $post) {
        $post->update(['processed' => true]);
    }
});
```

### Select Specific Columns
```php
// ❌ Bad - Select all columns
$users = User::all();

// ✅ Good - Select only needed columns
$users = User::select(['id', 'name', 'email'])->get();
```

### Counting Relationships
```php
// ❌ Bad
$posts = Post::with('comments')->get();
foreach ($posts as $post) {
    echo $post->comments->count(); // Loads all comment data
}

// ✅ Good - Use withCount
$posts = Post::withCount('comments')->get();
foreach ($posts as $post) {
    echo $post->comments_count; // Just the count
}
```

---

## 10. Database Transactions

### When to Use Transactions
- ✅ Multiple related database operations
- ✅ Financial transactions
- ✅ Data integrity critical operations

**Examples:**
```php
use Illuminate\Support\Facades\DB;

// ✅ Good - Automatic transaction
DB::transaction(function () {
    $user = User::create([...]);
    $profile = Profile::create(['user_id' => $user->id, ...]);
    $setting = Setting::create(['user_id' => $user->id, ...]);
});

// ✅ Good - Manual transaction with error handling
DB::beginTransaction();

try {
    $order = Order::create([...]);
    $payment = Payment::create([...]);
    $inventory = Inventory::decrement('stock', $order->quantity);

    DB::commit();
} catch (\Exception $e) {
    DB::rollBack();
    throw $e;
}

// ✅ Good - Transaction with retry on deadlock
DB::transaction(function () {
    // Database operations
}, 5); // Retry 5 times on deadlock
```

---

## 11. Raw Queries & Query Builder

### Use Query Builder When Possible
```php
// ✅ Good - Query Builder (safe from SQL injection)
$users = DB::table('users')
    ->where('status', 'active')
    ->where('created_at', '>', now()->subDays(30))
    ->orderBy('name')
    ->get();

// ⚠️ Careful - Raw queries (use bindings)
$users = DB::select('SELECT * FROM users WHERE status = ?', ['active']);

// ❌ Bad - SQL injection vulnerable
$status = request('status');
$users = DB::select("SELECT * FROM users WHERE status = '$status'"); // DANGEROUS!
```

---

## 12. Model Conventions

### Table Naming
- ✅ Plural, snake_case: `users`, `blog_posts`, `order_items`
- ❌ Singular: `user`, `blogPost`

### Primary Key
- ✅ Default: `id` (BIGINT UNSIGNED AUTO_INCREMENT)
- ⚠️ Custom: Override `$primaryKey` and `$incrementing`

```php
class Post extends Model
{
    // ✅ Default - uses 'id'

    // ⚠️ Custom primary key
    protected $primaryKey = 'post_id';

    // ⚠️ Non-incrementing (e.g., UUID)
    public $incrementing = false;
    protected $keyType = 'string';
}
```

### Timestamps
```php
class Post extends Model
{
    // ✅ Default - uses created_at, updated_at

    // ❌ Disable timestamps (not recommended)
    public $timestamps = false;

    // ✅ Custom timestamp columns
    const CREATED_AT = 'creation_date';
    const UPDATED_AT = 'last_update';
}
```

---

## 13. Database Configuration

### Environment Variables
```env
# .env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=
DB_CHARSET=utf8mb4
DB_COLLATION=utf8mb4_unicode_ci
```

### Multiple Database Connections
```php
// config/database.php
'connections' => [
    'mysql' => [...],
    'analytics' => [
        'driver' => 'mysql',
        'host' => env('ANALYTICS_DB_HOST'),
        'database' => env('ANALYTICS_DB_DATABASE'),
        // ...
    ],
],

// Usage
$users = DB::connection('analytics')->table('users')->get();

// In model
class AnalyticsLog extends Model
{
    protected $connection = 'analytics';
}
```

---

## 14. Migration Deployment

### Best Practices
- ✅ Test migrations locally first
- ✅ Review generated SQL before production
- ✅ Backup database before migration
- ✅ Run migrations during low-traffic periods
- ✅ Have rollback plan ready

**Commands:**
```bash
# Check migration status
php artisan migrate:status

# Run pending migrations
php artisan migrate

# Rollback last batch
php artisan migrate:rollback

# Rollback specific steps
php artisan migrate:rollback --step=3

# Rollback all migrations
php artisan migrate:reset

# Fresh migration (drop all tables)
php artisan migrate:fresh

# Fresh with seeding
php artisan migrate:fresh --seed

# Preview SQL without running
php artisan migrate --pretend
```

---

## 15. Database Testing

### Use In-Memory Database
```php
// phpunit.xml
<php>
    <env name="DB_CONNECTION" value="sqlite"/>
    <env name="DB_DATABASE" value=":memory:"/>
</php>

// Test
use Illuminate\Foundation\Testing\RefreshDatabase;

class PostTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_create_post(): void
    {
        $post = Post::create([
            'title' => 'Test Post',
            'content' => 'Test content',
        ]);

        $this->assertDatabaseHas('posts', [
            'title' => 'Test Post',
        ]);
    }
}
```

---

## 16. Common Pitfalls

### Avoid These Mistakes
```php
// ❌ Bad - No indexes on foreign keys
$table->unsignedBigInteger('user_id');

// ✅ Good
$table->foreignId('user_id')->constrained();

// ❌ Bad - Using text columns for frequently queried data
$table->text('status');

// ✅ Good
$table->enum('status', ['active', 'inactive']);

// ❌ Bad - Not using transactions for related operations
$order = Order::create([...]);
$payment = Payment::create([...]);

// ✅ Good
DB::transaction(function () {
    $order = Order::create([...]);
    $payment = Payment::create([...]);
});

// ❌ Bad - Not handling NULL values properly
$table->integer('count'); // Will fail if NULL

// ✅ Good
$table->integer('count')->default(0);
$table->integer('optional_count')->nullable();
```

---

## References

- [Laravel Migrations](https://laravel.com/docs/migrations)
- [Laravel Eloquent](https://laravel.com/docs/eloquent)
- [Database Query Builder](https://laravel.com/docs/queries)
- [Database Indexing Best Practices](https://use-the-index-luke.com/)
- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
