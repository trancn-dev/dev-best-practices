---
type: command
name: writing-test
version: 2.0
scope: project
integration:
  - nuxt
  - vue
  - vitest
  - playwright
---

# Command: Writing Test

## Mục tiêu
Lệnh `writing-test` được sử dụng để **viết test cases** cho feature mới hoặc code hiện có.

Mục tiêu chính:
- Đảm bảo test coverage >= 70%.
- Test all critical paths, edge cases, và error scenarios.
- Tạo test có thể maintain và mở rộng.
- Document test scenarios rõ ràng.

---

## Quy trình viết test

### 1. Gather Context

**Câu hỏi cần trả lời:**

#### A. Feature Information
- Feature name và branch?
- Summary của thay đổi (link tới design & requirements docs)?
- Components/composables/pages affected?

#### B. Existing Test Suites
- Unit tests hiện có?
- Component tests hiện có?
- E2E tests hiện có?
- Any flaky hoặc slow tests cần tránh?

#### C. Coverage Goals
- Coverage target: [X]%
- Priority areas cần test?
- Known edge cases?

---

### 2. Unit Tests (Composables & Utilities)

#### A. Identify Test Scenarios

```markdown
## Unit Test Plan: [useAuth]

### Happy Path Scenarios
1. Login success: When valid credentials, expect user logged in
2. Logout: When logout called, expect user cleared

### Edge Cases
1. Token expired: When token expired, expect auto logout
2. Network error: When API fails, expect error state

### Error Handling
1. Invalid credentials: Expect error message
2. API timeout: Expect timeout error
```

#### B. Write Unit Tests (Vitest)

```typescript
// composables/useAuth.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useAuth } from './useAuth'

describe('useAuth', () => {
  beforeEach(() => {
    // Reset state before each test
    vi.clearAllMocks()
  })

  it('should login successfully with valid credentials', async () => {
    const { login, user, isAuthenticated } = useAuth()

    await login('user@example.com', 'password123')

    expect(isAuthenticated.value).toBe(true)
    expect(user.value).toMatchObject({
      email: 'user@example.com'
    })
  })

  it('should handle login failure', async () => {
    const { login, error } = useAuth()

    await login('invalid@example.com', 'wrong')

    expect(error.value).toBeTruthy()
  })

  it('should logout and clear user data', async () => {
    const { login, logout, user, isAuthenticated } = useAuth()

    await login('user@example.com', 'password123')
    await logout()

    expect(isAuthenticated.value).toBe(false)
    expect(user.value).toBeNull()
  })
})
```

---

### 3. Component Tests (Vue Test Utils + Vitest)

#### A. Component Test Plan

```markdown
## Component Test Plan: UserProfile.vue

### Rendering Tests
1. Renders user info correctly
2. Shows loading state
3. Shows error state

### Interaction Tests
1. Edit button enables edit mode
2. Save button submits changes
3. Cancel button resets form

### Props/Events Tests
1. Accepts userId prop
2. Emits update:profile on save
3. Emits cancel on cancel click
```

#### B. Write Component Tests

```typescript
// components/UserProfile.test.ts
import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import UserProfile from './UserProfile.vue'

describe('UserProfile', () => {
  it('renders user information', async () => {
    const wrapper = mount(UserProfile, {
      props: {
        userId: 1
      }
    })

    await wrapper.vm.$nextTick()

    expect(wrapper.find('[data-test="user-name"]').text()).toBe('John Doe')
    expect(wrapper.find('[data-test="user-email"]').text()).toBe('john@example.com')
  })

  it('enables edit mode when edit button clicked', async () => {
    const wrapper = mount(UserProfile, {
      props: {
        userId: 1,
        editable: true
      }
    })

    await wrapper.find('[data-test="edit-button"]').trigger('click')

    expect(wrapper.find('[data-test="name-input"]').exists()).toBe(true)
  })

  it('emits update:profile when form submitted', async () => {
    const wrapper = mount(UserProfile, {
      props: {
        userId: 1,
        editable: true
      }
    })

    await wrapper.find('[data-test="edit-button"]').trigger('click')
    await wrapper.find('[data-test="name-input"]').setValue('Jane Doe')
    await wrapper.find('[data-test="save-button"]').trigger('click')

    expect(wrapper.emitted('update:profile')).toBeTruthy()
    expect(wrapper.emitted('update:profile')?.[0]).toEqual([
      expect.objectContaining({ name: 'Jane Doe' })
    ])
  })

  it('shows loading state while fetching', () => {
    const wrapper = mount(UserProfile, {
      props: {
        userId: 1
      },
      global: {
        stubs: {
          // Mock composables if needed
        }
      }
    })

    expect(wrapper.find('[data-test="loading"]').exists()).toBe(true)
  })

  it('shows error message on fetch failure', async () => {
    const wrapper = mount(UserProfile, {
      props: {
        userId: 999 // Non-existent user
      }
    })

    await wrapper.vm.$nextTick()

    expect(wrapper.find('[data-test="error"]').exists()).toBe(true)
  })
})
```

---

### 4. E2E Tests (Playwright)

#### A. E2E Test Scenarios

```markdown
## E2E Test Plan: User Authentication Flow

### User Stories
1. User can login with valid credentials
2. User can view profile after login
3. User can edit profile
4. User can logout

### Critical Paths
1. Login → Dashboard → Profile → Edit → Save → Logout
2. Login with invalid credentials → Show error
3. Access protected page without login → Redirect to login
```

#### B. Write E2E Tests

```typescript
// tests/e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test.describe('User Authentication', () => {
  test('user can login and view profile', async ({ page }) => {
    await page.goto('/login')

    // Fill login form
    await page.fill('[data-test="email-input"]', 'user@example.com')
    await page.fill('[data-test="password-input"]', 'password123')
    await page.click('[data-test="login-button"]')

    // Should redirect to dashboard
    await expect(page).toHaveURL('/dashboard')

    // Navigate to profile
    await page.click('[data-test="profile-link"]')
    await expect(page).toHaveURL('/profile')

    // Check profile info displayed
    await expect(page.locator('[data-test="user-name"]')).toContainText('John Doe')
  })

  test('shows error with invalid credentials', async ({ page }) => {
    await page.goto('/login')

    await page.fill('[data-test="email-input"]', 'invalid@example.com')
    await page.fill('[data-test="password-input"]', 'wrong')
    await page.click('[data-test="login-button"]')

    // Should show error message
    await expect(page.locator('[data-test="error-message"]')).toBeVisible()
    await expect(page.locator('[data-test="error-message"]')).toContainText('Invalid credentials')
  })

  test('redirects to login when accessing protected page', async ({ page }) => {
    await page.goto('/dashboard')

    // Should redirect to login
    await expect(page).toHaveURL('/login')
  })

  test('user can edit profile', async ({ page, context }) => {
    // Login first
    await page.goto('/login')
    await page.fill('[data-test="email-input"]', 'user@example.com')
    await page.fill('[data-test="password-input"]', 'password123')
    await page.click('[data-test="login-button"]')

    // Go to profile
    await page.goto('/profile')

    // Click edit
    await page.click('[data-test="edit-button"]')

    // Change name
    await page.fill('[data-test="name-input"]', 'Jane Doe')
    await page.click('[data-test="save-button"]')

    // Should show success message
    await expect(page.locator('[data-test="success-message"]')).toBeVisible()
    await expect(page.locator('[data-test="user-name"]')).toContainText('Jane Doe')
  })

  test('user can logout', async ({ page }) => {
    // Login first
    await page.goto('/login')
    await page.fill('[data-test="email-input"]', 'user@example.com')
    await page.fill('[data-test="password-input"]', 'password123')
    await page.click('[data-test="login-button"]')

    // Logout
    await page.click('[data-test="user-menu"]')
    await page.click('[data-test="logout-button"]')

    // Should redirect to login
    await expect(page).toHaveURL('/login')
  })
})
```

---

### 5. Test Best Practices

#### Do's ✅
- Write descriptive test names
- Test behavior, not implementation
- Use `data-test` attributes for selectors
- Mock external dependencies (API, localStorage, etc.)
- Test edge cases and error scenarios
- Keep tests independent and isolated
- Use `beforeEach` to reset state
- Aim for fast tests

#### Don'ts ❌
- Don't test framework internals
- Don't test third-party libraries
- Don't write flaky tests
- Don't over-mock (test real behavior when possible)
- Don't ignore failing tests
- Don't write tests that depend on each other

---

## Test Coverage Goals

- **Composables**: 90%+ (business logic critical)
- **Components**: 70%+ (UI behavior)
- **Utils/Helpers**: 100% (pure functions easy to test)
- **E2E**: Cover all critical user journeys

---

## Running Tests

```bash
# Run all tests
npm run test

# Run unit tests only
npm run test:unit

# Run component tests
npm run test:component

# Run E2E tests
npm run test:e2e

# Run with coverage
npm run test:coverage

# Watch mode
npm run test:watch
```

---

## CI Integration

Tests should run automatically on:
- Every push to feature branch
- Every pull request
- Before merge to main/develop

See `.github/workflows/ci.yml` for configuration.

---

## Troubleshooting

### Flaky Tests
- Add proper `await` for async operations
- Use `waitFor` for elements that appear after delay
- Mock timers if needed
- Increase timeout for slow operations

### Slow Tests
- Mock expensive operations (API, file I/O)
- Use `test.concurrent` for independent tests
- Optimize test setup/teardown

### Test Isolation Issues
- Reset mocks in `beforeEach`
- Clear state between tests
- Don't rely on test execution order
