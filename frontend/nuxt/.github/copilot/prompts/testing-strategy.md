# Prompt: Testing Strategy

## Purpose
Help create comprehensive testing strategy for features and components.

## When to Use
- Planning tests for new features
- Improving test coverage
- Need guidance on what to test

---

## Prompt Template

```
I need a testing strategy for [FEATURE/COMPONENT]:

**Feature**: [Name and description]
**Components Involved**:
- [Component 1]
- [Component 2]

**User Flows**:
1. [Flow 1]
2. [Flow 2]

**Edge Cases**:
- [Edge case 1]
- [Edge case 2]

Please provide:
1. Unit test scenarios
2. Component test scenarios
3. E2E test scenarios
4. Test priorities (critical vs nice-to-have)
```

---

## Example: Authentication Feature

**Input:**
```
I need a testing strategy for authentication:

**Feature**: User login/logout with JWT
**Components Involved**:
- LoginForm.vue
- useAuth composable
- auth middleware

**User Flows**:
1. Login with email/password
2. Stay logged in after page refresh
3. Logout
4. Access protected pages

**Edge Cases**:
- Invalid credentials
- Token expiration
- Network errors
```

**Expected Output:**

### Unit Tests (useAuth composable)
```typescript
describe('useAuth', () => {
  it('should login with valid credentials')
  it('should set user and token after login')
  it('should handle login failure')
  it('should logout and clear user data')
  it('should restore session from cookie')
  it('should handle expired token')
})
```

### Component Tests (LoginForm.vue)
```typescript
describe('LoginForm', () => {
  it('should render email and password inputs')
  it('should validate email format')
  it('should validate required fields')
  it('should emit submit event with credentials')
  it('should show error message on failure')
  it('should disable submit button while loading')
})
```

### E2E Tests
```typescript
test('user can login and access dashboard', async ({ page }) => {
  // Test implementation
})

test('user redirected to login when accessing protected page', async ({ page }) => {
  // Test implementation
})

test('user stays logged in after page refresh', async ({ page }) => {
  // Test implementation
})
```

### Priority
**Critical (P0)**:
- Login success flow
- Protected page access
- Token persistence

**Important (P1)**:
- Error handling
- Validation
- Logout

**Nice-to-have (P2)**:
- Loading states
- Edge cases

---

## References

- [Vitest](https://vitest.dev/)
- [Vue Test Utils](https://test-utils.vuejs.org/)
- [Playwright](https://playwright.dev/)
