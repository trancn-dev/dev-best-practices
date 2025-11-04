# Security Best Practices - Nguyên Tắc Bảo Mật

> Hướng dẫn chi tiết về bảo mật ứng dụng dựa trên OWASP Top 10 và industry standards
>
> **Mục đích**: Bảo vệ ứng dụng khỏi các lỗ hổng bảo mật phổ biến

---

## 📋 Mục Lục
- [OWASP Top 10](#owasp-top-10)
- [Authentication & Authorization](#authentication--authorization)
- [Input Validation](#input-validation)
- [Data Protection](#data-protection)
- [API Security](#api-security)
- [Dependency Security](#dependency-security)
- [Infrastructure Security](#infrastructure-security)
- [Security Checklist](#security-checklist)

---

## 🛡️ OWASP TOP 10 (2021)

### 1️⃣ Broken Access Control

**Vấn đề**: User có thể truy cập tài nguyên không được phép

```javascript
// ❌ BAD - Insecure Direct Object Reference (IDOR)
app.get('/api/users/:id/profile', (req, res) => {
    const profile = db.getProfile(req.params.id);
    res.json(profile);  // Any user can access any profile!
});

// ✅ GOOD - Check authorization
app.get('/api/users/:id/profile', async (req, res) => {
    const requestedUserId = req.params.id;
    const currentUser = req.user;

    // Check if user can access this profile
    if (currentUser.id !== requestedUserId && !currentUser.isAdmin) {
        return res.status(403).json({ error: 'Access denied' });
    }

    const profile = await db.getProfile(requestedUserId);
    res.json(profile);
});
```

**Prevention:**
- ✅ Implement proper authorization checks
- ✅ Deny by default
- ✅ Use centralized authorization logic
- ✅ Log access control failures

---

### 2️⃣ Cryptographic Failures

**Vấn đề**: Dữ liệu nhạy cảm bị lộ do mã hóa yếu hoặc không mã hóa

```python
# ❌ BAD - Plain text password
def create_user(username, password):
    user = User(username=username, password=password)
    db.save(user)

# ✅ GOOD - Hash password with bcrypt
import bcrypt

def create_user(username, password):
    # Generate salt and hash password
    salt = bcrypt.gensalt(rounds=12)
    password_hash = bcrypt.hashpw(password.encode('utf-8'), salt)

    user = User(username=username, password_hash=password_hash)
    db.save(user)

def verify_password(username, password):
    user = db.get_user(username)
    return bcrypt.checkpw(
        password.encode('utf-8'),
        user.password_hash
    )
```

**Mã hóa dữ liệu nhạy cảm:**

```typescript
// ✅ GOOD - Encrypt sensitive data at rest
import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY; // 32 bytes

function encrypt(text: string): string {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(ALGORITHM, ENCRYPTION_KEY, iv);

    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    const authTag = cipher.getAuthTag();

    return iv.toString('hex') + ':' + authTag.toString('hex') + ':' + encrypted;
}

function decrypt(encrypted: string): string {
    const parts = encrypted.split(':');
    const iv = Buffer.from(parts[0], 'hex');
    const authTag = Buffer.from(parts[1], 'hex');
    const encryptedText = parts[2];

    const decipher = crypto.createDecipheriv(ALGORITHM, ENCRYPTION_KEY, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
}

// Usage
const creditCard = '4111-1111-1111-1111';
const encrypted = encrypt(creditCard);
db.save({ creditCard: encrypted });
```

**Prevention:**
- ✅ Use strong encryption (AES-256)
- ✅ Hash passwords with bcrypt/argon2
- ✅ Use HTTPS for data in transit
- ✅ Never store sensitive data in plain text
- ✅ Rotate encryption keys regularly

---

### 3️⃣ Injection Attacks

#### SQL Injection

```java
// ❌ BAD - SQL Injection vulnerability
public User getUser(String userId) {
    String query = "SELECT * FROM users WHERE id = " + userId;
    return db.execute(query);
}
// Attack: userId = "1 OR 1=1" returns all users!

// ✅ GOOD - Parameterized query
public User getUser(String userId) {
    String query = "SELECT * FROM users WHERE id = ?";
    return db.execute(query, userId);
}

// ✅ GOOD - Using ORM
public User getUser(String userId) {
    return User.findById(userId);
}
```

#### NoSQL Injection

```javascript
// ❌ BAD - NoSQL injection
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    const user = await db.collection('users').findOne({
        username: username,
        password: password
    });
    // Attack: { "username": {"$ne": null}, "password": {"$ne": null} }
});

// ✅ GOOD - Sanitize input
app.post('/login', async (req, res) => {
    const username = String(req.body.username);
    const password = String(req.body.password);

    const user = await db.collection('users').findOne({
        username: username
    });

    if (user && await bcrypt.compare(password, user.passwordHash)) {
        // Success
    }
});
```

#### Command Injection

```python
# ❌ BAD - Command injection
import os

def ping_host(hostname):
    os.system(f"ping -c 1 {hostname}")
    # Attack: hostname = "google.com; rm -rf /"

# ✅ GOOD - Use safe libraries
import subprocess

def ping_host(hostname):
    # Validate hostname format
    if not re.match(r'^[a-zA-Z0-9.-]+$', hostname):
        raise ValueError("Invalid hostname")

    # Use subprocess with list arguments (no shell)
    result = subprocess.run(
        ['ping', '-c', '1', hostname],
        capture_output=True,
        timeout=5
    )
    return result.returncode == 0
```

**Prevention:**
- ✅ Use parameterized queries/prepared statements
- ✅ Use ORMs properly
- ✅ Validate and sanitize all inputs
- ✅ Use allow-lists, not deny-lists
- ✅ Avoid shell execution with user input

---

### 4️⃣ Insecure Design

**Vấn đề**: Thiếu security controls trong thiết kế

```typescript
// ❌ BAD - No rate limiting on sensitive endpoint
app.post('/api/login', async (req, res) => {
    const { username, password } = req.body;
    const user = await authenticateUser(username, password);
    // Attacker can brute force passwords!
});

// ✅ GOOD - Rate limiting implemented
import rateLimit from 'express-rate-limit';

const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // 5 requests per window
    message: 'Too many login attempts, please try again later',
    standardHeaders: true,
    legacyHeaders: false,
});

app.post('/api/login', loginLimiter, async (req, res) => {
    const { username, password } = req.body;
    const user = await authenticateUser(username, password);

    // Implement account lockout after failed attempts
    if (!user) {
        await incrementFailedAttempts(username);
        if (await shouldLockAccount(username)) {
            await lockAccount(username);
            return res.status(429).json({
                error: 'Account locked due to too many failed attempts'
            });
        }
    }
});
```

**Prevention:**
- ✅ Threat modeling
- ✅ Secure by design principles
- ✅ Rate limiting
- ✅ Account lockout mechanisms
- ✅ Security reviews in design phase

---

### 5️⃣ Security Misconfiguration

```javascript
// ❌ BAD - Exposing error details
app.use((err, req, res, next) => {
    res.status(500).json({
        error: err.message,
        stack: err.stack,  // Leaks internal information!
        query: req.query
    });
});

// ✅ GOOD - Generic error message for users
app.use((err, req, res, next) => {
    // Log detailed error for developers
    logger.error('Error occurred', {
        error: err.message,
        stack: err.stack,
        url: req.url,
        method: req.method,
        userId: req.user?.id
    });

    // Return generic message to user
    res.status(500).json({
        error: 'Internal server error'
    });
});
```

**Security Headers:**

```javascript
// ✅ GOOD - Security headers with Helmet
import helmet from 'helmet';

app.use(helmet());

// Or configure manually
app.use((req, res, next) => {
    // Prevent clickjacking
    res.setHeader('X-Frame-Options', 'DENY');

    // XSS protection
    res.setHeader('X-XSS-Protection', '1; mode=block');

    // Prevent MIME sniffing
    res.setHeader('X-Content-Type-Options', 'nosniff');

    // HTTPS only
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');

    // Content Security Policy
    res.setHeader('Content-Security-Policy', "default-src 'self'");

    next();
});
```

**Prevention:**
- ✅ Remove default credentials
- ✅ Disable unnecessary features
- ✅ Keep software updated
- ✅ Use security headers
- ✅ Hide server information

---

### 6️⃣ Vulnerable and Outdated Components

```bash
# Check for vulnerabilities
npm audit
npm audit fix

# Use Snyk or similar tools
npx snyk test
```

```json
// package.json - Pin versions
{
    "dependencies": {
        "express": "4.18.2",  // Exact version, not "^4.18.2"
        "jsonwebtoken": "9.0.0"
    }
}
```

**Prevention:**
- ✅ Regular dependency updates
- ✅ Monitor security advisories
- ✅ Use `npm audit` / `yarn audit`
- ✅ Automated dependency scanning
- ✅ Remove unused dependencies

---

### 7️⃣ Identification and Authentication Failures

```typescript
// ❌ BAD - Weak session management
app.post('/login', async (req, res) => {
    const user = await authenticateUser(req.body.username, req.body.password);
    if (user) {
        req.session.userId = user.id;  // Predictable session ID
    }
});

// ✅ GOOD - Secure session management
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const redisClient = createClient();

app.use(session({
    store: new RedisStore({ client: redisClient }),
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: true,      // HTTPS only
        httpOnly: true,    // No JavaScript access
        maxAge: 1800000,   // 30 minutes
        sameSite: 'strict' // CSRF protection
    }
}));

// Implement multi-factor authentication
async function verifyMFA(userId: string, code: string): Promise<boolean> {
    const secret = await getUserMFASecret(userId);
    return speakeasy.totp.verify({
        secret: secret,
        encoding: 'base32',
        token: code,
        window: 1
    });
}
```

**Password Requirements:**

```javascript
// ✅ GOOD - Strong password policy
function validatePassword(password) {
    const minLength = 12;
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumbers = /\d/.test(password);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    if (password.length < minLength) {
        throw new Error('Password must be at least 12 characters');
    }

    if (!hasUpperCase || !hasLowerCase || !hasNumbers || !hasSpecialChar) {
        throw new Error('Password must contain uppercase, lowercase, number, and special character');
    }

    // Check against common passwords
    if (isCommonPassword(password)) {
        throw new Error('Password is too common');
    }

    return true;
}
```

**Prevention:**
- ✅ Multi-factor authentication
- ✅ Strong password requirements
- ✅ Secure session management
- ✅ Rate limiting on auth endpoints
- ✅ Account lockout after failed attempts

---

### 8️⃣ Software and Data Integrity Failures

```javascript
// ❌ BAD - Accepting unsigned/unverified packages
npm install some-package

// ✅ GOOD - Verify package integrity
npm install some-package --integrity

// Use lock files
// package-lock.json (npm)
// yarn.lock (yarn)
// pnpm-lock.yaml (pnpm)
```

**Code Signing:**

```bash
# Sign Git commits
git config --global user.signingkey YOUR_GPG_KEY
git config --global commit.gpgsign true
git commit -S -m "feat: add feature"
```

**Prevention:**
- ✅ Use package lock files
- ✅ Verify digital signatures
- ✅ Use trusted repositories
- ✅ Implement CI/CD pipeline security
- ✅ Code signing

---

### 9️⃣ Security Logging and Monitoring Failures

```typescript
// ✅ GOOD - Comprehensive logging
import winston from 'winston';

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.json(),
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' })
    ]
});

// Log security events
function logSecurityEvent(event: string, details: any) {
    logger.warn('Security Event', {
        event,
        timestamp: new Date().toISOString(),
        ip: details.ip,
        userId: details.userId,
        userAgent: details.userAgent,
        ...details
    });
}

// Examples
app.post('/login', async (req, res) => {
    const result = await authenticateUser(req.body.username, req.body.password);

    if (!result.success) {
        logSecurityEvent('LOGIN_FAILED', {
            username: req.body.username,
            ip: req.ip,
            userAgent: req.get('user-agent')
        });
    } else {
        logSecurityEvent('LOGIN_SUCCESS', {
            userId: result.user.id,
            ip: req.ip
        });
    }
});

// Monitor for suspicious activity
async function detectAnomalies(userId: string) {
    const recentLogins = await getRecentLogins(userId);

    // Check for multiple failed attempts
    const failedAttempts = recentLogins.filter(l => !l.success).length;
    if (failedAttempts > 5) {
        await alertSecurityTeam('Multiple failed login attempts', { userId });
    }

    // Check for login from unusual location
    const usualCountries = await getUserUsualCountries(userId);
    const currentCountry = await getCountryFromIP(req.ip);
    if (!usualCountries.includes(currentCountry)) {
        await alertUser('Login from new location', { userId, country: currentCountry });
    }
}
```

**Prevention:**
- ✅ Log all security events
- ✅ Monitor logs for anomalies
- ✅ Set up alerts
- ✅ Retain logs for forensics
- ✅ Protect log integrity

---

### 🔟 Server-Side Request Forgery (SSRF)

```python
# ❌ BAD - SSRF vulnerability
import requests

@app.route('/fetch')
def fetch_url():
    url = request.args.get('url')
    response = requests.get(url)  # Can access internal resources!
    return response.content
    # Attack: /fetch?url=http://localhost:8080/admin

# ✅ GOOD - Validate and restrict URLs
import requests
from urllib.parse import urlparse

ALLOWED_DOMAINS = ['example.com', 'api.example.com']
BLOCKED_IPS = ['127.0.0.1', '0.0.0.0', '169.254.169.254']  # Block metadata endpoint

@app.route('/fetch')
def fetch_url():
    url = request.args.get('url')

    # Parse URL
    parsed = urlparse(url)

    # Check scheme
    if parsed.scheme not in ['http', 'https']:
        return 'Invalid URL scheme', 400

    # Check domain
    if parsed.hostname not in ALLOWED_DOMAINS:
        return 'Domain not allowed', 403

    # Resolve and check IP
    ip = socket.gethostbyname(parsed.hostname)
    if ip in BLOCKED_IPS or ip.startswith('10.') or ip.startswith('192.168.'):
        return 'IP not allowed', 403

    # Fetch with timeout
    response = requests.get(url, timeout=5)
    return response.content
```

**Prevention:**
- ✅ Whitelist allowed domains
- ✅ Block private IP ranges
- ✅ Disable unnecessary protocols
- ✅ Use network segmentation

---

## 🔑 AUTHENTICATION & AUTHORIZATION

### JWT Best Practices

```typescript
// ✅ GOOD - Secure JWT implementation
import jwt from 'jsonwebtoken';

const ACCESS_TOKEN_SECRET = process.env.ACCESS_TOKEN_SECRET;
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET;

// Generate tokens
function generateTokens(user: User) {
    const accessToken = jwt.sign(
        {
            userId: user.id,
            email: user.email,
            role: user.role
        },
        ACCESS_TOKEN_SECRET,
        {
            expiresIn: '15m',  // Short-lived
            algorithm: 'HS256',
            issuer: 'your-app',
            audience: 'your-app-users'
        }
    );

    const refreshToken = jwt.sign(
        { userId: user.id },
        REFRESH_TOKEN_SECRET,
        {
            expiresIn: '7d',  // Longer-lived
            algorithm: 'HS256'
        }
    );

    return { accessToken, refreshToken };
}

// Verify token middleware
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }

    try {
        const decoded = jwt.verify(token, ACCESS_TOKEN_SECRET, {
            algorithms: ['HS256'],
            issuer: 'your-app',
            audience: 'your-app-users'
        });

        req.user = decoded;
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ error: 'Token expired' });
        }
        return res.status(403).json({ error: 'Invalid token' });
    }
}

// Refresh token endpoint
app.post('/api/refresh', async (req, res) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(401).json({ error: 'Refresh token required' });
    }

    try {
        // Verify refresh token
        const decoded = jwt.verify(refreshToken, REFRESH_TOKEN_SECRET);

        // Check if refresh token is revoked
        const isRevoked = await isTokenRevoked(refreshToken);
        if (isRevoked) {
            return res.status(403).json({ error: 'Refresh token revoked' });
        }

        // Get user
        const user = await getUserById(decoded.userId);

        // Generate new tokens
        const tokens = generateTokens(user);

        // Revoke old refresh token
        await revokeToken(refreshToken);

        res.json(tokens);
    } catch (error) {
        return res.status(403).json({ error: 'Invalid refresh token' });
    }
});
```

### OAuth 2.0 / OpenID Connect

```javascript
// ✅ GOOD - Using Passport.js with Google OAuth
import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';

passport.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: '/auth/google/callback',
    scope: ['profile', 'email']
}, async (accessToken, refreshToken, profile, done) => {
    try {
        // Find or create user
        let user = await User.findOne({ googleId: profile.id });

        if (!user) {
            user = await User.create({
                googleId: profile.id,
                email: profile.emails[0].value,
                name: profile.displayName
            });
        }

        return done(null, user);
    } catch (error) {
        return done(error, null);
    }
}));

// Routes
app.get('/auth/google',
    passport.authenticate('google', { scope: ['profile', 'email'] })
);

app.get('/auth/google/callback',
    passport.authenticate('google', { failureRedirect: '/login' }),
    (req, res) => {
        // Success
        res.redirect('/dashboard');
    }
);
```

---

## ✅ INPUT VALIDATION

```typescript
// ✅ GOOD - Comprehensive validation
import Joi from 'joi';
import DOMPurify from 'isomorphic-dompurify';

// Schema validation
const userSchema = Joi.object({
    email: Joi.string()
        .email()
        .required()
        .max(255),

    password: Joi.string()
        .min(12)
        .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
        .required(),

    age: Joi.number()
        .integer()
        .min(18)
        .max(120)
        .required(),

    website: Joi.string()
        .uri()
        .optional()
});

// Validate and sanitize
async function createUser(req: Request, res: Response) {
    try {
        // Validate
        const validated = await userSchema.validateAsync(req.body, {
            abortEarly: false,  // Return all errors
            stripUnknown: true  // Remove unknown fields
        });

        // Sanitize HTML inputs
        const sanitizedData = {
            ...validated,
            bio: DOMPurify.sanitize(validated.bio)
        };

        // Create user
        const user = await User.create(sanitizedData);
        res.json(user);

    } catch (error) {
        if (error.isJoi) {
            return res.status(400).json({
                error: 'Validation failed',
                details: error.details
            });
        }
        throw error;
    }
}
```

---

## 🔒 DATA PROTECTION

### Sensitive Data Handling

```python
# ✅ GOOD - Mask sensitive data in logs
def mask_email(email: str) -> str:
    """Mask email: john@example.com -> j***@example.com"""
    username, domain = email.split('@')
    return f"{username[0]}***@{domain}"

def mask_credit_card(card: str) -> str:
    """Mask credit card: 4111-1111-1111-1111 -> ****-****-****-1111"""
    return f"****-****-****-{card[-4:]}"

def mask_phone(phone: str) -> str:
    """Mask phone: +1234567890 -> +*******890"""
    return f"+*******{phone[-3:]}"

# Use in logging
logger.info(f"User registered: {mask_email(user.email)}")
logger.info(f"Payment processed: {mask_credit_card(card_number)}")
```

### Data Retention

```javascript
// ✅ GOOD - Implement data retention policy
async function cleanupOldData() {
    const RETENTION_DAYS = 90;
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - RETENTION_DAYS);

    // Delete old logs
    await db.logs.deleteMany({
        createdAt: { $lt: cutoffDate }
    });

    // Anonymize old user data
    await db.users.updateMany(
        {
            deletedAt: { $lt: cutoffDate },
            anonymized: false
        },
        {
            $set: {
                email: 'deleted@example.com',
                name: 'Deleted User',
                phone: null,
                address: null,
                anonymized: true
            }
        }
    );
}

// Run daily
cron.schedule('0 0 * * *', cleanupOldData);
```

---

## 🔐 API SECURITY

### API Key Management

```typescript
// ✅ GOOD - API key with rate limiting
import crypto from 'crypto';

interface APIKey {
    id: string;
    key: string;
    userId: string;
    name: string;
    permissions: string[];
    rateLimit: number;
    expiresAt: Date;
}

// Generate API key
function generateAPIKey(): string {
    return crypto.randomBytes(32).toString('hex');
}

// API key middleware
async function validateAPIKey(req, res, next) {
    const apiKey = req.headers['x-api-key'];

    if (!apiKey) {
        return res.status(401).json({ error: 'API key required' });
    }

    // Hash API key before lookup (store hashed keys in DB)
    const hashedKey = crypto
        .createHash('sha256')
        .update(apiKey)
        .digest('hex');

    const keyData = await db.apiKeys.findOne({
        key: hashedKey,
        active: true
    });

    if (!keyData) {
        return res.status(401).json({ error: 'Invalid API key' });
    }

    // Check expiration
    if (keyData.expiresAt && keyData.expiresAt < new Date()) {
        return res.status(401).json({ error: 'API key expired' });
    }

    // Check rate limit
    const usage = await getAPIKeyUsage(keyData.id);
    if (usage.count >= keyData.rateLimit) {
        return res.status(429).json({ error: 'Rate limit exceeded' });
    }

    // Check permissions
    const requiredPermission = getRequiredPermission(req.path, req.method);
    if (!keyData.permissions.includes(requiredPermission)) {
        return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Track usage
    await incrementAPIKeyUsage(keyData.id);

    req.apiKey = keyData;
    next();
}
```

### CORS Configuration

```javascript
// ✅ GOOD - Strict CORS configuration
import cors from 'cors';

const corsOptions = {
    origin: function (origin, callback) {
        const allowedOrigins = process.env.ALLOWED_ORIGINS.split(',');

        // Allow requests with no origin (mobile apps, Postman, etc.)
        if (!origin) return callback(null, true);

        if (allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    optionsSuccessStatus: 200,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    exposedHeaders: ['X-Total-Count'],
    maxAge: 600  // 10 minutes
};

app.use(cors(corsOptions));
```

---

## 📦 DEPENDENCY SECURITY

```bash
# Regular security audits
npm audit
npm audit fix

# Check for outdated packages
npm outdated

# Use Snyk for advanced scanning
npx snyk test
npx snyk monitor

# GitHub Dependabot
# Enable in GitHub repo settings
```

**.npmrc** - Configure security settings:
```
audit-level=moderate
save-exact=true
package-lock=true
```

---

## 🛡️ SECURITY CHECKLIST

### 🔴 Critical (Must Have)

- [ ] All passwords are hashed with bcrypt/argon2
- [ ] HTTPS enabled in production
- [ ] SQL/NoSQL injection prevented
- [ ] XSS prevention implemented
- [ ] CSRF protection enabled
- [ ] Authentication on sensitive endpoints
- [ ] Authorization checks implemented
- [ ] Rate limiting on auth endpoints
- [ ] Security headers configured
- [ ] Secrets in environment variables
- [ ] Input validation on all endpoints
- [ ] Error messages don't leak information

### 🟡 Important (Should Have)

- [ ] Multi-factor authentication
- [ ] Session management secure
- [ ] API rate limiting
- [ ] Logging security events
- [ ] Regular dependency updates
- [ ] Security monitoring
- [ ] Data encryption at rest
- [ ] Secure file uploads
- [ ] Content Security Policy
- [ ] Account lockout mechanism

### 💡 Recommended (Nice to Have)

- [ ] Security headers (Helmet)
- [ ] Penetration testing
- [ ] Security training for team
- [ ] Bug bounty program
- [ ] Incident response plan
- [ ] Regular security audits
- [ ] Web Application Firewall
- [ ] DDoS protection
- [ ] Intrusion detection system

---

## 📚 REFERENCES

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Mozilla Web Security](https://infosec.mozilla.org/guidelines/web_security)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
