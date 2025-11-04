# Prompt: Bug Fix Assistant

## Purpose
Help diagnose and fix bugs in Laravel applications with systematic debugging approach.

## When to Use
- Application errors or exceptions
- Unexpected behavior
- Performance issues
- Data inconsistencies
- Integration failures

---

## Prompt Template

```
I'm experiencing a bug in my Laravel application:

**Symptom**: [Describe what's happening]
**Expected**: [What should happen]
**Environment**: [local/staging/production]
**Laravel Version**: [e.g., 11.x]
**PHP Version**: [e.g., 8.2]

**Error Message** (if any):
[ERROR_MESSAGE]

**Code**:
[RELEVANT_CODE]

**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**What I've Tried**:
- [Attempt 1]
- [Attempt 2]

Please help me:
1. Diagnose the root cause
2. Provide a fix
3. Explain why it happened
4. Suggest how to prevent similar issues
5. Recommend additional debugging if needed
```

---

## Example Usage

### Example 1: N+1 Query Problem

**Input:**
```
I'm experiencing a bug in my Laravel application:

**Symptom**: The user list page is very slow (5+ seconds)
**Expected**: Should load in < 1 second
**Environment**: Production
**Laravel Version**: 11.x
**PHP Version**: 8.2

**Code**:
public function index()
{
    $users = User::all();
    return view('users.index', compact('users'));
}

// In view:
@foreach($users as $user)
    <tr>
        <td>{{ $user->name }}</td>
        <td>{{ $user->posts->count() }}</td>
        <td>{{ $user->comments->count() }}</td>
    </tr>
@endforeach

**Steps to Reproduce**:
1. Navigate to /users
2. Page takes 5+ seconds to load
3. Laravel Debugbar shows 1000+ queries

**What I've Tried**:
- Checked database indexes
- Increased PHP memory limit
```

**Expected Output:**

### 🔍 Root Cause Analysis

**Issue**: N+1 Query Problem

You're loading all users (1 query), then for each user, you're loading:
- Posts (N queries)
- Comments (N queries)

With 500 users, that's **1 + 500 + 500 = 1001 queries**!

### ✅ Solution

```php
// Controller
public function index()
{
    $users = User::withCount(['posts', 'comments'])
        ->paginate(50); // Also add pagination!

    return view('users.index', compact('users'));
}

// View remains the same
@foreach($users as $user)
    <tr>
        <td>{{ $user->name }}</td>
        <td>{{ $user->posts_count }}</td>
        <td>{{ $user->comments_count }}</td>
    </tr>
@endforeach
```

### 📊 Performance Improvement

**Before**: 1001 queries, ~5 seconds
**After**: 1 query, < 100ms

### 📝 Explanation

1. `withCount()` adds a subquery to count related records
2. No additional queries for each user
3. Results available as `{relation}_count` attribute
4. Added pagination to limit results per page

### 🛡️ Prevention

1. **Always eager load relationships**:
   ```php
   User::with('posts', 'comments')->get();
   ```

2. **Use Laravel Debugbar in development**:
   ```bash
   composer require barryvdh/laravel-debugbar --dev
   ```

3. **Monitor query count in tests**:
   ```php
   DB::enableQueryLog();
   $this->get('/users');
   $queries = DB::getQueryLog();
   $this->assertLessThan(5, count($queries));
   ```

4. **Add database query logging for slow queries**:
   ```php
   // AppServiceProvider
   DB::listen(function ($query) {
       if ($query->time > 1000) {
           Log::warning('Slow query', [
               'sql' => $query->sql,
               'time' => $query->time
           ]);
       }
   });
   ```

### 🔧 Additional Recommendations

1. **Add caching**:
   ```php
   $users = Cache::remember('users.index', 600, function () {
       return User::withCount(['posts', 'comments'])->paginate(50);
   });
   ```

2. **Consider using cursor pagination for large datasets**:
   ```php
   User::withCount(['posts', 'comments'])->cursorPaginate(50);
   ```

3. **Add indexes** on foreign keys if not already present:
   ```php
   Schema::table('posts', function (Blueprint $table) {
       $table->index('user_id');
   });
   ```

---

### Example 2: Mass Assignment Error

**Input:**
```
I'm experiencing a bug in my Laravel application:

**Symptom**: Getting MassAssignmentException when creating user
**Expected**: User should be created successfully

**Error Message**:
Illuminate\Database\Eloquent\MassAssignmentException: Add [role] to fillable property to allow mass assignment on [App\Models\User].

**Code**:
public function store(Request $request)
{
    $user = User::create($request->all());
    return response()->json($user, 201);
}

**What I've Tried**:
- Checked if 'role' is in the request
- Cleared cache
```

**Expected Output:**

### 🔍 Root Cause Analysis

**Issue**: Mass Assignment Protection

Laravel's mass assignment protection is blocking the 'role' field because it's not in the `$fillable` array of your User model.

### ⚠️ Security Warning

**DO NOT** add `role` to `$fillable` directly! This is a security vulnerability that would allow users to make themselves admins.

### ✅ Solution

**Option 1: Separate Role Assignment (Recommended)**
```php
public function store(StoreUserRequest $request)
{
    $user = User::create([
        'name' => $request->name,
        'email' => $request->email,
        'password' => Hash::make($request->password),
    ]);

    // Only admins can assign roles
    if ($request->user()->isAdmin() && $request->has('role')) {
        $user->role = $request->role;
        $user->save();
    }

    return new UserResource($user);
}
```

**Option 2: Use Authorization**
```php
// Model
protected $fillable = ['name', 'email', 'password'];

public function setRoleAttribute($value)
{
    // Only allow admins to set role
    if (auth()->check() && auth()->user()->isAdmin()) {
        $this->attributes['role'] = $value;
    }
}

// Controller with authorization check
public function store(StoreUserRequest $request)
{
    $this->authorize('assignRole', User::class);

    $user = User::create($request->validated());

    return new UserResource($user);
}
```

### 📝 Explanation

1. Mass assignment protection prevents malicious users from setting arbitrary fields
2. `$fillable` defines which fields can be mass assigned
3. Sensitive fields like 'role', 'is_admin' should NEVER be in `$fillable`
4. Always validate and authorize before assigning sensitive fields

### 🛡️ Prevention

1. **Never use** `$request->all()`:
   ```php
   // ❌ Bad
   User::create($request->all());

   // ✅ Good
   User::create($request->validated());
   ```

2. **Use FormRequest validation**:
   ```php
   class StoreUserRequest extends FormRequest
   {
       public function authorize(): bool
       {
           return $this->user()->can('create', User::class);
       }

       public function rules(): array
       {
           return [
               'name' => 'required|string|max:255',
               'email' => 'required|email|unique:users',
               'password' => 'required|min:8|confirmed',
               // Note: 'role' is NOT here
           ];
       }
   }
   ```

3. **Whitelist approach**:
   ```php
   protected $fillable = ['name', 'email', 'password'];
   ```

4. **Use policies for authorization**:
   ```php
   class UserPolicy
   {
       public function assignRole(User $user): bool
       {
           return $user->isAdmin();
       }
   }
   ```

---

## Common Bug Categories

### Database Issues
```
Problem: Query errors, data inconsistencies
Check:
- Migration files
- Model relationships
- Database indexes
- Foreign key constraints
```

### Authentication Issues
```
Problem: Login failures, permission errors
Check:
- Guards and providers config
- Password hashing
- Session configuration
- Middleware setup
```

### Performance Issues
```
Problem: Slow responses, timeouts
Check:
- N+1 queries (use Debugbar)
- Missing indexes
- Large dataset without pagination
- No caching strategy
```

### API Issues
```
Problem: 404, 422, 500 errors
Check:
- Route definitions
- Controller methods
- Validation rules
- API Resource transformations
```

---

## Debugging Checklist

### General Steps
- [ ] Check Laravel logs (`storage/logs/laravel.log`)
- [ ] Enable debug mode locally (`APP_DEBUG=true`)
- [ ] Clear caches (`php artisan cache:clear`, `config:clear`, `route:clear`)
- [ ] Check environment variables (`.env`)
- [ ] Run migrations (`php artisan migrate:status`)
- [ ] Check database connection
- [ ] Review recent code changes
- [ ] Check server requirements (PHP version, extensions)

### For Queries
- [ ] Enable query logging
- [ ] Use Laravel Debugbar
- [ ] Check N+1 queries
- [ ] Verify indexes exist
- [ ] Check raw SQL with `toSql()`

### For Errors
- [ ] Read full stack trace
- [ ] Check line numbers
- [ ] Look at surrounding code
- [ ] Check documentation
- [ ] Search for similar issues on Stack Overflow/GitHub

---

## Variations

### For Production Bugs
```
This is a production bug affecting users:
[DESCRIPTION]

Please provide:
1. Quick hotfix (if possible)
2. Root cause analysis
3. Long-term solution
4. Monitoring recommendations
```

### For Testing Failures
```
My test is failing:
[TEST_CODE]
[ERROR_MESSAGE]

Please help me understand why and how to fix it.
```

### For Integration Issues
```
I'm having issues integrating with [SERVICE]:
[DESCRIPTION]
[ERROR_LOGS]

Please help debug the integration.
```

---

## Related Prompts

- `code-explanation.md` - Understand problematic code
- `refactoring-suggestions.md` - Improve code quality
- `testing-strategy.md` - Write tests to prevent bugs
- `performance-optimization.md` - Fix performance issues
