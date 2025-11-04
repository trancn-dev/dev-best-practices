# Prompt: Bug Fix Assistant

## Purpose
Help diagnose and fix bugs in Nuxt/Vue applications with systematic debugging approach.

## When to Use
- Component errors or exceptions
- Unexpected UI behavior
- API/data fetching issues
- Performance problems
- Hydration mismatches

---

## Prompt Template

```
I'm experiencing a bug in my Nuxt application:

**Symptom**: [Describe what's happening]
**Expected**: [What should happen]
**Environment**: [local/staging/production]
**Nuxt Version**: [e.g., 3.x]
**Node Version**: [e.g., 20.x]

**Error Message** (if any):
[ERROR_MESSAGE]

**Component Code**:
[RELEVANT_CODE]

**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**What I've Tried**:
- [Attempt 1]
- [Attempt 2]

Please help me:
1. Diagnose the root cause
2. Provide a fix
3. Explain why it happened
4. Suggest how to prevent similar issues
```

---

## Example: Hydration Mismatch

**Input:**
```
I'm experiencing a bug in my Nuxt application:

**Symptom**: Console shows "Hydration completed but contains mismatches"
**Expected**: Clean hydration without warnings
**Environment**: Development
**Nuxt Version**: 3.8

**Component Code**:
```vue
<template>
  <div>
    <p>{{ new Date().toLocaleDateString() }}</p>
  </div>
</template>
```

**Steps to Reproduce**:
1. Load page
2. Check console
3. See hydration mismatch warning
```

**Expected Output:**

### 🔍 Root Cause
The date is generated on server and client at different times, causing HTML mismatch.

### ✅ Solution
```vue
<template>
  <div>
    <ClientOnly>
      <p>{{ new Date().toLocaleDateString() }}</p>
    </ClientOnly>
  </div>
</template>
```

### 📚 Explanation
`ClientOnly` component ensures code only runs on client, avoiding SSR/CSR mismatch.

### 🛡️ Prevention
- Avoid dynamic data in SSR that changes between server/client
- Use `ClientOnly` for client-specific code
- Use `useState` for shared state between server/client

---

## Common Issues

### 1. useFetch not reactive
**Problem**: Data doesn't update when dependencies change
**Solution**: Use `watch` option or `refresh()`

### 2. Component not found
**Problem**: Auto-import not working
**Solution**: Check component naming (PascalCase) and location

### 3. Middleware not running
**Problem**: Page loads without middleware
**Solution**: Check middleware naming and `definePageMeta`

---

## References

- [Nuxt Error Handling](https://nuxt.com/docs/getting-started/error-handling)
- [Vue Debugging Guide](https://vuejs.org/guide/extras/debugging.html)
