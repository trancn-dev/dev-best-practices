# Prompt: Refactoring Suggestions

## Purpose
Get actionable suggestions to improve code quality, maintainability, and performance through refactoring.

## When to Use
- Code smells detected
- Technical debt reduction
- Performance optimization
- Improving testability
- Following SOLID principles
- Modernizing legacy code

---

## Prompt Template

```
Please analyze this code and provide refactoring suggestions:

[CODE_BLOCK]

Focus on:
1. **Code smells**: Identify anti-patterns and bad practices
2. **SOLID principles**: How can we improve adherence?
3. **Performance**: Are there performance issues?
4. **Maintainability**: Can we make it easier to maintain?
5. **Testability**: Is it easy to test?
6. **Laravel best practices**: Any violations?
7. **Security**: Any security concerns?

For each suggestion:
- Explain the problem
- Show the improved code
- Explain why it's better
- Estimate complexity (low/medium/high)
```

---

## Example Usage

### Input:
```
Please analyze this code and provide refactoring suggestions:

class UserController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8',
        ]);

        $user = new User();
        $user->name = $request->name;
        $user->email = $request->email;
        $user->password = Hash::make($request->password);
        $user->save();

        Mail::to($user->email)->send(new WelcomeEmail($user));

        Setting::create([
            'user_id' => $user->id,
            'theme' => 'light',
            'notifications' => true,
        ]);

        Log::info('User registered: ' . $user->email);

        return response()->json($user, 201);
    }
}
```

### Expected Output:

**Issue 1: Fat Controller (High Priority)**
❌ **Problem**: Controller contains business logic, violating Single Responsibility Principle

✅ **Solution**: Extract to Action class
```php
class CreateUserAction
{
    public function __construct(
        private readonly UserRepository $users,
        private readonly NotificationService $notifications
    ) {}

    public function execute(CreateUserData $data): User
    {
        $user = $this->users->create([
            'name' => $data->name,
            'email' => $data->email,
            'password' => Hash::make($data->password),
        ]);

        $this->notifications->sendWelcomeEmail($user);

        event(new UserCreated($user));

        return $user;
    }
}

class UserController extends Controller
{
    public function __construct(
        private readonly CreateUserAction $createUserAction
    ) {}

    public function store(CreateUserRequest $request): JsonResponse
    {
        $user = $this->createUserAction->execute(
            CreateUserData::fromRequest($request)
        );

        return new UserResource($user);
    }
}
```

**Why it's better:**
- Controller is thin (< 10 lines)
- Business logic is testable in isolation
- Follows Single Responsibility Principle
- Easier to reuse logic elsewhere
- Better separation of concerns

**Complexity**: Medium

---

**Issue 2: No FormRequest Validation (Medium Priority)**
❌ **Problem**: Validation in controller, no authorization check

✅ **Solution**: Use FormRequest
```php
class CreateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Add authorization logic if needed
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Vui lòng nhập tên.',
            'email.unique' => 'Email này đã được sử dụng.',
            'password.min' => 'Mật khẩu phải có ít nhất 8 ký tự.',
        ];
    }
}
```

**Why it's better:**
- Validation rules are reusable
- Custom error messages
- Authorization logic separated
- Cleaner controller code

**Complexity**: Low

---

**Issue 3: Synchronous Email Sending (High Priority)**
❌ **Problem**: Blocks HTTP response while sending email

✅ **Solution**: Queue the email
```php
Mail::to($user)->queue(new WelcomeEmail($user));
```

**Why it's better:**
- Fast HTTP response
- Better user experience
- Email failures don't affect registration
- Scalable approach

**Complexity**: Low

---

**Issue 4: No Database Transaction (High Priority)**
❌ **Problem**: If setting creation fails, user is already created

✅ **Solution**: Wrap in transaction
```php
DB::transaction(function () use ($data) {
    $user = $this->users->create($data);
    Setting::create(['user_id' => $user->id, ...]);
    return $user;
});
```

**Why it's better:**
- Data consistency guaranteed
- Automatic rollback on failure
- Prevents orphaned records

**Complexity**: Low

---

**Issue 5: Using Model Directly (Medium Priority)**
❌ **Problem**: Direct use of `Setting` model in controller/action

✅ **Solution**: Use Repository or Service
```php
class UserService
{
    public function createDefaultSettings(User $user): void
    {
        $this->settings->create([
            'user_id' => $user->id,
            'theme' => 'light',
            'notifications' => true,
        ]);
    }
}
```

**Why it's better:**
- Abstracted data access
- Easier to test with mocks
- Centralized settings logic

**Complexity**: Low

---

**Issue 6: No API Resource (Low Priority)**
❌ **Problem**: Returns raw model data

✅ **Solution**: Use API Resource
```php
return new UserResource($user);

// UserResource.php
class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
```

**Why it's better:**
- Control over exposed data
- Consistent API response format
- Hide sensitive fields
- Transformation logic separated

**Complexity**: Low

---

**Issue 7: Event-Driven Side Effects (Recommended)**
💡 **Enhancement**: Use events for setting creation

```php
// CreateUserAction
event(new UserCreated($user));

// Listener
class CreateDefaultSettings
{
    public function handle(UserCreated $event): void
    {
        Setting::create([
            'user_id' => $event->user->id,
            'theme' => 'light',
            'notifications' => true,
        ]);
    }
}
```

**Why it's better:**
- Decoupled components
- Easy to add more side effects
- Testable in isolation
- Follows Open/Closed Principle

**Complexity**: Medium

---

## Summary

**Critical Issues** (Fix Immediately):
1. Fat controller with business logic
2. Synchronous email sending
3. No database transaction

**Important Issues** (Fix Soon):
1. Missing FormRequest validation
2. Direct model usage

**Enhancements** (Nice to Have):
1. API Resource for responses
2. Event-driven architecture

**Estimated Total Effort**: 4-6 hours

---

## Variations

### Focus on Performance
```
Analyze this code for performance issues. What bottlenecks exist and how can we optimize?
```

### Focus on Security
```
Review this code for security vulnerabilities. What are the risks and how to fix them?
```

### Focus on Testing
```
How can we refactor this code to make it more testable? Show the refactored code and example tests.
```

### Focus on Specific Pattern
```
Refactor this code to follow the Repository pattern / Service pattern / Action pattern.
```

---

## Best Practices

1. **Prioritize issues**: Focus on critical issues first
2. **One step at a time**: Don't refactor everything at once
3. **Write tests first**: Ensure existing behavior is tested
4. **Small commits**: Commit each refactoring separately
5. **Review changes**: Get peer review before merging

---

## Related Prompts

- `code-explanation.md` - Understand code before refactoring
- `code-review.md` - Comprehensive code review
- `testing-strategy.md` - Test refactored code
- `performance-optimization.md` - Focus on performance
