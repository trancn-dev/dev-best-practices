# Prompt: API Design

## Purpose
Design RESTful APIs for Laravel applications following industry best practices, including endpoints, request/response formats, authentication, and documentation.

## When to Use
- Creating new API endpoints
- Designing API architecture
- Defining request/response structures
- Planning API versioning
- Implementing API authentication

---

## Prompt Template

```
I need to design an API for:

**Feature**: [What the API should do]
**Resources**: [Main entities/resources]
**Operations**: [CRUD operations needed]
**Authentication**: [Auth requirements]
**Special Requirements**:
- [Pagination, filtering, etc.]
- [Rate limiting needs]
- [Specific business rules]

Please provide:
1. **Endpoint design**: REST endpoints with HTTP methods
2. **Request formats**: Request body structures
3. **Response formats**: Success and error responses
4. **Validation rules**: Input validation
5. **Authentication**: Auth implementation
6. **Tests**: API test examples
7. **Documentation**: API documentation
```

---

## Example: Blog API

### Input:
```
I need to design an API for:

**Feature**: Blog management system
**Resources**: Posts, Comments, Tags
**Operations**:
- Posts: CRUD + publish/unpublish
- Comments: Create, read, moderate
- Tags: Read, auto-suggest
**Authentication**: JWT tokens
**Special Requirements**:
- Pagination for lists
- Search and filtering
- Rate limiting
- File uploads for post images
```

### Expected Output:

## 🚀 API Design: Blog Management

### Base URL
```
https://api.example.com/api/v1
```

### Authentication
All endpoints require JWT token except public read endpoints.

```
Authorization: Bearer {token}
```

---

## 📋 Endpoints

### Posts

#### 1. List Posts
```http
GET /posts
```

**Query Parameters:**
- `page` (integer): Page number (default: 1)
- `per_page` (integer): Items per page (default: 15, max: 100)
- `status` (string): Filter by status (draft, published)
- `tag` (string): Filter by tag slug
- `search` (string): Search in title and content
- `sort` (string): Sort field (created_at, title, views)
- `order` (string): Sort order (asc, desc)

**Response (200 OK):**
```json
{
    "data": [
        {
            "id": 1,
            "title": "Getting Started with Laravel",
            "slug": "getting-started-with-laravel",
            "excerpt": "Learn the basics of Laravel...",
            "content": "Full content here...",
            "status": "published",
            "featured_image": "https://cdn.example.com/images/post-1.jpg",
            "author": {
                "id": 1,
                "name": "John Doe",
                "avatar": "https://cdn.example.com/avatars/1.jpg"
            },
            "tags": [
                {
                    "id": 1,
                    "name": "Laravel",
                    "slug": "laravel"
                }
            ],
            "stats": {
                "views": 1250,
                "comments": 45,
                "likes": 89
            },
            "published_at": "2025-01-15T10:30:00Z",
            "created_at": "2025-01-15T09:00:00Z",
            "updated_at": "2025-01-15T10:30:00Z"
        }
    ],
    "meta": {
        "current_page": 1,
        "from": 1,
        "last_page": 10,
        "per_page": 15,
        "to": 15,
        "total": 150
    },
    "links": {
        "first": "https://api.example.com/api/v1/posts?page=1",
        "last": "https://api.example.com/api/v1/posts?page=10",
        "prev": null,
        "next": "https://api.example.com/api/v1/posts?page=2"
    }
}
```

#### 2. Get Single Post
```http
GET /posts/{id}
```

**Response (200 OK):**
```json
{
    "data": {
        "id": 1,
        "title": "Getting Started with Laravel",
        "slug": "getting-started-with-laravel",
        "content": "Full content...",
        "status": "published",
        "featured_image": "https://cdn.example.com/images/post-1.jpg",
        "author": {
            "id": 1,
            "name": "John Doe",
            "avatar": "https://cdn.example.com/avatars/1.jpg"
        },
        "tags": [
            {"id": 1, "name": "Laravel", "slug": "laravel"}
        ],
        "stats": {
            "views": 1250,
            "comments": 45,
            "likes": 89
        },
        "published_at": "2025-01-15T10:30:00Z",
        "created_at": "2025-01-15T09:00:00Z",
        "updated_at": "2025-01-15T10:30:00Z"
    }
}
```

#### 3. Create Post
```http
POST /posts
```

**Request Body:**
```json
{
    "title": "Getting Started with Laravel",
    "content": "Full content of the blog post...",
    "excerpt": "Short description...",
    "status": "draft",
    "featured_image": "base64_encoded_image_or_url",
    "tags": [1, 2, 3],
    "meta": {
        "seo_title": "Getting Started with Laravel - Complete Guide",
        "seo_description": "Learn Laravel from scratch..."
    }
}
```

**Validation Rules:**
- `title`: required, string, max:255, unique
- `content`: required, string, min:100
- `excerpt`: nullable, string, max:500
- `status`: required, in:draft,published
- `featured_image`: nullable, image, max:2048
- `tags`: nullable, array
- `tags.*`: exists:tags,id

**Response (201 Created):**
```json
{
    "data": {
        "id": 1,
        "title": "Getting Started with Laravel",
        "slug": "getting-started-with-laravel",
        "status": "draft",
        "created_at": "2025-01-15T09:00:00Z"
    },
    "message": "Post created successfully"
}
```

#### 4. Update Post
```http
PUT /posts/{id}
PATCH /posts/{id}
```

**Request Body:** (Same as create, all fields optional for PATCH)
```json
{
    "title": "Updated Title",
    "content": "Updated content..."
}
```

**Response (200 OK):**
```json
{
    "data": {
        "id": 1,
        "title": "Updated Title",
        "updated_at": "2025-01-15T11:00:00Z"
    },
    "message": "Post updated successfully"
}
```

#### 5. Delete Post
```http
DELETE /posts/{id}
```

**Response (200 OK):**
```json
{
    "message": "Post deleted successfully"
}
```

#### 6. Publish/Unpublish Post
```http
POST /posts/{id}/publish
POST /posts/{id}/unpublish
```

**Response (200 OK):**
```json
{
    "data": {
        "id": 1,
        "status": "published",
        "published_at": "2025-01-15T10:30:00Z"
    },
    "message": "Post published successfully"
}
```

---

### Comments

#### 1. List Comments for Post
```http
GET /posts/{post_id}/comments
```

**Query Parameters:**
- `page`, `per_page`, `sort`, `order`

**Response (200 OK):**
```json
{
    "data": [
        {
            "id": 1,
            "content": "Great article!",
            "author": {
                "id": 2,
                "name": "Jane Smith",
                "avatar": "https://cdn.example.com/avatars/2.jpg"
            },
            "status": "approved",
            "created_at": "2025-01-15T11:00:00Z"
        }
    ],
    "meta": {...}
}
```

#### 2. Create Comment
```http
POST /posts/{post_id}/comments
```

**Request Body:**
```json
{
    "content": "Great article, very helpful!"
}
```

**Validation:**
- `content`: required, string, min:10, max:1000

**Response (201 Created):**
```json
{
    "data": {
        "id": 1,
        "content": "Great article, very helpful!",
        "status": "pending",
        "created_at": "2025-01-15T11:00:00Z"
    },
    "message": "Comment submitted for moderation"
}
```

#### 3. Moderate Comment
```http
POST /comments/{id}/approve
POST /comments/{id}/reject
```

**Response (200 OK):**
```json
{
    "data": {
        "id": 1,
        "status": "approved"
    },
    "message": "Comment approved successfully"
}
```

---

### Tags

#### 1. List Tags
```http
GET /tags
```

**Response (200 OK):**
```json
{
    "data": [
        {
            "id": 1,
            "name": "Laravel",
            "slug": "laravel",
            "post_count": 45
        }
    ]
}
```

#### 2. Auto-suggest Tags
```http
GET /tags/suggest?q=lar
```

**Response (200 OK):**
```json
{
    "data": [
        {"id": 1, "name": "Laravel", "slug": "laravel"},
        {"id": 2, "name": "Laravel Nova", "slug": "laravel-nova"}
    ]
}
```

---

## 🔒 Authentication Implementation

### Register
```http
POST /auth/register
```

**Request:**
```json
{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123!",
    "password_confirmation": "SecurePass123!"
}
```

**Response (201 Created):**
```json
{
    "data": {
        "user": {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com"
        },
        "token": {
            "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
            "token_type": "Bearer",
            "expires_in": 3600
        }
    },
    "message": "Registration successful"
}
```

### Login
```http
POST /auth/login
```

**Request:**
```json
{
    "email": "john@example.com",
    "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
    "data": {
        "user": {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com"
        },
        "token": {
            "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
            "token_type": "Bearer",
            "expires_in": 3600
        }
    },
    "message": "Login successful"
}
```

### Logout
```http
POST /auth/logout
```

**Response (200 OK):**
```json
{
    "message": "Logged out successfully"
}
```

---

## ❌ Error Responses

### Validation Error (422)
```json
{
    "message": "The given data was invalid.",
    "errors": {
        "title": [
            "The title field is required."
        ],
        "content": [
            "The content must be at least 100 characters."
        ]
    }
}
```

### Unauthorized (401)
```json
{
    "message": "Unauthenticated."
}
```

### Forbidden (403)
```json
{
    "message": "You don't have permission to perform this action."
}
```

### Not Found (404)
```json
{
    "message": "Post not found."
}
```

### Rate Limit Exceeded (429)
```json
{
    "message": "Too many requests. Please try again in 60 seconds.",
    "retry_after": 60
}
```

### Server Error (500)
```json
{
    "message": "Internal server error occurred.",
    "error": "Error details (only in development)"
}
```

---

## 💻 Laravel Implementation

### Routes (routes/api.php)

```php
<?php

use App\Http\Controllers\Api\V1\{
    AuthController,
    PostController,
    CommentController,
    TagController
};
use Illuminate\Support\Facades\Route;

// Public routes
Route::prefix('v1')->group(function () {
    // Authentication
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    // Public read access
    Route::get('/posts', [PostController::class, 'index']);
    Route::get('/posts/{post}', [PostController::class, 'show']);
    Route::get('/posts/{post}/comments', [CommentController::class, 'index']);
    Route::get('/tags', [TagController::class, 'index']);
    Route::get('/tags/suggest', [TagController::class, 'suggest']);
});

// Protected routes
Route::prefix('v1')->middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Posts
    Route::apiResource('posts', PostController::class)->except(['index', 'show']);
    Route::post('/posts/{post}/publish', [PostController::class, 'publish']);
    Route::post('/posts/{post}/unpublish', [PostController::class, 'unpublish']);

    // Comments
    Route::post('/posts/{post}/comments', [CommentController::class, 'store']);
    Route::post('/comments/{comment}/approve', [CommentController::class, 'approve'])
        ->middleware('can:moderate,comment');
    Route::post('/comments/{comment}/reject', [CommentController::class, 'reject'])
        ->middleware('can:moderate,comment');
});
```

### Controller Example

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Http\Resources\PostResource;
use App\Http\Resources\PostCollection;
use App\Models\Post;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PostController extends Controller
{
    /**
     * Display a listing of posts.
     */
    public function index(Request $request): PostCollection
    {
        $posts = Post::query()
            ->with(['author', 'tags'])
            ->withCount(['comments', 'likes'])
            ->when($request->status, fn($q, $status) => $q->where('status', $status))
            ->when($request->tag, fn($q, $tag) => $q->whereHas('tags', fn($q) => $q->where('slug', $tag)))
            ->when($request->search, fn($q, $search) => $q->search($search))
            ->orderBy($request->input('sort', 'created_at'), $request->input('order', 'desc'))
            ->paginate($request->input('per_page', 15));

        return new PostCollection($posts);
    }

    /**
     * Store a newly created post.
     */
    public function store(StorePostRequest $request): JsonResponse
    {
        $post = Post::create($request->validated());

        if ($request->has('tags')) {
            $post->tags()->sync($request->tags);
        }

        return response()->json([
            'data' => new PostResource($post),
            'message' => 'Post created successfully',
        ], 201);
    }

    /**
     * Display the specified post.
     */
    public function show(Post $post): PostResource
    {
        $post->load(['author', 'tags'])
            ->loadCount(['comments', 'likes']);

        $post->increment('view_count');

        return new PostResource($post);
    }

    /**
     * Update the specified post.
     */
    public function update(UpdatePostRequest $request, Post $post): JsonResponse
    {
        $this->authorize('update', $post);

        $post->update($request->validated());

        if ($request->has('tags')) {
            $post->tags()->sync($request->tags);
        }

        return response()->json([
            'data' => new PostResource($post),
            'message' => 'Post updated successfully',
        ]);
    }

    /**
     * Remove the specified post.
     */
    public function destroy(Post $post): JsonResponse
    {
        $this->authorize('delete', $post);

        $post->delete();

        return response()->json([
            'message' => 'Post deleted successfully',
        ]);
    }

    /**
     * Publish a post.
     */
    public function publish(Post $post): JsonResponse
    {
        $this->authorize('publish', $post);

        $post->update([
            'status' => 'published',
            'published_at' => now(),
        ]);

        return response()->json([
            'data' => new PostResource($post),
            'message' => 'Post published successfully',
        ]);
    }
}
```

### Request Validation

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255', 'unique:posts'],
            'content' => ['required', 'string', 'min:100'],
            'excerpt' => ['nullable', 'string', 'max:500'],
            'status' => ['required', 'in:draft,published'],
            'featured_image' => ['nullable', 'image', 'max:2048'],
            'tags' => ['nullable', 'array'],
            'tags.*' => ['exists:tags,id'],
        ];
    }

    public function messages(): array
    {
        return [
            'content.min' => 'Post content must be at least 100 characters long.',
            'tags.*.exists' => 'One or more selected tags are invalid.',
        ];
    }
}
```

### API Resource

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'excerpt' => $this->excerpt,
            'content' => $this->when($request->routeIs('posts.show'), $this->content),
            'status' => $this->status,
            'featured_image' => $this->featured_image_url,
            'author' => new UserResource($this->whenLoaded('author')),
            'tags' => TagResource::collection($this->whenLoaded('tags')),
            'stats' => [
                'views' => $this->view_count,
                'comments' => $this->comments_count ?? 0,
                'likes' => $this->likes_count ?? 0,
            ],
            'published_at' => $this->published_at?->toIso8601String(),
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
```

---

## 🧪 API Tests

```php
<?php

namespace Tests\Feature\Api;

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PostApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_list_posts(): void
    {
        Post::factory()->count(20)->create();

        $response = $this->getJson('/api/v1/posts');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'title', 'slug', 'author', 'tags']
                ],
                'meta',
                'links'
            ])
            ->assertJsonCount(15, 'data'); // Default pagination
    }

    public function test_can_create_post_when_authenticated(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/posts', [
                'title' => 'Test Post',
                'content' => str_repeat('Test content. ', 20),
                'status' => 'draft',
            ]);

        $response->assertCreated()
            ->assertJsonFragment(['title' => 'Test Post']);

        $this->assertDatabaseHas('posts', ['title' => 'Test Post']);
    }

    public function test_cannot_create_post_when_unauthenticated(): void
    {
        $response = $this->postJson('/api/v1/posts', [
            'title' => 'Test Post',
        ]);

        $response->assertUnauthorized();
    }

    public function test_validates_post_creation(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/posts', [
                'title' => '', // Required
                'content' => 'Too short', // Min 100 chars
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['title', 'content']);
    }
}
```

---

## Related Prompts

- `testing-strategy.md` - Test API endpoints
- `documentation-generation.md` - Generate API docs
- `database-design.md` - Design API database schema
- `security-audit.md` - Secure API endpoints
