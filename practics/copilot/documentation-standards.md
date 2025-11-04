# Rule: Documentation Standards & Technical Writing

## Intent
Enforce clear, concise, and maintainable documentation practices for code comments, API docs, README files, and technical specifications.

## Scope
Applies to all documentation including inline comments, JSDoc/docstrings, README files, API documentation, and architecture documents.

---

## 1. Code Comments

### When to Comment

- ✅ **MUST** comment complex algorithms
- ✅ **MUST** explain non-obvious decisions
- ✅ **MUST** document public APIs
- ❌ **MUST NOT** comment obvious code
- ❌ **MUST NOT** leave commented-out code

```javascript
// ✅ GOOD - Explains WHY, not WHAT
// Using exponential backoff to avoid overwhelming the API
// which has rate limiting of 100 requests per minute
const delay = Math.pow(2, retryCount) * 1000;

// ❌ BAD - States the obvious
// Increment i by 1
i++;

// ❌ BAD - Commented-out code
// const oldFunction = () => { ... };
```

### JSDoc / Docstrings

```javascript
// ✅ GOOD - JSDoc
/**
 * Fetches user data from the API
 * @param {string} userId - The user's unique identifier
 * @param {Object} options - Optional parameters
 * @param {boolean} options.includeProfile - Include user profile data
 * @returns {Promise<User>} The user object
 * @throws {APIError} When the user is not found
 * @example
 * const user = await getUser('123', { includeProfile: true });
 */
async function getUser(userId, options = {}) {
    // ...
}
```

```python
# ✅ GOOD - Python docstring
def calculate_total(items: List[Item], tax_rate: float = 0.1) -> float:
    """
    Calculate the total price including tax.

    Args:
        items: List of items to calculate total for
        tax_rate: Tax rate as decimal (default: 0.1 for 10%)

    Returns:
        Total price including tax

    Raises:
        ValueError: If items list is empty

    Example:
        >>> items = [Item(price=10), Item(price=20)]
        >>> calculate_total(items, 0.2)
        36.0
    """
    if not items:
        raise ValueError("Items list cannot be empty")

    subtotal = sum(item.price for item in items)
    return subtotal * (1 + tax_rate)
```

---

## 2. README Files

### Required Sections

```markdown
# Project Name

Brief description (1-2 sentences)

## Features

- Feature 1
- Feature 2

## Installation

\`\`\`bash
npm install
\`\`\`

## Usage

\`\`\`javascript
import { function } from 'package';
function();
\`\`\`

## Configuration

\`\`\`env
API_KEY=your_key
DATABASE_URL=your_url
\`\`\`

## API Documentation

See [API.md](./API.md)

## Development

\`\`\`bash
npm run dev
npm test
\`\`\`

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

MIT
```

### Examples & Screenshots

- ✅ **MUST** include code examples
- ✅ **SHOULD** include screenshots for UI
- ✅ **SHOULD** provide quick start guide

---

## 3. API Documentation

### OpenAPI/Swagger

```yaml
# ✅ GOOD - Complete API documentation
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
  description: API for managing users

paths:
  /users:
    get:
      summary: List all users
      description: Retrieve a paginated list of users
      parameters:
        - name: page
          in: query
          description: Page number
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          description: Items per page
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
              example:
                data: [{ id: 1, name: "John" }]
                pagination: { page: 1, total: 100 }
```

---

## 4. Architecture Documentation

### ADR (Architecture Decision Records)

```markdown
# ADR 001: Use PostgreSQL for Primary Database

## Status
Accepted

## Context
We need to choose a database for our application that supports:
- Complex queries with joins
- ACID transactions
- JSON data types
- Full-text search

## Decision
We will use PostgreSQL as our primary database.

## Consequences

### Positive
- Excellent support for relational data
- JSONB support for flexible schemas
- Strong ACID guarantees
- Mature ecosystem

### Negative
- More complex to scale horizontally than NoSQL
- Requires more expertise to optimize

## Alternatives Considered
- MongoDB: Rejected due to lack of strong consistency
- MySQL: Rejected due to weaker JSON support
```

---

## 5. Inline Documentation

### Self-Documenting Code

- ✅ **MUST** use descriptive variable names
- ✅ **MUST** use intention-revealing functions
- ✅ **SHOULD** prefer code clarity over comments

```javascript
// ✅ GOOD - Self-documenting
function calculateMonthlyPayment(principal, annualRate, years) {
    const monthlyRate = annualRate / 12;
    const numberOfPayments = years * 12;

    return (principal * monthlyRate) /
           (1 - Math.pow(1 + monthlyRate, -numberOfPayments));
}

// ❌ BAD - Needs comments to understand
function calc(p, r, y) {
    const m = r / 12;
    const n = y * 12;
    return (p * m) / (1 - Math.pow(1 + m, -n));
}
```

---

## 6. Technical Writing Guidelines

### Writing Style

- ✅ **MUST** use active voice
- ✅ **MUST** be concise
- ✅ **MUST** use present tense
- ✅ **SHOULD** use bullet points for lists
- ❌ **MUST NOT** use jargon without explanation

```markdown
✅ GOOD:
- The function returns a Promise
- Call this method to initialize the service
- Authentication is required

❌ BAD:
- The Promise will be returned by the function
- This method should be called in order to initialize
- The user must be authenticated before proceeding
```

### Code Examples

- ✅ **MUST** be runnable
- ✅ **MUST** include imports
- ✅ **SHOULD** show expected output

```javascript
// ✅ GOOD - Complete example
import { createUser } from './api';

async function example() {
    const user = await createUser({
        name: 'John Doe',
        email: 'john@example.com'
    });

    console.log(user);
    // Output: { id: '123', name: 'John Doe', ... }
}
```

---

## 7. Changelog

### Keep a Changelog Format

```markdown
# Changelog

## [Unreleased]
### Added
- New feature X

### Changed
- Updated dependency Y

### Fixed
- Bug Z

## [1.2.0] - 2025-11-01
### Added
- User authentication
- Password reset flow

### Changed
- Updated UI design

### Deprecated
- Old login endpoint (/api/auth)

### Removed
- Legacy API v1

### Fixed
- Memory leak in background job

### Security
- Fixed XSS vulnerability in comments
```

---

## 8. Diagram Guidelines

### Use Diagrams for Complex Flows

```markdown
# System Architecture

\`\`\`mermaid
graph TD
    A[Client] -->|HTTP| B[Load Balancer]
    B --> C[API Server 1]
    B --> D[API Server 2]
    C --> E[(Database)]
    D --> E
    C --> F[(Redis Cache)]
    D --> F
\`\`\`
```

---

## 9. Copilot Instructions

When generating documentation, Copilot **MUST**:

1. **WRITE** clear, concise descriptions
2. **INCLUDE** code examples with imports
3. **ADD** parameter descriptions
4. **SPECIFY** return types
5. **LIST** possible exceptions
6. **PROVIDE** usage examples
7. **USE** present tense, active voice
8. **AVOID** jargon without explanation

### Response Pattern

```markdown
✅ **Documentation Generated:**

\`\`\`javascript
/**
 * Processes a payment transaction
 *
 * @param {string} orderId - Unique order identifier
 * @param {Object} payment - Payment details
 * @param {string} payment.method - Payment method ('card' | 'paypal')
 * @param {number} payment.amount - Amount in cents
 * @returns {Promise<Transaction>} Processed transaction
 * @throws {PaymentError} If payment processing fails
 *
 * @example
 * const transaction = await processPayment('order-123', {
 *     method: 'card',
 *     amount: 9999
 * });
 */
async function processPayment(orderId, payment) {
    // Implementation
}
\`\`\`
```

---

## 10. Checklist

### Code Documentation
- [ ] Public APIs documented (JSDoc/docstrings)
- [ ] Complex logic explained
- [ ] Parameters and return types specified
- [ ] Examples provided
- [ ] No commented-out code

### Project Documentation
- [ ] README with installation/usage
- [ ] API documentation (OpenAPI)
- [ ] Architecture diagrams
- [ ] Changelog maintained
- [ ] Contributing guidelines

### Quality
- [ ] Clear and concise
- [ ] Active voice used
- [ ] Present tense
- [ ] Code examples runnable
- [ ] No unexplained jargon

---

## References

- Google Developer Documentation Style Guide
- Microsoft Writing Style Guide
- Write the Docs Community

**Remember:** Good documentation saves time for everyone, including your future self.
