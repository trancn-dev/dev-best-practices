# Rule: TypeScript Standards

## Intent
Define TypeScript standards and best practices for type safety and code quality in the Nuxt frontend.

## Scope
Applies to all TypeScript code in components, composables, utilities, and types.

---

## 1. Type Definitions

### Interfaces vs Types

**Use `interface` for:**
- Object shapes
- When you need declaration merging
- Public APIs

```typescript
interface User {
  id: number
  name: string
  email: string
  role: 'admin' | 'user'
}

// Can be extended
interface AdminUser extends User {
  permissions: string[]
}
```

**Use `type` for:**
- Unions, intersections
- Mapped types
- Type aliases

```typescript
type Status = 'pending' | 'active' | 'inactive'
type ID = string | number

type UserOrAdmin = User | AdminUser
type RequiredUser = Required<User>
```

---

## 2. Typing Components

```typescript
//types/components.ts
import type { Component } from 'vue'

export interface ButtonProps {
  label: string
  variant?: 'primary' | 'secondary'
  disabled?: boolean
  onClick?: () => void
}

export interface FormData {
  username: string
  email: string
  password: string
}
```

---

## 3. Avoid `any`

```typescript
// ❌ Bad
const data: any = fetchData()

// ✅ Good
interface Data {
  id: number
  name: string
}
const data: Data = fetchData()

// ✅ Use unknown for truly unknown types
const data: unknown = fetchData()
if (isData(data)) {
  // Type guard
  console.log(data.name)
}
```

---

## 4. Generics

```typescript
// Generic function
function identity<T>(value: T): T {
  return value
}

// Generic component props
interface ListProps<T> {
  items: T[]
  onSelect: (item: T) => void
}

// Generic composable
export function useList<T>(initialItems: T[]) {
  const items = ref<T[]>(initialItems)

  const add = (item: T) => {
    items.value.push(item)
  }

  return { items, add }
}
```

---

## References

- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [Vue TypeScript Guide](https://vuejs.org/guide/typescript/overview.html)
