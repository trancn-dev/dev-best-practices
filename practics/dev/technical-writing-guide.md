# Technical Writing Guide - Hướng Dẫn Viết Kỹ Thuật

> Guide for writing clear, concise, and effective technical documentation
>
> **Mục đích**: Viết tài liệu kỹ thuật dễ hiểu, chính xác, hữu ích

---

## 📋 Mục Lục
- [Writing Principles](#writing-principles)
- [Document Structure](#document-structure)
- [Style Guidelines](#style-guidelines)
- [Code Examples](#code-examples)
- [Markdown Best Practices](#markdown-best-practices)
- [Common Mistakes](#common-mistakes)
- [Tools & Resources](#tools--resources)

---

## ✍️ WRITING PRINCIPLES

### The Four Cs

```
✅ CLEAR - Easy to understand
✅ CONCISE - No unnecessary words
✅ CONSISTENT - Same terms, same style
✅ CORRECT - Technically accurate
```

### Know Your Audience

```javascript
// ✅ GOOD - For beginners
/**
 * Creates a new user account.
 *
 * This function takes user information and saves it to the database.
 * It automatically hashes the password before storing it for security.
 *
 * @param {string} name - The user's full name (e.g., "John Doe")
 * @param {string} email - The user's email address
 * @returns {Object} The newly created user
 */
async function createUser(name, email) {
    // Implementation
}

// ✅ GOOD - For experienced developers
/**
 * Creates user with bcrypt password hashing (cost factor: 10).
 * Throws DuplicateError if email exists.
 *
 * @param {UserInput} input
 * @returns {Promise<User>}
 * @throws {ValidationError|DuplicateError}
 */
async function createUser(input) {
    // Implementation
}
```

### Active Voice vs Passive Voice

```markdown
# ✅ GOOD - Active voice (clear, direct)
- Click the button to save your changes.
- The function returns a promise.
- Configure the database connection before starting the server.

# ❌ BAD - Passive voice (wordy, unclear)
- The button should be clicked to save your changes.
- A promise is returned by the function.
- The database connection should be configured before the server is started.
```

### Present Tense

```markdown
# ✅ GOOD - Present tense
The function calculates the total price.
When the user clicks Submit, the form validates the input.

# ❌ BAD - Past/future tense
The function will calculate the total price.
When the user clicked Submit, the form validated the input.
```

---

## 📐 DOCUMENT STRUCTURE

### Start with Why

```markdown
# ✅ GOOD - Purpose-driven introduction

# Authentication Guide

This guide explains how to authenticate users in your application using JWT tokens.

## Why JWT?

JWT (JSON Web Token) provides a secure, stateless way to verify user identity
without storing session data on the server. This makes it ideal for:
- Microservices architectures
- Mobile applications
- APIs with high traffic

## What you'll learn

- How to generate and verify JWT tokens
- How to implement refresh tokens
- How to handle token expiration
- Security best practices

---

# ❌ BAD - Jumps straight to "How"

# Authentication

Here's how to use JWT:

```javascript
const token = jwt.sign(payload, secret);
```
```

### Logical Flow

```markdown
# ✅ GOOD - Logical progression

1. **Introduction** - What and why
2. **Prerequisites** - What you need to know/have
3. **Overview** - High-level explanation
4. **Step-by-step guide** - Detailed instructions
5. **Examples** - Working code samples
6. **Troubleshooting** - Common issues
7. **Next steps** - What to do next

---

# Example Structure

## Introduction
Redis is an in-memory data store used for caching and session management.

## Prerequisites
- Node.js 18+
- Redis server running
- Basic understanding of key-value stores

## Installation
```bash
npm install redis
```

## Quick Start
```javascript
const redis = require('redis');
const client = redis.createClient();
```

## Usage Examples
### Example 1: String Operations
### Example 2: Hash Operations

## Common Issues
### Connection Refused
### Timeout Errors

## Next Steps
- Learn about Redis data types
- Set up Redis clustering
- Implement caching strategies
```

---

## 🎨 STYLE GUIDELINES

### Be Concise

```markdown
# ✅ GOOD - Concise and clear
Install the package:
```bash
npm install express
```

Start the server:
```javascript
const app = require('express')();
app.listen(3000);
```

---

# ❌ BAD - Wordy and redundant
In order to install the package, you will need to run the following
command in your terminal or command prompt:
```bash
npm install express
```

After the installation process has completed successfully, you can start
the server by creating an instance of express and calling the listen method
on it, as shown in the code example below:
```javascript
const app = require('express')();
app.listen(3000);
```
```

### Use Lists Effectively

```markdown
# ✅ GOOD - Well-structured lists

## API Features

Our API provides the following capabilities:

- **User Management**: Create, read, update, and delete users
- **Authentication**: JWT-based authentication with refresh tokens
- **Rate Limiting**: 100 requests per minute per API key
- **Webhooks**: Real-time notifications for events

---

# ❌ BAD - Paragraph format

Our API provides user management capabilities including creating, reading,
updating and deleting users. It also has authentication using JWT with
refresh tokens. There is rate limiting at 100 requests per minute per API
key and webhooks for real-time notifications.
```

### Headings Hierarchy

```markdown
# ✅ GOOD - Clear hierarchy

# Main Title (H1) - Only one per document

## Major Section (H2)

### Subsection (H3)

#### Minor Detail (H4)

Regular paragraph text here.

---

# ❌ BAD - Inconsistent hierarchy

# Title

#### Subsection (skipped H2 and H3)

## Another Section (wrong order)
```

### Tables for Comparison

```markdown
# ✅ GOOD - Use tables for structured data

## HTTP Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid input data |
| 401 | Unauthorized | Missing/invalid authentication |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Unexpected server error |

---

# ❌ BAD - Paragraph format

The 200 status code means OK and is used for successful GET, PUT, and PATCH
requests. 201 means Created and is used for successful POST. 204 means...
```

---

## 💻 CODE EXAMPLES

### Complete & Runnable

```markdown
# ✅ GOOD - Complete, runnable example

```javascript
// Complete example with imports and error handling
const express = require('express');
const app = express();

app.use(express.json());

app.get('/api/users/:id', async (req, res) => {
    try {
        const user = await db.users.findById(req.params.id);

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json(user);
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.listen(3000, () => {
    console.log('Server running on port 3000');
});
```

---

# ❌ BAD - Incomplete example

```javascript
// Incomplete - missing context
app.get('/api/users/:id', async (req, res) => {
    const user = await db.users.findById(req.params.id);
    res.json(user);
});
```
```

### Before and After Examples

```markdown
# ✅ GOOD - Show transformation

## Refactoring Example

### Before (❌)
```javascript
function calculateTotal(items) {
    var total = 0;
    for (var i = 0; i < items.length; i++) {
        total = total + items[i].price * items[i].quantity;
    }
    return total;
}
```

### After (✅)
```javascript
function calculateTotal(items) {
    return items.reduce((total, item) =>
        total + (item.price * item.quantity), 0
    );
}
```

**Improvements:**
- More concise using `reduce()`
- Uses modern ES6 syntax
- Easier to read and understand
```

### Highlight Key Parts

```javascript
// ✅ GOOD - Highlight important lines

// Generate JWT token
const token = jwt.sign(
    { userId: user.id, email: user.email },
    process.env.JWT_SECRET,  // ⬅️ Store secret in environment variable
    { expiresIn: '15m' }     // ⬅️ Short-lived access token
);

// Store refresh token
const refreshToken = generateRefreshToken();
await db.refreshTokens.insert({
    userId: user.id,
    token: refreshToken,
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)  // ⬅️ 7 days
});
```

### Don't Do This Examples

```markdown
# ✅ GOOD - Show what NOT to do

## Security: Password Storage

### ❌ DON'T: Store plain text passwords
```javascript
// NEVER do this!
await db.users.insert({
    username: 'john',
    password: 'mypassword123'  // ⚠️ Security vulnerability!
});
```

### ✅ DO: Hash passwords before storing
```javascript
const bcrypt = require('bcrypt');

const hashedPassword = await bcrypt.hash(password, 10);
await db.users.insert({
    username: 'john',
    password: hashedPassword  // ✅ Secure
});
```
```

---

## 📝 MARKDOWN BEST PRACTICES

### Formatting

```markdown
# ✅ GOOD - Consistent formatting

**Bold** for emphasis
*Italic* for terms
`code` for code snippets
[Link text](URL) for links

- Unordered list item
- Another item
  - Nested item

1. Ordered list item
2. Another item

> Blockquote for important notes

---

# ❌ BAD - Inconsistent formatting

__Bold__ and **bold** mixed
_Italic_ and *italic* mixed
```code``` and `code` mixed
```

### Code Blocks

```markdown
# ✅ GOOD - Language specified

```javascript
const greeting = 'Hello, World!';
console.log(greeting);
```

```python
greeting = "Hello, World!"
print(greeting)
```

```bash
npm install express
node server.js
```

---

# ❌ BAD - No language specified

```
const greeting = 'Hello, World!';
console.log(greeting);
```
```

### Links

```markdown
# ✅ GOOD - Descriptive link text

Learn more about [JWT authentication](https://jwt.io)
See the [API documentation](docs/api.md) for details
Read our [contributing guidelines](CONTRIBUTING.md)

---

# ❌ BAD - Generic link text

Click [here](https://jwt.io) to learn more
[Link](docs/api.md)
```

### Images

```markdown
# ✅ GOOD - Descriptive alt text and context

The dashboard displays real-time metrics:

![Dashboard showing user activity, response times, and error rates](images/dashboard.png)

---

# ❌ BAD - No context or poor alt text

![Image](images/dashboard.png)
```

---

## ⚠️ COMMON MISTAKES

### Ambiguous Pronouns

```markdown
# ✅ GOOD - Specific references
When the user submits the form, the application validates the input data.
If validation fails, the application displays an error message.

---

# ❌ BAD - Ambiguous "it"
When the user submits the form, it validates the input.
If it fails, it displays an error.
```

### Assumptions

```markdown
# ✅ GOOD - Explicit prerequisites

## Prerequisites

Before starting, ensure you have:
- Node.js 18 or higher installed
- PostgreSQL database running
- Basic knowledge of Express.js
- Git installed for version control

---

# ❌ BAD - Assumes knowledge
Simply run `npm start` to begin.
(Assumes user knows how to install dependencies, configure environment, etc.)
```

### Jargon Without Explanation

```markdown
# ✅ GOOD - Explain technical terms

## CORS (Cross-Origin Resource Sharing)

CORS is a security feature that restricts web pages from making requests
to a different domain than the one serving the page. For example, if your
frontend runs on `https://example.com`, it cannot make API calls to
`https://api.other.com` unless the API explicitly allows it.

To enable CORS in Express:
```javascript
const cors = require('cors');
app.use(cors());
```

---

# ❌ BAD - Unexplained jargon
Enable CORS middleware to handle preflight requests with OPTIONS method
for cross-origin XHR and fetch API calls.
```

### Outdated Information

```markdown
# ✅ GOOD - Include version information

## Installation (Node.js 18+)

As of Node.js 18, the fetch API is built-in:

```javascript
const response = await fetch('https://api.example.com');
```

For Node.js 16 and earlier, install node-fetch:
```bash
npm install node-fetch
```

**Last updated:** 2025-11-01

---

# ❌ BAD - No version context
Use node-fetch for HTTP requests:
```bash
npm install node-fetch
```
(This is outdated for Node 18+)
```

---

## 🛠️ TOOLS & RESOURCES

### Writing Tools

```markdown
## Grammar & Style
- [Grammarly](https://grammarly.com) - Grammar checker
- [Hemingway Editor](http://hemingwayapp.com) - Readability
- [Vale](https://vale.sh) - Prose linter

## Markdown Editors
- [Typora](https://typora.io) - WYSIWYG Markdown editor
- [Mark Text](https://marktext.app) - Open-source editor
- [VSCode](https://code.visualstudio.com) - With Markdown extensions

## Diagram Tools
- [Mermaid](https://mermaid.js.org) - Text-based diagrams
- [draw.io](https://draw.io) - Visual diagramming
- [Excalidraw](https://excalidraw.com) - Hand-drawn style diagrams

## API Documentation
- [Swagger UI](https://swagger.io/tools/swagger-ui/)
- [Redoc](https://redocly.com/redoc/)
- [Postman](https://www.postman.com)
```

### Style Guides

```markdown
## Industry Style Guides

- [Google Developer Documentation Style Guide](https://developers.google.com/style)
- [Microsoft Writing Style Guide](https://docs.microsoft.com/en-us/style-guide/)
- [Apple Style Guide](https://help.apple.com/applestyleguide/)
- [Red Hat Technical Writing Style Guide](https://stylepedia.net/)
```

---

## ✅ WRITING CHECKLIST

### Before Publishing

- [ ] Clear title and purpose statement
- [ ] Table of contents for long documents
- [ ] Prerequisites listed
- [ ] Code examples are complete and tested
- [ ] Screenshots/diagrams are up-to-date
- [ ] Links are working
- [ ] Spelling and grammar checked
- [ ] Consistent formatting
- [ ] Version/date information included
- [ ] Reviewed by another person

### Content Quality

- [ ] Uses active voice
- [ ] Present tense
- [ ] Short sentences (< 25 words)
- [ ] Short paragraphs (< 5 sentences)
- [ ] No jargon without explanation
- [ ] Specific, not vague
- [ ] Includes examples
- [ ] Addresses common errors

### Accessibility

- [ ] Alt text for images
- [ ] Descriptive link text
- [ ] Proper heading hierarchy
- [ ] Tables have headers
- [ ] Color is not the only indicator
- [ ] Code blocks have language specified

---

## 📚 REFERENCES

- [Write the Docs](https://www.writethedocs.org/)
- [The Documentation System](https://documentation.divio.com/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Plain Language Guidelines](https://www.plainlanguage.gov/guidelines/)
- [Butterick's Practical Typography](https://practicaltypography.com/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
