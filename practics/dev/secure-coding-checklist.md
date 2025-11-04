# Secure Coding Checklist - Danh Sách Kiểm Tra Lập Trình An Toàn

> Comprehensive checklist for writing secure code, preventing vulnerabilities
>
> **Mục đích**: Ngăn chặn lỗ hổng bảo mật từ giai đoạn development

---

## 📋 Mục Lục
- [Input Validation](#input-validation)
- [Authentication & Authorization](#authentication--authorization)
- [Cryptography](#cryptography)
- [SQL Injection Prevention](#sql-injection-prevention)
- [XSS Prevention](#xss-prevention)
- [CSRF Protection](#csrf-protection)
- [Secure Dependencies](#secure-dependencies)
- [Secrets Management](#secrets-management)

---

## 🔍 INPUT VALIDATION

### Never Trust User Input

```javascript
// ✅ GOOD - Validate and sanitize all input
const { body, validationResult } = require('express-validator');

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
        .withMessage('Invalid age')
], (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    // Process validated input
    const { email, username, age } = req.body;
    // ...
});

// ❌ BAD - Using input directly
app.post('/api/users', (req, res) => {
    const user = req.body;  // Dangerous!
    db.users.insert(user);
});
```

### Whitelist Validation

```javascript
// ✅ GOOD - Whitelist allowed values
const ALLOWED_SORT_FIELDS = ['name', 'email', 'created_at'];
const ALLOWED_SORT_ORDERS = ['asc', 'desc'];

function validateSortParams(sortBy, order) {
    if (!ALLOWED_SORT_FIELDS.includes(sortBy)) {
        throw new Error('Invalid sort field');
    }
    if (!ALLOWED_SORT_ORDERS.includes(order)) {
        throw new Error('Invalid sort order');
    }
    return { sortBy, order };
}

// Usage
const { sortBy, order } = validateSortParams(req.query.sortBy, req.query.order);
const users = await db.users.find().sort({ [sortBy]: order });

// ❌ BAD - Blacklist (can be bypassed)
const FORBIDDEN_FIELDS = ['password', 'secret_key'];
if (FORBIDDEN_FIELDS.includes(req.query.sortBy)) {
    throw new Error('Forbidden field');
}
```

### File Upload Validation

```javascript
// ✅ GOOD - Comprehensive file validation
const multer = require('multer');
const path = require('path');
const crypto = require('crypto');

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/gif'];
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

const storage = multer.diskStorage({
    destination: './uploads/',
    filename: (req, file, cb) => {
        // Generate random filename
        const randomName = crypto.randomBytes(16).toString('hex');
        const ext = path.extname(file.originalname);
        cb(null, `${randomName}${ext}`);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: MAX_FILE_SIZE },
    fileFilter: (req, file, cb) => {
        // Check MIME type
        if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
            return cb(new Error('Invalid file type'), false);
        }

        // Check file extension
        const ext = path.extname(file.originalname).toLowerCase();
        if (!['.jpg', '.jpeg', '.png', '.gif'].includes(ext)) {
            return cb(new Error('Invalid file extension'), false);
        }

        cb(null, true);
    }
});

// Additional validation after upload
const FileType = require('file-type');

app.post('/upload', upload.single('avatar'), async (req, res) => {
    try {
        // Verify actual file type (not just extension)
        const fileType = await FileType.fromFile(req.file.path);

        if (!ALLOWED_MIME_TYPES.includes(fileType.mime)) {
            fs.unlinkSync(req.file.path);  // Delete invalid file
            return res.status(400).json({ error: 'Invalid file type' });
        }

        res.json({ filename: req.file.filename });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});
```

---

## 🔐 AUTHENTICATION & AUTHORIZATION

### Password Security

```javascript
// ✅ GOOD - Secure password hashing
const bcrypt = require('bcrypt');

async function hashPassword(password) {
    // Validate password strength
    if (password.length < 12) {
        throw new Error('Password must be at least 12 characters');
    }

    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumbers = /\d/.test(password);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    if (!hasUpperCase || !hasLowerCase || !hasNumbers || !hasSpecialChar) {
        throw new Error('Password must contain uppercase, lowercase, number, and special character');
    }

    // Use bcrypt with appropriate cost factor
    const saltRounds = 12;
    return await bcrypt.hash(password, saltRounds);
}

async function verifyPassword(password, hash) {
    return await bcrypt.compare(password, hash);
}

// ❌ BAD - Weak password storage
function hashPassword(password) {
    return crypto.createHash('md5').update(password).digest('hex');  // Never use MD5!
}
```

### JWT Security

```javascript
// ✅ GOOD - Secure JWT implementation
const jwt = require('jsonwebtoken');

// Use environment variable for secret
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

function generateTokens(userId) {
    // Short-lived access token
    const accessToken = jwt.sign(
        { userId, type: 'access' },
        JWT_SECRET,
        {
            expiresIn: '15m',
            algorithm: 'HS256',
            issuer: 'myapp',
            audience: 'myapp-api'
        }
    );

    // Longer-lived refresh token
    const refreshToken = jwt.sign(
        { userId, type: 'refresh' },
        JWT_REFRESH_SECRET,
        {
            expiresIn: '7d',
            algorithm: 'HS256'
        }
    );

    return { accessToken, refreshToken };
}

function verifyAccessToken(token) {
    try {
        const decoded = jwt.verify(token, JWT_SECRET, {
            algorithms: ['HS256'],
            issuer: 'myapp',
            audience: 'myapp-api'
        });

        if (decoded.type !== 'access') {
            throw new Error('Invalid token type');
        }

        return decoded;
    } catch (error) {
        throw new Error('Invalid token');
    }
}

// Store refresh tokens in database for revocation
async function storeRefreshToken(userId, token) {
    await db.refresh_tokens.insert({
        user_id: userId,
        token_hash: crypto.createHash('sha256').update(token).digest('hex'),
        created_at: new Date(),
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    });
}

// ❌ BAD - Insecure JWT
const token = jwt.sign({ userId }, 'hardcoded-secret', { expiresIn: '30d' });
```

### Role-Based Access Control (RBAC)

```javascript
// ✅ GOOD - Proper authorization checks
const PERMISSIONS = {
    'user:read': ['user', 'admin'],
    'user:write': ['admin'],
    'user:delete': ['admin'],
    'post:read': ['user', 'admin', 'guest'],
    'post:write': ['user', 'admin'],
    'post:delete': ['admin']
};

function hasPermission(userRole, permission) {
    return PERMISSIONS[permission]?.includes(userRole) || false;
}

// Middleware
function requirePermission(permission) {
    return (req, res, next) => {
        const user = req.user;  // From authentication middleware

        if (!user) {
            return res.status(401).json({ error: 'Unauthorized' });
        }

        if (!hasPermission(user.role, permission)) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        next();
    };
}

// Usage
app.delete('/api/users/:id',
    authenticate,
    requirePermission('user:delete'),
    async (req, res) => {
        await db.users.delete(req.params.id);
        res.json({ success: true });
    }
);

// ❌ BAD - Client-controlled authorization
app.delete('/api/users/:id', async (req, res) => {
    if (req.body.isAdmin) {  // Client can set this!
        await db.users.delete(req.params.id);
    }
});
```

---

## 🔒 CRYPTOGRAPHY

### Encryption Best Practices

```javascript
// ✅ GOOD - AES-256-GCM encryption
const crypto = require('crypto');

class Encryptor {
    constructor(key) {
        // Key should be 32 bytes for AES-256
        this.key = Buffer.from(key, 'hex');
    }

    encrypt(plaintext) {
        // Generate random IV for each encryption
        const iv = crypto.randomBytes(16);

        const cipher = crypto.createCipheriv('aes-256-gcm', this.key, iv);

        let ciphertext = cipher.update(plaintext, 'utf8', 'hex');
        ciphertext += cipher.final('hex');

        // Get authentication tag
        const authTag = cipher.getAuthTag();

        // Return IV + auth tag + ciphertext
        return iv.toString('hex') + ':' + authTag.toString('hex') + ':' + ciphertext;
    }

    decrypt(encrypted) {
        const parts = encrypted.split(':');
        const iv = Buffer.from(parts[0], 'hex');
        const authTag = Buffer.from(parts[1], 'hex');
        const ciphertext = parts[2];

        const decipher = crypto.createDecipheriv('aes-256-gcm', this.key, iv);
        decipher.setAuthTag(authTag);

        let plaintext = decipher.update(ciphertext, 'hex', 'utf8');
        plaintext += decipher.final('utf8');

        return plaintext;
    }
}

// Usage
const encryptor = new Encryptor(process.env.ENCRYPTION_KEY);
const encrypted = encryptor.encrypt('sensitive data');
const decrypted = encryptor.decrypt(encrypted);

// ❌ BAD - Weak encryption
function encrypt(text) {
    const cipher = crypto.createCipher('aes192', 'password');  // Deprecated!
    return cipher.update(text, 'utf8', 'hex') + cipher.final('hex');
}
```

### Secure Random Generation

```javascript
// ✅ GOOD - Cryptographically secure random
const crypto = require('crypto');

function generateSecureToken(length = 32) {
    return crypto.randomBytes(length).toString('hex');
}

function generateSecureNumber(min, max) {
    const range = max - min + 1;
    const bytesNeeded = Math.ceil(Math.log2(range) / 8);
    const maxValue = Math.pow(256, bytesNeeded);

    let value;
    do {
        const bytes = crypto.randomBytes(bytesNeeded);
        value = bytes.readUIntBE(0, bytesNeeded);
    } while (value >= maxValue - (maxValue % range));

    return min + (value % range);
}

// ❌ BAD - Not cryptographically secure
function generateToken() {
    return Math.random().toString(36).substring(2);  // Don't use for security!
}
```

---

## 💉 SQL INJECTION PREVENTION

### Parameterized Queries

```javascript
// ✅ GOOD - Parameterized queries
const { Pool } = require('pg');
const pool = new Pool();

async function getUser(email) {
    const query = 'SELECT * FROM users WHERE email = $1';
    const result = await pool.query(query, [email]);
    return result.rows[0];
}

async function searchUsers(term) {
    const query = `
        SELECT id, name, email
        FROM users
        WHERE name ILIKE $1
        OR email ILIKE $1
    `;
    const result = await pool.query(query, [`%${term}%`]);
    return result.rows;
}

// ❌ BAD - String concatenation (SQL injection!)
async function getUser(email) {
    const query = `SELECT * FROM users WHERE email = '${email}'`;
    // Attacker can input: ' OR '1'='1' --
    const result = await pool.query(query);
    return result.rows[0];
}
```

### ORM Usage

```javascript
// ✅ GOOD - Using ORM safely
const { Sequelize, DataTypes } = require('sequelize');

const User = sequelize.define('User', {
    email: DataTypes.STRING,
    name: DataTypes.STRING
});

// Safe query
async function searchUsers(searchTerm) {
    return await User.findAll({
        where: {
            [Op.or]: [
                { name: { [Op.iLike]: `%${searchTerm}%` } },
                { email: { [Op.iLike]: `%${searchTerm}%` } }
            ]
        }
    });
}

// ⚠️ CAREFUL - Raw queries still need parameterization
async function customQuery(userId) {
    // ✅ GOOD - Parameterized raw query
    return await sequelize.query(
        'SELECT * FROM users WHERE id = ?',
        {
            replacements: [userId],
            type: QueryTypes.SELECT
        }
    );

    // ❌ BAD - String concatenation in raw query
    return await sequelize.query(
        `SELECT * FROM users WHERE id = ${userId}`
    );
}
```

---

## 🛡️ XSS PREVENTION

### Output Encoding

```javascript
// ✅ GOOD - Escape HTML entities
function escapeHtml(unsafe) {
    return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

// Template rendering with auto-escaping
app.get('/profile', (req, res) => {
    // Using template engine with auto-escaping (Handlebars, EJS)
    res.render('profile', {
        username: req.user.name  // Auto-escaped by template engine
    });
});

// API response
app.get('/api/users/:id', async (req, res) => {
    const user = await getUser(req.params.id);

    // Sanitize user-generated content
    res.json({
        id: user.id,
        name: escapeHtml(user.name),
        bio: escapeHtml(user.bio)
    });
});

// ❌ BAD - Raw HTML output
app.get('/profile', (req, res) => {
    res.send(`<h1>Welcome ${req.user.name}</h1>`);  // XSS vulnerable!
});
```

### Content Security Policy (CSP)

```javascript
// ✅ GOOD - Strict CSP headers
const helmet = require('helmet');

app.use(helmet.contentSecurityPolicy({
    directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],  // Avoid 'unsafe-inline' if possible
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", "data:", "https:"],
        connectSrc: ["'self'", "https://api.myapp.com"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
        upgradeInsecureRequests: []
    }
}));

// Better: Use nonces for inline scripts
app.use((req, res, next) => {
    res.locals.nonce = crypto.randomBytes(16).toString('base64');
    next();
});

app.use(helmet.contentSecurityPolicy({
    directives: {
        scriptSrc: ["'self'", (req, res) => `'nonce-${res.locals.nonce}'`]
    }
}));

// In template
// <script nonce="<%= nonce %>">...</script>
```

### DOMPurify for Rich Content

```javascript
// ✅ GOOD - Sanitize user HTML
const createDOMPurify = require('dompurify');
const { JSDOM } = require('jsdom');

const window = new JSDOM('').window;
const DOMPurify = createDOMPurify(window);

function sanitizeHtml(dirty) {
    return DOMPurify.sanitize(dirty, {
        ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br'],
        ALLOWED_ATTR: ['href', 'title'],
        ALLOWED_URI_REGEXP: /^(?:(?:https?|mailto):)/i
    });
}

// Usage
app.post('/api/posts', async (req, res) => {
    const cleanContent = sanitizeHtml(req.body.content);

    await db.posts.insert({
        title: req.body.title,
        content: cleanContent,
        author_id: req.user.id
    });

    res.json({ success: true });
});
```

---

## 🔰 CSRF PROTECTION

### CSRF Tokens

```javascript
// ✅ GOOD - CSRF protection
const csrf = require('csurf');
const cookieParser = require('cookie-parser');

app.use(cookieParser());
app.use(csrf({ cookie: true }));

// Send token to client
app.get('/form', (req, res) => {
    res.render('form', { csrfToken: req.csrfToken() });
});

// Validate token on POST
app.post('/api/submit', (req, res) => {
    // Token automatically validated by middleware
    // If invalid, returns 403 Forbidden
    processForm(req.body);
    res.json({ success: true });
});

// Frontend usage
// <form method="POST" action="/api/submit">
//     <input type="hidden" name="_csrf" value="<%= csrfToken %>">
// </form>

// Or in AJAX
// fetch('/api/submit', {
//     method: 'POST',
//     headers: {
//         'CSRF-Token': csrfToken
//     },
//     body: JSON.stringify(data)
// });
```

### SameSite Cookies

```javascript
// ✅ GOOD - Secure cookie configuration
app.use(session({
    secret: process.env.SESSION_SECRET,
    cookie: {
        httpOnly: true,        // Prevent JavaScript access
        secure: true,          // HTTPS only
        sameSite: 'strict',    // CSRF protection
        maxAge: 24 * 60 * 60 * 1000  // 24 hours
    },
    resave: false,
    saveUninitialized: false
}));

// Set custom cookie
res.cookie('auth_token', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: 3600000
});
```

---

## 📦 SECURE DEPENDENCIES

### Dependency Scanning

```bash
# ✅ GOOD - Regular security audits

# npm audit
npm audit
npm audit fix

# Check for outdated packages
npm outdated

# Use npm ci for reproducible builds
npm ci

# Snyk (third-party tool)
npx snyk test
npx snyk monitor

# OWASP Dependency Check
dependency-check --project MyApp --scan ./
```

### Package.json Security

```json
{
  "scripts": {
    "audit": "npm audit",
    "audit:fix": "npm audit fix",
    "preinstall": "npx npm-force-resolutions"
  },
  "resolutions": {
    "**/**/lodash": "^4.17.21",
    "**/**/minimist": "^1.2.6"
  }
}
```

### Lock Files

```bash
# ✅ GOOD - Commit lock files
git add package-lock.json
git add yarn.lock
git commit -m "Lock dependencies"

# ❌ BAD - Ignore lock files
# This leads to non-reproducible builds
```

---

## 🔑 SECRETS MANAGEMENT

### Environment Variables

```javascript
// ✅ GOOD - Load from environment
require('dotenv').config();

const config = {
    db: {
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME
    },
    jwt: {
        secret: process.env.JWT_SECRET,
        expiresIn: process.env.JWT_EXPIRES_IN || '15m'
    },
    encryption: {
        key: process.env.ENCRYPTION_KEY
    }
};

// Validate required variables
const required = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'JWT_SECRET', 'ENCRYPTION_KEY'];
for (const key of required) {
    if (!process.env[key]) {
        throw new Error(`Missing required environment variable: ${key}`);
    }
}

// ❌ BAD - Hardcoded secrets
const config = {
    db: {
        password: 'my_password_123'  // Never do this!
    },
    jwt: {
        secret: 'super-secret-key'
    }
};
```

### .env File Security

```bash
# ✅ GOOD - .env.example (committed)
DB_HOST=localhost
DB_USER=your_username
DB_PASSWORD=your_password
JWT_SECRET=your_secret_key
ENCRYPTION_KEY=your_encryption_key

# .env (NOT committed, in .gitignore)
DB_HOST=prod-db.example.com
DB_USER=prod_user
DB_PASSWORD=actual_secure_password_here
JWT_SECRET=actual_jwt_secret_here
ENCRYPTION_KEY=64_char_hex_encryption_key_here
```

```gitignore
# .gitignore
.env
.env.local
.env.production
*.pem
*.key
secrets/
```

### AWS Secrets Manager

```javascript
// ✅ GOOD - Use secrets manager for production
const AWS = require('aws-sdk');

async function getSecret(secretName) {
    const client = new AWS.SecretsManager({
        region: process.env.AWS_REGION
    });

    try {
        const data = await client.getSecretValue({ SecretId: secretName }).promise();

        if ('SecretString' in data) {
            return JSON.parse(data.SecretString);
        }
    } catch (error) {
        console.error('Error fetching secret:', error);
        throw error;
    }
}

// Load secrets at startup
async function initializeSecrets() {
    const secrets = await getSecret('myapp/production');

    process.env.DB_PASSWORD = secrets.DB_PASSWORD;
    process.env.JWT_SECRET = secrets.JWT_SECRET;
    process.env.ENCRYPTION_KEY = secrets.ENCRYPTION_KEY;
}
```

---

## ✅ SECURE CODING CHECKLIST

### General Security

- [ ] All user input validated and sanitized
- [ ] Parameterized queries used (no SQL injection)
- [ ] Output encoding prevents XSS
- [ ] CSRF protection enabled
- [ ] Strong password requirements enforced
- [ ] Secure password hashing (bcrypt, argon2)
- [ ] JWT tokens properly validated
- [ ] Role-based access control implemented
- [ ] HTTPS enforced in production
- [ ] Security headers configured (helmet.js)

### Authentication & Authorization

- [ ] Multi-factor authentication available
- [ ] Account lockout after failed attempts
- [ ] Password reset tokens expire
- [ ] Session tokens stored securely
- [ ] Logout invalidates all tokens
- [ ] Authorization checked on every request
- [ ] Resource ownership verified

### Data Protection

- [ ] Sensitive data encrypted at rest
- [ ] Sensitive data encrypted in transit (TLS)
- [ ] PII properly anonymized in logs
- [ ] Database backups encrypted
- [ ] Encryption keys rotated regularly
- [ ] Secrets stored in secrets manager

### Dependencies

- [ ] Dependencies regularly updated
- [ ] Security audits run (npm audit)
- [ ] Lock files committed
- [ ] Only necessary dependencies installed
- [ ] Dependencies from trusted sources

### Logging & Monitoring

- [ ] Security events logged
- [ ] Failed authentication attempts logged
- [ ] Sensitive data not logged
- [ ] Log injection prevented
- [ ] Monitoring alerts configured
- [ ] Regular security reviews scheduled

---

## 📚 REFERENCES

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)
- [Snyk Security Knowledge Base](https://snyk.io/learn/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
