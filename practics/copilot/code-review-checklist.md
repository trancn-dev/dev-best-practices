# Rule: Code Review Standards

## Intent
Enforce comprehensive code review practices to maintain code quality, catch bugs early, and ensure best practices. Copilot must assist reviewers with automated checks and suggestions.

## Scope
Applies to all code reviews, pull requests, and code quality assessments.

---

## 1. Pre-Review Checklist (Author Responsibilities)

### Before Submitting PR
- ✅ **MUST** pass all builds successfully
- ✅ **MUST** pass all tests (unit + integration)
- ✅ **MUST** have zero linting errors
- ✅ **MUST** be formatted according to project style guide
- ✅ **MUST** perform self-review
- ✅ **MUST** remove all debug code, console.log statements
- ✅ **MUST** have clear commit messages (conventional commits format)
- ✅ **MUST** update with latest base branch (no merge conflicts)
- ✅ **MUST** have reasonable scope (< 400 lines ideal, < 1000 max)
- ✅ **MUST** include comprehensive PR description

### PR Description Requirements

```markdown
## What
Brief description of changes

## Why
Business/technical reason for changes

## How
Implementation approach

## Testing
- Unit tests added/updated
- Integration tests added/updated
- Manual testing performed

## Related Issues
Closes #123
Fixes #456

## Screenshots (if UI changes)
[Attach here]
```

---

## 2. Code Quality Review

### Naming & Readability

**Rules:**
- ✅ **MUST** use meaningful, intention-revealing names
- ✅ **MUST** avoid magic numbers (use named constants)
- ✅ **MUST** follow consistent naming conventions
- ✅ **MUST** keep functions small (< 20 lines ideal)
- ❌ **MUST NOT** use generic names like `data`, `info`, `temp`
- ❌ **MUST NOT** use abbreviations unless widely known

**Check:**
```javascript
// ❌ BAD
const d = new Date();
function calc(a, b) { return a * b * 0.2; }
let x = getUserData();

// ✅ GOOD
const currentDate = new Date();
const TAX_RATE = 0.2;
function calculateTaxAmount(price, quantity) {
    return price * quantity * TAX_RATE;
}
const userProfile = getUserProfile();
```

### Function Design

**Rules:**
- ✅ **MUST** do ONE thing only (Single Responsibility)
- ✅ **MUST** have 0-3 parameters (use objects for more)
- ✅ **MUST** have clear return types
- ✅ **MUST** avoid side effects
- ❌ **MUST NOT** have flag parameters
- ❌ **MUST NOT** be longer than 50 lines

**Check:**
```typescript
// ❌ BAD - Multiple responsibilities
function processUserData(user: User) {
    validateUser(user);
    saveToDatabase(user);
    sendEmail(user);
    updateCache(user);
}

// ✅ GOOD - Single responsibility
function registerUser(user: User) {
    validateUser(user);
    return saveUserToDatabase(user);
}

function notifyUserRegistration(user: User) {
    sendWelcomeEmail(user);
}
```

### Error Handling

**Rules:**
- ✅ **MUST** handle all possible errors
- ✅ **MUST** provide meaningful error messages
- ✅ **MUST** validate all inputs
- ✅ **MUST** log errors with context
- ❌ **MUST NOT** have empty catch blocks
- ❌ **MUST NOT** return null (return empty collections instead)

**Check:**
```javascript
// ❌ BAD
try {
    await processPayment(order);
} catch (error) {
    // Empty catch
}

// ✅ GOOD
try {
    await processPayment(order);
} catch (error) {
    logger.error('Payment processing failed', {
        orderId: order.id,
        error: error.message,
        stack: error.stack
    });
    throw new PaymentError('Failed to process payment', error);
}
```

### Code Duplication (DRY)

**Rules:**
- ✅ **MUST** extract duplicate code into reusable functions
- ✅ **MUST** use composition over inheritance
- ❌ **MUST NOT** copy-paste similar code blocks

**Check:**
```python
# ❌ BAD - Duplication
def calculate_vip_order_total(items):
    total = sum(item.price * item.quantity for item in items)
    tax = total * 0.1
    discount = total * 0.2
    return total + tax - discount

def calculate_regular_order_total(items):
    total = sum(item.price * item.quantity for item in items)
    tax = total * 0.1
    discount = total * 0.05
    return total + tax - discount

# ✅ GOOD - Extracted common logic
def calculate_order_total(items, discount_rate):
    subtotal = sum(item.price * item.quantity for item in items)
    tax = subtotal * 0.1
    discount = subtotal * discount_rate
    return subtotal + tax - discount
```

---

## 3. Architecture & Design Review

### SOLID Principles Check

1. **Single Responsibility**
   ```javascript
   // ❌ BAD
   class User {
       saveToDatabase() { }
       sendEmail() { }
       generateReport() { }
   }

   // ✅ GOOD
   class User { /* data only */ }
   class UserRepository { save() { } }
   class EmailService { send() { } }
   ```

2. **Dependency Injection**
   ```typescript
   // ❌ BAD - Tight coupling
   class UserService {
       constructor() {
           this.repository = new UserRepository();
       }
   }

   // ✅ GOOD - Loose coupling
   class UserService {
       constructor(private repository: UserRepository) { }
   }
   ```

3. **Interface Segregation**
   ```java
   // ✅ GOOD - Focused interfaces
   interface Readable {
       void read();
   }

   interface Writable {
       void write();
   }

   class Document implements Readable, Writable {
       public void read() { }
       public void write() { }
   }
   ```

### Design Patterns Check

**Review for:**
- ✅ Proper use of patterns (Strategy, Factory, Observer, etc.)
- ✅ Avoid anti-patterns (God Object, Spaghetti Code)
- ✅ Separation of concerns
- ✅ Loose coupling, high cohesion

---

## 4. Security Review

### Critical Security Checks

- [ ] **No hardcoded secrets** (API keys, passwords)
  ```javascript
  // ❌ BAD
  const API_KEY = "sk_live_1234567890abcdef";

  // ✅ GOOD
  const API_KEY = process.env.STRIPE_API_KEY;
  ```

- [ ] **Input validation** for all user inputs
  ```python
  # ✅ GOOD
  def create_user(email, password):
      if not is_valid_email(email):
          raise ValidationError("Invalid email format")
      if len(password) < 8:
          raise ValidationError("Password too short")
  ```

- [ ] **SQL injection prevention**
  ```javascript
  // ❌ BAD
  const query = `SELECT * FROM users WHERE email = '${email}'`;

  // ✅ GOOD - Parameterized query
  const query = 'SELECT * FROM users WHERE email = ?';
  db.query(query, [email]);
  ```

- [ ] **XSS prevention**
  ```javascript
  // ✅ GOOD - Escape user input
  const sanitizedInput = escapeHtml(userInput);
  element.textContent = sanitizedInput; // Not innerHTML
  ```

- [ ] **Authentication & Authorization** properly implemented
- [ ] **CSRF protection** enabled
- [ ] **Sensitive data** not logged or exposed
- [ ] **Dependencies** checked for vulnerabilities

---

## 5. Performance Review

### Performance Checks

- [ ] **No N+1 query problems**
  ```javascript
  // ❌ BAD - N+1 queries
  const users = await User.findAll();
  for (const user of users) {
      user.posts = await Post.findByUserId(user.id); // N queries
  }

  // ✅ GOOD - Single query with join
  const users = await User.findAll({
      include: [Post]
  });
  ```

- [ ] **Proper indexing** for database queries
  ```sql
  -- ✅ GOOD - Add index for frequently queried columns
  CREATE INDEX idx_users_email ON users(email);
  CREATE INDEX idx_orders_user_id ON orders(user_id);
  ```

- [ ] **Caching** for expensive operations
  ```javascript
  // ✅ GOOD
  async function getPopularProducts() {
      const cached = await cache.get('popular_products');
      if (cached) return cached;

      const products = await db.query('SELECT * FROM products...');
      await cache.set('popular_products', products, 3600);
      return products;
  }
  ```

- [ ] **Avoid unnecessary loops**
  ```javascript
  // ❌ BAD - O(n²)
  for (let item of list1) {
      for (let item2 of list2) {
          if (item.id === item2.id) { }
      }
  }

  // ✅ GOOD - O(n)
  const map = new Map(list2.map(item => [item.id, item]));
  for (let item of list1) {
      if (map.has(item.id)) { }
  }
  ```

- [ ] **Lazy loading** for large datasets
- [ ] **Pagination** for list endpoints
- [ ] **Debouncing/throttling** for frequent operations

---

## 6. Testing Review

### Test Coverage Requirements

- [ ] **Unit tests** for all business logic
- [ ] **Integration tests** for critical flows
- [ ] **Edge cases** covered
- [ ] **Error scenarios** tested
- [ ] **Test names** descriptive and clear
- [ ] **Tests independent** (no order dependency)
- [ ] **No flaky tests**
- [ ] **Mock external dependencies**

### Test Quality Check

```javascript
// ✅ GOOD - Clear test structure
describe('UserService', () => {
    describe('createUser', () => {
        it('should create user with valid data', async () => {
            // Given
            const userData = { name: 'John', email: 'john@example.com' };

            // When
            const result = await userService.createUser(userData);

            // Then
            expect(result).toBeDefined();
            expect(result.name).toBe('John');
        });

        it('should throw error for invalid email', async () => {
            // Given
            const userData = { name: 'John', email: 'invalid' };

            // When & Then
            await expect(userService.createUser(userData))
                .rejects.toThrow('Invalid email');
        });
    });
});
```

---

## 7. Documentation Review

### Documentation Requirements

- [ ] **README updated** (if new feature)
- [ ] **API documentation** updated (if API changes)
- [ ] **Inline comments** for complex logic only
- [ ] **Function/class documentation** (JSDoc, docstrings)
- [ ] **Migration guide** (if breaking changes)
- [ ] **Changelog updated**

### Comment Quality

```javascript
// ❌ BAD - Obvious comment
// Get user name
const name = user.getName();

// ❌ BAD - Outdated comment
// Returns user email (actually returns user object now)
function getUser() {
    return user;
}

// ✅ GOOD - Explains WHY
// Using exponential backoff to avoid overwhelming external API
// which has rate limiting of 100 requests per minute
const delay = calculateExponentialBackoff(retryCount);
```

---

## 8. Common Code Smells

### Detect and Flag

- ❌ **Long functions** (> 50 lines)
- ❌ **Large classes** (> 500 lines)
- ❌ **Too many parameters** (> 3)
- ❌ **Deep nesting** (> 3 levels)
- ❌ **Complex conditionals** (multiple && and ||)
- ❌ **Duplicate code**
- ❌ **Dead code** (unused variables, functions)
- ❌ **God objects** (classes doing too much)
- ❌ **Feature envy** (method uses more of another class than its own)
- ❌ **Primitive obsession** (using primitives instead of objects)

### Refactoring Suggestions

```javascript
// ❌ CODE SMELL - Deep nesting
function processOrder(order) {
    if (order) {
        if (order.items) {
            if (order.items.length > 0) {
                if (order.customer) {
                    // Process
                }
            }
        }
    }
}

// ✅ REFACTORED - Guard clauses
function processOrder(order) {
    if (!order) return;
    if (!order.items || order.items.length === 0) return;
    if (!order.customer) return;

    // Process
}
```

---

## 9. Review Etiquette

### For Reviewers

**DO:**
- ✅ Be respectful and constructive
- ✅ Explain WHY, not just WHAT is wrong
- ✅ Suggest concrete solutions
- ✅ Praise good code
- ✅ Ask questions instead of making demands
- ✅ Review promptly (within 24 hours)

**DON'T:**
- ❌ Be rude or condescending
- ❌ Make personal attacks
- ❌ Block PR on minor style issues
- ❌ Request changes without explanation
- ❌ Nitpick unnecessarily

### Comment Templates

```markdown
# 🐛 Bug Risk
This could cause null pointer exception when user is not logged in.
Suggest adding validation: `if (!user) return null;`

# 💡 Suggestion
Consider extracting this logic into a separate function for reusability.

# ❓ Question
What happens if the API returns an error? Should we retry or fail immediately?

# 👍 Praise
Great use of the Strategy pattern here! This makes the code very extensible.

# ⚠️ Security
This endpoint is vulnerable to SQL injection. Please use parameterized queries.

# 🎯 Performance
This loop is O(n²). Consider using a Map for O(n) lookup.
```

---

## 10. Copilot-Specific Instructions

### Automated Review Tasks

When reviewing code, Copilot should:

1. **CHECK** naming conventions automatically
2. **FLAG** functions > 20 lines
3. **FLAG** parameters > 3
4. **DETECT** code duplication
5. **IDENTIFY** security vulnerabilities
6. **VERIFY** error handling exists
7. **CHECK** test coverage
8. **SUGGEST** refactoring opportunities

### Response Pattern

```markdown
❌ **Issue Found:** [Category]
Description of the problem

📍 **Location:** Line 45-52

🔍 **Impact:** [Critical/High/Medium/Low]
Why this matters

✅ **Suggested Fix:**
[Specific code example]

📚 **Reference:**
[Link to documentation or best practice]
```

### Example Review Comment

```markdown
❌ **Issue Found:** Security Vulnerability

SQL injection risk detected in user login function.

📍 **Location:** Line 23
```javascript
const query = `SELECT * FROM users WHERE email = '${email}'`;
```

🔍 **Impact:** Critical
Attacker can execute arbitrary SQL commands.

✅ **Suggested Fix:**
```javascript
const query = 'SELECT * FROM users WHERE email = ?';
const result = await db.query(query, [email]);
```

📚 **Reference:**
- [OWASP SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
```

---

## 11. Review Checklist Summary

### Quick Checklist (< 2 minutes)
- [ ] PR description complete?
- [ ] Tests passing?
- [ ] No obvious bugs?
- [ ] Code follows conventions?

### Standard Review (5-15 minutes)
- [ ] All items in Quick Checklist
- [ ] Code quality checks
- [ ] Architecture review
- [ ] Security basics
- [ ] Test coverage adequate

### Thorough Review (15-30 minutes)
- [ ] All items in Standard Review
- [ ] Deep security analysis
- [ ] Performance optimization opportunities
- [ ] Architectural implications
- [ ] Edge cases covered

---

## Priority Levels

1. **Critical (P0)** - Security vulnerabilities, data loss risks
2. **High (P1)** - Bugs, incorrect logic, performance issues
3. **Medium (P2)** - Code quality, maintainability
4. **Low (P3)** - Style, minor improvements

**Action:**
- P0/P1: Must fix before merge
- P2: Should fix, can be follow-up PR
- P3: Nice to have, optional

---

## References
- Clean Code - Robert C. Martin
- Code Complete - Steve McConnell
- OWASP Security Guidelines
- Google Engineering Practices

**Remember:** Code review is about improving code quality and sharing knowledge, not about showing who's smarter.
