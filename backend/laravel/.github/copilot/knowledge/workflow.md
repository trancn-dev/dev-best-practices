# Development Workflows & Processes

This document describes the standard workflows, processes, and procedures for developing features in the Laravel DevKit project.

---

## Table of Contents

1. [Development Lifecycle](#development-lifecycle)
2. [Feature Development Workflow](#feature-development-workflow)
3. [Bug Fix Workflow](#bug-fix-workflow)
4. [Code Review Process](#code-review-process)
5. [Testing Workflow](#testing-workflow)
6. [Deployment Workflow](#deployment-workflow)
7. [Database Migration Workflow](#database-migration-workflow)
8. [API Development Workflow](#api-development-workflow)

---

## Development Lifecycle

```
Planning → Design → Implementation → Testing → Review → Deployment → Monitoring
   ↓         ↓           ↓            ↓         ↓          ↓           ↓
Docs    Architecture   Code        Tests    PR Review   Release    Metrics
```

### Phases

1. **Planning** (1-2 days)
   - Define requirements
   - Create user stories
   - Estimate effort
   - Assign tasks

2. **Design** (1-3 days)
   - Architecture design
   - Database schema
   - API contracts
   - UI/UX mockups

3. **Implementation** (3-10 days)
   - Write code
   - Write tests
   - Document code
   - Self-review

4. **Testing** (1-2 days)
   - Unit tests
   - Feature tests
   - Integration tests
   - Manual testing

5. **Review** (1-2 days)
   - Code review
   - Security review
   - Performance review
   - Documentation review

6. **Deployment** (0.5-1 day)
   - Staging deployment
   - Smoke tests
   - Production deployment
   - Rollback plan ready

7. **Monitoring** (Ongoing)
   - Error tracking
   - Performance monitoring
   - User feedback
   - Metrics analysis

---

## Feature Development Workflow

### Step 1: Create Feature Branch

```bash
# Update main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/user-authentication

# Branch naming convention:
# feature/short-description
# bugfix/issue-number-description
# hotfix/critical-issue
# refactor/component-name
```

### Step 2: Plan Implementation

```bash
# Use Copilot command
@workspace /new-requirement Implement user authentication system

# Create task breakdown
# - Database schema for users
# - Registration endpoint
# - Login endpoint
# - Password reset
# - Email verification
# - Tests for each component
```

### Step 3: Implement Database Schema

```bash
# Create migration
php artisan make:migration create_users_table

# Edit migration file
# - Define columns
# - Add indexes
# - Add foreign keys
# - Implement down() method

# Run migration
php artisan migrate

# If issues, rollback and fix
php artisan migrate:rollback
```

### Step 4: Create Model & Relationships

```bash
# Create model
php artisan make:model User

# Define:
# - Fillable/guarded attributes
# - Hidden attributes
# - Casts
# - Relationships
# - Accessors/Mutators
# - Scopes
```

### Step 5: Create Form Requests

```bash
# Create request for validation
php artisan make:request StoreUserRequest
php artisan make:request UpdateUserRequest

# Define:
# - Validation rules
# - Authorization logic
# - Custom error messages
# - Prepared data
```

### Step 6: Create Action/Service

```bash
# Create action for business logic
php artisan make:action CreateUserAction

# Implement:
# - Type hints
# - Business logic
# - Database transactions
# - Event dispatching
# - Error handling
```

### Step 7: Create Controller

```bash
# Create controller
php artisan make:controller Api/UserController --api

# Implement:
# - Inject dependencies
# - Use Form Requests
# - Use Actions/Services
# - Return API Resources
# - Handle exceptions
```

### Step 8: Create API Resource

```bash
# Create resource for response formatting
php artisan make:resource UserResource
php artisan make:resource UserCollection

# Define:
# - Transformed attributes
# - Conditional fields
# - Relationships
# - Meta data
```

### Step 9: Create Policy

```bash
# Create policy for authorization
php artisan make:policy UserPolicy

# Implement:
# - viewAny, view
# - create, update, delete
# - Custom policies
# - Register in AuthServiceProvider
```

### Step 10: Register Routes

```php
// routes/api.php
Route::prefix('v1')->group(function () {
    Route::apiResource('users', UserController::class);
});

// Test routes
php artisan route:list --path=users
```

### Step 11: Write Tests

```bash
# Create feature test
php artisan make:test UserApiTest

# Create unit test
php artisan make:test CreateUserActionTest --unit

# Write tests for:
# - Happy path
# - Edge cases
# - Error cases
# - Validation
# - Authorization

# Run tests
php artisan test
php artisan test --coverage
```

### Step 12: Generate Documentation

```bash
# Use Copilot prompt
@workspace /doc Generate API documentation for UserController

# Generate OpenAPI spec
php artisan scribe:generate

# Review documentation
# - Endpoint descriptions
# - Request examples
# - Response examples
# - Error codes
```

### Step 13: Code Quality Checks

```bash
# Format code
./vendor/bin/pint

# Static analysis
./vendor/bin/phpstan analyse

# Run all tests
php artisan test

# Check test coverage
php artisan test --coverage --min=80
```

### Step 14: Commit Changes

```bash
# Stage changes
git add .

# Commit with conventional commit message
git commit -m "feat(auth): implement user registration and login

- Add User model with authentication
- Create registration endpoint with validation
- Create login endpoint with JWT tokens
- Add email verification
- Add password reset functionality
- Add comprehensive test suite
- Add API documentation

Closes #123"

# Commit message format:
# <type>(<scope>): <subject>
#
# <body>
#
# <footer>

# Types: feat, fix, docs, style, refactor, test, chore
```

### Step 15: Push & Create PR

```bash
# Push branch
git push origin feature/user-authentication

# Create PR on GitHub/GitLab
# - Fill PR template
# - Add description
# - Link issues
# - Add reviewers
# - Add labels
```

### Step 16: Code Review

```bash
# Address review comments
# - Make changes
# - Run tests
# - Commit fixes
# - Push updates

git add .
git commit -m "fix: address code review comments"
git push origin feature/user-authentication
```

### Step 17: Merge to Main

```bash
# After approval, merge PR
# - Squash commits (if many small commits)
# - Or merge commit (if clean history)
# - Delete feature branch

# Pull latest main
git checkout main
git pull origin main

# Delete local feature branch
git branch -d feature/user-authentication
```

---

## Bug Fix Workflow

### Step 1: Identify Bug

```bash
# Create bug ticket with:
# - Steps to reproduce
# - Expected behavior
# - Actual behavior
# - Environment details
# - Error logs
# - Screenshots
```

### Step 2: Reproduce Bug

```bash
# Create test that reproduces bug
php artisan make:test BugReproductionTest

# Test should fail
php artisan test --filter BugReproductionTest
```

### Step 3: Create Bugfix Branch

```bash
git checkout main
git pull origin main
git checkout -b bugfix/123-fix-user-registration-email
```

### Step 4: Fix Bug

```bash
# Use Copilot assistant
@workspace /bug Fix user registration email not being sent

# Implement fix:
# - Identify root cause
# - Fix the issue
# - Ensure test passes
# - Add additional tests
```

### Step 5: Verify Fix

```bash
# Run specific test
php artisan test --filter BugReproductionTest

# Run all tests
php artisan test

# Manual testing
# - Test the specific scenario
# - Test related functionality
# - Test edge cases
```

### Step 6: Commit & PR

```bash
git add .
git commit -m "fix(auth): resolve email not being sent on registration

- Fix queue configuration issue
- Add test to prevent regression
- Update documentation

Fixes #123"

git push origin bugfix/123-fix-user-registration-email
```

---

## Code Review Process

### For Reviewers

**Review Checklist**:

1. **Functionality**
   - [ ] Code does what it's supposed to do
   - [ ] Edge cases handled
   - [ ] Error cases handled
   - [ ] Business logic correct

2. **Code Quality**
   - [ ] Follows PSR-12 standards
   - [ ] Follows Laravel conventions
   - [ ] No code smells
   - [ ] DRY principle followed
   - [ ] SOLID principles followed

3. **Security**
   - [ ] Input validated
   - [ ] Output escaped
   - [ ] No SQL injection risks
   - [ ] No XSS vulnerabilities
   - [ ] Authorization checked
   - [ ] Sensitive data protected

4. **Performance**
   - [ ] No N+1 queries
   - [ ] Efficient algorithms
   - [ ] Proper indexing
   - [ ] Caching where appropriate
   - [ ] No memory leaks

5. **Testing**
   - [ ] Tests included
   - [ ] Tests pass
   - [ ] Coverage adequate (>80%)
   - [ ] Tests meaningful

6. **Documentation**
   - [ ] Code commented appropriately
   - [ ] PHPDoc complete
   - [ ] API docs updated
   - [ ] README updated if needed

7. **Database**
   - [ ] Migrations reversible
   - [ ] Indexes added
   - [ ] Foreign keys defined
   - [ ] No breaking changes

**Review Process**:

```bash
# Checkout PR branch
git fetch origin
git checkout feature/user-authentication

# Run tests
php artisan test

# Run static analysis
./vendor/bin/phpstan analyse

# Code style check
./vendor/bin/pint --test

# Review code in IDE
# - Read through changes
# - Check for issues
# - Test locally

# Leave review comments
# - Be constructive
# - Suggest improvements
# - Ask questions
# - Approve or request changes
```

---

## Testing Workflow

### Test-Driven Development (TDD)

```
1. Write failing test
   ↓
2. Write minimal code to pass
   ↓
3. Refactor code
   ↓
4. Repeat
```

### Test Types

**1. Unit Tests** (`tests/Unit/`)
```bash
# Test single class/method in isolation
php artisan make:test CreateUserActionTest --unit

# Example:
public function test_it_creates_user_with_valid_data()
{
    $action = new CreateUserAction();
    $data = ['name' => 'John', 'email' => 'john@example.com'];

    $user = $action->execute($data);

    $this->assertInstanceOf(User::class, $user);
    $this->assertEquals('John', $user->name);
}
```

**2. Feature Tests** (`tests/Feature/`)
```bash
# Test HTTP endpoints
php artisan make:test UserApiTest

# Example:
public function test_user_can_register()
{
    $response = $this->postJson('/api/v1/register', [
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'password' => 'SecurePass123!',
        'password_confirmation' => 'SecurePass123!',
    ]);

    $response->assertCreated()
        ->assertJsonStructure(['data', 'token']);

    $this->assertDatabaseHas('users', [
        'email' => 'john@example.com'
    ]);
}
```

**3. Integration Tests**
```bash
# Test multiple components together
public function test_order_processing_workflow()
{
    // Create user
    // Create products
    // Place order
    // Process payment
    // Send notifications
    // Assert all steps completed
}
```

### Running Tests

```bash
# All tests
php artisan test

# Specific test file
php artisan test tests/Feature/UserApiTest.php

# Specific test method
php artisan test --filter test_user_can_register

# With coverage
php artisan test --coverage

# Parallel execution
php artisan test --parallel

# Stop on failure
php artisan test --stop-on-failure
```

---

## Deployment Workflow

### Staging Deployment

```bash
# 1. Merge to staging branch
git checkout staging
git merge develop
git push origin staging

# 2. Automated deployment (CI/CD)
# - Run tests
# - Build assets
# - Deploy to staging server
# - Run migrations
# - Clear caches

# 3. Smoke tests
curl https://staging.example.com/health
curl https://staging.example.com/api/v1/users

# 4. Manual testing
# - Test new features
# - Test existing features
# - Test edge cases

# 5. Monitor for issues
# - Check error logs
# - Check performance
# - Check user feedback
```

### Production Deployment

```bash
# 1. Create release branch
git checkout main
git pull origin main
git checkout -b release/v1.2.0

# 2. Update version numbers
# - composer.json
# - package.json
# - CHANGELOG.md

# 3. Create release tag
git add .
git commit -m "chore: bump version to 1.2.0"
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin release/v1.2.0
git push origin v1.2.0

# 4. Deployment checklist
# - [ ] All tests passing
# - [ ] Code reviewed and approved
# - [ ] Changelog updated
# - [ ] Documentation updated
# - [ ] Database migrations tested
# - [ ] Rollback plan ready
# - [ ] Monitoring alerts configured
# - [ ] Team notified

# 5. Deploy to production
# - Put application in maintenance mode
php artisan down

# - Pull latest code
git pull origin main

# - Install dependencies
composer install --no-dev --optimize-autoloader

# - Run migrations
php artisan migrate --force

# - Clear caches
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# - Restart services
php artisan queue:restart
sudo systemctl reload php8.2-fpm
sudo systemctl reload nginx

# - Take application out of maintenance
php artisan up

# 6. Verify deployment
curl https://example.com/health
php artisan tinker
>>> DB::connection()->getPdo();

# 7. Monitor
# - Check error logs
# - Check application logs
# - Check performance metrics
# - Check user reports

# 8. Rollback if needed
git revert HEAD
php artisan migrate:rollback
# Deploy previous version
```

---

## Database Migration Workflow

### Creating Migrations

```bash
# Create table migration
php artisan make:migration create_users_table

# Add column
php artisan make:migration add_status_to_users_table

# Modify column
php artisan make:migration modify_email_column_in_users_table

# Drop column
php artisan make:migration drop_old_column_from_users_table

# Create pivot table
php artisan make:migration create_post_tag_pivot_table
```

### Writing Migrations

```php
// up() - forward migration
public function up(): void
{
    Schema::create('users', function (Blueprint $table) {
        $table->id();
        $table->string('email')->unique();
        $table->timestamps();

        // Add indexes
        $table->index('email');
    });
}

// down() - rollback migration
public function down(): void
{
    Schema::dropIfExists('users');
}
```

### Running Migrations

```bash
# Run pending migrations
php artisan migrate

# Rollback last batch
php artisan migrate:rollback

# Rollback specific steps
php artisan migrate:rollback --step=2

# Reset all migrations
php artisan migrate:reset

# Refresh (rollback + migrate)
php artisan migrate:refresh

# Fresh (drop all tables + migrate)
php artisan migrate:fresh

# With seeding
php artisan migrate:fresh --seed

# Check status
php artisan migrate:status
```

### Migration Best Practices

1. **Always Reversible**
   - Implement `down()` method
   - Test rollback before deploying

2. **One Change Per Migration**
   - Don't mix table creation and modification
   - Separate concerns

3. **Never Modify Published Migrations**
   - Create new migration instead
   - Keep history intact

4. **Use Transactions** (when possible)
   - Atomic operations
   - Rollback on failure

5. **Add Indexes**
   - Foreign keys
   - Frequently queried columns
   - Unique constraints

---

## API Development Workflow

### Step 1: Design API Contract

```yaml
# openapi.yaml
/api/v1/users:
  get:
    summary: List users
    parameters:
      - name: page
      - name: per_page
    responses:
      200:
        description: Success
```

### Step 2: Create Routes

```php
// routes/api.php
Route::prefix('v1')->group(function () {
    Route::apiResource('users', UserController::class);
});
```

### Step 3: Implement Controller

```php
class UserController extends Controller
{
    public function index(Request $request): UserCollection
    {
        $users = User::paginate($request->input('per_page', 15));
        return new UserCollection($users);
    }
}
```

### Step 4: Create Resources

```php
class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
        ];
    }
}
```

### Step 5: Write Tests

```php
public function test_can_list_users()
{
    User::factory()->count(20)->create();

    $response = $this->getJson('/api/v1/users');

    $response->assertOk()
        ->assertJsonStructure(['data', 'meta', 'links']);
}
```

### Step 6: Generate Documentation

```bash
php artisan scribe:generate
```

---

**Last Updated**: 2025-10-30
**Version**: 1.0
**Maintained By**: Development Team
