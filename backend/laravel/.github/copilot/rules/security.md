# Rule: Security Best Practices

## Intent
This rule enforces security best practices for Laravel applications based on OWASP guidelines and Laravel security standards. Copilot must follow these security principles when generating or reviewing code.

## Scope
Applies to all PHP files, especially controllers, services, middleware, authentication, authorization, and data handling logic.

---

## 1. Input Validation & Sanitization

### Always Validate Input
- ✅ Use FormRequest classes for validation
- ✅ Validate all user inputs (GET, POST, headers, cookies)
- ✅ Define validation rules explicitly
- ❌ Never trust user input

**Example:**
```php
// ✅ Good - Using FormRequest
class StoreUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8|confirmed',
        ];
    }
}

// Controller
public function store(StoreUserRequest $request)
{
    $validated = $request->validated(); // Only validated data
    // ...
}

// ❌ Bad - No validation
public function store(Request $request)
{
    User::create($request->all()); // Dangerous!
}
```

### SQL Injection Prevention
- ✅ Always use Eloquent ORM or Query Builder
- ✅ Use parameter binding for raw queries
- ❌ Never concatenate user input into SQL

**Example:**
```php
// ✅ Good - Eloquent
$user = User::where('email', $request->email)->first();

// ✅ Good - Query Builder with binding
$users = DB::table('users')
    ->where('email', $email)
    ->get();

// ✅ Good - Raw query with binding
DB::select('SELECT * FROM users WHERE email = ?', [$email]);

// ❌ Bad - SQL Injection vulnerable
DB::select("SELECT * FROM users WHERE email = '$email'");
```

---

## 2. Authentication & Session Management

### Password Security
- ✅ Use bcrypt or argon2 for password hashing
- ✅ Minimum 8 characters password
- ✅ Implement password confirmation for sensitive operations
- ❌ Never store plain text passwords
- ❌ Never log passwords

**Example:**
```php
// ✅ Good - Hashing password
use Illuminate\Support\Facades\Hash;

$user->password = Hash::make($request->password);

// ✅ Good - Verify password
if (Hash::check($request->password, $user->password)) {
    // Authenticated
}

// ❌ Bad - Plain text password
$user->password = $request->password; // Never do this!
```

### Session Security
- ✅ Regenerate session ID after login
- ✅ Set secure session cookie options
- ✅ Implement session timeout
- ✅ Use HTTPS in production

**Example:**
```php
// ✅ Good - Regenerate session
$request->session()->regenerate();

// config/session.php
return [
    'secure' => env('SESSION_SECURE_COOKIE', true), // HTTPS only
    'http_only' => true, // No JavaScript access
    'same_site' => 'lax', // CSRF protection
    'lifetime' => 120, // 2 hours
];
```

---

## 3. Authorization & Access Control

### Use Policies and Gates
- ✅ Define authorization logic in Policy classes
- ✅ Check permissions before actions
- ✅ Use middleware for route protection
- ❌ Don't check authorization in views only

**Example:**
```php
// ✅ Good - Policy
class PostPolicy
{
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}

// Controller
public function update(Request $request, Post $post)
{
    $this->authorize('update', $post);
    // Update post
}

// ❌ Bad - No authorization check
public function update(Request $request, Post $post)
{
    $post->update($request->all()); // Anyone can update!
}
```

### Route Protection
```php
// ✅ Good - Protected routes
Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index']);
});

// ✅ Good - Role-based protection
Route::middleware(['auth', 'role:admin'])->group(function () {
    Route::resource('users', UserController::class);
});
```

---

## 4. XSS (Cross-Site Scripting) Prevention

### Output Escaping
- ✅ Use Blade `{{ }}` for automatic escaping
- ✅ Use `e()` helper for manual escaping
- ⚠️ Use `{!! !!}` only for trusted HTML
- ❌ Never output raw user input

**Example:**
```blade
{{-- ✅ Good - Auto escaped --}}
<p>{{ $user->bio }}</p>

{{-- ✅ Good - Manual escaping --}}
<p><?php echo e($user->bio); ?></p>

{{-- ⚠️ Careful - No escaping (use only for trusted content) --}}
<div>{!! $trustedHtml !!}</div>

{{-- ❌ Bad - Vulnerable to XSS --}}
<p><?php echo $user->bio; ?></p>
```

### Content Security Policy
```php
// ✅ Add CSP headers
// app/Http/Middleware/SecurityHeaders.php
public function handle($request, Closure $next)
{
    $response = $next($request);

    $response->headers->set('X-Content-Type-Options', 'nosniff');
    $response->headers->set('X-Frame-Options', 'DENY');
    $response->headers->set('X-XSS-Protection', '1; mode=block');
    $response->headers->set('Content-Security-Policy', "default-src 'self'");

    return $response;
}
```

---

## 5. CSRF (Cross-Site Request Forgery) Protection

### Use CSRF Tokens
- ✅ CSRF protection enabled by default in Laravel
- ✅ Include `@csrf` in all forms
- ✅ Add CSRF token to AJAX requests
- ❌ Never disable CSRF protection without good reason

**Example:**
```blade
{{-- ✅ Good - CSRF token in form --}}
<form method="POST" action="/user">
    @csrf
    <input type="text" name="name">
    <button type="submit">Submit</button>
</form>
```

```javascript
// ✅ Good - CSRF token in AJAX
$.ajaxSetup({
    headers: {
        'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
    }
});

// Or with Axios
axios.defaults.headers.common['X-CSRF-TOKEN'] =
    document.querySelector('meta[name="csrf-token"]').content;
```

---

## 6. Mass Assignment Protection

### Define Fillable or Guarded
- ✅ Always use `$fillable` or `$guarded` in models
- ✅ Whitelist approach with `$fillable` is preferred
- ❌ Never use `$guarded = []` in production

**Example:**
```php
// ✅ Good - Whitelist approach
class User extends Model
{
    protected $fillable = ['name', 'email', 'password'];
}

// ✅ Good - Use validated data
$user = User::create($request->validated());

// ❌ Bad - No protection
class User extends Model
{
    protected $guarded = []; // Dangerous!
}

// ❌ Bad - Mass assignment without validation
User::create($request->all()); // Can assign is_admin, etc.
```

---

## 7. File Upload Security

### Validate File Uploads
- ✅ Validate file type, size, and MIME type
- ✅ Generate unique filename
- ✅ Store outside public directory if sensitive
- ✅ Scan for malware if possible
- ❌ Never trust client-provided filename

**Example:**
```php
// ✅ Good - Secure file upload
public function upload(Request $request)
{
    $request->validate([
        'avatar' => 'required|image|mimes:jpeg,png,jpg|max:2048',
    ]);

    $path = $request->file('avatar')->store('avatars', 'private');

    // Generate safe filename
    $filename = Str::random(40) . '.' . $request->file('avatar')->extension();

    return $path;
}

// ❌ Bad - Insecure upload
public function upload(Request $request)
{
    $file = $request->file('avatar');
    $file->move('public/uploads', $file->getClientOriginalName()); // Dangerous!
}
```

---

## 8. Sensitive Data Protection

### Environment Variables
- ✅ Store secrets in `.env` file
- ✅ Never commit `.env` to version control
- ✅ Use `config()` to access configuration
- ❌ Never hardcode credentials in code

**Example:**
```php
// ✅ Good - Using config
$apiKey = config('services.stripe.secret');

// .env
STRIPE_SECRET=sk_test_...

// config/services.php
return [
    'stripe' => [
        'secret' => env('STRIPE_SECRET'),
    ],
];

// ❌ Bad - Hardcoded secret
$apiKey = 'sk_test_hardcoded_key'; // Never do this!
```

### Logging Security
- ✅ Log security events (failed logins, permission denied)
- ❌ Never log sensitive data (passwords, tokens, credit cards)
- ✅ Mask sensitive data in logs

**Example:**
```php
// ✅ Good - Safe logging
Log::info('User login attempt', [
    'email' => $email,
    'ip' => $request->ip(),
]);

// ❌ Bad - Logging sensitive data
Log::info('Login', [
    'password' => $password, // Never log passwords!
    'credit_card' => $cc, // Never log CC numbers!
]);
```

---

## 9. API Security

### Authentication
- ✅ Use Laravel Sanctum or Passport
- ✅ Implement rate limiting
- ✅ Use HTTPS for API endpoints
- ✅ Validate API tokens

**Example:**
```php
// ✅ Good - API rate limiting
Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function () {
    Route::get('/user', [UserController::class, 'index']);
});

// config/sanctum.php
'expiration' => 60, // Token expires in 60 minutes
```

### CORS Configuration
```php
// config/cors.php
return [
    'paths' => ['api/*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE'],
    'allowed_origins' => [env('FRONTEND_URL')], // Specific domains only
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['Content-Type', 'Authorization'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
```

---

## 10. Database Security

### Query Security
- ✅ Use parameterized queries
- ✅ Limit query results with pagination
- ✅ Use database transactions for critical operations
- ❌ Never expose database errors to users

**Example:**
```php
// ✅ Good - Transaction for data integrity
DB::transaction(function () use ($userId, $amount) {
    $user = User::lockForUpdate()->find($userId);
    $user->balance -= $amount;
    $user->save();

    Transaction::create([
        'user_id' => $userId,
        'amount' => $amount,
    ]);
});

// ✅ Good - Hide DB errors in production
// .env
APP_DEBUG=false

// ❌ Bad - Exposing DB errors
try {
    // Query
} catch (\Exception $e) {
    return response()->json(['error' => $e->getMessage()]); // May leak info
}
```

---

## 11. Encryption & Hashing

### Data Encryption
- ✅ Use Laravel's `Crypt` facade for encryption
- ✅ Encrypt sensitive data at rest
- ✅ Use HTTPS for data in transit

**Example:**
```php
use Illuminate\Support\Facades\Crypt;

// ✅ Good - Encrypt sensitive data
$encrypted = Crypt::encryptString($sensitiveData);
$decrypted = Crypt::decryptString($encrypted);

// ✅ Good - Hash for one-way data
use Illuminate\Support\Facades\Hash;
$hash = Hash::make($password);
```

---

## 12. Security Headers

### Essential Headers
```php
// ✅ Implement security headers middleware
public function handle($request, Closure $next)
{
    $response = $next($request);

    return $response->withHeaders([
        'X-Content-Type-Options' => 'nosniff',
        'X-Frame-Options' => 'SAMEORIGIN',
        'X-XSS-Protection' => '1; mode=block',
        'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',
        'Content-Security-Policy' => "default-src 'self'; script-src 'self' 'unsafe-inline'",
        'Referrer-Policy' => 'strict-origin-when-cross-origin',
        'Permissions-Policy' => 'geolocation=(), microphone=(), camera=()',
    ]);
}
```

---

## 13. Dependency Security

### Keep Dependencies Updated
- ✅ Regularly run `composer audit`
- ✅ Update packages with security patches
- ✅ Review package source code for critical dependencies
- ❌ Don't use abandoned packages

**Commands:**
```bash
# Check for security vulnerabilities
composer audit

# Update packages
composer update

# Check outdated packages
composer outdated
```

---

## 14. Common Vulnerabilities Checklist

### OWASP Top 10
- [ ] A01: Broken Access Control - ✅ Use policies and middleware
- [ ] A02: Cryptographic Failures - ✅ Encrypt sensitive data
- [ ] A03: Injection - ✅ Use Eloquent/Query Builder
- [ ] A04: Insecure Design - ✅ Follow security by design
- [ ] A05: Security Misconfiguration - ✅ Secure defaults, disable debug in prod
- [ ] A06: Vulnerable Components - ✅ Keep dependencies updated
- [ ] A07: Authentication Failures - ✅ Strong password policy, MFA
- [ ] A08: Software/Data Integrity - ✅ Verify integrity of updates
- [ ] A09: Logging/Monitoring Failures - ✅ Log security events
- [ ] A10: Server-Side Request Forgery - ✅ Validate URLs, whitelist domains

---

## 15. Security Testing

### Regular Security Audits
```php
// ✅ Write security tests
public function test_user_cannot_update_other_user_post()
{
    $user1 = User::factory()->create();
    $user2 = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $user1->id]);

    $response = $this->actingAs($user2)
        ->putJson("/api/posts/{$post->id}", ['title' => 'Hacked']);

    $response->assertForbidden();
}

public function test_password_must_be_hashed()
{
    $user = User::factory()->create(['password' => 'password123']);

    $this->assertNotEquals('password123', $user->password);
    $this->assertTrue(Hash::check('password123', $user->password));
}
```

---

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Laravel Security Best Practices](https://laravel.com/docs/security)
- [PHP Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/PHP_Configuration_Cheat_Sheet.html)
- [Sanctum Documentation](https://laravel.com/docs/sanctum)
- [Laravel Security Checklist](https://github.com/lostlink/laravel-security-checklist)

---

## Emergency Response

### If Security Breach Detected:
1. **Isolate**: Take affected systems offline
2. **Assess**: Determine scope and impact
3. **Contain**: Patch vulnerability immediately
4. **Notify**: Inform affected users and authorities if required
5. **Review**: Conduct post-mortem and improve security
6. **Monitor**: Increase monitoring for follow-up attacks
