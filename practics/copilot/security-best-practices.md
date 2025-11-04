# Rule: Security Best Practices & Secure Coding

## Intent
Prevent common security vulnerabilities and enforce secure coding practices based on OWASP Top 10 and industry standards. Copilot must detect security risks and suggest secure alternatives.

## Scope
Applies to all code generation, authentication, data handling, API development, and security-sensitive operations.

---

## 1. OWASP Top 10 - Critical Security Rules

### A01: Broken Access Control

- ✅ **MUST** verify user permissions before resource access
- ✅ **MUST** implement authorization checks on every request
- ✅ **MUST** use principle of least privilege
- ✅ **MUST** deny by default
- ❌ **MUST NOT** rely on client-side authorization
- ❌ **MUST NOT** expose direct object references (IDOR)

```javascript
// ❌ BAD - Insecure Direct Object Reference
app.get('/api/users/:id/profile', (req, res) => {
    const profile = db.getProfile(req.params.id);
    res.json(profile);  // Any user can access any profile!
});

// ✅ GOOD - Authorization check
app.get('/api/users/:id/profile', (req, res) => {
    if (req.user.id !== req.params.id && !req.user.isAdmin) {
        return res.status(403).json({ error: 'Access denied' });
    }
    const profile = db.getProfile(req.params.id);
    res.json(profile);
});
```

### A02: Cryptographic Failures

**Password Hashing**
- ✅ **MUST** use bcrypt/argon2 (cost factor ≥ 12)
- ✅ **MUST** salt passwords automatically
- ❌ **MUST NOT** use MD5, SHA1, or plain text
- ❌ **MUST NOT** implement custom crypto

```javascript
// ✅ GOOD - bcrypt with proper cost
const bcrypt = require('bcrypt');

async function hashPassword(password) {
    const saltRounds = 12;
    return await bcrypt.hash(password, saltRounds);
}

async function verifyPassword(password, hash) {
    return await bcrypt.compare(password, hash);
}

// ❌ BAD - Weak hashing
const hash = crypto.createHash('md5').update(password).digest('hex');
```

**Data Encryption**
- ✅ **MUST** use AES-256-GCM for encryption
- ✅ **MUST** generate random IV for each encryption
- ✅ **MUST** use authenticated encryption
- ✅ **MUST** store encryption keys in environment variables
- ❌ **MUST NOT** hardcode encryption keys

```javascript
// ✅ GOOD - AES-256-GCM with random IV
const crypto = require('crypto');

function encrypt(plaintext, key) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

    let ciphertext = cipher.update(plaintext, 'utf8', 'hex');
    ciphertext += cipher.final('hex');

    const authTag = cipher.getAuthTag();
    return iv.toString('hex') + ':' + authTag.toString('hex') + ':' + ciphertext;
}
```

### A03: Injection Attacks

**SQL Injection Prevention**
- ✅ **MUST** use parameterized queries/prepared statements
- ✅ **MUST** use ORMs properly
- ✅ **MUST** validate and sanitize input
- ❌ **MUST NOT** concatenate user input into SQL

```javascript
// ✅ GOOD - Parameterized query
async function getUser(email) {
    const query = 'SELECT * FROM users WHERE email = $1';
    return await pool.query(query, [email]);
}

// ❌ BAD - SQL injection vulnerable
async function getUser(email) {
    const query = `SELECT * FROM users WHERE email = '${email}'`;
    return await pool.query(query);
}
```

**NoSQL Injection Prevention**
```javascript
// ✅ GOOD - Type coercion and validation
async function login(req, res) {
    const username = String(req.body.username);
    const password = String(req.body.password);

    const user = await User.findOne({ username });
    if (user && await bcrypt.compare(password, user.passwordHash)) {
        // Success
    }
}

// ❌ BAD - NoSQL injection vulnerable
async function login(req, res) {
    const user = await User.findOne({
        username: req.body.username,  // Can be {"$ne": null}
        password: req.body.password
    });
}
```

**Command Injection Prevention**
- ✅ **MUST** avoid shell execution with user input
- ✅ **MUST** use subprocess with list arguments (no shell)
- ✅ **MUST** validate input against whitelist

```python
# ✅ GOOD - Safe subprocess
import subprocess
import re

def ping_host(hostname):
    if not re.match(r'^[a-zA-Z0-9.-]+$', hostname):
        raise ValueError("Invalid hostname")

    result = subprocess.run(
        ['ping', '-c', '1', hostname],
        capture_output=True,
        timeout=5
    )
    return result.returncode == 0

# ❌ BAD - Command injection
import os
def ping_host(hostname):
    os.system(f"ping -c 1 {hostname}")  # Vulnerable!
```

### A04: Insecure Design

**Rate Limiting (Required)**
- ✅ **MUST** implement rate limiting on all endpoints
- ✅ **MUST** have stricter limits on auth endpoints (5 attempts/15 min)
- ✅ **MUST** implement account lockout after failed attempts

```javascript
// ✅ GOOD - Rate limiting
import rateLimit from 'express-rate-limit';

const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
});

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    skipSuccessfulRequests: true
});

app.use('/api/', generalLimiter);
app.use('/api/auth/login', authLimiter);
```

**Account Lockout**
```javascript
// ✅ GOOD - Account lockout mechanism
async function handleFailedLogin(username) {
    await incrementFailedAttempts(username);
    const attempts = await getFailedAttempts(username);

    if (attempts >= 5) {
        await lockAccount(username, 30 * 60);  // 30 minutes
        throw new Error('Account locked due to too many failed attempts');
    }
}
```

### A05: Security Misconfiguration

**Security Headers (Required)**
```javascript
// ✅ GOOD - Security headers with Helmet
import helmet from 'helmet';

app.use(helmet());

// Or manual configuration
app.use((req, res, next) => {
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    res.setHeader('Content-Security-Policy', "default-src 'self'");
    next();
});
```

**Error Handling**
- ✅ **MUST** log detailed errors for developers
- ✅ **MUST** return generic errors to users
- ❌ **MUST NOT** expose stack traces in production
- ❌ **MUST NOT** leak internal information

```javascript
// ✅ GOOD - Safe error handling
app.use((err, req, res, next) => {
    logger.error('Error', {
        error: err.message,
        stack: err.stack,
        url: req.url,
        userId: req.user?.id
    });

    res.status(500).json({
        error: 'Internal server error',
        requestId: req.id
    });
});

// ❌ BAD - Exposes sensitive info
app.use((err, req, res, next) => {
    res.status(500).json({
        error: err.message,
        stack: err.stack  // Security risk!
    });
});
```

### A06: Vulnerable Components

**Dependency Management**
- ✅ **MUST** run `npm audit` regularly
- ✅ **MUST** keep dependencies updated
- ✅ **MUST** use lock files (package-lock.json)
- ✅ **MUST** remove unused dependencies
- ✅ **SHOULD** use automated scanning (Snyk, Dependabot)

```bash
# Check vulnerabilities
npm audit
npm audit fix

# Use exact versions
{
    "dependencies": {
        "express": "4.18.2"  # Not "^4.18.2"
    }
}
```

### A07: Authentication Failures

**JWT Security**
- ✅ **MUST** use short expiration times (15 minutes for access tokens)
- ✅ **MUST** use HTTPS only
- ✅ **MUST** validate issuer, audience, algorithm
- ✅ **MUST** implement token refresh mechanism
- ❌ **MUST NOT** store sensitive data in JWT
- ❌ **MUST NOT** use `none` algorithm

```javascript
// ✅ GOOD - Secure JWT
const jwt = require('jsonwebtoken');

function generateAccessToken(userId) {
    return jwt.sign(
        { userId, type: 'access' },
        process.env.JWT_SECRET,
        {
            expiresIn: '15m',
            algorithm: 'HS256',
            issuer: 'myapp',
            audience: 'myapp-api'
        }
    );
}

function verifyToken(token) {
    return jwt.verify(token, process.env.JWT_SECRET, {
        algorithms: ['HS256'],
        issuer: 'myapp',
        audience: 'myapp-api'
    });
}
```

**Session Management**
- ✅ **MUST** use secure, httpOnly cookies
- ✅ **MUST** regenerate session ID after login
- ✅ **MUST** implement session timeout (30 minutes)
- ✅ **MUST** use sameSite='strict' for CSRF protection

```javascript
// ✅ GOOD - Secure sessions
app.use(session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: true,       // HTTPS only
        httpOnly: true,     // No JavaScript access
        maxAge: 1800000,    // 30 minutes
        sameSite: 'strict'  // CSRF protection
    }
}));
```

**Multi-Factor Authentication**
- ✅ **SHOULD** implement MFA for sensitive operations
- ✅ **MUST** support TOTP (Time-based OTP)

### A08: Software Integrity Failures

- ✅ **MUST** use package lock files
- ✅ **MUST** verify package integrity
- ✅ **SHOULD** sign Git commits
- ✅ **SHOULD** use CI/CD pipeline security

```bash
# Verify package integrity
npm install --integrity

# Sign Git commits
git config commit.gpgsign true
git commit -S -m "feat: add feature"
```

### A09: Logging & Monitoring

**Security Event Logging (Required)**
- ✅ **MUST** log all authentication attempts
- ✅ **MUST** log authorization failures
- ✅ **MUST** log data access/modifications
- ✅ **MUST** include timestamp, user ID, IP, action
- ❌ **MUST NOT** log sensitive data (passwords, tokens)

```javascript
// ✅ GOOD - Comprehensive logging
const winston = require('winston');

function logSecurityEvent(event, details) {
    logger.warn('Security Event', {
        event,
        timestamp: new Date().toISOString(),
        ip: details.ip,
        userId: details.userId,
        userAgent: details.userAgent,
        ...details
    });
}

// Log failed login
app.post('/login', async (req, res) => {
    const result = await authenticateUser(req.body.username, req.body.password);

    if (!result.success) {
        logSecurityEvent('LOGIN_FAILED', {
            username: req.body.username,
            ip: req.ip,
            userAgent: req.get('user-agent')
        });
    }
});
```

**Anomaly Detection**
```javascript
// ✅ GOOD - Detect suspicious activity
async function detectAnomalies(userId) {
    const recentLogins = await getRecentLogins(userId, 24);

    // Multiple failed attempts
    const failedCount = recentLogins.filter(l => !l.success).length;
    if (failedCount > 5) {
        await alertSecurityTeam('Multiple failed logins', { userId });
    }

    // Login from new location
    const currentCountry = await getCountryFromIP(req.ip);
    const usualCountries = await getUserUsualCountries(userId);
    if (!usualCountries.includes(currentCountry)) {
        await alertUser('Login from new location', { userId, country: currentCountry });
    }
}
```

### A10: Server-Side Request Forgery (SSRF)

- ✅ **MUST** validate and whitelist URLs
- ✅ **MUST** block private IP ranges
- ✅ **MUST** block cloud metadata endpoints
- ❌ **MUST NOT** accept arbitrary URLs from users

```python
# ✅ GOOD - SSRF prevention
from urllib.parse import urlparse
import socket

ALLOWED_DOMAINS = ['example.com', 'api.example.com']
BLOCKED_IPS = ['127.0.0.1', '0.0.0.0', '169.254.169.254']

def fetch_url(url):
    parsed = urlparse(url)

    # Check scheme
    if parsed.scheme not in ['http', 'https']:
        raise ValueError('Invalid scheme')

    # Check domain
    if parsed.hostname not in ALLOWED_DOMAINS:
        raise ValueError('Domain not allowed')

    # Check resolved IP
    ip = socket.gethostbyname(parsed.hostname)
    if ip in BLOCKED_IPS or ip.startswith(('10.', '192.168.', '172.')):
        raise ValueError('IP not allowed')

    return requests.get(url, timeout=5)
```

---

## 2. Input Validation

### Validation Rules

- ✅ **MUST** validate all user input (body, query, params, headers)
- ✅ **MUST** use whitelist validation
- ✅ **MUST** validate data types, length, format, range
- ✅ **MUST** sanitize input before use
- ❌ **MUST NOT** trust client-side validation

```javascript
// ✅ GOOD - Comprehensive validation
const { body, query, param, validationResult } = require('express-validator');

app.post('/api/users', [
    body('email')
        .isEmail()
        .normalizeEmail()
        .withMessage('Invalid email'),
    body('username')
        .isLength({ min: 3, max: 30 })
        .matches(/^[a-zA-Z0-9_]+$/)
        .withMessage('Username must be alphanumeric'),
    body('age')
        .optional()
        .isInt({ min: 0, max: 150 })
], (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    // Process validated input
});
```

### Whitelist Validation

```javascript
// ✅ GOOD - Whitelist allowed values
const ALLOWED_SORT_FIELDS = ['name', 'email', 'created_at'];
const ALLOWED_SORT_ORDERS = ['asc', 'desc'];

function validateSort(sortBy, order) {
    if (!ALLOWED_SORT_FIELDS.includes(sortBy)) {
        throw new Error('Invalid sort field');
    }
    if (!ALLOWED_SORT_ORDERS.includes(order)) {
        throw new Error('Invalid sort order');
    }
    return { sortBy, order };
}
```

### File Upload Security

- ✅ **MUST** validate MIME type and extension
- ✅ **MUST** verify actual file content (magic bytes)
- ✅ **MUST** limit file size (< 5MB typical)
- ✅ **MUST** generate random filenames
- ✅ **MUST** store files outside webroot
- ❌ **MUST NOT** execute uploaded files
- ❌ **MUST NOT** trust client-provided filename

```javascript
// ✅ GOOD - Secure file upload
const multer = require('multer');
const FileType = require('file-type');

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png'];
const MAX_SIZE = 5 * 1024 * 1024;

const upload = multer({
    storage: multer.diskStorage({
        destination: './uploads/',
        filename: (req, file, cb) => {
            const randomName = crypto.randomBytes(16).toString('hex');
            cb(null, randomName + path.extname(file.originalname));
        }
    }),
    limits: { fileSize: MAX_SIZE },
    fileFilter: (req, file, cb) => {
        if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
            return cb(new Error('Invalid file type'), false);
        }
        cb(null, true);
    }
});

app.post('/upload', upload.single('file'), async (req, res) => {
    // Verify actual file type
    const fileType = await FileType.fromFile(req.file.path);
    if (!ALLOWED_MIME_TYPES.includes(fileType.mime)) {
        fs.unlinkSync(req.file.path);
        return res.status(400).json({ error: 'Invalid file' });
    }
    res.json({ filename: req.file.filename });
});
```

---

## 3. XSS Prevention

### Output Encoding

- ✅ **MUST** escape HTML entities in output
- ✅ **MUST** use template engines with auto-escaping
- ✅ **MUST** sanitize user-generated HTML
- ❌ **MUST NOT** use `innerHTML` with user data

```javascript
// ✅ GOOD - Escape HTML
function escapeHtml(unsafe) {
    return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

// ❌ BAD - XSS vulnerable
res.send(`<h1>Welcome ${req.user.name}</h1>`);

// ✅ GOOD - Use template engine
res.render('welcome', { name: req.user.name });
```

### Content Security Policy

```javascript
// ✅ GOOD - Strict CSP
app.use(helmet.contentSecurityPolicy({
    directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
        objectSrc: ["'none'"],
        upgradeInsecureRequests: []
    }
}));
```

### Sanitize Rich Content

```javascript
// ✅ GOOD - DOMPurify for user HTML
const DOMPurify = require('dompurify');

function sanitizeHtml(dirty) {
    return DOMPurify.sanitize(dirty, {
        ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p'],
        ALLOWED_ATTR: ['href'],
        ALLOWED_URI_REGEXP: /^https?:/i
    });
}
```

---

## 4. CSRF Protection

- ✅ **MUST** implement CSRF tokens for state-changing operations
- ✅ **MUST** use SameSite cookies
- ✅ **MUST** validate Origin/Referer headers
- ✅ **SHOULD** use double-submit cookie pattern

```javascript
// ✅ GOOD - CSRF tokens
const csrf = require('csurf');
app.use(csrf({ cookie: true }));

app.get('/form', (req, res) => {
    res.render('form', { csrfToken: req.csrfToken() });
});

app.post('/submit', (req, res) => {
    // Token automatically validated
    processForm(req.body);
});
```

---

## 5. Secrets Management

- ✅ **MUST** store secrets in environment variables
- ✅ **MUST** use secret management services (AWS Secrets Manager, Vault)
- ✅ **MUST** rotate secrets regularly
- ✅ **MUST** use different secrets per environment
- ❌ **MUST NOT** hardcode secrets in code
- ❌ **MUST NOT** commit secrets to git

```javascript
// ✅ GOOD - Environment variables
const config = {
    jwtSecret: process.env.JWT_SECRET,
    dbPassword: process.env.DB_PASSWORD,
    apiKey: process.env.API_KEY
};

// ❌ BAD - Hardcoded secrets
const config = {
    jwtSecret: 'hardcoded-secret-123',
    apiKey: 'sk_live_abc123'
};
```

**Git Secrets Prevention**
```bash
# Use .gitignore
echo ".env" >> .gitignore
echo "config/secrets.json" >> .gitignore

# Use git-secrets tool
git secrets --install
git secrets --register-aws
```

---

## 6. API Security

### Authentication
- ✅ **MUST** use Bearer tokens (JWT) or API keys
- ✅ **MUST** validate on every request
- ✅ **MUST** use HTTPS only
- ❌ **MUST NOT** pass credentials in URL

### CORS Configuration
```javascript
// ✅ GOOD - Restrict CORS
const cors = require('cors');

app.use(cors({
    origin: ['https://myapp.com'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// ❌ BAD - Permissive CORS
app.use(cors({ origin: '*' }));
```

---

## 7. Copilot-Specific Instructions

### Auto-Detection Rules

When generating code, Copilot **MUST**:

1. **DETECT** SQL injection risks (string concatenation in queries)
2. **DETECT** XSS vulnerabilities (unescaped output)
3. **DETECT** hardcoded secrets
4. **DETECT** missing authentication checks
5. **DETECT** weak cryptography
6. **DETECT** command injection risks
7. **ENFORCE** input validation on all endpoints
8. **ENFORCE** parameterized queries
9. **SUGGEST** rate limiting for sensitive endpoints
10. **WARN** about security misconfigurations

### Security Alert Format

```markdown
🚨 **SECURITY RISK:** SQL Injection Vulnerability

**Location:** Line 42
\`\`\`javascript
const query = \`SELECT * FROM users WHERE id = \${userId}\`;
\`\`\`

**Risk Level:** Critical
**Impact:** Attacker can execute arbitrary SQL

✅ **Secure Fix:**
\`\`\`javascript
const query = 'SELECT * FROM users WHERE id = $1';
const result = await pool.query(query, [userId]);
\`\`\`

**Reference:** OWASP A03:2021 - Injection
```

### Pre-Commit Security Checklist

Before suggesting code, verify:
- [ ] No hardcoded secrets or credentials
- [ ] All inputs validated and sanitized
- [ ] SQL queries parameterized
- [ ] Output properly escaped
- [ ] Authentication/authorization implemented
- [ ] Error messages don't leak sensitive info
- [ ] HTTPS used for sensitive operations
- [ ] Rate limiting considered
- [ ] Logging implemented (without sensitive data)
- [ ] Security headers configured

---

## 8. Quick Security Checklist

### Authentication & Authorization
- [ ] Strong password policy (min 12 chars, complexity)
- [ ] Passwords hashed with bcrypt (cost ≥ 12)
- [ ] JWT with short expiration (15 min)
- [ ] MFA implemented for sensitive operations
- [ ] Authorization checks on all endpoints
- [ ] Session timeout configured
- [ ] Rate limiting on auth endpoints

### Input Validation
- [ ] All inputs validated (body, query, params)
- [ ] Whitelist validation used
- [ ] File uploads validated (type, size, content)
- [ ] SQL queries parameterized
- [ ] No command injection risks

### Output & XSS
- [ ] HTML entities escaped
- [ ] CSP headers configured
- [ ] Template engines with auto-escaping
- [ ] User HTML sanitized (DOMPurify)

### Cryptography
- [ ] AES-256-GCM for encryption
- [ ] Random IV for each encryption
- [ ] TLS 1.2+ for transport
- [ ] Secrets in environment variables
- [ ] No weak algorithms (MD5, SHA1)

### API Security
- [ ] HTTPS enforced
- [ ] CORS properly configured
- [ ] Rate limiting implemented
- [ ] Security headers (Helmet)
- [ ] Error handling doesn't leak info

### Infrastructure
- [ ] Dependencies updated regularly
- [ ] npm audit passing
- [ ] Logging enabled (no sensitive data)
- [ ] Monitoring and alerts configured
- [ ] Backups encrypted

---

## References

- OWASP Top 10 2021
- OWASP Cheat Sheet Series
- CWE Top 25 Most Dangerous Software Weaknesses
- NIST Cybersecurity Framework
- PCI DSS Requirements

**Remember:** Security is not a feature, it's a requirement. Always assume all input is malicious and validate/sanitize everything.
