# Coding Conventions & Standards

This document describes the coding conventions, naming standards, and style guidelines for the Nuxt frontend project.

---

## Table of Contents

1. [Naming Conventions](#naming-conventions)
2. [File Organization](#file-organization)
3. [Code Style](#code-style)
4. [Best Practices](#best-practices)

---

## Naming Conventions

### Components
- **PascalCase** for component files and names
- Examples: `UserProfile.vue`, `BlogPost.vue`, `AppHeader.vue`

### Composables
- **camelCase** with `use` prefix
- Examples: `useAuth.ts`, `useUserProfile.ts`, `useApi.ts`

### Pages
- **kebab-case** or **camelCase**
- Examples: `index.vue`, `about.vue`, `blog-post.vue`, `[id].vue`

### Utilities
- **camelCase** for function names
- Examples: `formatDate.ts`, `validateEmail.ts`

### Types/Interfaces
- **PascalCase** for interfaces and types
- Examples: `User`, `Post`, `ApiResponse`

### Constants
- **UPPER_SNAKE_CASE**
- Examples: `API_BASE_URL`, `MAX_RETRIES`

---

## File Organization

### Component Files

```vue
<script setup lang="ts">
// 1. Imports
// 2. Types/Interfaces (if not in separate file)
// 3. Props
// 4. Emits
// 5. Composables
// 6. State
// 7. Computed
// 8. Watch
// 9. Lifecycle
// 10. Methods
</script>

<template>
  <!-- Template -->
</template>

<style scoped>
/* Styles */
</style>
```

---

## Code Style

### Indentation
- **2 spaces** for Vue/TS/JS files
- No tabs

### Line Length
- **Soft limit**: 100 characters
- **Hard limit**: 120 characters

### Quotes
- **Single quotes** for strings
- **Double quotes** for HTML attributes

### Semicolons
- Optional (rely on ESLint/Prettier)

---

## Best Practices

### Do's ✅
- Use TypeScript for type safety
- Use Composition API (`<script setup>`)
- Extract reusable logic to composables
- Keep components small and focused
- Write descriptive variable/function names
- Add comments for complex logic
- Use auto-imports for components and composables

### Don'ts ❌
- Don't use `any` type
- Don't ignore TypeScript errors
- Don't leave console.log in production code
- Don't create God components (too much responsibility)
- Don't nest components too deeply
- Don't duplicate code (DRY principle)

---

## References

- [Vue 3 Style Guide](https://vuejs.org/style-guide/)
- [Nuxt 3 Best Practices](https://nuxt.com/docs/guide/going-further/experimental-features)
- [TypeScript Best Practices](https://www.typescriptlang.org/docs/handbook/declaration-files/do-s-and-don-ts.html)
