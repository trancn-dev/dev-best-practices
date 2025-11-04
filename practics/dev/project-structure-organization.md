# Project Structure & Organization - Cấu Trúc Dự Án

> Hướng dẫn tổ chức code, folder structure và best practices cho các loại dự án
>
> **Mục đích**: Tạo cấu trúc project rõ ràng, dễ navigate, scale và maintain

---

## 📋 Mục Lục
- [General Principles](#general-principles)
- [Frontend Projects](#frontend-projects)
- [Backend Projects](#backend-projects)
- [Full-Stack Projects](#full-stack-projects)
- [Monorepo vs Multi-repo](#monorepo-vs-multi-repo)
- [Configuration Files](#configuration-files)
- [Environment Variables](#environment-variables)

---

## 🎯 GENERAL PRINCIPLES

### Core Principles

```
✅ Separation of Concerns
✅ Feature-based Organization
✅ Consistent Naming
✅ Clear Dependencies
✅ Easy to Navigate
✅ Scalable Structure
```

### Common Patterns

```
1. Layer-based (MVC, 3-tier)
2. Feature-based (Domain-driven)
3. Hybrid (Layer + Feature)
```

---

## ⚛️ FRONTEND PROJECTS

### React/Next.js Structure

```
my-react-app/
├── public/                 # Static assets
│   ├── images/
│   ├── fonts/
│   └── favicon.ico
│
├── src/
│   ├── app/               # Next.js App Router (or pages/)
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── api/           # API routes
│   │   └── [feature]/     # Feature-based routes
│   │
│   ├── components/        # Reusable components
│   │   ├── ui/           # Basic UI components
│   │   │   ├── Button/
│   │   │   │   ├── Button.tsx
│   │   │   │   ├── Button.test.tsx
│   │   │   │   ├── Button.module.css
│   │   │   │   └── index.ts
│   │   │   ├── Input/
│   │   │   └── Modal/
│   │   │
│   │   ├── layout/       # Layout components
│   │   │   ├── Header/
│   │   │   ├── Footer/
│   │   │   └── Sidebar/
│   │   │
│   │   └── features/     # Feature-specific components
│   │       ├── auth/
│   │       │   ├── LoginForm/
│   │       │   └── RegisterForm/
│   │       └── user/
│   │           └── UserProfile/
│   │
│   ├── hooks/            # Custom React hooks
│   │   ├── useAuth.ts
│   │   ├── useLocalStorage.ts
│   │   └── useDebounce.ts
│   │
│   ├── lib/              # Business logic
│   │   ├── api/          # API client
│   │   │   ├── client.ts
│   │   │   ├── auth.ts
│   │   │   └── users.ts
│   │   ├── utils/        # Utility functions
│   │   │   ├── format.ts
│   │   │   ├── validation.ts
│   │   │   └── helpers.ts
│   │   └── constants/
│   │       └── config.ts
│   │
│   ├── store/            # State management (Redux/Zustand)
│   │   ├── slices/
│   │   │   ├── authSlice.ts
│   │   │   └── userSlice.ts
│   │   └── store.ts
│   │
│   ├── types/            # TypeScript types
│   │   ├── api.ts
│   │   ├── models.ts
│   │   └── index.ts
│   │
│   ├── styles/           # Global styles
│   │   ├── globals.css
│   │   ├── variables.css
│   │   └── mixins.scss
│   │
│   └── middleware.ts     # Next.js middleware
│
├── tests/                # Test utilities
│   ├── setup.ts
│   ├── mocks/
│   └── fixtures/
│
├── .env.local            # Environment variables
├── .env.example
├── .eslintrc.json
├── .prettierrc
├── next.config.js
├── package.json
├── tsconfig.json
└── README.md
```

### Vue/Nuxt Structure

```
my-vue-app/
├── assets/               # Uncompiled assets
│   ├── images/
│   ├── styles/
│   └── fonts/
│
├── components/           # Vue components
│   ├── base/            # Base components (Button, Input)
│   ├── layout/          # Layout components
│   └── features/        # Feature components
│
├── composables/          # Composition API functions
│   ├── useAuth.ts
│   └── useFetch.ts
│
├── layouts/              # Layout components
│   ├── default.vue
│   └── admin.vue
│
├── pages/                # File-based routing
│   ├── index.vue
│   ├── about.vue
│   └── users/
│       ├── index.vue
│       └── [id].vue
│
├── plugins/              # Vue plugins
│   └── axios.ts
│
├── stores/               # Pinia stores
│   ├── auth.ts
│   └── user.ts
│
├── types/
├── utils/
├── middleware/
├── nuxt.config.ts
└── package.json
```

---

## 🖥️ BACKEND PROJECTS

### Node.js/Express Structure

```
my-express-api/
├── src/
│   ├── config/           # Configuration
│   │   ├── database.ts
│   │   ├── redis.ts
│   │   └── environment.ts
│   │
│   ├── controllers/      # Request handlers
│   │   ├── authController.ts
│   │   ├── userController.ts
│   │   └── index.ts
│   │
│   ├── services/         # Business logic
│   │   ├── authService.ts
│   │   ├── userService.ts
│   │   ├── emailService.ts
│   │   └── index.ts
│   │
│   ├── repositories/     # Data access layer
│   │   ├── userRepository.ts
│   │   ├── postRepository.ts
│   │   └── index.ts
│   │
│   ├── models/           # Database models
│   │   ├── User.ts
│   │   ├── Post.ts
│   │   └── index.ts
│   │
│   ├── routes/           # API routes
│   │   ├── authRoutes.ts
│   │   ├── userRoutes.ts
│   │   ├── index.ts
│   │   └── v1/          # Versioned routes
│   │       └── index.ts
│   │
│   ├── middleware/       # Express middleware
│   │   ├── auth.ts
│   │   ├── errorHandler.ts
│   │   ├── validation.ts
│   │   └── rateLimiter.ts
│   │
│   ├── utils/            # Utility functions
│   │   ├── logger.ts
│   │   ├── validators.ts
│   │   └── helpers.ts
│   │
│   ├── types/            # TypeScript types
│   │   ├── express.d.ts
│   │   └── models.ts
│   │
│   ├── jobs/             # Background jobs
│   │   ├── emailJob.ts
│   │   └── cleanupJob.ts
│   │
│   ├── app.ts            # Express app setup
│   └── server.ts         # Server entry point
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── scripts/              # Utility scripts
│   ├── seed.ts
│   └── migrate.ts
│
├── .env
├── .env.example
├── package.json
├── tsconfig.json
└── README.md
```

### Clean Architecture (Advanced)

```
my-clean-api/
├── src/
│   ├── domain/           # Business entities & logic
│   │   ├── entities/
│   │   │   ├── User.ts
│   │   │   └── Order.ts
│   │   ├── valueObjects/
│   │   │   ├── Email.ts
│   │   │   └── Money.ts
│   │   ├── repositories/ # Interface definitions
│   │   │   └── IUserRepository.ts
│   │   └── services/
│   │       └── DomainService.ts
│   │
│   ├── application/      # Use cases
│   │   ├── useCases/
│   │   │   ├── CreateUser/
│   │   │   │   ├── CreateUserUseCase.ts
│   │   │   │   ├── CreateUserDTO.ts
│   │   │   │   └── CreateUserValidator.ts
│   │   │   └── GetUser/
│   │   └── services/
│   │
│   ├── infrastructure/   # External concerns
│   │   ├── database/
│   │   │   ├── repositories/
│   │   │   │   └── UserRepository.ts
│   │   │   └── migrations/
│   │   ├── http/
│   │   │   ├── controllers/
│   │   │   ├── routes/
│   │   │   └── middleware/
│   │   ├── email/
│   │   └── cache/
│   │
│   ├── shared/           # Shared kernel
│   │   ├── errors/
│   │   ├── types/
│   │   └── utils/
│   │
│   └── main.ts
│
└── tests/
```

---

## 🔄 FULL-STACK PROJECTS

### Monorepo Structure (Turborepo/Nx)

```
my-fullstack-app/
├── apps/
│   ├── web/              # Next.js frontend
│   │   ├── app/
│   │   ├── components/
│   │   ├── public/
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── api/              # Express backend
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   └── admin/            # Admin dashboard
│       └── ...
│
├── packages/             # Shared packages
│   ├── ui/              # Shared UI components
│   │   ├── src/
│   │   │   ├── Button/
│   │   │   └── Input/
│   │   └── package.json
│   │
│   ├── config/          # Shared configs
│   │   ├── eslint/
│   │   ├── typescript/
│   │   └── package.json
│   │
│   ├── types/           # Shared TypeScript types
│   │   ├── src/
│   │   │   ├── api.ts
│   │   │   └── models.ts
│   │   └── package.json
│   │
│   └── utils/           # Shared utilities
│       ├── src/
│       └── package.json
│
├── docker/              # Docker files
│   ├── Dockerfile.web
│   ├── Dockerfile.api
│   └── docker-compose.yml
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── deploy.yml
│
├── turbo.json           # Turborepo config
├── package.json         # Root package.json
├── pnpm-workspace.yaml
└── README.md
```

---

## 📦 MONOREPO VS MULTI-REPO

### Monorepo (Single Repository)

```
✅ Advantages:
- Easier code sharing
- Atomic commits across projects
- Unified tooling & dependencies
- Better refactoring
- Single source of truth

❌ Disadvantages:
- Larger repository size
- More complex CI/CD
- Requires tools (Turborepo, Nx, Lerna)
- Permission management harder
```

**Use when:**
- Projects are tightly coupled
- Shared code between projects
- Small to medium team
- Want simplified dependency management

### Multi-repo (Multiple Repositories)

```
✅ Advantages:
- Clear ownership
- Independent deployments
- Smaller codebases
- Easier permissions
- Simpler CI/CD per repo

❌ Disadvantages:
- Code duplication
- Harder to share code
- Version synchronization issues
- Multiple PR/review processes
```

**Use when:**
- Projects are independent
- Different teams/products
- Different release cycles
- Large organization

---

## ⚙️ CONFIGURATION FILES

### Essential Config Files

```
my-project/
├── .editorconfig         # Editor configuration
├── .gitignore           # Git ignore rules
├── .gitattributes       # Git attributes
├── .nvmrc               # Node version
├── .prettierrc          # Prettier config
├── .prettierignore
├── .eslintrc.json       # ESLint config
├── .eslintignore
├── tsconfig.json        # TypeScript config
├── jest.config.js       # Jest testing
├── vitest.config.ts     # Vitest testing
├── .env.example         # Environment template
├── package.json
├── pnpm-lock.yaml       # Lock file
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
└── LICENSE
```

### .editorconfig Example

```ini
# .editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false

[*.py]
indent_size = 4
```

### .gitignore Example

```gitignore
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/
.nyc_output

# Production
build/
dist/
out/
.next/

# Environment variables
.env
.env*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log
npm-debug.log*

# Temporary
.cache/
tmp/
temp/
```

---

## 🔐 ENVIRONMENT VARIABLES

### Structure

```
my-project/
├── .env                  # Local development (gitignored)
├── .env.example          # Template (committed)
├── .env.development      # Development
├── .env.staging          # Staging
├── .env.production       # Production (never commit!)
└── .env.test            # Testing
```

### .env.example

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
DATABASE_POOL_SIZE=20

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=

# Authentication
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=7d

# External APIs
STRIPE_API_KEY=sk_test_...
SENDGRID_API_KEY=SG....

# App Config
NODE_ENV=development
PORT=3000
API_URL=http://localhost:3000/api
FRONTEND_URL=http://localhost:3001

# Feature Flags
FEATURE_NEW_DASHBOARD=true
FEATURE_BETA_SEARCH=false
```

### Loading Environment Variables

```typescript
// config/environment.ts
import { z } from 'zod';

const envSchema = z.object({
    NODE_ENV: z.enum(['development', 'staging', 'production', 'test']),
    PORT: z.string().transform(Number),
    DATABASE_URL: z.string().url(),
    JWT_SECRET: z.string().min(32),
    STRIPE_API_KEY: z.string().startsWith('sk_'),
});

function validateEnv() {
    try {
        return envSchema.parse(process.env);
    } catch (error) {
        console.error('❌ Invalid environment variables:', error);
        process.exit(1);
    }
}

export const env = validateEnv();
```

---

## 📚 DOCUMENTATION STRUCTURE

```
my-project/
├── docs/
│   ├── README.md              # Overview
│   ├── GETTING_STARTED.md     # Setup guide
│   ├── ARCHITECTURE.md        # Architecture docs
│   ├── API.md                 # API documentation
│   ├── DEPLOYMENT.md          # Deployment guide
│   ├── CONTRIBUTING.md        # Contribution guide
│   └── TROUBLESHOOTING.md     # Common issues
│
└── README.md                  # Main README
```

### README.md Template

```markdown
# Project Name

Brief description of the project

## Features

- Feature 1
- Feature 2

## Tech Stack

- Frontend: React, TypeScript, Tailwind
- Backend: Node.js, Express, PostgreSQL
- DevOps: Docker, GitHub Actions

## Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- pnpm 8+

### Installation

\`\`\`bash
# Clone repo
git clone https://github.com/user/project.git

# Install dependencies
pnpm install

# Setup environment
cp .env.example .env

# Run migrations
pnpm db:migrate

# Start development server
pnpm dev
\`\`\`

## Project Structure

\`\`\`
src/
├── components/
├── pages/
└── utils/
\`\`\`

## Available Scripts

- `pnpm dev` - Start development server
- `pnpm build` - Build for production
- `pnpm test` - Run tests
- `pnpm lint` - Lint code

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT
```

---

## 🎯 BEST PRACTICES

### ✅ DO

- ✅ Group by feature, not by type
- ✅ Keep folder structure flat when possible
- ✅ Use index files for exports
- ✅ Consistent naming conventions
- ✅ Separate concerns (UI, logic, data)
- ✅ Document structure in README
- ✅ Use absolute imports
- ✅ Version your APIs

### ❌ DON'T

- ❌ Deeply nested folders
- ❌ Mix different concerns
- ❌ Inconsistent naming
- ❌ Circular dependencies
- ❌ Large god files
- ❌ Hardcode configuration
- ❌ Commit sensitive data

---

## 📚 REFERENCES

- [The Twelve-Factor App](https://12factor.net/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Feature-Sliced Design](https://feature-sliced.design/)
- [Screaming Architecture](https://blog.cleancoder.com/uncle-bob/2011/09/30/Screaming-Architecture.html)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
