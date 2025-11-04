# Rule: Testing Standards

## Intent
Define testing standards and practices for unit, component, and E2E tests.

## Scope
Applies to all test files using Vitest, Vue Test Utils, and Playwright.

---

## 1. Test File Naming

```
composables/useAuth.ts       → composables/useAuth.test.ts
components/UserCard.vue      → components/UserCard.test.ts
utils/formatDate.ts          → utils/formatDate.test.ts
```

---

## 2. Test Structure

```typescript
describe('useAuth', () => {
  beforeEach(() => {
    // Setup
  })

  afterEach(() => {
    // Cleanup
  })

  it('should login successfully', async () => {
    // Arrange
    const credentials = { email: 'test@example.com', password: 'password' }

    // Act
    const { login } = useAuth()
    await login(credentials)

    // Assert
    expect(isAuthenticated.value).toBe(true)
  })
})
```

---

## 3. Test Coverage Goals

- **Composables**: 90%+
- **Utils**: 100%
- **Components**: 70%+
- **E2E**: Critical user flows

---

## References

- [Vitest Documentation](https://vitest.dev/)
- [Vue Test Utils](https://test-utils.vuejs.org/)
- [Playwright](https://playwright.dev/)
