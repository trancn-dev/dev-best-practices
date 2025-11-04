# Project Context for GitHub Copilot

This file provides essential context about the Laravel DevKit project to help GitHub Copilot generate better, more contextually appropriate code suggestions.

---

## Project Overview

**Project Name**: Laravel DevKit
**Type**: laravel
**Version**: Laravel 12.x
**PHP Version**: 8.2+
**Purpose**: Laravel development kit with GitHub Copilot integration

---

## Technology Stack

### Backend
- **Framework**: Laravel 12.x
- **PHP**: 8.2+
- **Database**: SQLite (default) | MySQL 8.0+ | PostgreSQL 13+ (fully supported)
- **Cache**: Redis, Memcached, File (configurable)
- **Queue**: Redis, Database, Sync (configurable)
- **Search**: Laravel Scout (optional)

### Frontend
- **Build Tool**: Vite 7.x
- **CSS Framework**: Tailwind CSS 4.x
- **JavaScript**: Vanilla JS / Alpine.js (configurable)

### Development Tools
- **Testing**: PHPUnit / Pest
- **Code Quality**: PHPStan, Pint
- **Debug**: Telescope, Debugbar
- **API Documentation**: Scribe / OpenAPI

---

## Project Structure

```
app/
├── Actions/              # Single-purpose action classes
├── Console/             # Artisan commands
├── DataTransferObjects/ # DTOs for data transfer
├── Enums/               # PHP 8.1+ enums
├── Events/              # Event classes
├── Exceptions/          # Custom exceptions
├── Http/
│   ├── Controllers/     # HTTP controllers
│   │   ├── Api/        # API controllers
│   │   └── Web/        # Web controllers
│   ├── Middleware/      # HTTP middleware
│   ├── Requests/        # Form request validation
│   └── Resources/       # API resources
├── Jobs/                # Queue jobs
├── Listeners/           # Event listeners
├── Mail/                # Mailable classes
├── Models/              # Eloquent models
├── Notifications/       # Notification classes
├── Policies/            # Authorization policies
├── Providers/           # Service providers
├── Repositories/        # Repository pattern (optional)
├── Services/            # Business logic services
└── Traits/              # Reusable traits
```

---

## Architectural Patterns

### Primary Patterns Used

1. **Action Pattern**
   - Single-purpose classes for business operations
   - Located in `app/Actions/`
   - Example: `CreateUserAction`, `ProcessPaymentAction`

2. **Service Layer Pattern**
   - Business logic services
   - Located in `app/Services/`
   - Example: `PaymentService`, `NotificationService`

3. **Repository Pattern** (Optional)
   - Data access abstraction
   - Located in `app/Repositories/`
   - Example: `UserRepository`, `PostRepository`

4. **DTO Pattern**
   - Immutable data transfer objects
   - Located in `app/DataTransferObjects/`
   - Example: `CreateUserData`, `UpdatePostData`

### Design Principles

- **SOLID Principles**: Follow all SOLID principles strictly
- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **YAGNI**: You Aren't Gonna Need It
- **Dependency Injection**: Use constructor injection via service container

---

## Coding Standards

### PHP Standards
- **PSR-12**: PHP coding style guide (enforced)
- **Type Hints**: Always use type hints for parameters and return types
- **Strict Types**: Use `declare(strict_types=1)` in all files
- **PHPDoc**: Comprehensive documentation for all public methods

### Laravel Conventions
- **Naming**: Follow Laravel naming conventions
  - Controllers: `UserController` (singular)
  - Models: `User` (singular)
  - Tables: `users` (plural, snake_case)
  - Migrations: `create_users_table`
  - Routes: `users.index`, `users.show` (plural)

- **Method Naming**:
  - Controller actions: `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`
  - Eloquent: camelCase (`getUserPosts`)
  - Database: snake_case (`user_posts`)

### Code Organization
- **Fat Models, Skinny Controllers**: Move business logic to Actions/Services
- **Form Requests**: Use for all validation
- **API Resources**: Use for all API responses
- **Events & Listeners**: Use for side effects and async operations
- **Jobs**: Use for long-running or async tasks

---

## Database Conventions

### Table Naming
- Plural, snake_case: `users`, `blog_posts`, `order_items`
- Pivot tables: Alphabetically ordered, singular: `post_tag`, `role_user`

### Column Naming
- snake_case: `first_name`, `created_at`, `is_active`
- Foreign keys: `{model}_id` (e.g., `user_id`, `post_id`)
- Polymorphic: `{relation}_type`, `{relation}_id`

### Indexes
- Always add indexes on foreign keys
- Add indexes on frequently queried columns
- Use composite indexes for multi-column queries
- Name indexes: `{table}_{column}_index`

### Migrations
- Always reversible (implement `down()` method)
- Use descriptive names
- One change per migration
- Never modify published migrations

---

## API Standards

### RESTful Conventions
- Use proper HTTP methods: GET, POST, PUT/PATCH, DELETE
- Use proper HTTP status codes
- Version APIs: `/api/v1/`
- Use resource naming (plural): `/api/v1/users`

### Response Format
```json
{
  "data": { /* resource or collection */ },
  "meta": { /* pagination, etc. */ },
  "links": { /* HATEOAS links */ }
}
```

### Error Format
```json
{
  "message": "Error message",
  "errors": { /* validation errors */ }
}
```

---

## Security Practices

### Authentication
- Use Laravel Sanctum for API authentication
- Use Laravel Breeze/Fortify for web authentication
- Never store plain text passwords
- Use bcrypt/argon2 for password hashing

### Authorization
- Use Policies for authorization logic
- Use Gates for simple checks
- Always authorize requests: `$this->authorize('update', $post)`

### Input Validation
- Always validate user input
- Use Form Requests for validation
- Sanitize input when necessary
- Use `validated()` method, never `all()`

### Data Protection
- Use `$fillable` or `$guarded` on models
- Never expose sensitive data in API responses
- Use `$hidden` property on models
- Encrypt sensitive data at rest

---

## Testing Strategy

### Test Types
- **Unit Tests**: Test individual classes/methods in isolation
- **Feature Tests**: Test HTTP requests and responses
- **Integration Tests**: Test component interactions

### Coverage Goals
- Critical paths: 100%
- Business logic: 90%+
- Controllers: 80%+
- Overall: 75%+

### Naming Convention
```php
/** @test */
public function it_can_create_a_user()
{
    // Arrange
    // Act
    // Assert
}
```

---

## Performance Considerations

### Query Optimization
- Always eager load relationships (`with()`)
- Avoid N+1 queries
- Use `select()` to load only needed columns
- Use database indexes
- Use `chunk()` for large datasets

### Caching Strategy
- Cache expensive queries
- Use Redis for cache
- Tag caches for easy invalidation
- Cache time-based data appropriately

### Queue Usage
- Queue long-running tasks
- Queue external API calls
- Queue email sending
- Queue report generation

---

## Development Workflow

### Git Workflow
- Branch naming: `feature/`, `bugfix/`, `hotfix/`
- Commit messages: Conventional Commits format
- Pull requests: Required for main branch
- Code review: Required before merge

### Environment
- Use `.env` for configuration
- Never commit `.env` file
- Use `.env.example` as template
- Different `.env` for each environment

---

## Third-Party Services

### Commonly Used Packages
- **Laravel Sanctum**: API authentication
- **Laravel Telescope**: Debug and monitoring
- **Laravel Horizon**: Queue monitoring
- **Laravel Pint**: Code style fixer
- **PHPStan**: Static analysis
- **Pest**: Testing framework (optional)
- **Laravel Scribe**: API documentation

---

## AI Assistant Guidelines

When generating code for this project, please:

1. **Follow Laravel conventions** strictly
2. **Use type hints** for all parameters and return types
3. **Write PHPDoc** for all public methods
4. **Include tests** for new features
5. **Use Form Requests** for validation
6. **Use API Resources** for API responses
7. **Use Actions/Services** for business logic
8. **Follow PSR-12** coding standards
9. **Consider security** implications
10. **Optimize for performance** (avoid N+1, use caching)

### Code Generation Preferences

- **Prefer**: Eloquent over Query Builder over Raw SQL
- **Prefer**: Actions over fat controllers
- **Prefer**: Services for complex business logic
- **Prefer**: Events for side effects
- **Prefer**: Jobs for async operations
- **Prefer**: Policies for authorization
- **Prefer**: Form Requests for validation
- **Prefer**: API Resources for transformations

---

## Common Patterns to Use

### Controller Pattern
```php
public function store(StoreUserRequest $request, CreateUserAction $action): JsonResponse
{
    $user = $action->execute($request->validated());

    return response()->json(
        new UserResource($user),
        201
    );
}
```

### Action Pattern
```php
class CreateUserAction
{
    public function execute(array $data): User
    {
        return DB::transaction(function () use ($data) {
            $user = User::create($data);
            event(new UserCreated($user));
            return $user;
        });
    }
}
```

### Service Pattern
```php
class PaymentService
{
    public function processPayment(Order $order): Payment
    {
        // Complex payment logic here
    }
}
```

---

## File Header Template

All PHP files should start with:

```php
<?php

declare(strict_types=1);

namespace App\[Directory];

// Imports here

/**
 * [Class description]
 *
 * @package App\[Directory]
 */
```

---

## Additional Context

### Project-Specific Notes
- This is a development kit, so code should be exemplary
- All code should follow best practices
- Documentation is crucial
- Performance and security are top priorities

### Future Plans
- Add more scaffolding commands
- Integrate with more third-party services
- Add more examples and templates
- Improve CI/CD pipeline

---

**Last Updated**: 2025-10-30
**Maintained By**: Development Team
**Contact**: [Your contact information]
