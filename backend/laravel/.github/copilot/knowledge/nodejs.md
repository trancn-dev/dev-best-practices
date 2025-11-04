# Node.js Development Guide

## Node.js Version Requirements

**Minimum Node.js Version**: [NODE_VERSION]
**Recommended Node.js Version**: [NODE_VERSION] LTS or higher
**Package Manager**: npm / yarn / pnpm

### Modern JavaScript/TypeScript Features

- **ES Modules**: Import/export syntax
- **Async/Await**: Promise-based asynchronous code
- **Optional Chaining**: `?.` for safe property access
- **Nullish Coalescing**: `??` operator
- **Private Fields**: `#privateField` syntax
- **Top-level Await**: Await at module level
- **TypeScript**: Static typing (if enabled)

---

## Framework

**Framework**: [FRAMEWORK] [FRAMEWORK_VERSION]
**Architecture**: [MVC / Layered / Microservices]

### Core Concepts

#### 1. Express.js Basics

```javascript
import express from 'express';

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/api/users', async (req, res) => {
    const users = await userService.findAll();
    res.json(users);
});

app.post('/api/users', async (req, res) => {
    const user = await userService.create(req.body);
    res.status(201).json(user);
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: err.message });
});

app.listen(3000, () => {
    console.log('Server running on port 3000');
});
```

#### 2. TypeScript with Express

```typescript
import express, { Request, Response, NextFunction } from 'express';

interface User {
    id: number;
    name: string;
    email: string;
}

interface CreateUserDTO {
    name: string;
    email: string;
    password: string;
}

class UserController {
    async getAll(req: Request, res: Response): Promise<void> {
        const users = await userService.findAll();
        res.json(users);
    }

    async create(req: Request<{}, {}, CreateUserDTO>, res: Response): Promise<void> {
        const user = await userService.create(req.body);
        res.status(201).json(user);
    }
}
```

#### 3. Dependency Injection (NestJS style)

```typescript
import { Injectable } from '@nestjs/common';

@Injectable()
export class UserService {
    constructor(
        private readonly userRepository: UserRepository,
        private readonly hashService: HashService,
    ) {}

    async createUser(dto: CreateUserDto): Promise<User> {
        const hashedPassword = await this.hashService.hash(dto.password);

        return this.userRepository.create({
            ...dto,
            password: hashedPassword,
        });
    }
}
```

#### 4. Middleware

```typescript
// Authentication middleware
const authenticate = async (req: Request, res: Response, next: NextFunction) => {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        res.status(401).json({ error: 'Invalid token' });
    }
};

// Usage
app.get('/api/profile', authenticate, async (req, res) => {
    const user = await userService.findById(req.user.id);
    res.json(user);
});
```

#### 5. Database with Prisma

```typescript
// schema.prisma
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String
  posts     Post[]
  createdAt DateTime @default(now())
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String?
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
}

// Usage
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Create user with posts
const user = await prisma.user.create({
    data: {
        name: 'John Doe',
        email: 'john@example.com',
        posts: {
            create: [
                { title: 'First Post', content: 'Hello World' }
            ]
        }
    },
    include: {
        posts: true
    }
});

// Query with relations
const users = await prisma.user.findMany({
    include: {
        posts: true
    },
    where: {
        posts: {
            some: {
                published: true
            }
        }
    }
});
```

#### 6. Validation

```typescript
import { z } from 'zod';

// Define schema
const createUserSchema = z.object({
    name: z.string().min(2).max(100),
    email: z.string().email(),
    password: z.string().min(8),
    age: z.number().min(18).optional(),
});

type CreateUserInput = z.infer<typeof createUserSchema>;

// Validation middleware
const validate = (schema: z.ZodSchema) => {
    return (req: Request, res: Response, next: NextFunction) => {
        try {
            schema.parse(req.body);
            next();
        } catch (error) {
            if (error instanceof z.ZodError) {
                res.status(400).json({
                    error: 'Validation failed',
                    details: error.errors
                });
            }
        }
    };
};

// Usage
app.post('/api/users', validate(createUserSchema), async (req, res) => {
    const user = await userService.create(req.body);
    res.json(user);
});
```

#### 7. Error Handling

```typescript
class AppError extends Error {
    constructor(
        public statusCode: number,
        public message: string,
        public isOperational = true
    ) {
        super(message);
        Object.setPrototypeOf(this, AppError.prototype);
    }
}

class NotFoundError extends AppError {
    constructor(resource: string) {
        super(404, `${resource} not found`);
    }
}

class ValidationError extends AppError {
    constructor(message: string) {
        super(400, message);
    }
}

// Global error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    if (err instanceof AppError) {
        return res.status(err.statusCode).json({
            error: err.message
        });
    }

    // Unexpected errors
    console.error('Unexpected error:', err);
    res.status(500).json({
        error: 'Internal server error'
    });
});
```

#### 8. Async Error Handling

```typescript
// Wrapper to catch async errors
const asyncHandler = (fn: Function) => {
    return (req: Request, res: Response, next: NextFunction) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
};

// Usage
app.get('/api/users/:id', asyncHandler(async (req, res) => {
    const user = await userService.findById(req.params.id);
    if (!user) {
        throw new NotFoundError('User');
    }
    res.json(user);
}));
```

---

## Node.js Best Practices

### 1. Service Layer Pattern

```typescript
// services/user.service.ts
export class UserService {
    constructor(
        private readonly userRepository: UserRepository,
        private readonly emailService: EmailService,
    ) {}

    async createUser(dto: CreateUserDto): Promise<User> {
        // Business logic here
        const user = await this.userRepository.create(dto);
        await this.emailService.sendWelcome(user.email);
        return user;
    }

    async findById(id: number): Promise<User | null> {
        return this.userRepository.findById(id);
    }
}
```

### 2. Repository Pattern

```typescript
// repositories/user.repository.ts
export class UserRepository {
    constructor(private readonly db: Database) {}

    async create(data: CreateUserData): Promise<User> {
        return this.db.user.create({ data });
    }

    async findById(id: number): Promise<User | null> {
        return this.db.user.findUnique({ where: { id } });
    }

    async findByEmail(email: string): Promise<User | null> {
        return this.db.user.findUnique({ where: { email } });
    }

    async update(id: number, data: UpdateUserData): Promise<User> {
        return this.db.user.update({
            where: { id },
            data
        });
    }
}
```

### 3. DTOs (Data Transfer Objects)

```typescript
// dtos/user.dto.ts
export class CreateUserDto {
    name: string;
    email: string;
    password: string;
}

export class UpdateUserDto {
    name?: string;
    email?: string;
}

export class UserResponseDto {
    id: number;
    name: string;
    email: string;
    createdAt: Date;

    constructor(user: User) {
        this.id = user.id;
        this.name = user.name;
        this.email = user.email;
        this.createdAt = user.createdAt;
        // Don't include password
    }
}
```

### 4. Environment Configuration

```typescript
// config/env.config.ts
import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
    NODE_ENV: z.enum(['development', 'production', 'test']),
    PORT: z.string().transform(Number),
    DATABASE_URL: z.string().url(),
    JWT_SECRET: z.string().min(32),
    REDIS_URL: z.string().url().optional(),
});

export const env = envSchema.parse(process.env);
```

### 5. Logging

```typescript
import winston from 'winston';

export const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' }),
    ],
});

if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.simple(),
    }));
}

// Usage
logger.info('User created', { userId: user.id });
logger.error('Database error', { error: err.message });
```

### 6. Testing with Jest

```typescript
// user.service.spec.ts
import { UserService } from './user.service';
import { UserRepository } from '../repositories/user.repository';

describe('UserService', () => {
    let service: UserService;
    let repository: jest.Mocked<UserRepository>;

    beforeEach(() => {
        repository = {
            create: jest.fn(),
            findById: jest.fn(),
        } as any;

        service = new UserService(repository);
    });

    describe('createUser', () => {
        it('should create a user', async () => {
            const dto = {
                name: 'John',
                email: 'john@example.com',
                password: 'password123'
            };

            const expected = { id: 1, ...dto };
            repository.create.mockResolvedValue(expected);

            const result = await service.createUser(dto);

            expect(result).toEqual(expected);
            expect(repository.create).toHaveBeenCalledWith(dto);
        });
    });
});
```

### 7. Caching with Redis

```typescript
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

export class CacheService {
    async get<T>(key: string): Promise<T | null> {
        const data = await redis.get(key);
        return data ? JSON.parse(data) : null;
    }

    async set(key: string, value: any, ttl?: number): Promise<void> {
        const data = JSON.stringify(value);
        if (ttl) {
            await redis.setex(key, ttl, data);
        } else {
            await redis.set(key, data);
        }
    }

    async del(key: string): Promise<void> {
        await redis.del(key);
    }
}

// Usage with decorator
function Cacheable(ttl: number = 3600) {
    return function (
        target: any,
        propertyKey: string,
        descriptor: PropertyDescriptor
    ) {
        const originalMethod = descriptor.value;

        descriptor.value = async function (...args: any[]) {
            const key = `${propertyKey}:${JSON.stringify(args)}`;
            const cached = await cacheService.get(key);

            if (cached) {
                return cached;
            }

            const result = await originalMethod.apply(this, args);
            await cacheService.set(key, result, ttl);
            return result;
        };

        return descriptor;
    };
}
```

---

## Security Best Practices

### 1. Input Validation

```typescript
// Always validate user input
const schema = z.object({
    email: z.string().email(),
    password: z.string().min(8)
});

schema.parse(req.body);
```

### 2. Password Hashing

```typescript
import bcrypt from 'bcryptjs';

// Hash password
const hashedPassword = await bcrypt.hash(password, 10);

// Verify password
const isValid = await bcrypt.compare(password, hashedPassword);
```

### 3. JWT Authentication

```typescript
import jwt from 'jsonwebtoken';

// Generate token
const token = jwt.sign(
    { userId: user.id },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
);

// Verify token
const decoded = jwt.verify(token, process.env.JWT_SECRET);
```

### 4. Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

### 5. CORS Configuration

```typescript
import cors from 'cors';

app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(','),
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
}));
```

---

## Performance Optimization

### 1. Database Query Optimization

```typescript
// ❌ BAD: N+1 query
const users = await db.user.findMany();
for (const user of users) {
    user.posts = await db.post.findMany({ where: { authorId: user.id } });
}

// ✅ GOOD: Include relation
const users = await db.user.findMany({
    include: {
        posts: true
    }
});
```

### 2. Async/Await Best Practices

```typescript
// ❌ BAD: Sequential
const user = await getUserById(1);
const posts = await getPostsByUserId(1);
const comments = await getCommentsByUserId(1);

// ✅ GOOD: Parallel
const [user, posts, comments] = await Promise.all([
    getUserById(1),
    getPostsByUserId(1),
    getCommentsByUserId(1)
]);
```

### 3. Stream Large Data

```typescript
import { createReadStream } from 'fs';

app.get('/api/export', (req, res) => {
    res.setHeader('Content-Type', 'text/csv');
    const stream = createReadStream('large-file.csv');
    stream.pipe(res);
});
```

---

## Code Style

```typescript
// Use TypeScript strict mode
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true
  }
}

// Use ESLint
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ]
}

// Use Prettier
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100
}
```

---

## Additional Resources

- [Node.js Documentation](https://nodejs.org/docs)
- [Express.js Guide](https://expressjs.com/guide)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook)
- [Prisma Documentation](https://www.prisma.io/docs)
- [NestJS Documentation](https://docs.nestjs.com)
