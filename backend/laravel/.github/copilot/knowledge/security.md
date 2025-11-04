# Security Standards & Best Practices

This document describes the security policies, standards, and best practices for the Laravel DevKit project.

---

## Table of Contents

1. [Security Principles](#security-principles)
2. [Authentication](#authentication)
3. [Authorization](#authorization)
4. [Input Validation](#input-validation)
5. [XSS Protection](#xss-protection)
6. [CSRF Protection](#csrf-protection)
7. [SQL Injection Prevention](#sql-injection-prevention)
8. [Password Security](#password-security)
9. [Session Security](#session-security)
10. [API Security](#api-security)
11. [File Upload Security](#file-upload-security)
12. [Security Headers](#security-headers)

---

## Security Principles

### Defense in Depth
Multiple layers of security controls.

### Principle of Least Privilege
Grant minimum necessary permissions.

### Fail Securely
Default to denying access.

### Never Trust User Input
Validate and sanitize everything.

### Security by Design
Consider security from the start.

---

## Authentication

### Password Requirements

```php
// app/Http/Requests/RegisterRequest.php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => [
                'required',
                'confirmed',
                Password::min(12)                  // Minimum 12 characters
                    ->letters()                    // Must contain letters
                    ->mixedCase()                  // Must contain uppercase and lowercase
                    ->numbers()                    // Must contain numbers
                    ->symbols()                    // Must contain symbols
                    ->uncompromised(),            // Check against pwned passwords
            ],
        ];
    }
}
```

### Login Throttling

```php
// config/auth.php
'throttle' => [
    'max_attempts' => 5,
    'decay_minutes' => 5,
],

// routes/web.php
Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle:login');
```

### Two-Factor Authentication

```php
namespace App\Services;

use PragmaRX\Google2FA\Google2FA;

class TwoFactorService
{
    private Google2FA $google2fa;

    public function __construct()
    {
        $this->google2fa = new Google2FA();
    }

    public function generateSecretKey(): string
    {
        return $this->google2fa->generateSecretKey();
    }

    public function getQRCode(User $user, string $secret): string
    {
        return $this->google2fa->getQRCodeUrl(
            config('app.name'),
            $user->email,
            $secret
        );
    }

    public function verify(string $secret, string $code): bool
    {
        return $this->google2fa->verifyKey($secret, $code);
    }
}
```

### Session Management

```php
// app/Http/Controllers/Auth/LoginController.php
public function login(LoginRequest $request)
{
    $credentials = $request->validated();

    if (!Auth::attempt($credentials, $request->boolean('remember'))) {
        return back()->withErrors([
            'email' => 'Invalid credentials.',
        ])->onlyInput('email');
    }

    // Regenerate session to prevent session fixation
    $request->session()->regenerate();

    // Log the login
    activity()
        ->causedBy(Auth::user())
        ->log('User logged in');

    return redirect()->intended(route('dashboard'));
}

public function logout(Request $request)
{
    Auth::logout();

    // Invalidate session
    $request->session()->invalidate();

    // Regenerate CSRF token
    $request->session()->regenerateToken();

    return redirect()->route('login');
}
```

### Remember Me Security

```php
// config/session.php
'secure' => env('SESSION_SECURE_COOKIE', true),      // HTTPS only
'http_only' => true,                                 // Prevent JavaScript access
'same_site' => 'strict',                             // CSRF protection
'lifetime' => 120,                                   // 2 hours
```

---

## Authorization

### Use Policies

```php
// app/Policies/ProjectPolicy.php
namespace App\Policies;

use App\Models\User;
use App\Models\Project;

class ProjectPolicy
{
    /**
     * Determine if the user can view the project.
     */
    public function view(User $user, Project $project): bool
    {
        return $user->id === $project->user_id
            || $user->isAdmin()
            || $project->users->contains($user);
    }

    /**
     * Determine if the user can update the project.
     */
    public function update(User $user, Project $project): bool
    {
        return $user->id === $project->user_id || $user->isAdmin();
    }

    /**
     * Determine if the user can delete the project.
     */
    public function delete(User $user, Project $project): bool
    {
        // Only owner can delete (not even admin)
        return $user->id === $project->user_id;
    }

    /**
     * Determine if the user can deploy the project.
     */
    public function deploy(User $user, Project $project): bool
    {
        return ($user->id === $project->user_id || $user->isAdmin())
            && $project->status === 'active';
    }
}
```

### Authorize in Controllers

```php
namespace App\Http\Controllers;

use App\Models\Project;

class ProjectController extends Controller
{
    public function show(Project $project)
    {
        $this->authorize('view', $project);

        return view('projects.show', compact('project'));
    }

    public function update(UpdateProjectRequest $request, Project $project)
    {
        $this->authorize('update', $project);

        $project->update($request->validated());

        return redirect()->route('projects.show', $project);
    }

    public function destroy(Project $project)
    {
        $this->authorize('delete', $project);

        $project->delete();

        return redirect()->route('projects.index');
    }
}
```

### Authorize in Blade Templates

```blade
@can('update', $project)
    <a href="{{ route('projects.edit', $project) }}">Edit</a>
@endcan

@can('delete', $project)
    <form method="POST" action="{{ route('projects.destroy', $project) }}">
        @csrf
        @method('DELETE')
        <button type="submit">Delete</button>
    </form>
@endcan
```

### Role-Based Access Control (RBAC)

```php
// app/Models/User.php
class User extends Authenticatable
{
    public function hasRole(string $role): bool
    {
        return $this->role === $role;
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isDeveloper(): bool
    {
        return $this->role === 'developer';
    }

    public function hasPermission(string $permission): bool
    {
        return $this->permissions->contains('name', $permission);
    }
}

// app/Http/Middleware/EnsureUserHasRole.php
class EnsureUserHasRole
{
    public function handle(Request $request, Closure $next, string $role)
    {
        if (!$request->user() || !$request->user()->hasRole($role)) {
            abort(403, 'Unauthorized');
        }

        return $next($request);
    }
}

// routes/web.php
Route::middleware(['auth', 'role:admin'])->group(function () {
    Route::get('/admin', [AdminController::class, 'index']);
});
```

---

## Input Validation

### Always Validate User Input

```php
// app/Http/Requests/CreateProjectRequest.php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateProjectRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255|regex:/^[a-zA-Z0-9\s\-_]+$/',
            'description' => 'nullable|string|max:5000',
            'status' => 'required|in:draft,active,archived',
            'url' => 'nullable|url|max:255',
            'repository' => 'nullable|url|regex:/^https:\/\/(github|gitlab)\.com/',
            'tags' => 'nullable|array|max:10',
            'tags.*' => 'string|max:50|regex:/^[a-zA-Z0-9\-]+$/',
            'settings' => 'nullable|array',
            'settings.*.key' => 'required_with:settings|string|max:100',
            'settings.*.value' => 'required_with:settings|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'name.regex' => 'Project name can only contain letters, numbers, spaces, hyphens, and underscores.',
            'repository.regex' => 'Repository must be a GitHub or GitLab URL.',
            'tags.*.regex' => 'Tags can only contain letters, numbers, and hyphens.',
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'name' => strip_tags($this->name),
            'description' => strip_tags($this->description),
        ]);
    }
}
```

### Sanitize Input

```php
// app/Services/InputSanitizer.php
namespace App\Services;

class InputSanitizer
{
    public static function sanitize(string $input): string
    {
        // Remove HTML tags
        $input = strip_tags($input);

        // Remove null bytes
        $input = str_replace(chr(0), '', $input);

        // Trim whitespace
        $input = trim($input);

        return $input;
    }

    public static function sanitizeHtml(string $html): string
    {
        // Use HTMLPurifier or similar
        $config = HTMLPurifier_Config::createDefault();
        $purifier = new HTMLPurifier($config);

        return $purifier->purify($html);
    }
}
```

### Validate File Uploads

```php
public function rules(): array
{
    return [
        'avatar' => [
            'required',
            'file',
            'mimes:jpg,jpeg,png',
            'max:2048',              // 2MB max
            'dimensions:min_width=100,min_height=100,max_width=2000,max_height=2000',
        ],
        'document' => [
            'required',
            'file',
            'mimes:pdf,doc,docx',
            'max:10240',             // 10MB max
        ],
    ];
}
```

---

## XSS Protection

### Blade Escaping (Default)

```blade
{{-- Automatically escaped --}}
<div>{{ $user->name }}</div>

{{-- Raw output (DANGEROUS - avoid unless necessary) --}}
<div>{!! $trustedHtml !!}</div>

{{-- Safe: Use for trusted, sanitized content only --}}
<div>{!! Purifier::clean($userContent) !!}</div>
```

### Content Security Policy (CSP)

```php
// app/Http/Middleware/AddSecurityHeaders.php
namespace App\Http\Middleware;

class AddSecurityHeaders
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        $response->headers->set(
            'Content-Security-Policy',
            "default-src 'self'; " .
            "script-src 'self' 'unsafe-inline' https://cdn.example.com; " .
            "style-src 'self' 'unsafe-inline'; " .
            "img-src 'self' data: https:; " .
            "font-src 'self'; " .
            "connect-src 'self'; " .
            "frame-ancestors 'none';"
        );

        return $response;
    }
}
```

### Sanitize Rich Text Content

```php
use HTMLPurifier;
use HTMLPurifier_Config;

class ContentService
{
    public function sanitizeRichText(string $content): string
    {
        $config = HTMLPurifier_Config::createDefault();
        $config->set('HTML.Allowed', 'p,b,strong,i,em,u,a[href],ul,ol,li,br');
        $config->set('AutoFormat.AutoParagraph', true);
        $config->set('AutoFormat.RemoveEmpty', true);

        $purifier = new HTMLPurifier($config);

        return $purifier->purify($content);
    }
}
```

---

## CSRF Protection

### Enabled by Default

Laravel automatically protects all POST, PUT, PATCH, DELETE requests.

### Add CSRF Token to Forms

```blade
<form method="POST" action="{{ route('projects.store') }}">
    @csrf
    {{-- Form fields --}}
    <button type="submit">Submit</button>
</form>

{{-- For PUT/PATCH/DELETE --}}
<form method="POST" action="{{ route('projects.update', $project) }}">
    @csrf
    @method('PUT')
    {{-- Form fields --}}
</form>
```

### AJAX Requests

```javascript
// Include in layout
<meta name="csrf-token" content="{{ csrf_token() }}">

// Axios (automatic)
window.axios.defaults.headers.common['X-CSRF-TOKEN'] =
    document.querySelector('meta[name="csrf-token"]').getAttribute('content');

// Fetch API
fetch('/api/endpoint', {
    method: 'POST',
    headers: {
        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
});
```

### Exclude Routes from CSRF Protection

```php
// app/Http/Middleware/VerifyCsrfToken.php
protected $except = [
    'webhook/*',
    'api/*',  // If using API tokens
];
```

---

## SQL Injection Prevention

### Use Query Builder (Safe)

```php
// ✅ Safe: Parameterized query
$users = DB::table('users')
    ->where('email', $email)
    ->where('status', 'active')
    ->get();
```

### Use Eloquent (Safe)

```php
// ✅ Safe: Eloquent ORM
$user = User::where('email', $email)->first();
$projects = Project::where('user_id', $userId)->get();
```

### Parameter Binding

```php
// ✅ Safe: Named bindings
$users = DB::select('SELECT * FROM users WHERE email = :email', [
    'email' => $email,
]);

// ✅ Safe: Positional bindings
$users = DB::select('SELECT * FROM users WHERE email = ?', [$email]);
```

### Dangerous Practices to Avoid

```php
// ❌ DANGEROUS: Never concatenate user input
$users = DB::select("SELECT * FROM users WHERE email = '$email'");

// ❌ DANGEROUS: Raw queries with user input
$users = DB::raw("SELECT * FROM users WHERE name LIKE '%$name%'");

// ✅ Safe alternative:
$users = User::where('name', 'like', "%{$name}%")->get();
```

### WhereRaw with Bindings

```php
// ✅ Safe: Use bindings with whereRaw
$projects = Project::whereRaw('YEAR(created_at) = ?', [2025])->get();

// ❌ DANGEROUS: Direct concatenation
$projects = Project::whereRaw("YEAR(created_at) = $year")->get();
```

---

## Password Security

### Hashing Passwords

```php
use Illuminate\Support\Facades\Hash;

// Hash password
$hashedPassword = Hash::make('password');

// Verify password
if (Hash::check('password', $hashedPassword)) {
    // Password is correct
}

// Check if rehash is needed (bcrypt cost changed)
if (Hash::needsRehash($hashedPassword)) {
    $hashedPassword = Hash::make('password');
}
```

### Password Reset

```php
// app/Http/Controllers/Auth/PasswordResetController.php
use Illuminate\Support\Facades\Password;

public function sendResetLink(Request $request)
{
    $request->validate(['email' => 'required|email']);

    $status = Password::sendResetLink(
        $request->only('email')
    );

    return $status === Password::RESET_LINK_SENT
        ? back()->with('status', __($status))
        : back()->withErrors(['email' => __($status)]);
}

public function reset(Request $request)
{
    $request->validate([
        'token' => 'required',
        'email' => 'required|email',
        'password' => ['required', 'confirmed', Password::min(12)->uncompromised()],
    ]);

    $status = Password::reset(
        $request->only('email', 'password', 'password_confirmation', 'token'),
        function ($user, $password) {
            $user->forceFill([
                'password' => Hash::make($password),
                'remember_token' => Str::random(60),
            ])->save();

            event(new PasswordReset($user));
        }
    );

    return $status === Password::PASSWORD_RESET
        ? redirect()->route('login')->with('status', __($status))
        : back()->withErrors(['email' => [__($status)]]);
}
```

### Password History

```php
// Prevent password reuse
class User extends Authenticatable
{
    public function passwordHistories(): HasMany
    {
        return $this->hasMany(PasswordHistory::class);
    }

    public function updatePassword(string $newPassword): void
    {
        // Check against last 5 passwords
        $recentPasswords = $this->passwordHistories()
            ->latest()
            ->take(5)
            ->get();

        foreach ($recentPasswords as $history) {
            if (Hash::check($newPassword, $history->password)) {
                throw new \Exception('Cannot reuse recent passwords');
            }
        }

        // Save new password
        $this->update(['password' => Hash::make($newPassword)]);

        // Store in history
        $this->passwordHistories()->create([
            'password' => Hash::make($newPassword),
        ]);
    }
}
```

---

## Session Security

### Configuration

```php
// config/session.php
return [
    'driver' => env('SESSION_DRIVER', 'redis'),      // Use redis/database, not file
    'lifetime' => 120,                                // 2 hours
    'expire_on_close' => false,
    'encrypt' => true,                                // Encrypt session data
    'secure' => env('SESSION_SECURE_COOKIE', true),   // HTTPS only
    'http_only' => true,                              // Prevent JavaScript access
    'same_site' => 'strict',                          // CSRF protection
];
```

### Session Fixation Prevention

```php
// Regenerate session on login
Auth::login($user);
$request->session()->regenerate();

// Regenerate session on privilege escalation
$user->update(['role' => 'admin']);
$request->session()->regenerate();
```

### Concurrent Session Management

```php
// Limit concurrent sessions
class LoginController extends Controller
{
    public function login(Request $request)
    {
        // ... authentication logic

        // Delete other sessions for this user
        DB::table('sessions')
            ->where('user_id', $user->id)
            ->where('id', '!=', $request->session()->getId())
            ->delete();

        return redirect()->intended();
    }
}
```

---

## API Security

### API Token Authentication

```php
// Generate token
$token = $user->createToken('api-token', ['read', 'write'])->plainTextToken;

// Verify token
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $request) => $request->user());
});
```

### Rate Limiting

```php
// app/Providers/RouteServiceProvider.php
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)
        ->by($request->user()?->id ?: $request->ip())
        ->response(function () {
            return response()->json([
                'error' => [
                    'code' => 'RATE_LIMIT_EXCEEDED',
                    'message' => 'Too many requests.',
                ],
            ], 429);
        });
});
```

### API Key Validation

```php
// app/Http/Middleware/ValidateApiKey.php
class ValidateApiKey
{
    public function handle(Request $request, Closure $next)
    {
        $apiKey = $request->header('X-API-Key');

        if (!$apiKey || !$this->isValidApiKey($apiKey)) {
            return response()->json([
                'error' => [
                    'code' => 'INVALID_API_KEY',
                    'message' => 'Invalid or missing API key.',
                ],
            ], 401);
        }

        return $next($request);
    }

    private function isValidApiKey(string $key): bool
    {
        return ApiKey::where('key', hash('sha256', $key))
            ->where('expires_at', '>', now())
            ->where('is_active', true)
            ->exists();
    }
}
```

---

## File Upload Security

### Validate File Types

```php
public function rules(): array
{
    return [
        'file' => [
            'required',
            'file',
            'mimes:jpg,jpeg,png,pdf',           // Whitelist allowed types
            'max:5120',                         // 5MB max
        ],
    ];
}
```

### Store Files Securely

```php
public function upload(Request $request)
{
    $request->validate([
        'file' => 'required|file|mimes:jpg,jpeg,png|max:2048',
    ]);

    // Generate unique filename
    $filename = Str::uuid() . '.' . $request->file('file')->extension();

    // Store in private disk
    $path = $request->file('file')->storeAs(
        'uploads',
        $filename,
        'private'  // Not publicly accessible
    );

    // Save to database
    $upload = Upload::create([
        'user_id' => auth()->id(),
        'filename' => $filename,
        'original_name' => $request->file('file')->getClientOriginalName(),
        'path' => $path,
        'mime_type' => $request->file('file')->getMimeType(),
        'size' => $request->file('file')->getSize(),
    ]);

    return response()->json(['id' => $upload->id]);
}
```

### Serve Files with Authorization

```php
public function download(Upload $upload)
{
    // Check authorization
    $this->authorize('download', $upload);

    // Serve file
    return Storage::disk('private')->download(
        $upload->path,
        $upload->original_name
    );
}
```

### Scan Files for Malware

```php
use Illuminate\Support\Facades\Validator;
use Symfony\Component\Process\Process;

Validator::extend('virus_free', function ($attribute, $value, $parameters, $validator) {
    $filePath = $value->getRealPath();

    // Run ClamAV scan
    $process = new Process(['clamscan', '--no-summary', $filePath]);
    $process->run();

    return $process->getExitCode() === 0;
});

// In form request
public function rules(): array
{
    return [
        'file' => 'required|file|mimes:pdf,doc,docx|max:10240|virus_free',
    ];
}
```

---

## Security Headers

### Add Security Headers Middleware

```php
// app/Http/Middleware/AddSecurityHeaders.php
namespace App\Http\Middleware;

class AddSecurityHeaders
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        // Prevent MIME type sniffing
        $response->headers->set('X-Content-Type-Options', 'nosniff');

        // Enable XSS filter
        $response->headers->set('X-XSS-Protection', '1; mode=block');

        // Prevent clickjacking
        $response->headers->set('X-Frame-Options', 'DENY');

        // Force HTTPS
        $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');

        // Content Security Policy
        $response->headers->set('Content-Security-Policy',
            "default-src 'self'; " .
            "script-src 'self' 'unsafe-inline' 'unsafe-eval'; " .
            "style-src 'self' 'unsafe-inline'; " .
            "img-src 'self' data: https:; " .
            "font-src 'self'; " .
            "connect-src 'self'; " .
            "frame-ancestors 'none';"
        );

        // Referrer Policy
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

        // Permissions Policy
        $response->headers->set('Permissions-Policy',
            'geolocation=(), microphone=(), camera=()'
        );

        return $response;
    }
}
```

### Register Middleware

```php
// app/Http/Kernel.php
protected $middlewareGroups = [
    'web' => [
        // ...
        \App\Http\Middleware\AddSecurityHeaders::class,
    ],
];
```

---

## Security Checklist

- [ ] All passwords hashed with bcrypt/argon2
- [ ] Password requirements enforced (12+ chars, mixed case, numbers, symbols)
- [ ] Login throttling enabled (5 attempts = 5 min lockout)
- [ ] CSRF protection enabled on all forms
- [ ] SQL injection prevented (use Query Builder/Eloquent)
- [ ] XSS protection (escape all output)
- [ ] Authorization checks on all sensitive operations
- [ ] Input validation on all user inputs
- [ ] File upload validation (type, size, mime)
- [ ] Files stored in non-public directories
- [ ] Security headers configured
- [ ] HTTPS enforced in production
- [ ] Session security configured (secure, httponly, samesite)
- [ ] API rate limiting enabled
- [ ] API authentication required
- [ ] Sensitive data encrypted in database
- [ ] Error messages don't reveal sensitive info
- [ ] Dependencies regularly updated
- [ ] Security audits performed
- [ ] Logs monitored for suspicious activity
