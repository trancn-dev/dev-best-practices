# Documentation Standards - Chuẩn Tài Liệu

> Standards for writing clear, maintainable documentation
>
> **Mục đích**: Documentation dễ đọc, dễ maintain, hữu ích cho team

---

## 📋 Mục Lục
- [Documentation Types](#documentation-types)
- [README Best Practices](#readme-best-practices)
- [API Documentation](#api-documentation)
- [Code Comments](#code-comments)
- [Architecture Decision Records](#architecture-decision-records)
- [Diagrams](#diagrams)
- [Changelog](#changelog)
- [Wiki & Knowledge Base](#wiki--knowledge-base)

---

## 📚 DOCUMENTATION TYPES

### Documentation Hierarchy

```
1. README.md
   - Project overview
   - Quick start guide
   - Installation instructions

2. CONTRIBUTING.md
   - How to contribute
   - Development setup
   - Coding standards

3. API Documentation
   - OpenAPI/Swagger
   - Request/response examples
   - Authentication

4. Architecture Docs
   - System design
   - ADRs (Architecture Decision Records)
   - C4 diagrams

5. User Guides
   - How-to guides
   - Tutorials
   - FAQs

6. Code Comments
   - JSDoc/TSDoc
   - Inline explanations
   - Why, not what
```

---

## 📖 README BEST PRACTICES

### Comprehensive README Template

```markdown
# ✅ GOOD - Complete README.md

# Project Name

> Brief description of what this project does

[![Build Status](https://img.shields.io/github/workflow/status/user/repo/CI)](https://github.com/user/repo/actions)
[![Coverage](https://img.shields.io/codecov/c/github/user/repo)](https://codecov.io/gh/user/repo)
[![License](https://img.shields.io/github/license/user/repo)](LICENSE)

## 📋 Table of Contents

- [Features](#features)
- [Demo](#demo)
- [Installation](#installation)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Configuration](#configuration)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

- 🚀 Fast and lightweight
- 📦 Zero dependencies
- 🔒 Secure by default
- 📱 Mobile-friendly
- ♿ Accessible

## 🎬 Demo

![Demo GIF](docs/demo.gif)

Live demo: [https://demo.example.com](https://demo.example.com)

## 📦 Installation

### Prerequisites

- Node.js >= 18.0.0
- PostgreSQL >= 14
- Redis >= 7

### Install via npm

\`\`\`bash
npm install project-name
\`\`\`

### Install from source

\`\`\`bash
git clone https://github.com/user/repo.git
cd repo
npm install
cp .env.example .env
npm run build
\`\`\`

## 🚀 Usage

### Quick Start

\`\`\`javascript
const ProjectName = require('project-name');

const instance = new ProjectName({
    apiKey: 'your-api-key',
    timeout: 5000
});

const result = await instance.doSomething();
console.log(result);
\`\`\`

### Advanced Usage

\`\`\`javascript
// Example with all options
const instance = new ProjectName({
    apiKey: process.env.API_KEY,
    baseUrl: 'https://api.example.com',
    timeout: 10000,
    retries: 3,
    debug: true
});
\`\`\`

## 📚 API Reference

See [API Documentation](docs/API.md) for detailed API reference.

### Main Methods

#### `doSomething(options)`

Does something useful.

**Parameters:**
- `options` (Object) - Configuration options
  - `name` (string) - Required. The name
  - `value` (number) - Optional. The value (default: 0)

**Returns:** Promise<Result>

**Example:**

\`\`\`javascript
const result = await instance.doSomething({
    name: 'example',
    value: 42
});
\`\`\`

## ⚙️ Configuration

Configuration can be provided via:

1. Environment variables
2. Configuration file
3. Constructor options

### Environment Variables

\`\`\`bash
API_KEY=your-api-key
DATABASE_URL=postgresql://localhost/myapp
REDIS_URL=redis://localhost:6379
LOG_LEVEL=info
\`\`\`

### Configuration File

Create `config.json`:

\`\`\`json
{
  "apiKey": "your-api-key",
  "timeout": 5000,
  "retries": 3
}
\`\`\`

## 🛠️ Development

### Setup

\`\`\`bash
# Clone repository
git clone https://github.com/user/repo.git
cd repo

# Install dependencies
npm install

# Setup database
npm run db:setup

# Start development server
npm run dev
\`\`\`

### Available Scripts

\`\`\`bash
npm run dev          # Start development server
npm run build        # Build for production
npm run test         # Run tests
npm run test:watch   # Run tests in watch mode
npm run lint         # Lint code
npm run format       # Format code
\`\`\`

## 🧪 Testing

\`\`\`bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test
npm test -- user.test.js
\`\`\`

## 🚀 Deployment

### Docker

\`\`\`bash
docker build -t myapp .
docker run -p 3000:3000 myapp
\`\`\`

### Kubernetes

\`\`\`bash
kubectl apply -f k8s/
\`\`\`

See [Deployment Guide](docs/DEPLOYMENT.md) for detailed instructions.

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

### Development Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- [Library Name](https://example.com) - Used for X
- [Tool Name](https://example.com) - Used for Y

## 📧 Contact

- Author: Your Name
- Email: your.email@example.com
- Twitter: [@yourhandle](https://twitter.com/yourhandle)
- GitHub: [@yourusername](https://github.com/yourusername)

---

Made with ❤️ by [Your Name](https://github.com/yourusername)
```

---

## 🔌 API DOCUMENTATION

### OpenAPI/Swagger Specification

```yaml
# ✅ GOOD - OpenAPI 3.0 specification

openapi: 3.0.0
info:
  title: My API
  version: 1.0.0
  description: API for managing users and posts
  contact:
    name: API Support
    email: support@example.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://staging-api.example.com/v1
    description: Staging

paths:
  /users:
    get:
      summary: List all users
      description: Returns a paginated list of users
      tags:
        - Users
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
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/Pagination'
              example:
                data:
                  - id: 1
                    name: John Doe
                    email: john@example.com
                pagination:
                  page: 1
                  limit: 20
                  total: 100
        '401':
          $ref: '#/components/responses/Unauthorized'

    post:
      summary: Create a user
      tags:
        - Users
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUser'
            example:
              name: John Doe
              email: john@example.com
              password: securepassword123
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
          readOnly: true
        name:
          type: string
        email:
          type: string
          format: email
        created_at:
          type: string
          format: date-time
          readOnly: true
      required:
        - name
        - email

    CreateUser:
      type: object
      properties:
        name:
          type: string
          minLength: 3
          maxLength: 100
        email:
          type: string
          format: email
        password:
          type: string
          minLength: 8
      required:
        - name
        - email
        - password

    Pagination:
      type: object
      properties:
        page:
          type: integer
        limit:
          type: integer
        total:
          type: integer
        hasMore:
          type: boolean

    Error:
      type: object
      properties:
        error:
          type: string
        message:
          type: string
        details:
          type: array
          items:
            type: object

  responses:
    Unauthorized:
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Unauthorized
            message: Invalid or missing authentication token

    BadRequest:
      description: Bad Request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

### JSDoc Comments

```javascript
// ✅ GOOD - Comprehensive JSDoc

/**
 * User service for managing user accounts
 * @module services/user
 */

/**
 * Creates a new user account
 *
 * @async
 * @function createUser
 * @param {Object} userData - The user data
 * @param {string} userData.name - User's full name
 * @param {string} userData.email - User's email address
 * @param {string} userData.password - User's password (will be hashed)
 * @returns {Promise<User>} The created user object
 * @throws {ValidationError} If input data is invalid
 * @throws {DuplicateError} If email already exists
 *
 * @example
 * const user = await createUser({
 *   name: 'John Doe',
 *   email: 'john@example.com',
 *   password: 'securepass123'
 * });
 */
async function createUser(userData) {
    // Validate input
    const { error } = userSchema.validate(userData);
    if (error) {
        throw new ValidationError(error.message);
    }

    // Check for duplicates
    const existing = await db.users.findByEmail(userData.email);
    if (existing) {
        throw new DuplicateError('Email already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(userData.password, 10);

    // Create user
    const user = await db.users.create({
        ...userData,
        password: hashedPassword
    });

    return user;
}

/**
 * User object
 * @typedef {Object} User
 * @property {number} id - User ID
 * @property {string} name - User's full name
 * @property {string} email - User's email address
 * @property {Date} created_at - Account creation timestamp
 * @property {Date} updated_at - Last update timestamp
 */
```

---

## 💬 CODE COMMENTS

### When to Comment

```javascript
// ✅ GOOD - Explain WHY, not WHAT

// Use binary search because array is sorted and can be large (>10k items)
const index = binarySearch(sortedArray, target);

// Retry 3 times with exponential backoff to handle transient network errors
const result = await retry(fetchData, { maxAttempts: 3, backoff: 'exponential' });

// ❌ BAD - Obvious comments
// Increment i by 1
i++;

// Loop through array
for (const item of items) {
    // ...
}
```

### TODO Comments

```javascript
// ✅ GOOD - Actionable TODOs with context

// TODO(john): Implement caching layer to improve performance
// See issue #123 for requirements
async function fetchUserData(userId) {
    return await db.users.findById(userId);
}

// FIXME: Race condition when multiple requests update same record
// Need to implement optimistic locking or use database transactions
async function updateCounter(id) {
    const record = await db.counters.find(id);
    record.count += 1;
    await db.counters.update(id, record);
}

// HACK: Temporary workaround for API bug in v1.2.3
// Remove when upgrading to v1.3.0 (scheduled for Q2 2025)
const response = await api.getData({ workaround: true });

// ❌ BAD - Vague TODOs
// TODO: fix this
// TODO: improve performance
```

### Complex Logic Comments

```javascript
// ✅ GOOD - Explain complex algorithms

/**
 * Calculate shipping cost using zone-based pricing
 *
 * Algorithm:
 * 1. Determine shipping zone based on destination postal code
 * 2. Calculate base rate from weight and dimensions
 * 3. Apply zone multiplier (Zone 1: 1.0x, Zone 2: 1.5x, Zone 3: 2.0x)
 * 4. Add fuel surcharge (currently 15%)
 * 5. Apply any applicable discounts
 */
function calculateShippingCost(package, destination) {
    const zone = getShippingZone(destination.postalCode);
    const baseRate = calculateBaseRate(package.weight, package.dimensions);
    const zoneMultiplier = ZONE_MULTIPLIERS[zone];
    const fuelSurcharge = baseRate * FUEL_SURCHARGE_RATE;
    const subtotal = (baseRate * zoneMultiplier) + fuelSurcharge;
    const discount = calculateDiscount(subtotal, destination.customerType);

    return subtotal - discount;
}
```

---

## 📐 ARCHITECTURE DECISION RECORDS

### ADR Template

```markdown
# ✅ GOOD - ADR Template

# ADR 001: Use PostgreSQL for Primary Database

## Status

Accepted

## Context

We need to choose a database for storing user data, orders, and inventory.
Requirements:
- ACID transactions for financial data
- Complex queries with joins
- Strong consistency
- Good performance for read-heavy workloads
- Open source

Options considered:
1. PostgreSQL
2. MySQL
3. MongoDB
4. DynamoDB

## Decision

We will use PostgreSQL as our primary database.

## Rationale

- **ACID Compliance**: PostgreSQL provides full ACID guarantees, critical for financial transactions
- **Advanced Features**: Supports JSON, full-text search, and window functions
- **Performance**: Excellent query optimizer and indexing capabilities
- **Community**: Large, active community and extensive documentation
- **Cost**: Open source with no licensing fees
- **Ecosystem**: Rich ecosystem of tools and extensions

Trade-offs:
- Vertical scaling limits (addressed with read replicas)
- More complex to operate than managed services (acceptable with our DevOps team)

## Consequences

### Positive
- Strong data consistency and integrity
- Powerful query capabilities
- No vendor lock-in
- Lower operational costs

### Negative
- Need to manage database operations ourselves
- Scaling requires careful planning
- Team needs PostgreSQL expertise

### Neutral
- Migration from current MySQL database required
- Need to set up backup and replication

## Implementation

1. Set up PostgreSQL 15 cluster (2 weeks)
2. Create database schema (1 week)
3. Migrate data from MySQL (2 weeks)
4. Set up monitoring and alerting (1 week)
5. Train team on PostgreSQL (ongoing)

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Performance Comparison](link-to-benchmark)
- [Cost Analysis](link-to-spreadsheet)

## Revision History

- 2025-01-15: Initial proposal
- 2025-01-20: Accepted by architecture team
```

---

## 📊 DIAGRAMS

### C4 Model

```
# ✅ GOOD - C4 diagrams for architecture

## Level 1: System Context
┌─────────────────────────────────────────┐
│          E-commerce System              │
│                                         │
│  ┌──────────┐      ┌────────────────┐  │
│  │   Web    │      │  Mobile App    │  │
│  │   App    │      │                │  │
│  └────┬─────┘      └───────┬────────┘  │
│       │                    │            │
│       └────────┬───────────┘            │
│                │                        │
│         ┌──────▼──────┐                 │
│         │   API       │                 │
│         │  Gateway    │                 │
│         └──────┬──────┘                 │
│                │                        │
│    ┌───────────┼───────────┐           │
│    │           │           │           │
│ ┌──▼───┐  ┌───▼────┐  ┌───▼────┐      │
│ │ User │  │ Order  │  │Payment │      │
│ │Service│ │Service │  │Service │      │
│ └──────┘  └────────┘  └────────┘      │
│                                         │
└─────────────────────────────────────────┘
        │              │
   ┌────▼────┐    ┌────▼─────┐
   │PostgreSQL│    │  Redis   │
   └─────────┘    └──────────┘
```

### Sequence Diagrams

```mermaid
# ✅ GOOD - Mermaid sequence diagram

sequenceDiagram
    participant User
    participant API
    participant Auth
    participant DB
    participant Cache

    User->>API: POST /api/login
    API->>Auth: Validate credentials
    Auth->>DB: Query user
    DB-->>Auth: User data
    Auth->>Auth: Verify password
    Auth-->>API: JWT token
    API->>Cache: Store session
    API-->>User: 200 OK + token
```

---

## 📝 CHANGELOG

### Keep a Changelog Format

```markdown
# ✅ GOOD - Changelog

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature X for Y

### Changed
- Improved performance of Z

## [1.2.0] - 2025-01-15

### Added
- User profile avatars (#123)
- Export data to CSV feature (#145)
- Dark mode support (#156)

### Changed
- Updated Node.js to v18 (#134)
- Improved error messages (#142)
- Optimized database queries (15% faster)

### Fixed
- Fixed memory leak in WebSocket connections (#138)
- Resolved XSS vulnerability in comments (#149)
- Fixed pagination bug on search page (#151)

### Deprecated
- Old API v1 endpoints (will be removed in v2.0)

### Removed
- Removed support for Node.js v14

### Security
- Updated dependencies to patch CVE-2025-1234

## [1.1.0] - 2024-12-01

[See full changelog...](https://github.com/user/repo/blob/main/CHANGELOG.md)
```

---

## ✅ DOCUMENTATION CHECKLIST

### Project Documentation
- [ ] README.md with quick start
- [ ] CONTRIBUTING.md for contributors
- [ ] LICENSE file
- [ ] CHANGELOG.md
- [ ] Code of Conduct
- [ ] Security policy (SECURITY.md)

### Code Documentation
- [ ] JSDoc/TSDoc comments for public APIs
- [ ] Inline comments for complex logic
- [ ] Examples in documentation
- [ ] Type definitions

### API Documentation
- [ ] OpenAPI/Swagger specification
- [ ] Request/response examples
- [ ] Authentication guide
- [ ] Error codes documented
- [ ] Rate limits documented

### Architecture Documentation
- [ ] System architecture diagram
- [ ] ADRs for major decisions
- [ ] Database schema documentation
- [ ] Deployment architecture
- [ ] Security architecture

### User Documentation
- [ ] Getting started guide
- [ ] Tutorials for common tasks
- [ ] FAQ section
- [ ] Troubleshooting guide

---

## 📚 REFERENCES

- [Write the Docs](https://www.writethedocs.org/)
- [Google Developer Documentation Style Guide](https://developers.google.com/style)
- [Microsoft Writing Style Guide](https://docs.microsoft.com/en-us/style-guide/)
- [Keep a Changelog](https://keepachangelog.com/)
- [C4 Model](https://c4model.com/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
