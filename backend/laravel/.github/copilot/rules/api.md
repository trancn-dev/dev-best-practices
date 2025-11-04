# Rule: API Design Standards

## Intent
This rule defines RESTful API design standards for Laravel applications. Copilot must follow these conventions when generating or reviewing API code to ensure consistency, scalability, and best practices.

## Scope
Applies to all API routes, controllers, resources, requests, and responses in the application.

---

## 1. RESTful Resource Design

### HTTP Methods & CRUD Operations
```
GET     /api/posts          - List all posts (index)
GET     /api/posts/{id}     - Get single post (show)
POST    /api/posts          - Create new post (store)
PUT     /api/posts/{id}     - Update entire post (update)
PATCH   /api/posts/{id}     - Update partial post (update)
DELETE  /api/posts/{id}     - Delete post (destroy)
```

### Route Definition
```php
// ✅ Good - Resource routes
use App\Http\Controllers\Api\PostController;

Route::prefix('api')->middleware('auth:sanctum')->group(function () {
    Route::apiResource('posts', PostController::class);

    // Custom actions
    Route::post('posts/{post}/publish', [PostController::class, 'publish']);
    Route::post('posts/{post}/archive', [PostController::class, 'archive']);
});

// ❌ Bad - Inconsistent naming
Route::get('/get-post/{id}', [PostController::class, 'getPost']);
Route::post('/create-post', [PostController::class, 'createPost']);
```

---

## 2. URL Naming Conventions

### Rules
- ✅ Use plural nouns for resources: `/posts`, `/users`, `/comments`
- ✅ Use kebab-case for multi-word resources: `/blog-posts`, `/user-profiles`
- ✅ Use nested routes for relationships: `/posts/{post}/comments`
- ✅ Use query parameters for filtering: `/posts?status=published&sort=created_at`
- ❌ Avoid verbs in URLs (except for actions): `/posts/search` ❌, use `/posts?q=keyword` ✅

**Examples:**
```php
// ✅ Good URL structure
GET    /api/users                          # List users
GET    /api/users/{user}                   # Get user
GET    /api/users/{user}/posts             # Get user's posts
GET    /api/posts?status=published         # Filter posts
GET    /api/posts?sort=-created_at         # Sort by created_at desc

// ❌ Bad URL structure
GET    /api/getUsers                       # Don't use verbs
GET    /api/user/{id}                      # Use plural
GET    /api/posts_published                # Use query params
GET    /api/posts/user/{userId}            # Wrong nesting order
```

---

## 3. HTTP Status Codes

### Standard Status Codes
```php
// Success
200 OK                  - Successful GET, PUT, PATCH, DELETE
201 Created            - Successful POST (resource created)
204 No Content         - Successful DELETE (no content to return)

// Client Errors
400 Bad Request        - Invalid request syntax
401 Unauthorized       - Authentication required
403 Forbidden          - Authenticated but not authorized
404 Not Found          - Resource not found
422 Unprocessable Entity - Validation errors
429 Too Many Requests  - Rate limit exceeded

// Server Errors
500 Internal Server Error - Server error
503 Service Unavailable   - Server temporarily unavailable
```

### Usage in Controllers
```php
class PostController extends Controller
{
    public function index()
    {
        $posts = Post::paginate(15);
        return response()->json($posts, 200); // or ->json($posts)
    }

    public function store(StorePostRequest $request)
    {
        $post = Post::create($request->validated());
        return response()->json($post, 201); // Created
    }

    public function show(Post $post)
    {
        return response()->json($post, 200);
    }

    public function update(UpdatePostRequest $request, Post $post)
    {
        $post->update($request->validated());
        return response()->json($post, 200);
    }

    public function destroy(Post $post)
    {
        $post->delete();
        return response()->json(null, 204); // No Content
    }
}
```

---

## 4. Response Format

### Standard JSON Response Structure
```php
// ✅ Success Response
{
    "data": {
        "id": 1,
        "title": "Post Title",
        "content": "Post content...",
        "author": {
            "id": 10,
            "name": "John Doe"
        },
        "created_at": "2025-01-15T10:30:00Z",
        "updated_at": "2025-01-15T10:30:00Z"
    },
    "meta": {
        "request_id": "abc-123"
    }
}

// ✅ Collection Response with Pagination
{
    "data": [
        {"id": 1, "title": "Post 1"},
        {"id": 2, "title": "Post 2"}
    ],
    "links": {
        "first": "http://api.example.com/posts?page=1",
        "last": "http://api.example.com/posts?page=10",
        "prev": null,
        "next": "http://api.example.com/posts?page=2"
    },
    "meta": {
        "current_page": 1,
        "from": 1,
        "last_page": 10,
        "per_page": 15,
        "to": 15,
        "total": 150
    }
}

// ✅ Error Response
{
    "error": {
        "message": "Validation failed",
        "code": "VALIDATION_ERROR",
        "details": {
            "email": ["The email field is required."],
            "password": ["The password must be at least 8 characters."]
        }
    }
}
```

---

## 5. API Resources

### Use Laravel API Resources
```php
// app/Http/Resources/PostResource.php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'excerpt' => $this->excerpt,
            'content' => $this->content,
            'status' => $this->status,
            'author' => new UserResource($this->whenLoaded('author')),
            'tags' => TagResource::collection($this->whenLoaded('tags')),
            'comments_count' => $this->when($this->comments_count !== null, $this->comments_count),
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}

// Controller usage
public function show(Post $post)
{
    $post->load(['author', 'tags']);
    return new PostResource($post);
}

public function index()
{
    $posts = Post::with(['author'])->paginate(15);
    return PostResource::collection($posts);
}
```

### Resource Collections
```php
// app/Http/Resources/PostCollection.php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class PostCollection extends ResourceCollection
{
    public function toArray($request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'total_posts' => $this->collection->count(),
                'generated_at' => now()->toIso8601String(),
            ],
        ];
    }
}
```

---

## 6. Request Validation

### Form Request Classes
```php
// app/Http/Requests/StorePostRequest.php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // or check policy
    }

    public function rules(): array
    {
        return [
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'status' => 'required|in:draft,published,archived',
            'tags' => 'nullable|array',
            'tags.*' => 'integer|exists:tags,id',
            'publish_at' => 'nullable|date|after:now',
        ];
    }

    public function messages(): array
    {
        return [
            'title.required' => 'Please provide a title for the post.',
            'status.in' => 'The status must be draft, published, or archived.',
        ];
    }
}
```

---

## 7. Error Handling

### Custom Exception Handler
```php
// app/Exceptions/Handler.php
namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

class Handler extends ExceptionHandler
{
    public function register(): void
    {
        $this->renderable(function (ModelNotFoundException $e, $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'error' => [
                        'message' => 'Resource not found',
                        'code' => 'RESOURCE_NOT_FOUND',
                    ]
                ], 404);
            }
        });

        $this->renderable(function (ValidationException $e, $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'error' => [
                        'message' => 'Validation failed',
                        'code' => 'VALIDATION_ERROR',
                        'details' => $e->errors(),
                    ]
                ], 422);
            }
        });
    }
}
```

### Custom Exceptions
```php
// app/Exceptions/InsufficientFundsException.php
namespace App\Exceptions;

use Exception;

class InsufficientFundsException extends Exception
{
    public function render($request)
    {
        return response()->json([
            'error' => [
                'message' => 'Insufficient funds in account',
                'code' => 'INSUFFICIENT_FUNDS',
            ]
        ], 400);
    }
}
```

---

## 8. Authentication & Authorization

### API Token Authentication (Sanctum)
```php
// config/sanctum.php
return [
    'expiration' => 60, // minutes
];

// routes/api.php
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);

    Route::apiResource('posts', PostController::class);
});

// AuthController
public function login(LoginRequest $request)
{
    $credentials = $request->validated();

    if (!Auth::attempt($credentials)) {
        return response()->json([
            'error' => [
                'message' => 'Invalid credentials',
                'code' => 'INVALID_CREDENTIALS',
            ]
        ], 401);
    }

    $user = Auth::user();
    $token = $user->createToken('api-token')->plainTextToken;

    return response()->json([
        'data' => new UserResource($user),
        'token' => $token,
    ]);
}
```

### Authorization with Policies
```php
// app/Policies/PostPolicy.php
class PostPolicy
{
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}

// Controller
public function update(UpdatePostRequest $request, Post $post)
{
    $this->authorize('update', $post);

    $post->update($request->validated());
    return new PostResource($post);
}
```

---

## 9. Versioning

### URI Versioning (Recommended)
```php
// routes/api.php
Route::prefix('v1')->group(function () {
    Route::apiResource('posts', V1\PostController::class);
});

Route::prefix('v2')->group(function () {
    Route::apiResource('posts', V2\PostController::class);
});

// URL: /api/v1/posts
// URL: /api/v2/posts
```

### Header Versioning (Alternative)
```php
// Middleware to handle Accept header versioning
// Accept: application/vnd.api.v1+json
```

---

## 10. Pagination

### Standard Pagination
```php
// ✅ Good - Using pagination
public function index(Request $request)
{
    $perPage = $request->input('per_page', 15);
    $posts = Post::paginate($perPage);

    return PostResource::collection($posts);
}

// URL: /api/posts?page=2&per_page=20

// ❌ Bad - No pagination
public function index()
{
    $posts = Post::all(); // Can return thousands of records
    return PostResource::collection($posts);
}
```

### Cursor Pagination (for large datasets)
```php
public function index()
{
    $posts = Post::cursorPaginate(15);
    return PostResource::collection($posts);
}
```

---

## 11. Filtering, Sorting & Searching

### Query Parameters
```php
// ✅ Good - Using query parameters
public function index(Request $request)
{
    $query = Post::query();

    // Filtering
    if ($request->has('status')) {
        $query->where('status', $request->status);
    }

    if ($request->has('author_id')) {
        $query->where('user_id', $request->author_id);
    }

    // Searching
    if ($request->has('q')) {
        $query->where('title', 'like', '%' . $request->q . '%')
              ->orWhere('content', 'like', '%' . $request->q . '%');
    }

    // Sorting
    $sortBy = $request->input('sort', 'created_at');
    $sortDirection = $request->input('direction', 'desc');
    $query->orderBy($sortBy, $sortDirection);

    $posts = $query->paginate(15);

    return PostResource::collection($posts);
}

// Usage:
// /api/posts?status=published&author_id=5&q=laravel&sort=title&direction=asc
```

---

## 12. Rate Limiting

### Apply Rate Limiting
```php
// app/Providers/RouteServiceProvider.php
protected function configureRateLimiting()
{
    RateLimiter::for('api', function (Request $request) {
        return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
    });
}

// routes/api.php
Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
    Route::apiResource('posts', PostController::class);
});

// Custom rate limit
Route::middleware(['throttle:10,1'])->group(function () {
    Route::post('/export', [ExportController::class, 'export']);
});
```

### Rate Limit Response
```json
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
Retry-After: 45

{
    "error": {
        "message": "Too many requests. Please try again later.",
        "code": "RATE_LIMIT_EXCEEDED"
    }
}
```

---

## 13. CORS Configuration

### Configure CORS
```php
// config/cors.php
return [
    'paths' => ['api/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        env('FRONTEND_URL', 'http://localhost:3000'),
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => ['X-Total-Count', 'X-Page-Count'],

    'max_age' => 0,

    'supports_credentials' => true,
];
```

---

## 14. API Documentation

### Document Your API
```php
/**
 * @OA\Get(
 *     path="/api/posts",
 *     summary="Get list of posts",
 *     tags={"Posts"},
 *     @OA\Parameter(
 *         name="status",
 *         in="query",
 *         description="Filter by status",
 *         required=false,
 *         @OA\Schema(type="string", enum={"draft", "published", "archived"})
 *     ),
 *     @OA\Response(
 *         response=200,
 *         description="Successful operation",
 *         @OA\JsonContent(
 *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/Post"))
 *         )
 *     ),
 *     security={{"sanctum": {}}}
 * )
 */
public function index(Request $request)
{
    // ...
}
```

---

## 15. API Testing

### Feature Tests for API
```php
namespace Tests\Feature\Api;

use Tests\TestCase;
use App\Models\User;
use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;

class PostApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_list_posts(): void
    {
        Post::factory()->count(5)->create();

        $response = $this->getJson('/api/posts');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'title', 'content', 'created_at']
                ],
                'meta' => ['current_page', 'total']
            ])
            ->assertJsonCount(5, 'data');
    }

    public function test_can_create_post(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/posts', [
                'title' => 'Test Post',
                'content' => 'Test content',
                'status' => 'published',
            ]);

        $response->assertCreated()
            ->assertJsonStructure([
                'data' => ['id', 'title', 'content']
            ]);

        $this->assertDatabaseHas('posts', [
            'title' => 'Test Post',
            'user_id' => $user->id,
        ]);
    }

    public function test_unauthenticated_user_cannot_create_post(): void
    {
        $response = $this->postJson('/api/posts', [
            'title' => 'Test Post',
        ]);

        $response->assertUnauthorized();
    }

    public function test_validation_error_returns_422(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/posts', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['title', 'content']);
    }
}
```

---

## 16. Best Practices Checklist

### API Design
- [ ] Use RESTful conventions
- [ ] Version your API
- [ ] Use proper HTTP methods and status codes
- [ ] Implement pagination for collections
- [ ] Use API Resources for responses
- [ ] Validate all inputs with FormRequests
- [ ] Implement proper error handling

### Security
- [ ] Use authentication (Sanctum/Passport)
- [ ] Implement authorization with Policies
- [ ] Apply rate limiting
- [ ] Configure CORS properly
- [ ] Validate and sanitize inputs
- [ ] Use HTTPS in production

### Performance
- [ ] Use eager loading to prevent N+1 queries
- [ ] Implement caching where appropriate
- [ ] Use pagination or cursor pagination
- [ ] Optimize database queries
- [ ] Use queues for heavy operations

### Documentation
- [ ] Document all endpoints
- [ ] Provide request/response examples
- [ ] Document authentication requirements
- [ ] List all error codes
- [ ] Keep documentation up to date

---

## References

- [REST API Best Practices](https://restfulapi.net/)
- [Laravel API Resources](https://laravel.com/docs/eloquent-resources)
- [Laravel Sanctum](https://laravel.com/docs/sanctum)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- [API Security Checklist](https://github.com/shieldfy/API-Security-Checklist)

---

## Controller Method Order (RESTful)

Controllers implementing RESTful APIs MUST order methods as follows for clarity and consistency:

1. `index`   – List all resources
2. `show`    – Show a single resource
3. `store`   – Create a new resource
4. `update`  – Update an existing resource
5. `destroy` – Delete a resource
6. Custom methods (if any) should be placed after the standard RESTful methods, grouped together and documented.

**Example:**
```php
class PostController extends Controller
{
    public function index() { /* ... */ }
    public function show(Post $post) { /* ... */ }
    public function store(Request $request) { /* ... */ }
    public function update(Request $request, Post $post) { /* ... */ }
    public function destroy(Post $post) { /* ... */ }
    // --- Custom actions below ---
    public function publish(Post $post) { /* ... */ }
}
```

> This order improves readability and makes it easier for developers to find standard actions quickly. Copilot and contributors MUST follow this order when generating or reviewing controller code.

---
