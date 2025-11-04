# API Design & Standards

This document describes the API design principles, standards, and conventions for the Laravel DevKit project.

---

## Table of Contents

1. [API Design Principles](#api-design-principles)
2. [RESTful Conventions](#restful-conventions)
3. [API Versioning](#api-versioning)
4. [Authentication & Authorization](#authentication--authorization)
5. [Request & Response Formats](#request--response-formats)
6. [Error Handling](#error-handling)
7. [Rate Limiting](#rate-limiting)
8. [API Documentation](#api-documentation)

---

## API Design Principles

### 1. RESTful Design
- Use HTTP methods correctly (GET, POST, PUT, PATCH, DELETE)
- Resources are nouns, not verbs
- Use HTTP status codes properly
- Stateless communication

### 2. Consistency
- Consistent naming conventions
- Consistent response structures
- Consistent error formats
- Consistent pagination

### 3. Simplicity
- Clear and intuitive endpoints
- Minimal required parameters
- Sensible defaults
- Clear documentation

### 4. Security First
- Authentication required by default
- Validate all inputs
- Rate limiting
- CORS configuration
- No sensitive data in URLs

---

## RESTful Conventions

### Resource Naming

**Rules**:
- Use plural nouns for resources: `/users`, `/projects`
- Use kebab-case for multi-word resources: `/project-templates`
- Nested resources for relationships: `/users/{id}/projects`
- Use query parameters for filtering: `/users?status=active`

### HTTP Methods

| Method | Purpose | Example | Success Code |
|--------|---------|---------|--------------|
| GET | Retrieve resource(s) | `GET /users` | 200 |
| POST | Create resource | `POST /users` | 201 |
| PUT | Replace resource | `PUT /users/1` | 200 |
| PATCH | Update resource | `PATCH /users/1` | 200 |
| DELETE | Delete resource | `DELETE /users/1` | 204 |

### Standard Endpoints

```
# User Resource
GET     /api/v1/users              # List all users
POST    /api/v1/users              # Create user
GET     /api/v1/users/{id}         # Get user
PUT     /api/v1/users/{id}         # Replace user
PATCH   /api/v1/users/{id}         # Update user
DELETE  /api/v1/users/{id}         # Delete user

# Nested Resources
GET     /api/v1/users/{id}/projects        # List user's projects
POST    /api/v1/users/{id}/projects        # Create project for user
GET     /api/v1/users/{id}/projects/{pid}  # Get user's project

# Actions (non-CRUD)
POST    /api/v1/users/{id}/suspend         # Suspend user
POST    /api/v1/users/{id}/restore         # Restore user
POST    /api/v1/projects/{id}/deploy       # Deploy project
```

---

## API Versioning

### Version Strategy

Use URI versioning: `/api/v1/`, `/api/v2/`

**Example**:
```
/api/v1/users
/api/v2/users
```

### Version Management

```php
// routes/api.php
Route::prefix('v1')->group(function () {
    Route::apiResource('users', UserController::class);
});

Route::prefix('v2')->group(function () {
    Route::apiResource('users', V2\UserController::class);
});
```

### Deprecation Policy

1. **Announce deprecation** 6 months in advance
2. **Maintain old version** for at least 12 months
3. **Provide migration guide**
4. **Add deprecation headers**:
   ```
   Deprecation: true
   Sunset: Sat, 31 Dec 2025 23:59:59 GMT
   Link: <https://api.example.com/v2/users>; rel="successor-version"
   ```

---

## Authentication & Authorization

### Authentication Methods

#### 1. Laravel Sanctum (Recommended)

**API Token Authentication**:
```php
// Generate token
$token = $user->createToken('api-token')->plainTextToken;

// Request header
Authorization: Bearer {token}
```

**Implementation**:
```php
// app/Http/Controllers/Api/AuthController.php
class AuthController extends Controller
{
    public function login(LoginRequest $request)
    {
        $credentials = $request->validated();

        if (!Auth::attempt($credentials)) {
            return response()->json([
                'message' => 'Invalid credentials'
            ], 401);
        }

        $user = Auth::user();
        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'data' => [
                'token' => $token,
                'user' => new UserResource($user),
            ]
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully'
        ]);
    }
}
```

#### 2. OAuth2 (Laravel Passport)

For third-party integrations requiring full OAuth2 support.

### Authorization

**Use Policies**:
```php
// app/Policies/ProjectPolicy.php
class ProjectPolicy
{
    public function view(User $user, Project $project): bool
    {
        return $user->id === $project->user_id || $user->isAdmin();
    }

    public function update(User $user, Project $project): bool
    {
        return $user->id === $project->user_id;
    }

    public function delete(User $user, Project $project): bool
    {
        return $user->id === $project->user_id || $user->isAdmin();
    }
}

// In controller
public function update(UpdateProjectRequest $request, Project $project)
{
    $this->authorize('update', $project);

    // Update logic...
}
```

---

## Request & Response Formats

### Request Format

#### Headers
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

#### Request Body (JSON)
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "role": "developer"
}
```

### Response Format

#### Success Response Structure

```json
{
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2025-10-30T10:00:00Z"
  },
  "meta": {
    "timestamp": "2025-10-30T10:00:00Z",
    "version": "1.0.0"
  }
}
```

#### Collection Response Structure

```json
{
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane@example.com"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 42,
    "last_page": 3
  },
  "links": {
    "first": "https://api.example.com/users?page=1",
    "last": "https://api.example.com/users?page=3",
    "prev": null,
    "next": "https://api.example.com/users?page=2"
  }
}
```

### API Resources

**User Resource**:
```php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'email_verified' => !is_null($this->email_verified_at),
            'role' => $this->role,
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),

            // Conditional attributes
            'projects_count' => $this->when($request->has('include_counts'), function () {
                return $this->projects()->count();
            }),

            // Relationships
            'projects' => ProjectResource::collection($this->whenLoaded('projects')),
        ];
    }

    public function with(Request $request): array
    {
        return [
            'meta' => [
                'timestamp' => now()->toIso8601String(),
                'version' => '1.0.0',
            ],
        ];
    }
}
```

**User Collection**:
```php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class UserCollection extends ResourceCollection
{
    public function toArray(Request $request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'total' => $this->total(),
                'count' => $this->count(),
                'per_page' => $this->perPage(),
                'current_page' => $this->currentPage(),
                'total_pages' => $this->lastPage(),
            ],
            'links' => [
                'first' => $this->url(1),
                'last' => $this->url($this->lastPage()),
                'prev' => $this->previousPageUrl(),
                'next' => $this->nextPageUrl(),
            ],
        ];
    }
}
```

### Pagination

```php
// Controller
public function index(Request $request)
{
    $users = User::query()
        ->when($request->has('status'), fn($q) => $q->where('status', $request->status))
        ->paginate($request->get('per_page', 15));

    return new UserCollection($users);
}

// Request
GET /api/v1/users?page=2&per_page=20&status=active
```

### Filtering, Sorting, and Searching

```php
public function index(Request $request)
{
    $query = User::query();

    // Filtering
    if ($request->has('status')) {
        $query->where('status', $request->status);
    }

    if ($request->has('role')) {
        $query->where('role', $request->role);
    }

    // Searching
    if ($request->has('search')) {
        $query->where(function ($q) use ($request) {
            $q->where('name', 'like', "%{$request->search}%")
              ->orWhere('email', 'like', "%{$request->search}%");
        });
    }

    // Sorting
    $sortBy = $request->get('sort_by', 'created_at');
    $sortOrder = $request->get('sort_order', 'desc');
    $query->orderBy($sortBy, $sortOrder);

    // Include relationships
    if ($request->has('include')) {
        $includes = explode(',', $request->include);
        $query->with($includes);
    }

    return new UserCollection($query->paginate());
}

// Example request
GET /api/v1/users?status=active&role=developer&search=john&sort_by=name&sort_order=asc&include=projects,profile
```

---

## Error Handling

### Error Response Structure

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The given data was invalid.",
    "details": {
      "email": [
        "The email field is required.",
        "The email must be a valid email address."
      ],
      "password": [
        "The password must be at least 12 characters."
      ]
    }
  },
  "meta": {
    "timestamp": "2025-10-30T10:00:00Z",
    "request_id": "abc123"
  }
}
```

### HTTP Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid request format |
| 401 | Unauthorized | Missing or invalid token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation errors |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Maintenance mode |

### Custom Exception Handler

```php
// app/Exceptions/Handler.php
namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Throwable;

class Handler extends ExceptionHandler
{
    public function render($request, Throwable $e)
    {
        if ($request->is('api/*')) {
            return $this->handleApiException($request, $e);
        }

        return parent::render($request, $e);
    }

    protected function handleApiException($request, Throwable $e)
    {
        if ($e instanceof ValidationException) {
            return response()->json([
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'The given data was invalid.',
                    'details' => $e->errors(),
                ],
                'meta' => [
                    'timestamp' => now()->toIso8601String(),
                    'request_id' => $request->id(),
                ],
            ], 422);
        }

        if ($e instanceof NotFoundHttpException) {
            return response()->json([
                'error' => [
                    'code' => 'NOT_FOUND',
                    'message' => 'Resource not found.',
                ],
                'meta' => [
                    'timestamp' => now()->toIso8601String(),
                    'request_id' => $request->id(),
                ],
            ], 404);
        }

        if ($e instanceof AuthenticationException) {
            return response()->json([
                'error' => [
                    'code' => 'UNAUTHENTICATED',
                    'message' => 'Authentication required.',
                ],
                'meta' => [
                    'timestamp' => now()->toIso8601String(),
                    'request_id' => $request->id(),
                ],
            ], 401);
        }

        // Default error response
        return response()->json([
            'error' => [
                'code' => 'INTERNAL_ERROR',
                'message' => 'An error occurred.',
            ],
            'meta' => [
                'timestamp' => now()->toIso8601String(),
                'request_id' => $request->id(),
            ],
        ], 500);
    }
}
```

### Custom API Exceptions

```php
namespace App\Exceptions;

use Exception;

class UserNotFoundException extends Exception
{
    public function render($request)
    {
        return response()->json([
            'error' => [
                'code' => 'USER_NOT_FOUND',
                'message' => 'The requested user could not be found.',
            ],
        ], 404);
    }
}

class InsufficientPermissionsException extends Exception
{
    public function render($request)
    {
        return response()->json([
            'error' => [
                'code' => 'INSUFFICIENT_PERMISSIONS',
                'message' => 'You do not have permission to perform this action.',
            ],
        ], 403);
    }
}
```

---

## Rate Limiting

### Configuration

```php
// app/Providers/RouteServiceProvider.php
protected function configureRateLimiting()
{
    RateLimiter::for('api', function (Request $request) {
        return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
    });

    RateLimiter::for('api-strict', function (Request $request) {
        return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
    });
}
```

### Apply Rate Limiting

```php
// routes/api.php
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {
    Route::apiResource('users', UserController::class);
});

Route::middleware(['auth:sanctum', 'throttle:api-strict'])->group(function () {
    Route::post('projects/{id}/deploy', [ProjectController::class, 'deploy']);
});
```

### Rate Limit Response

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "retry_after": 60
  }
}
```

**Response Headers**:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1698660000
Retry-After: 60
```

---

## API Documentation

### OpenAPI (Swagger) Specification

Use Laravel Scramble or L5-Swagger for automatic API documentation.

**Example Annotations**:
```php
/**
 * @OA\Get(
 *     path="/api/v1/users",
 *     summary="List all users",
 *     tags={"Users"},
 *     security={{"bearerAuth":{}}},
 *     @OA\Parameter(
 *         name="page",
 *         in="query",
 *         description="Page number",
 *         required=false,
 *         @OA\Schema(type="integer")
 *     ),
 *     @OA\Response(
 *         response=200,
 *         description="Successful operation",
 *         @OA\JsonContent(ref="#/components/schemas/UserCollection")
 *     ),
 *     @OA\Response(
 *         response=401,
 *         description="Unauthorized"
 *     )
 * )
 */
public function index(Request $request)
{
    // Implementation
}
```

---

## API Testing

### Feature Tests

```php
namespace Tests\Feature\Api;

use Tests\TestCase;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

class UserApiTest extends TestCase
{
    public function test_can_list_users()
    {
        Sanctum::actingAs(User::factory()->create());

        $response = $this->getJson('/api/v1/users');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'name', 'email', 'created_at']
                ],
                'meta',
                'links'
            ]);
    }

    public function test_can_create_user()
    {
        Sanctum::actingAs(User::factory()->admin()->create());

        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'SecurePassword123!',
            'password_confirmation' => 'SecurePassword123!',
        ];

        $response = $this->postJson('/api/v1/users', $userData);

        $response->assertCreated()
            ->assertJsonStructure([
                'data' => ['id', 'name', 'email']
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com'
        ]);
    }

    public function test_cannot_create_user_without_authentication()
    {
        $response = $this->postJson('/api/v1/users', []);

        $response->assertUnauthorized();
    }

    public function test_validation_error_returns_422()
    {
        Sanctum::actingAs(User::factory()->create());

        $response = $this->postJson('/api/v1/users', [
            'name' => '',
            'email' => 'invalid-email',
        ]);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'error' => [
                    'code',
                    'message',
                    'details'
                ]
            ]);
    }
}
```

---

## Best Practices

### 1. Use API Resources
Always use API Resources to transform models into JSON responses.

### 2. Validate All Inputs
Use Form Requests for validation.

### 3. Use Proper HTTP Methods
Don't use POST for everything.

### 4. Version Your API
Start with v1 from day one.

### 5. Paginate Collections
Always paginate list endpoints.

### 6. Use Consistent Naming
Stick to conventions throughout the API.

### 7. Document Everything
Keep API documentation up to date.

### 8. Handle Errors Gracefully
Return meaningful error messages.

### 9. Secure Your API
Authenticate, authorize, and rate limit.

### 10. Test Thoroughly
Write tests for all API endpoints.

---

## API Checklist

- [ ] RESTful endpoints following conventions
- [ ] API versioning implemented
- [ ] Authentication (Sanctum/Passport)
- [ ] Authorization (Policies)
- [ ] API Resources for responses
- [ ] Form Requests for validation
- [ ] Consistent error handling
- [ ] Rate limiting configured
- [ ] Pagination implemented
- [ ] API documentation (OpenAPI)
- [ ] Feature tests written
- [ ] CORS configured
- [ ] Security headers set
