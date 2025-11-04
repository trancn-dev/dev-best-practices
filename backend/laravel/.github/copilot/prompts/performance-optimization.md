# Prompt: Performance Optimization

## Purpose
Identify and fix performance bottlenecks in Laravel applications for faster response times, lower resource usage, and better scalability.

## When to Use
- Application is slow
- High server resource usage
- Database query optimization needed
- Caching strategy required
- Scaling for production

---

## Prompt Template

```
I need to optimize the performance of:

**Component**: [Controller/Query/Page/Feature]
**Current Performance**: [Response time, query count, memory usage]
**Target Performance**: [Desired metrics]

**Code**:
[CODE_BLOCK]

**Symptoms**:
- [Slow page load]
- [High memory usage]
- [Many database queries]
- [etc.]

Please provide:
1. **Performance analysis**: What are the bottlenecks?
2. **Specific issues**: Identify each problem
3. **Solutions**: How to fix each issue
4. **Expected improvements**: What gains to expect
5. **Implementation priority**: What to fix first
6. **Monitoring**: How to measure improvements
```

---

## Example Usage

### Input:
```
I need to optimize the performance of:

**Component**: Post listing page
**Current Performance**: 3-5 seconds load time, 500+ queries
**Target Performance**: < 500ms, < 10 queries

**Code**:
public function index()
{
    $posts = Post::all();
    return view('posts.index', compact('posts'));
}

// In Blade view:
@foreach($posts as $post)
    <div class="post">
        <h2>{{ $post->title }}</h2>
        <p>By {{ $post->author->name }}</p>
        <p>{{ $post->comments->count() }} comments</p>
        <p>{{ $post->likes->count() }} likes</p>
        <div class="tags">
            @foreach($post->tags as $tag)
                <span>{{ $tag->name }}</span>
            @endforeach
        </div>
    </div>
@endforeach

**Symptoms**:
- Page takes 5+ seconds to load
- Laravel Debugbar shows 500+ queries
- Server CPU usage spikes
```

### Expected Output:

## 🔍 Performance Analysis

### Current Issues Identified

1. **❌ Critical: N+1 Query Problem (Priority: HIGH)**
   - Loading all posts (1 query)
   - For each post, loading author (N queries)
   - For each post, counting comments (N queries)
   - For each post, counting likes (N queries)
   - For each post, loading tags (N queries)
   - **Total: 1 + 4N queries** (with 100 posts = 401 queries!)

2. **❌ Critical: No Pagination (Priority: HIGH)**
   - Loading ALL posts into memory
   - With 10,000 posts, this loads ~100MB of data
   - Overwhelming for browser and server

3. **❌ Major: No Caching (Priority: MEDIUM)**
   - Same data loaded on every request
   - No cache headers set

4. **❌ Major: Loading Full Models (Priority: MEDIUM)**
   - Not selecting specific columns
   - Loading all model data unnecessarily

---

## ✅ Solutions

### Solution 1: Fix N+1 Queries (Critical)

**Problem**: Loading relationships in loops

**Fix**:
```php
public function index()
{
    $posts = Post::with(['author', 'tags'])
        ->withCount(['comments', 'likes'])
        ->latest()
        ->paginate(15);

    return view('posts.index', compact('posts'));
}
```

**Blade (no changes needed)**:
```blade
@foreach($posts as $post)
    <div class="post">
        <h2>{{ $post->title }}</h2>
        <p>By {{ $post->author->name }}</p>
        <p>{{ $post->comments_count }} comments</p>
        <p>{{ $post->likes_count }} likes</p>
        <div class="tags">
            @foreach($post->tags as $tag)
                <span>{{ $tag->name }}</span>
            @endforeach
        </div>
    </div>
@endforeach

{{ $posts->links() }}
```

**Expected Improvement**:
- Queries: 500+ → 3 queries (94% reduction)
- Response time: 5s → 200ms (96% faster)
- Memory: 100MB → 2MB (98% reduction)

---

### Solution 2: Add Caching (High Impact)

**Problem**: Same data loaded on every request

**Fix**:
```php
public function index(Request $request)
{
    $page = $request->get('page', 1);

    $posts = Cache::remember("posts:page:{$page}", 3600, function () {
        return Post::with(['author', 'tags'])
            ->withCount(['comments', 'likes'])
            ->latest()
            ->paginate(15);
    });

    return view('posts.index', compact('posts'));
}

// Clear cache when posts are created/updated
class Post extends Model
{
    protected static function booted()
    {
        static::saved(function () {
            Cache::tags('posts')->flush();
        });

        static::deleted(function () {
            Cache::tags('posts')->flush();
        });
    }
}
```

**Expected Improvement**:
- Cached response: 200ms → 10ms (95% faster)
- Database load: 100 req/s → 1 req/s

---

### Solution 3: Select Only Needed Columns

**Problem**: Loading all columns for all models

**Fix**:
```php
public function index()
{
    $posts = Post::select(['id', 'title', 'author_id', 'created_at'])
        ->with([
            'author' => function ($query) {
                $query->select(['id', 'name']);
            },
            'tags' => function ($query) {
                $query->select(['tags.id', 'tags.name']);
            }
        ])
        ->withCount(['comments', 'likes'])
        ->latest()
        ->paginate(15);

    return view('posts.index', compact('posts'));
}
```

**Expected Improvement**:
- Data transferred: 500KB → 50KB (90% reduction)
- Memory usage: 2MB → 500KB (75% reduction)

---

### Solution 4: Add Database Indexes

**Problem**: Slow queries due to missing indexes

**Fix**:
```php
// Migration
Schema::table('posts', function (Blueprint $table) {
    $table->index('author_id');
    $table->index('created_at');
    $table->index(['author_id', 'created_at']);
});

Schema::table('comments', function (Blueprint $table) {
    $table->index('post_id');
});

Schema::table('likes', function (Blueprint $table) {
    $table->index('post_id');
});

Schema::table('post_tag', function (Blueprint $table) {
    $table->index('post_id');
    $table->index('tag_id');
});
```

**Expected Improvement**:
- Query time: 200ms → 20ms (90% faster)
- Can handle 10x more records with same performance

---

### Solution 5: Implement Redis Caching

**Problem**: File-based cache is slow

**Fix**:
```env
# .env
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

```php
// config/cache.php - already configured by default
'default' => env('CACHE_DRIVER', 'redis'),
```

**Expected Improvement**:
- Cache read: 10ms → 1ms
- Cache write: 20ms → 2ms
- Better scalability

---

## 📊 Complete Optimized Implementation

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class PostController extends Controller
{
    /**
     * Display paginated list of posts with optimized queries.
     */
    public function index(Request $request)
    {
        $page = $request->get('page', 1);
        $perPage = 15;

        // Cache posts for 1 hour
        $posts = Cache::tags(['posts'])
            ->remember("posts:page:{$page}", 3600, function () use ($perPage) {
                return Post::select([
                        'id',
                        'title',
                        'excerpt',
                        'author_id',
                        'created_at',
                    ])
                    ->with([
                        'author' => function ($query) {
                            $query->select(['id', 'name', 'avatar']);
                        },
                        'tags' => function ($query) {
                            $query->select(['tags.id', 'tags.name', 'tags.slug']);
                        }
                    ])
                    ->withCount(['comments', 'likes'])
                    ->latest('created_at')
                    ->paginate($perPage);
            });

        return view('posts.index', compact('posts'));
    }
}

// Model - Clear cache on changes
class Post extends Model
{
    protected static function booted()
    {
        // Clear cache when post is saved or deleted
        static::saved(fn() => Cache::tags(['posts'])->flush());
        static::deleted(fn() => Cache::tags(['posts'])->flush());
    }
}
```

---

## 📈 Performance Comparison

### Before Optimization
```
⏱️ Response Time: 5000ms
💾 Memory Usage: 100MB
🔢 Database Queries: 501
📊 Queries per Page Load: 501
💰 Server Cost: High
👥 Concurrent Users Supported: ~10
```

### After Optimization
```
⏱️ Response Time: 10ms (cached) / 50ms (uncached)
💾 Memory Usage: 500KB
🔢 Database Queries: 3 (uncached)
📊 Queries per Page Load: 0 (cached) / 3 (uncached)
💰 Server Cost: 90% reduction
👥 Concurrent Users Supported: ~1000
```

### Improvement Summary
- **99% faster** response time
- **99.5% less** memory usage
- **99.4% fewer** database queries
- **100x more** concurrent users

---

## 🎯 Implementation Priority

### Phase 1: Critical (Do Immediately)
1. ✅ Fix N+1 queries with eager loading
2. ✅ Add pagination
3. ✅ Add database indexes

**Estimated Time**: 2 hours
**Expected Improvement**: 95% faster

### Phase 2: High Impact (Do This Week)
1. ✅ Implement caching
2. ✅ Select only needed columns
3. ✅ Switch to Redis cache

**Estimated Time**: 4 hours
**Expected Improvement**: Additional 90% improvement on cached requests

### Phase 3: Optimization (Do This Month)
1. ✅ Implement CDN for static assets
2. ✅ Add HTTP caching headers
3. ✅ Optimize images
4. ✅ Implement lazy loading

**Estimated Time**: 8 hours
**Expected Improvement**: Better user experience

---

## 📊 Monitoring & Measurement

### Tools to Use

1. **Laravel Debugbar** (Development)
```bash
composer require barryvdh/laravel-debugbar --dev
```

2. **Laravel Telescope** (Development)
```bash
composer require laravel/telescope --dev
php artisan telescope:install
```

3. **Query Logging**
```php
// AppServiceProvider
DB::listen(function ($query) {
    if ($query->time > 100) {
        Log::warning('Slow query detected', [
            'sql' => $query->sql,
            'time' => $query->time,
            'bindings' => $query->bindings,
        ]);
    }
});
```

4. **Performance Metrics**
```php
// Measure page load time
$start = microtime(true);
// ... your code ...
$duration = microtime(true) - $start;
Log::info('Page load time', ['duration' => $duration]);
```

### Metrics to Track

- Response time (p50, p95, p99)
- Database query count
- Memory usage
- Cache hit rate
- Concurrent users
- Server CPU/RAM usage

---

## 🚀 Additional Optimizations

### 1. Queue Heavy Operations
```php
// Instead of synchronous operations
Mail::to($user)->send(new WelcomeEmail());

// Use queues
Mail::to($user)->queue(new WelcomeEmail());
```

### 2. Use Chunking for Large Datasets
```php
// Process large datasets efficiently
Post::chunk(100, function ($posts) {
    foreach ($posts as $post) {
        $this->process($post);
    }
});
```

### 3. Database Connection Pooling
```php
// config/database.php
'options' => [
    PDO::ATTR_PERSISTENT => true,
],
```

### 4. OPcache Configuration
```ini
; php.ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
```

---

## ✅ Performance Checklist

### Development
- [ ] Enable query logging
- [ ] Use Laravel Debugbar
- [ ] Profile slow pages
- [ ] Test with realistic data

### Before Deployment
- [ ] N+1 queries eliminated
- [ ] Pagination implemented
- [ ] Database indexes added
- [ ] Caching strategy implemented
- [ ] Tested under load

### Production
- [ ] Redis configured
- [ ] OPcache enabled
- [ ] CDN configured
- [ ] Monitoring setup
- [ ] Query logging enabled

---

## Related Prompts

- `bug-fix-assistant.md` - Fix performance bugs
- `refactoring-suggestions.md` - Refactor for performance
- `code-explanation.md` - Understand performance issues
- `testing-strategy.md` - Performance testing
