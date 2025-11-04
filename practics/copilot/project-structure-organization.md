# Rule: Project Structure & Organization

## Intent
Enforce consistent project structure and file organization patterns for maintainability, scalability, and team collaboration.

## Scope
Applies to all project initialization, directory structure, file naming, and module organization decisions.

---

## 1. Frontend Structure (React/Vue)

### React Project Structure

```
src/
├── assets/              # Static files (images, fonts)
│   ├── images/
│   └── fonts/
├── components/          # Reusable components
│   ├── common/         # Generic UI components
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.test.tsx
│   │   │   ├── Button.module.css
│   │   │   └── index.ts
│   │   └── Input/
│   └── features/       # Feature-specific components
│       └── UserProfile/
├── hooks/              # Custom React hooks
│   ├── useAuth.ts
│   ├── useFetch.ts
│   └── useLocalStorage.ts
├── pages/              # Route pages/views
│   ├── HomePage/
│   ├── LoginPage/
│   └── DashboardPage/
├── services/           # API calls and external services
│   ├── api/
│   │   ├── users.api.ts
│   │   └── orders.api.ts
│   └── auth.service.ts
├── store/              # State management (Redux/Zustand)
│   ├── slices/
│   │   ├── userSlice.ts
│   │   └── orderSlice.ts
│   └── store.ts
├── utils/              # Utility functions
│   ├── date.utils.ts
│   ├── validation.utils.ts
│   └── format.utils.ts
├── types/              # TypeScript types/interfaces
│   ├── user.types.ts
│   └── order.types.ts
├── constants/          # Constants and configuration
│   ├── routes.ts
│   └── config.ts
├── App.tsx
└── main.tsx
```

### Component Organization

```typescript
// ✅ GOOD - Component with colocation
components/
└── UserCard/
    ├── UserCard.tsx          // Main component
    ├── UserCard.test.tsx     // Tests
    ├── UserCard.module.css   // Styles
    ├── UserCard.stories.tsx  // Storybook
    ├── useUserCard.ts        // Custom hook
    └── index.ts              // Public API

// ✅ GOOD - index.ts for clean imports
// components/UserCard/index.ts
export { UserCard } from './UserCard';
export type { UserCardProps } from './UserCard';

// Usage
import { UserCard } from '@/components/UserCard';

// ❌ BAD - Everything in one folder
components/
├── UserCard.tsx
├── UserCardTest.tsx
├── UserCard.css
├── ProductCard.tsx
├── ProductCardTest.tsx
└── ...
```

---

## 2. Backend Structure (Node.js/Express)

### MVC Pattern

```
src/
├── config/                 # Configuration files
│   ├── database.ts
│   ├── redis.ts
│   └── jwt.ts
├── controllers/           # Route handlers
│   ├── user.controller.ts
│   └── order.controller.ts
├── models/               # Database models
│   ├── user.model.ts
│   └── order.model.ts
├── services/             # Business logic
│   ├── user.service.ts
│   ├── order.service.ts
│   └── email.service.ts
├── repositories/         # Database access layer
│   ├── user.repository.ts
│   └── order.repository.ts
├── middlewares/          # Express middlewares
│   ├── auth.middleware.ts
│   ├── validate.middleware.ts
│   └── error.middleware.ts
├── routes/               # API routes
│   ├── user.routes.ts
│   ├── order.routes.ts
│   └── index.ts
├── utils/                # Utilities
│   ├── logger.ts
│   └── validators.ts
├── types/                # TypeScript types
│   ├── user.types.ts
│   └── order.types.ts
├── constants/            # Constants
│   └── errors.ts
├── app.ts                # Express app setup
└── server.ts             # Server entry point
```

### Clean Architecture Example

```typescript
// ✅ GOOD - Layered architecture
// controllers/user.controller.ts
export class UserController {
    constructor(private userService: UserService) {}

    async createUser(req: Request, res: Response) {
        const user = await this.userService.createUser(req.body);
        res.status(201).json(user);
    }
}

// services/user.service.ts
export class UserService {
    constructor(private userRepository: UserRepository) {}

    async createUser(userData: CreateUserDTO) {
        // Business logic
        const hashedPassword = await bcrypt.hash(userData.password, 10);
        return this.userRepository.create({
            ...userData,
            password: hashedPassword
        });
    }
}

// repositories/user.repository.ts
export class UserRepository {
    async create(userData: User) {
        return db.users.create(userData);
    }

    async findByEmail(email: string) {
        return db.users.findOne({ where: { email } });
    }
}
```

---

## 3. Monorepo Structure

### Turborepo/Nx Structure

```
.
├── apps/                  # Applications
│   ├── web/              # Frontend app
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── api/              # Backend API
│   │   ├── src/
│   │   └── package.json
│   └── admin/            # Admin dashboard
├── packages/             # Shared packages
│   ├── ui/              # Shared UI components
│   │   ├── src/
│   │   └── package.json
│   ├── config/          # Shared configs
│   │   ├── eslint/
│   │   └── typescript/
│   ├── utils/           # Shared utilities
│   └── types/           # Shared TypeScript types
├── package.json
├── turbo.json
└── pnpm-workspace.yaml
```

---

## 4. File Naming Conventions

### Naming Rules

- ✅ **Components**: PascalCase (`UserCard.tsx`)
- ✅ **Utilities**: camelCase (`dateUtils.ts`)
- ✅ **Constants**: UPPER_SNAKE_CASE (`API_ROUTES.ts`)
- ✅ **Hooks**: camelCase with `use` prefix (`useAuth.ts`)
- ✅ **Types**: PascalCase with `.types.ts` suffix (`User.types.ts`)

```typescript
// ✅ GOOD - Consistent naming
components/
├── UserCard.tsx           // Component
├── UserCard.test.tsx      // Test
├── UserCard.module.css    // CSS Module
└── index.ts               // Barrel export

hooks/
└── useAuth.ts             // Hook

utils/
└── dateUtils.ts           // Utility

types/
└── User.types.ts          // Types

constants/
└── API_ROUTES.ts          // Constants

// ❌ BAD - Inconsistent naming
components/
├── user-card.tsx          // Wrong case
├── UserCard.spec.tsx      // Inconsistent test suffix
└── usercard.css           // Wrong case
```

---

## 5. Module Boundaries

### Domain-Driven Design

```
src/
├── modules/
│   ├── user/
│   │   ├── user.controller.ts
│   │   ├── user.service.ts
│   │   ├── user.repository.ts
│   │   ├── user.model.ts
│   │   ├── dto/
│   │   │   ├── create-user.dto.ts
│   │   │   └── update-user.dto.ts
│   │   └── tests/
│   ├── order/
│   │   ├── order.controller.ts
│   │   ├── order.service.ts
│   │   ├── order.repository.ts
│   │   └── order.model.ts
│   └── payment/
└── shared/
    ├── interfaces/
    ├── decorators/
    └── filters/
```

---

## 6. Configuration Management

### Environment-Specific Configs

```
config/
├── default.ts          # Default configuration
├── development.ts      # Development overrides
├── production.ts       # Production overrides
├── test.ts            # Test overrides
└── index.ts           # Config loader

// ✅ GOOD - Environment-specific config
// config/index.ts
const env = process.env.NODE_ENV || 'development';
const config = require(`./${env}`).default;

export default config;
```

---

## 7. Test Organization

### Test Structure

```
src/
├── components/
│   └── UserCard/
│       ├── UserCard.tsx
│       └── UserCard.test.tsx    # Colocated unit tests
└── services/
    └── user.service.ts

tests/                           # Integration/E2E tests
├── integration/
│   └── user.test.ts
├── e2e/
│   └── login.spec.ts
└── fixtures/
    └── users.json
```

---

## 8. Public API Pattern

### Barrel Exports

```typescript
// ✅ GOOD - Controlled public API
// components/index.ts
export { Button } from './Button';
export { Input } from './Input';
export type { ButtonProps } from './Button';
export type { InputProps } from './Input';

// Usage
import { Button, Input } from '@/components';

// ✅ GOOD - Module public API
// modules/user/index.ts
export { UserController } from './user.controller';
export { UserService } from './user.service';
export type { CreateUserDTO, UpdateUserDTO } from './dto';

// ❌ BAD - Direct imports bypass module boundaries
import { UserRepository } from '@/modules/user/user.repository';
```

---

## 9. Copilot Instructions

When generating project structure, Copilot **MUST**:

1. **FOLLOW** framework conventions (React, NestJS, etc.)
2. **SEPARATE** concerns (UI, logic, data)
3. **GROUP** related files together
4. **USE** consistent naming conventions
5. **CREATE** barrel exports for public APIs
6. **IMPLEMENT** layered architecture
7. **COLOCATE** tests with source files

---

## 10. Checklist

### Frontend Structure
- [ ] Components grouped by feature or domain
- [ ] Hooks in dedicated `hooks/` folder
- [ ] Services separated from components
- [ ] Types/interfaces in dedicated folder
- [ ] Utils separated from business logic

### Backend Structure
- [ ] Controllers handle HTTP only
- [ ] Services contain business logic
- [ ] Repositories handle data access
- [ ] Clear layer separation
- [ ] Configuration centralized

### General
- [ ] Consistent file naming
- [ ] Tests colocated with source
- [ ] Public APIs via barrel exports
- [ ] No circular dependencies
- [ ] Module boundaries respected

---

## References

- Project Guidelines (github.com/elsewhencode/project-guidelines)
- Bulletproof React (github.com/alan2207/bulletproof-react)
- Node.js Best Practices (github.com/goldbergyoni/nodebestpractices)

**Remember:** Good structure scales. Start organized, stay organized.
