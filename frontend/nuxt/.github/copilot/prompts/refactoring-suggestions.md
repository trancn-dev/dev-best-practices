# Prompt: Refactoring Suggestions

## Purpose
Get recommendations for refactoring code to improve quality, maintainability, and performance.

## When to Use
- Code smells detected
- Component too large or complex
- Duplicated code
- Performance issues

---

## Prompt Template

```
I need refactoring suggestions for [CODE/COMPONENT]:

**Current Issue**:
[Describe the problem - complexity, duplication, performance, etc.]

**Current Code**:
```[language]
[PASTE_CODE]
```

**Goals**:
- [Goal 1: e.g., reduce complexity]
- [Goal 2: e.g., improve reusability]
- [Goal 3: e.g., better performance]

Please suggest:
1. What to refactor
2. How to refactor (with code examples)
3. Benefits of the refactoring
4. Potential risks or trade-offs
```

---

## Example: Large Component

**Input:**
```
I need refactoring suggestions for UserDashboard.vue:

**Current Issue**:
Component is 500+ lines, does too much - fetches data, handles forms, renders charts, etc.

**Current Code**:
```vue
<script setup>
// 200 lines of logic
const user = ref()
const posts = ref()
const stats = ref()
// Fetch data, form handling, chart config, etc.
</script>

<template>
  <!-- 300 lines of template -->
  <div>
    <UserProfile />
    <PostsList />
    <StatsCharts />
    <EditForm />
  </div>
</template>
```

**Goals**:
- Reduce complexity
- Improve maintainability
- Better testability
```

**Expected Output:**

### Refactoring Plan

#### 1. Extract Composables
```typescript
// composables/useUserDashboard.ts
export const useUserDashboard = (userId: string) => {
  const { data: user } = useFetch(`/api/users/${userId}`)
  const { data: posts } = useFetch(`/api/users/${userId}/posts`)
  const { data: stats } = useFetch(`/api/users/${userId}/stats`)

  return { user, posts, stats }
}
```

#### 2. Split into Smaller Components
```
UserDashboard.vue (orchestrator, 100 lines)
├── UserProfileCard.vue (50 lines)
├── PostsList.vue (80 lines)
├── StatsCharts.vue (100 lines)
└── UserEditForm.vue (150 lines)
```

#### 3. Extract Form Logic
```typescript
// composables/useUserForm.ts
export const useUserForm = (initialData: User) => {
  const formData = ref({ ...initialData })
  const errors = ref({})

  function validate() { /* ... */ }
  async function submit() { /* ... */ }

  return { formData, errors, validate, submit }
}
```

### Benefits
- **Maintainability**: Smaller, focused components
- **Testability**: Each piece can be tested independently
- **Reusability**: Composables can be used elsewhere
- **Performance**: Smaller components = smaller bundles

### Risks
- **Over-abstraction**: Don't split too much
- **Indirection**: More files to navigate

---

## Common Refactoring Patterns

### 1. Extract Composable
When: Logic is reused or component too complex

### 2. Split Component
When: Component > 200 lines or multiple responsibilities

### 3. Extract Utility Function
When: Pure logic not tied to Vue reactivity

### 4. Use Computed Instead of Method
When: Deriving data that should be cached

### 5. Replace Watch with Computed
When: Simple data transformations

---

## References

- [Refactoring Guru](https://refactoring.guru/)
- [Vue Composition API Best Practices](https://vuejs.org/guide/reusability/composables.html)
