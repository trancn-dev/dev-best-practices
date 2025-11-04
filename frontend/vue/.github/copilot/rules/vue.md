# Rule: Vue 3 Composition API Standards

## Intent
This rule defines best practices and standards for Vue 3 Composition API usage in the Nuxt frontend.

## Scope
Applies to all Vue components, composables, and related code using Vue 3 Composition API.

---

## 1. Component Structure

### Single File Component (SFC) Structure

**Preferred order:**

```vue
<script setup lang="ts">
// 1. Imports
// 2. Props
// 3. Emits
// 4. Composables
// 5. Reactive state
// 6. Computed properties
// 7. Watch/WatchEffect
// 8. Lifecycle hooks
// 9. Methods
// 10. Provide/Inject
</script>

<template>
  <!-- Template content -->
</template>

<style scoped>
/* Styles */
</style>
```

**Example:**

```vue
<script setup lang="ts">
import { computed, ref, watch, onMounted } from 'vue'
import { useAuth } from '~/composables/useAuth'
import type { User } from '~/types'

// Props
const props = withDefaults(defineProps<{
  userId: string | number
  editable?: boolean
}>(), {
  editable: false
})

// Emits
const emit = defineEmits<{
  'update:profile': [user: User]
  'cancel': []
}>()

// Composables
const { user, isAuthenticated } = useAuth()

// Reactive state
const isLoading = ref(false)
const error = ref<string | null>(null)
const formData = ref<Partial<User>>({})

// Computed
const displayName = computed(() => {
  return user.value?.name || 'Anonymous'
})

const canEdit = computed(() => {
  return props.editable && isAuthenticated.value
})

// Watch
watch(() => props.userId, (newId) => {
  fetchUser(newId)
}, { immediate: true })

// Lifecycle
onMounted(() => {
  console.log('Component mounted')
})

// Methods
async function fetchUser(id: string | number) {
  isLoading.value = true
  try {
    const data = await $fetch(`/api/users/${id}`)
    formData.value = data
  } catch (err) {
    error.value = 'Failed to fetch user'
  } finally {
    isLoading.value = false
  }
}

function handleSave() {
  emit('update:profile', formData.value as User)
}

function handleCancel() {
  emit('cancel')
}
</script>

<template>
  <div class="user-profile">
    <div v-if="isLoading">Loading...</div>
    <div v-else-if="error">{{ error }}</div>
    <div v-else>
      <h2>{{ displayName }}</h2>
      <!-- More template content -->
    </div>
  </div>
</template>

<style scoped>
.user-profile {
  padding: 1rem;
}
</style>
```

---

## 2. Props & Emits

### Props Definition

**✅ Good - TypeScript with defaults:**

```typescript
// With defaults
const props = withDefaults(defineProps<{
  title: string
  count?: number
  items?: string[]
  config?: Record<string, any>
}>(), {
  count: 0,
  items: () => [],
  config: () => ({})
})

// Without defaults
const props = defineProps<{
  userId: string | number
  required: boolean
}>()
```

**❌ Bad - No types:**

```typescript
const props = defineProps({
  title: String,
  count: Number
})
```

### Emits Definition

**✅ Good - Typed emits:**

```typescript
const emit = defineEmits<{
  'update:modelValue': [value: string]
  'change': [id: number, name: string]
  'submit': [data: FormData]
  'cancel': []
}>()

// Usage
emit('update:modelValue', 'new value')
emit('change', 1, 'John')
emit('submit', formData)
emit('cancel')
```

**❌ Bad - Untyped:**

```typescript
const emit = defineEmits(['update:modelValue', 'change'])
```

---

## 3. Reactive State

### ref vs reactive

**Use `ref` for:**
- Primitive values (string, number, boolean)
- Single values that need reactivity
- When you need `.value` access

```typescript
const count = ref(0)
const name = ref('')
const isLoading = ref(false)
const user = ref<User | null>(null)

// Access with .value
count.value++
name.value = 'John'
```

**Use `reactive` for:**
- Objects with multiple related properties
- When you want to destructure without losing reactivity (with `toRefs`)

```typescript
const state = reactive({
  count: 0,
  name: '',
  isLoading: false
})

// Access without .value
state.count++
state.name = 'John'

// Destructure with toRefs
const { count, name } = toRefs(state)
```

**✅ Prefer `ref` for simplicity and consistency**

---

## 4. Computed Properties

**✅ Good - Use computed for derived data:**

```typescript
const count = ref(10)
const doubleCount = computed(() => count.value * 2)

const user = ref<User>({ name: 'John', age: 30 })
const displayName = computed(() => {
  return `${user.value.name} (${user.value.age})`
})

// Writable computed
const fullName = computed({
  get() {
    return `${firstName.value} ${lastName.value}`
  },
  set(value) {
    const [first, last] = value.split(' ')
    firstName.value = first
    lastName.value = last
  }
})
```

**❌ Bad - Using methods for derived data:**

```typescript
function getDoubleCount() {
  return count.value * 2
}
```

**When to use computed vs methods:**
- **Computed**: Cached, reactive dependencies, pure transformations
- **Methods**: Event handlers, async operations, side effects

---

## 5. Watchers

### watch vs watchEffect

**Use `watch` when:**
- You need to watch specific sources
- You need both old and new values
- You want lazy execution

```typescript
// Watch single ref
watch(count, (newVal, oldVal) => {
  console.log(`Count changed from ${oldVal} to ${newVal}`)
})

// Watch multiple sources
watch([firstName, lastName], ([newFirst, newLast], [oldFirst, oldLast]) => {
  console.log('Name changed')
})

// Watch reactive object property
watch(() => user.value.name, (newName) => {
  console.log(`Name: ${newName}`)
})

// With options
watch(count, (newVal) => {
  console.log(newVal)
}, {
  immediate: true,  // Run immediately
  deep: true,       // Deep watch for objects
  flush: 'post'     // Run after component update
})
```

**Use `watchEffect` when:**
- You want to track all dependencies automatically
- You don't need old values
- You want immediate execution

```typescript
watchEffect(() => {
  console.log(`Count is ${count.value}`)
  console.log(`Name is ${name.value}`)
  // Automatically tracks count and name
})

// With cleanup
watchEffect((onCleanup) => {
  const timer = setTimeout(() => {
    // Do something
  }, 1000)

  onCleanup(() => {
    clearTimeout(timer)
  })
})
```

**⚠️ Be cautious with watchers - they can cause performance issues if overused**

---

## 6. Lifecycle Hooks

```typescript
import {
  onBeforeMount,
  onMounted,
  onBeforeUpdate,
  onUpdated,
  onBeforeUnmount,
  onUnmounted,
  onErrorCaptured
} from 'vue'

// Before component is mounted
onBeforeMount(() => {
  console.log('Before mount')
})

// After component is mounted (most common)
onMounted(() => {
  console.log('Mounted')
  // Fetch data, setup event listeners, etc.
})

// Before component updates
onBeforeUpdate(() => {
  console.log('Before update')
})

// After component updates
onUpdated(() => {
  console.log('Updated')
})

// Before component unmounts
onBeforeUnmount(() => {
  console.log('Before unmount')
  // Cleanup: remove listeners, cancel requests
})

// After component unmounts
onUnmounted(() => {
  console.log('Unmounted')
})

// Error handling
onErrorCaptured((err, instance, info) => {
  console.error('Error captured:', err)
  return false // Prevent propagation
})
```

**Common use cases:**

```typescript
// Fetch data on mount
onMounted(async () => {
  const data = await fetchData()
  items.value = data
})

// Cleanup on unmount
onMounted(() => {
  const interval = setInterval(() => {
    // Do something
  }, 1000)

  onUnmounted(() => {
    clearInterval(interval)
  })
})
```

---

## 7. Provide / Inject

**✅ Good - Typed provide/inject:**

```typescript
// Parent component
import type { InjectionKey } from 'vue'

interface UserContext {
  user: Ref<User | null>
  updateUser: (user: User) => void
}

const UserContextKey: InjectionKey<UserContext> = Symbol('UserContext')

// Provide
const user = ref<User | null>(null)
const updateUser = (newUser: User) => {
  user.value = newUser
}

provide(UserContextKey, {
  user,
  updateUser
})

// Child component
const userContext = inject(UserContextKey)
if (userContext) {
  const { user, updateUser } = userContext
}

// With default value
const userContext = inject(UserContextKey, {
  user: ref(null),
  updateUser: () => {}
})
```

**Use provide/inject for:**
- Deep component trees (avoid prop drilling)
- Plugin-like features
- Theme/configuration

**Don't use for:**
- Simple parent-child communication (use props/emits)
- Global state (use Pinia instead)

---

## 8. Template Best Practices

### Directives

**v-if vs v-show:**

```vue
<!-- Use v-if when: -->
<!-- - Condition rarely changes -->
<!-- - Component won't render initially -->
<div v-if="isAuthenticated">
  <UserDashboard />
</div>

<!-- Use v-show when: -->
<!-- - Toggled frequently -->
<!-- - Element always exists in DOM -->
<div v-show="isVisible">
  Content
</div>
```

**v-for with :key:**

```vue
<!-- ✅ Good - Unique key -->
<div
  v-for="item in items"
  :key="item.id"
>
  {{ item.name }}
</div>

<!-- ❌ Bad - Index as key -->
<div
  v-for="(item, index) in items"
  :key="index"
>
  {{ item.name }}
</div>

<!-- ❌ Bad - No key -->
<div v-for="item in items">
  {{ item.name }}
</div>
```

**v-model:**

```vue
<!-- Basic v-model -->
<input v-model="name" />

<!-- With modifiers -->
<input v-model.trim="name" />
<input v-model.number="age" />
<input v-model.lazy="description" />

<!-- Custom component v-model -->
<CustomInput v-model="value" />

<!-- Multiple v-models -->
<CustomInput
  v-model:first-name="firstName"
  v-model:last-name="lastName"
/>
```

---

## 9. Component Communication

### Props Down, Events Up

```vue
<!-- Parent.vue -->
<script setup lang="ts">
const count = ref(0)

function handleIncrement(amount: number) {
  count.value += amount
}
</script>

<template>
  <ChildComponent
    :count="count"
    @increment="handleIncrement"
  />
</template>

<!-- ChildComponent.vue -->
<script setup lang="ts">
const props = defineProps<{
  count: number
}>()

const emit = defineEmits<{
  'increment': [amount: number]
}>()

function increment() {
  emit('increment', 1)
}
</script>

<template>
  <div>
    Count: {{ count }}
    <button @click="increment">Increment</button>
  </div>
</template>
```

---

## 10. TypeScript Integration

```typescript
// Define interfaces
interface User {
  id: number
  name: string
  email: string
  role: 'admin' | 'user'
}

// Use in component
const user = ref<User | null>(null)
const users = ref<User[]>([])

// Generic component props
defineProps<{
  items: T[]
  onSelect: (item: T) => void
}>()

// Typed computed
const activeUsers = computed<User[]>(() => {
  return users.value.filter(u => u.role === 'admin')
})
```

---

## 11. Performance Optimization

```vue
<script setup lang="ts">
// Lazy load heavy components
const HeavyComponent = defineAsyncComponent(() =>
  import('./HeavyComponent.vue')
)

// Memoize expensive computations
const expensiveValue = computed(() => {
  // Expensive calculation
  return heavyComputation(data.value)
})

// Use v-once for static content
</script>

<template>
  <!-- Static content -->
  <div v-once>
    <h1>{{ staticTitle }}</h1>
  </div>

  <!-- Lazy loaded component -->
  <Suspense>
    <HeavyComponent />
    <template #fallback>
      <div>Loading...</div>
    </template>
  </Suspense>
</template>
```

---

## 12. Common Patterns

### Loading State

```typescript
const isLoading = ref(false)
const error = ref<string | null>(null)
const data = ref<Data | null>(null)

async function fetchData() {
  isLoading.value = true
  error.value = null

  try {
    data.value = await $fetch('/api/data')
  } catch (err) {
    error.value = 'Failed to fetch data'
  } finally {
    isLoading.value = false
  }
}
```

### Form Handling

```typescript
const form = ref({
  name: '',
  email: '',
  password: ''
})

const errors = ref<Record<string, string>>({})

function validate() {
  errors.value = {}

  if (!form.value.name) {
    errors.value.name = 'Name is required'
  }

  if (!form.value.email) {
    errors.value.email = 'Email is required'
  }

  return Object.keys(errors.value).length === 0
}

async function handleSubmit() {
  if (!validate()) return

  try {
    await $fetch('/api/submit', {
      method: 'POST',
      body: form.value
    })
  } catch (err) {
    // Handle error
  }
}
```

---

## References

- [Vue 3 Composition API](https://vuejs.org/guide/extras/composition-api-faq.html)
- [Vue 3 Style Guide](https://vuejs.org/style-guide/)
- [Nuxt 3 Composables](https://nuxt.com/docs/guide/directory-structure/composables)
