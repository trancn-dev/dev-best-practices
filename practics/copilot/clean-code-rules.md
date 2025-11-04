# Rule: Clean Code Standards

## Intent
Enforce clean code principles from Robert C. Martin's "Clean Code" when generating, reviewing, or refactoring code. Copilot must follow these rules to ensure code is readable, maintainable, and professional.

## Scope
Applies to all code generation, code review, and refactoring suggestions across all programming languages.

---

## 1. Naming Conventions

### Rules
- ✅ **MUST** use meaningful and intention-revealing names
- ✅ **MUST** use pronounceable names
- ✅ **MUST** use searchable names
- ✅ **MUST** avoid misleading information
- ✅ **MUST** make meaningful distinctions
- ❌ **MUST NOT** use single-letter variables (except loop counters in short loops)
- ❌ **MUST NOT** use Hungarian notation or prefixes (m_, I, etc.)
- ❌ **MUST NOT** use generic names like `data`, `info`, `item`

### Examples

```javascript
// ❌ BAD
let d; // elapsed time
let accountList = {}; // misleading - not a list

// ✅ GOOD
let elapsedTimeInDays;
let accountMap = {};
```

```python
# ❌ BAD
def get_data():
    pass

# ✅ GOOD
def getUserProfileFromDatabase():
    pass
```

---

## 2. Functions

### Rules
- ✅ **MUST** keep functions small (ideally 4-5 lines, max 20 lines)
- ✅ **MUST** do ONE thing only
- ✅ **MUST** maintain one level of abstraction per function
- ✅ **MUST** minimize parameters (ideal: 0, good: 1-2, avoid: 3+)
- ✅ **MUST** avoid side effects
- ✅ **MUST** separate Command and Query
- ❌ **MUST NOT** use flag arguments
- ❌ **MUST NOT** return null (return empty collections/objects instead)
- ❌ **MUST NOT** pass null as parameters

### Parameter Guidelines
When function has 3+ parameters, suggest grouping into an object/interface:

```typescript
// ❌ BAD
function createUser(name: string, age: number, email: string,
                   address: string, phone: string) { }

// ✅ GOOD
interface UserData {
    name: string;
    age: number;
    email: string;
    address: string;
    phone: string;
}
function createUser(userData: UserData) { }
```

### Single Responsibility

```javascript
// ❌ BAD - Multiple responsibilities
function saveAndSendEmail(user) {
    saveUser(user);
    sendEmail(user.email);
}

// ✅ GOOD - Single responsibility
function saveUser(user) {
    // save logic only
}

function sendWelcomeEmail(user) {
    // email logic only
}
```

---

## 3. Comments

### Rules
- ✅ **PREFER** self-documenting code over comments
- ✅ **ALLOW** legal comments (copyright, license)
- ✅ **ALLOW** explanation of intent for complex algorithms
- ✅ **ALLOW** warnings about consequences
- ✅ **ALLOW** TODO comments (with tracking)
- ❌ **MUST NOT** write redundant comments
- ❌ **MUST NOT** write misleading comments
- ❌ **MUST NOT** leave commented-out code
- ❌ **MUST NOT** write obvious comments

### Good Comments

```python
# We use binary search because dataset can contain millions of records
# and needs O(log n) performance
def find_user(user_id):
    return binary_search(users, user_id)
```

### Bad Comments

```javascript
// ❌ BAD - Redundant
// Increment i by 1
i++;

// ❌ BAD - Obvious
// Default constructor
constructor() { }

// ❌ BAD - Commented out code
// function oldImplementation() {
//     // 50 lines...
// }
```

---

## 4. Formatting

### Rules
- ✅ **MUST** keep files reasonably sized (200-500 lines ideal)
- ✅ **MUST** group related concepts together
- ✅ **MUST** limit line length (80-120 characters)
- ✅ **MUST** use consistent indentation (2 or 4 spaces)
- ✅ **MUST** use vertical whitespace to separate concepts
- ✅ **MUST** declare variables close to usage
- ✅ **MUST** place caller functions above callee functions

### Structure

```javascript
// ✅ GOOD - Related concepts grouped
const userName = getUserName();
const userEmail = getUserEmail();
const userAge = getUserAge();

// Blank line separates different concept
const productName = getProductName();
const productPrice = getProductPrice();
```

---

## 5. Error Handling

### Rules
- ✅ **MUST** use exceptions instead of error codes
- ✅ **MUST** write try-catch-finally first when designing error-prone code
- ✅ **MUST** provide context with exceptions
- ✅ **MUST** define exception classes based on caller's needs
- ✅ **MUST** return empty collections instead of null
- ❌ **MUST NOT** return null
- ❌ **MUST NOT** pass null as parameters

### Examples

```java
// ❌ BAD - Error codes
public int deleteUser(User user) {
    if (userExists(user)) {
        delete(user);
        return 0;
    }
    return -1;
}

// ✅ GOOD - Exceptions
public void deleteUser(User user) throws UserNotFoundException {
    if (!userExists(user)) {
        throw new UserNotFoundException(user.id);
    }
    delete(user);
}
```

```typescript
// ❌ BAD - Returning null
function getUsers(): User[] | null {
    if (noUsers) return null;
    return users;
}

// ✅ GOOD - Return empty array
function getUsers(): User[] {
    if (noUsers) return [];
    return users;
}
```

---

## 6. Objects and Data Structures

### Rules
- ✅ **MUST** hide internal data structure
- ✅ **MUST** follow Law of Demeter (avoid train wrecks)
- ✅ **MUST** use Data Transfer Objects (DTOs) for data transfer
- ❌ **MUST NOT** expose internal implementation details

### Law of Demeter

```python
# ❌ BAD - Train wreck
output_dir = ctxt.getOptions().getScratchDir().getAbsolutePath()

# ✅ GOOD - Hide details
output_dir = ctxt.getScratchDirectoryPath()
```

### Data Transfer Objects

```typescript
// ✅ GOOD - DTO pattern
interface UserDTO {
    id: string;
    name: string;
    email: string;
}

class User {
    constructor(
        private id: string,
        private name: string,
        private email: string,
        private passwordHash: string
    ) {}

    toDTO(): UserDTO {
        return {
            id: this.id,
            name: this.name,
            email: this.email
            // passwordHash NOT exposed
        };
    }
}
```

---

## 7. Unit Tests - F.I.R.S.T Principles

### Rules
- ✅ **MUST** be **F**ast
- ✅ **MUST** be **I**ndependent
- ✅ **MUST** be **R**epeatable in any environment
- ✅ **MUST** be **S**elf-validating (boolean output)
- ✅ **MUST** be **T**imely (written before/with production code)
- ✅ **SHOULD** have one assert per test (ideal)
- ✅ **MUST** follow Given-When-Then pattern

### Test Structure

```python
def test_user_registration():
    # Given - Setup
    username = "testuser"
    email = "test@example.com"

    # When - Action
    user = register_user(username, email)

    # Then - Assertion
    assert user.username == username
    assert user.email == email
    assert user.is_active == True
```

---

## 8. Classes

### Rules
- ✅ **MUST** be small (measured by responsibilities, not lines)
- ✅ **MUST** follow Single Responsibility Principle
- ✅ **MUST** have high cohesion
- ✅ **MUST** follow class organization order:
  1. Constants
  2. Static variables
  3. Instance variables
  4. Constructors
  5. Public methods
  6. Private methods

### Organization

```java
// ✅ GOOD - Proper organization
public class User {
    // 1. Constants
    private static final int MAX_NAME_LENGTH = 100;

    // 2. Static variables
    private static int userCount = 0;

    // 3. Instance variables
    private String name;
    private String email;

    // 4. Constructor
    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }

    // 5. Public methods
    public String getName() {
        return name;
    }

    // 6. Private methods
    private void validateName(String name) {
        // validation
    }
}
```

### Single Responsibility

```javascript
// ❌ BAD - Multiple responsibilities
class User {
    saveToDatabase() { }
    sendEmail() { }
    generateReport() { }
    validateData() { }
}

// ✅ GOOD - Single responsibility each
class User {
    constructor(name, email) { }
    getName() { }
    getEmail() { }
}

class UserRepository {
    save(user) { }
}

class EmailService {
    send(user) { }
}

class ReportGenerator {
    generate(user) { }
}
```

---

## 9. SOLID Principles (Quick Reference)

1. **S**ingle Responsibility - One reason to change
2. **O**pen-Closed - Open for extension, closed for modification
3. **L**iskov Substitution - Subtypes must be substitutable
4. **I**nterface Segregation - Don't force unused interfaces
5. **D**ependency Inversion - Depend on abstractions

---

## 10. Copilot-Specific Instructions

### When Generating Code
1. **ALWAYS** check if function exceeds 20 lines → suggest splitting
2. **ALWAYS** check if parameters exceed 2 → suggest object grouping
3. **ALWAYS** use meaningful names → never suggest `data`, `info`, `temp`
4. **ALWAYS** return empty collections → never return null
5. **ALWAYS** validate before suggesting → ask if unsure about context

### When Reviewing Code
1. **CHECK** naming conventions first
2. **CHECK** function size and responsibility
3. **CHECK** error handling patterns
4. **CHECK** for code duplication
5. **SUGGEST** specific improvements with reasoning

### Response Pattern
When suggesting changes, use this format:

```
❌ Issue Found: [Specific violation]
✅ Suggested Fix: [Concrete solution]
📝 Reason: [Why this is better]

[Code example]
```

### Example Response

```
❌ Issue Found: Function has 5 parameters, violates Clean Code principle
✅ Suggested Fix: Group parameters into UserData object
📝 Reason: Reduces cognitive load, easier to extend, more maintainable

// Before
function createUser(name, email, age, phone, address) { }

// After
interface UserData {
    name: string;
    email: string;
    age: number;
    phone: string;
    address: string;
}
function createUser(userData: UserData) { }
```

---

## 11. Daily Checklist

### Before Committing Code
- [ ] All names are meaningful and clear?
- [ ] All functions do ONE thing only?
- [ ] No function exceeds 20 lines?
- [ ] Parameters ≤ 3?
- [ ] Code is self-documenting?
- [ ] No commented-out code?
- [ ] Error handling is proper?
- [ ] Tests are passing?

---

## References
- Clean Code - Robert C. Martin
- The Pragmatic Programmer - Andrew Hunt & David Thomas
- Refactoring - Martin Fowler

---

**Priority Enforcement:**
1. Naming (highest impact on readability)
2. Functions (size and responsibility)
3. Error Handling
4. Testing
5. Formatting

When in doubt, prioritize code clarity over cleverness.
