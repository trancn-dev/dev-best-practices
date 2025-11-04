# Architecture Overview

## Project Architecture

This Nuxt 3 frontend follows a modern, scalable architecture with clear separation of concerns.

---

## Layers

### 1. Presentation Layer
- **Components**: Reusable UI components
- **Pages**: Route-based views
- **Layouts**: Page wrappers

### 2. Business Logic Layer
- **Composables**: Reusable logic and state
- **Stores (Pinia)**: Global state management
- **Utilities**: Helper functions

### 3. Data Layer
- **API Client**: HTTP requests to backend
- **Server Routes**: Nuxt server API (if used)

---

## Data Flow

```
User Interaction → Component → Composable → API → Backend
                      ↓
                   Update State
                      ↓
                  Re-render UI
```

---

## Key Patterns

### 1. Composition API Pattern
All components use `<script setup>` for better DX and performance.

### 2. Composable Pattern
Business logic is extracted into composables for reusability:
- `useAuth()` - Authentication
- `useApi()` - API calls
- `useUser()` - User management

### 3. State Management
- **Local state**: Component-level with `ref`/`reactive`
- **Shared state**: Pinia stores for global state
- **Server state**: `useFetch`/`useAsyncData` for API data

---

## References

- See `.github/copilot/rules/` for detailed conventions
