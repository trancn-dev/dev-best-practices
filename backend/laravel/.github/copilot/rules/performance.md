# Rule: Performance Optimization Standards

## Intent
This rule defines performance optimization standards for Laravel applications. Copilot must follow these principles when generating or reviewing code to ensure optimal application performance, scalability, and resource efficiency.

## Scope
Applies to all PHP code, database queries, caching strategies, and system resource management.

---

## 1. Database Query Optimization

### N+1 Query Problem

**The Problem:**
```php
// ❌ Bad - N+1 queries (1 + N queries)
$posts = Post::all(); // 1 query
foreach ($posts as $post) {
    echo $post->author->name; // N queries (one per post)
    foreach ($post->comments as $comment) { // N queries
        echo $comment->user->name; // N * M queries
    }
}
// Total: 1 + N + (N * M) queries
```

**The Solution:**
```php
// ✅ Good - Eager loading (3 queries total)
$posts = Post::with(['author', 'comments.user'])->get();
foreach ($posts as $post) {
    echo $post->author->name; // No additional query
    foreach ($post->comments as $comment) {
        echo $comment->user->name; // No additional query
    }
}
// Total: 3 queries
```

### Lazy Eager Loading
```php
// ✅ Load relationships after initial query
$posts = Post::all();

if (auth()->user()->isAdmin()) {
    $posts->load('author'); // Only load if needed
}
```

### Count Relationships Efficiently
```php
// ❌ Bad - Loads all comment data
$posts = Post::with('comments')->get();
foreach ($posts as $post) {
    echo $post->comments->count();
}

// ✅ Good - Only counts
$posts = Post::withCount('comments')->get();
foreach ($posts as $post) {
    echo $post->comments_count; // Much faster
}

// ✅ Good - Multiple counts
$posts = Post::withCount(['comments', 'likes', 'views'])->get();
```

### Exists vs Count
```php
// ❌ Bad - Count when you only need to know if exists
if (Post::where('user_id', $userId)->count() > 0) {
    // ...
}

// ✅ Good - Use exists()
if (Post::where('user_id', $userId)->exists()) {
    // Much faster, stops at first match
}
```

### Select Only Needed Columns
```php
// ❌ Bad - Select all columns
$users = User::all();

// ✅ Good - Select specific columns
$users = User::select(['id', 'name', 'email'])->get();

// ✅ Good - In relationships
$posts = Post::with(['author' => function ($query) {
    $query->select(['id', 'name']);
}])->get();
```

### Chunk Large Datasets
```php
// ❌ Bad - Load everything into memory
$users = User::all(); // May cause memory issues with large datasets
foreach ($users as $user) {
    // Process
}

// ✅ Good - Process in chunks
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process
    }
});

// ✅ Good - Chunk by ID (safer for updates)
User::chunkById(100, function ($users) {
    foreach ($users as $user) {
        $user->update(['processed' => true]);
    }
}, 'id', 'users');
```

### Use Indexes Effectively
```php
// Migration
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained();
    $table->string('status');
    $table->timestamp('published_at')->nullable();
    $table->timestamps();

    // ✅ Add indexes for frequently queried columns
    $table->index('status');
    $table->index('published_at');
    $table->index(['user_id', 'status']); // Composite index
});

// Query that benefits from index
$posts = Post::where('status', 'published')
    ->where('published_at', '<=', now())
    ->orderBy('published_at', 'desc')
    ->get();
```

---

## 2. Caching Strategies

### Query Result Caching
```php
use Illuminate\Support\Facades\Cache;

// ❌ Bad - No caching
public function getPosts()
{
    return Post::where('status', 'published')
        ->orderBy('created_at', 'desc')
        ->get();
}

// ✅ Good - Cache query results
public function getPosts()
{
    return Cache::remember('posts:published', 3600, function () {
        return Post::where('status', 'published')
            ->orderBy('created_at', 'desc')
            ->get();
    });
}

// ✅ Good - Cache with tags (for easier invalidation)
public function getUserPosts(int $userId)
{
    return Cache::tags(['posts', "user:{$userId}"])
        ->remember("user:{$userId}:posts", 3600, function () use ($userId) {
            return Post::where('user_id', $userId)->get();
        });
}

// Invalidate cache
Cache::tags(['posts', "user:{$userId}"])->flush();
```

### Model Caching
```php
// ✅ Cache expensive model operations
class Post extends Model
{
    public function getRelatedPostsAttribute()
    {
        return Cache::remember("post:{$this->id}:related", 3600, function () {
            return Post::where('category_id', $this->category_id)
                ->where('id', '!=', $this->id)
                ->limit(5)
                ->get();
        });
    }
}
```

### Cache Invalidation
```php
// ✅ Clear cache when data changes
class PostController extends Controller
{
    public function update(Request $request, Post $post)
    {
        $post->update($request->validated());

        // Clear related caches
        Cache::forget('posts:published');
        Cache::forget("post:{$post->id}:related");
        Cache::tags(['posts', "user:{$post->user_id}"])->flush();

        return response()->json($post);
    }
}

// ✅ Use model events for automatic cache invalidation
class Post extends Model
{
    protected static function booted()
    {
        static::updated(function ($post) {
            Cache::forget('posts:published');
            Cache::forget("post:{$post->id}:related");
        });

        static::deleted(function ($post) {
            Cache::forget('posts:published');
        });
    }
}
```

### Cache Configuration
```php
// config/cache.php
'default' => env('CACHE_DRIVER', 'redis'), // Use Redis for production

'stores' => [
    'redis' => [
        'driver' => 'redis',
        'connection' => 'cache',
        'lock_connection' => 'default',
    ],
],

// .env
CACHE_DRIVER=redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
```

---

## 3. Queue Jobs for Heavy Operations

### When to Use Queues
- ✅ Email sending
- ✅ Image processing
- ✅ PDF generation
- ✅ API calls to external services
- ✅ Data exports
- ✅ Bulk operations

**Example:**
```php
// ❌ Bad - Blocking user request
public function register(Request $request)
{
    $user = User::create($request->validated());

    // Sends email synchronously (slow)
    Mail::to($user)->send(new WelcomeEmail($user));

    return response()->json($user, 201);
}

// ✅ Good - Queue the email
public function register(Request $request)
{
    $user = User::create($request->validated());

    // Queue email (fast response)
    Mail::to($user)->queue(new WelcomeEmail($user));

    return response()->json($user, 201);
}

// ✅ Good - Custom job
php artisan make:job ProcessUserAvatar

class ProcessUserAvatar implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public User $user,
        public UploadedFile $avatar
    ) {}

    public function handle(): void
    {
        // Resize image
        $image = Image::make($this->avatar);
        $image->fit(200, 200);
        $path = $image->save(storage_path("app/avatars/{$this->user->id}.jpg"));

        // Update user
        $this->user->update(['avatar' => $path]);
    }
}

// Dispatch job
ProcessUserAvatar::dispatch($user, $request->file('avatar'));

// Dispatch with delay
ProcessUserAvatar::dispatch($user, $avatar)
    ->delay(now()->addMinutes(5));

// Dispatch to specific queue
ProcessUserAvatar::dispatch($user, $avatar)
    ->onQueue('images');
```

---

## 4. Lazy Loading & Pagination

### Always Paginate Collections
```php
// ❌ Bad - Load all records
public function index()
{
    $posts = Post::all(); // Could be thousands
    return view('posts.index', compact('posts'));
}

// ✅ Good - Paginate
public function index()
{
    $posts = Post::paginate(15);
    return view('posts.index', compact('posts'));
}

// ✅ Good - Cursor pagination (for large datasets)
public function index()
{
    $posts = Post::cursorPaginate(15);
    return PostResource::collection($posts);
}
```

### Lazy Collections
```php
// ❌ Bad - Load all into memory
$users = User::all(); // 100,000 users = memory issue

// ✅ Good - Lazy collection
User::lazy()->each(function ($user) {
    // Process one at a time without loading all into memory
    $this->processUser($user);
});
```

---

## 5. Optimize Eloquent Queries

### Use Query Scopes
```php
// ✅ Reusable query logic
class Post extends Model
{
    public function scopePublished($query)
    {
        return $query->where('status', 'published')
            ->where('published_at', '<=', now());
    }

    public function scopePopular($query)
    {
        return $query->where('views', '>', 1000)
            ->orderBy('views', 'desc');
    }
}

// Usage
$posts = Post::published()->popular()->get();
```

### Avoid Unnecessary Hydration
```php
// ❌ Bad - Full Eloquent models
$userIds = User::where('status', 'active')->get()->pluck('id');

// ✅ Good - Just the data you need
$userIds = User::where('status', 'active')->pluck('id');

// ✅ Good - Plain arrays (faster than Eloquent)
$users = DB::table('users')->where('status', 'active')->get();
```

---

## 6. Asset Optimization

### Compile & Minify Assets
```javascript
// vite.config.js
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
    build: {
        minify: 'terser',
        rollupOptions: {
            output: {
                manualChunks: {
                    vendor: ['vue', 'axios'],
                },
            },
        },
    },
});
```

### Image Optimization
```php
// ✅ Use intervention/image for optimization
use Intervention\Image\Facades\Image;

public function uploadAvatar(Request $request)
{
    $image = Image::make($request->file('avatar'));

    // Resize and compress
    $image->fit(300, 300)
        ->encode('jpg', 80); // 80% quality

    $path = storage_path('app/public/avatars/' . auth()->id() . '.jpg');
    $image->save($path);

    return response()->json(['path' => $path]);
}
```

### Lazy Load Images
```blade
{{-- ✅ Lazy load images --}}
<img src="placeholder.jpg"
     data-src="{{ $post->image }}"
     loading="lazy"
     alt="{{ $post->title }}">
```

---

## 7. Memory Management

### Unset Variables
```php
// ✅ Free memory when done with large variables
$largeData = $this->fetchLargeDataset();
$this->process($largeData);
unset($largeData); // Free memory

// ✅ In loops
foreach ($users as $user) {
    $result = $this->heavyProcess($user);
    $this->save($result);
    unset($result); // Free memory each iteration
}
```

### Avoid Loading Unnecessary Relationships
```php
// ❌ Bad - Loads everything
$post = Post::with(['author', 'comments', 'tags', 'category'])->find($id);
return view('posts.show', compact('post'));

// ✅ Good - Only load what you need
$post = Post::with('author')->find($id);
return view('posts.show', compact('post'));
```

---

## 8. HTTP Client Optimization

### Use Async Requests
```php
use Illuminate\Support\Facades\Http;

// ❌ Bad - Sequential requests (slow)
$user = Http::get('https://api.example.com/user/1')->json();
$posts = Http::get('https://api.example.com/posts/1')->json();
$comments = Http::get('https://api.example.com/comments/1')->json();

// ✅ Good - Parallel requests (fast)
$responses = Http::pool(fn ($pool) => [
    $pool->get('https://api.example.com/user/1'),
    $pool->get('https://api.example.com/posts/1'),
    $pool->get('https://api.example.com/comments/1'),
]);

$user = $responses[0]->json();
$posts = $responses[1]->json();
$comments = $responses[2]->json();
```

### Timeout Configuration
```php
// ✅ Set appropriate timeouts
Http::timeout(3) // 3 seconds
    ->retry(3, 100) // Retry 3 times, 100ms apart
    ->get('https://api.example.com/data');
```

---

## 9. Session & Cookie Optimization

### Use Database/Redis for Sessions
```php
// .env - Don't use file driver in production
SESSION_DRIVER=redis // or database

// config/session.php
'driver' => env('SESSION_DRIVER', 'redis'),
```

### Minimize Session Data
```php
// ❌ Bad - Store large objects in session
session(['user_data' => $user->load('posts', 'comments', 'followers')]);

// ✅ Good - Store only IDs
session(['user_id' => $user->id]);

// ✅ Retrieve when needed
$user = User::find(session('user_id'));
```

---

## 10. Route Caching

### Cache Routes in Production
```bash
# Cache routes (production only)
php artisan route:cache

# Clear route cache
php artisan route:clear

# Cache config
php artisan config:cache

# Cache views
php artisan view:cache
```

**Note:** Route caching doesn't work with closure-based routes.

```php
// ❌ Bad - Can't be cached
Route::get('/posts', function () {
    return Post::all();
});

// ✅ Good - Can be cached
Route::get('/posts', [PostController::class, 'index']);
```

---

## 11. Opcode Caching (OPcache)

### Configure OPcache
```ini
; php.ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
```

---

## 12. Database Connection Pooling

### Use Persistent Connections
```php
// config/database.php
'mysql' => [
    'driver' => 'mysql',
    'host' => env('DB_HOST'),
    'port' => env('DB_PORT'),
    'database' => env('DB_DATABASE'),
    'username' => env('DB_USERNAME'),
    'password' => env('DB_PASSWORD'),
    'options' => [
        PDO::ATTR_PERSISTENT => true, // Persistent connections
    ],
],
```

---

## 13. Performance Monitoring

### Laravel Debugbar (Development)
```bash
composer require barryvdh/laravel-debugbar --dev
```

### Laravel Telescope (Development)
```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

### Measure Query Performance
```php
use Illuminate\Support\Facades\DB;

// ✅ Log slow queries
DB::listen(function ($query) {
    if ($query->time > 1000) { // > 1 second
        Log::warning('Slow query detected', [
            'sql' => $query->sql,
            'time' => $query->time,
            'bindings' => $query->bindings,
        ]);
    }
});
```

### Benchmark Code
```php
use Illuminate\Support\Benchmark;

// ✅ Compare different approaches
Benchmark::dd([
    'Approach A' => fn () => $this->methodA(),
    'Approach B' => fn () => $this->methodB(),
], iterations: 1000);
```

---

## 14. CDN for Static Assets

### Use CDN in Production
```php
// config/app.php
'asset_url' => env('ASSET_URL', null),

// .env (production)
ASSET_URL=https://cdn.example.com

// Usage in views
<link rel="stylesheet" href="{{ asset('css/app.css') }}">
// Outputs: https://cdn.example.com/css/app.css
```

---

## 15. Performance Checklist

### Development
- [ ] Enable query logging temporarily to find N+1 issues
- [ ] Use Laravel Debugbar to monitor queries
- [ ] Profile slow pages with Telescope
- [ ] Test with realistic data volumes

### Production
- [ ] Enable OPcache
- [ ] Use Redis/Memcached for cache
- [ ] Use Redis for sessions and queues
- [ ] Enable route, config, and view caching
- [ ] Set up queue workers
- [ ] Configure proper indexes on database
- [ ] Use CDN for static assets
- [ ] Enable Gzip compression
- [ ] Set up application monitoring (New Relic, Datadog)
- [ ] Regular database optimization (analyze tables, rebuild indexes)

### Code Review
- [ ] No N+1 queries
- [ ] Appropriate eager loading
- [ ] Proper use of caching
- [ ] Heavy operations queued
- [ ] Pagination on large datasets
- [ ] Indexes on frequently queried columns
- [ ] Minimal session data
- [ ] No closure-based routes (for caching)

---

## 16. Common Performance Anti-Patterns

### Avoid These
```php
// ❌ Loading all records
Post::all();

// ❌ N+1 queries
Post::all()->load('author');

// ❌ Counting with count()
if (Post::count() > 0) { }

// ❌ Using get() when you need one
Post::where('id', $id)->get()->first();

// ❌ Not using indexes
// SELECT * FROM posts WHERE YEAR(created_at) = 2024

// ❌ Storing large data in session
session(['data' => $largeArray]);

// ❌ Synchronous heavy operations
$this->generateReport(); // Blocks request
```

### Do This Instead
```php
// ✅ Paginate
Post::paginate(15);

// ✅ Eager load
Post::with('author')->get();

// ✅ Use exists()
if (Post::exists()) { }

// ✅ Use find() or first()
Post::find($id);

// ✅ Use indexed columns
// SELECT * FROM posts WHERE created_at >= '2024-01-01'

// ✅ Store minimal data
session(['user_id' => $id]);

// ✅ Queue heavy operations
GenerateReport::dispatch();
```

---

## References

- [Laravel Performance Tips](https://laravel.com/docs/performance)
- [Database Query Optimization](https://laravel.com/docs/queries#optimizing-queries)
- [Laravel Caching](https://laravel.com/docs/cache)
- [Laravel Queues](https://laravel.com/docs/queues)
- [N+1 Query Problem](https://laravel.com/docs/eloquent-relationships#eager-loading)
- [Laravel Telescope](https://laravel.com/docs/telescope)
