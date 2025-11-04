# Rule: Nuxt 3 Best Practices

## Intent
This rule defines best practices and standards for Nuxt 3 development including file structure, routing, data fetching, and Nuxt-specific features.

## Scope
Applies to all Nuxt 3 specific code, configurations, and patterns.

---

## 1. Directory Structure

```
app/
├── assets/          # Uncompiled assets (SCSS, images)
├── components/      # Vue components (auto-imported)
├── composables/     # Composable functions (auto-imported)
├── layouts/         # Layout components
├── middleware/      # Route middleware
├── pages/           # File-based routing
├── plugins/         # Plugins
├── public/          # Static files served at root
├── server/          # Server API routes
├── stores/          # Pinia stores
└── types/           # TypeScript type definitions
```

---

## 2. File-Based Routing

### Pages Structure

```
pages/
├── index.vue                    # /
├── about.vue                    # /about
├── posts/
│   ├── index.vue               # /posts
│   ├── [id].vue                # /posts/:id
│   └── create.vue              # /posts/create
├── users/
│   └── [id]/
│       ├── index.vue           # /users/:id
│       ├── edit.vue            # /users/:id/edit
│       └── settings.vue        # /users/:id/settings
└── [...slug].vue               # Catch-all route
```

### Page Component

```vue
<script setup lang="ts">
// Define page meta
definePageMeta({
  layout: 'default',
  middleware: ['auth'],
  title: 'Post Detail',
  keepalive: false
})

// Access route params
const route = useRoute()
const postId = route.params.id

// Fetch data
const { data: post } = await useFetch(`/api/posts/${postId}`)
</script>

<template>
  <div>
    <h1>{{ post?.title }}</h1>
    <p>{{ post?.content }}</p>
  </div>
</template>
```

### Dynamic Routes

```vue
<!-- pages/posts/[id].vue -->
<script setup lang="ts">
const route = useRoute()
const postId = computed(() => route.params.id)

// Fetch post by ID
const { data: post } = await useFetch(`/api/posts/${postId.value}`)
</script>

<!-- pages/blog/[...slug].vue - Catch all -->
<script setup lang="ts">
const route = useRoute()
const slug = route.params.slug // ['category', 'subcategory', 'post']
</script>
```

---

## 3. Layouts

### Layout Definition

```vue
<!-- layouts/default.vue -->
<script setup lang="ts">
const { isAuthenticated } = useAuth()
</script>

<template>
  <div class="layout-default">
    <AppHeader />
    <main>
      <slot />
    </main>
    <AppFooter />
  </div>
</template>

<style scoped>
.layout-default {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

main {
  flex: 1;
}
</style>
```

### Using Layouts in Pages

```vue
<script setup lang="ts">
// Define layout
definePageMeta({
  layout: 'admin'
})

// Or use false for no layout
definePageMeta({
  layout: false
})
</script>

<template>
  <!-- Page content -->
</template>
```

### Dynamic Layout

```vue
<script setup lang="ts">
const layout = computed(() => {
  return isAdmin.value ? 'admin' : 'default'
})

setPageLayout(layout)
</script>
```

---

## 4. Data Fetching

### useFetch vs $fetch

**Use `useFetch` for:**
- Component data that should be SSR-friendly
- Automatic reactivity
- Error and pending states

```typescript
const { data, pending, error, refresh } = await useFetch('/api/posts', {
  // Options
  key: 'posts',           // Cache key
  method: 'GET',
  query: { limit: 10 },
  headers: {},
  onRequest({ request, options }) {
    // Intercept request
  },
  onResponse({ response }) {
    // Handle response
  },
  transform(data) {
    // Transform response
    return data.map(item => ({ ...item, transformed: true }))
  }
})

// Reactive
watch(page, () => {
  refresh()
})
```

**Use `$fetch` for:**
- Event handlers
- Not SSR-critical
- More control over request

```typescript
async function handleSubmit() {
  try {
    const result = await $fetch('/api/posts', {
      method: 'POST',
      body: formData.value
    })
    // Handle success
  } catch (error) {
    // Handle error
  }
}
```

### useAsyncData

**For more complex data fetching:**

```typescript
const { data, pending, error, refresh } = await useAsyncData(
  'posts',  // Unique key
  async () => {
    const posts = await $fetch('/api/posts')
    const categories = await $fetch('/api/categories')

    return {
      posts,
      categories
    }
  },
  {
    // Options
    server: true,      // Fetch on server
    lazy: false,       // Wait for data before navigation
    immediate: true,   // Fetch immediately
    watch: [page],     // Re-fetch when dependencies change
    transform(data) {
      // Transform data
      return data
    }
  }
)
```

### useLazyFetch & useLazyAsyncData

**For non-blocking fetches:**

```typescript
// Won't block navigation
const { data, pending } = useLazyFetch('/api/posts')

const { data } = useLazyAsyncData('posts', () => $fetch('/api/posts'))
```

---

## 5. Composables

### Creating Composables

```typescript
// composables/useAuth.ts
export const useAuth = () => {
  const user = useState<User | null>('auth-user', () => null)
  const token = useCookie('auth-token')

  const isAuthenticated = computed(() => !!user.value)

  const login = async (credentials: Credentials) => {
    const { data } = await $fetch('/api/auth/login', {
      method: 'POST',
      body: credentials
    })

    user.value = data.user
    token.value = data.token
  }

  const logout = async () => {
    await $fetch('/api/auth/logout', { method: 'POST' })
    user.value = null
    token.value = null
  }

  const fetchUser = async () => {
    if (token.value) {
      const { data } = await $fetch('/api/auth/me')
      user.value = data
    }
  }

  return {
    user: readonly(user),
    isAuthenticated,
    login,
    logout,
    fetchUser
  }
}
```

### Composable Best Practices

**✅ Good:**

```typescript
// Return readonly refs for state
export const useCounter = () => {
  const count = ref(0)

  const increment = () => count.value++

  return {
    count: readonly(count),
    increment
  }
}

// Use useState for shared state
export const useSharedState = () => {
  const state = useState('shared-key', () => ({
    value: 0
  }))

  return state
}
```

**❌ Bad:**

```typescript
// Don't expose mutable state directly
export const useCounter = () => {
  const count = ref(0)
  return count  // Allows external mutation
}
```

---

## 6. Middleware

### Route Middleware

```typescript
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const { isAuthenticated } = useAuth()

  if (!isAuthenticated.value) {
    return navigateTo('/login')
  }
})

// middleware/admin.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const { user } = useAuth()

  if (user.value?.role !== 'admin') {
    return abortNavigation('Unauthorized')
  }
})
```

### Using Middleware

```vue
<script setup lang="ts">
// Apply to single page
definePageMeta({
  middleware: 'auth'
})

// Apply multiple middleware
definePageMeta({
  middleware: ['auth', 'admin']
})

// Inline middleware
definePageMeta({
  middleware: (to, from) => {
    if (to.params.id === '1') {
      return abortNavigation()
    }
  }
})
</script>
```

### Global Middleware

```typescript
// middleware/auth.global.ts
export default defineNuxtRouteMiddleware((to, from) => {
  // Runs on every route
})
```

---

## 7. Plugins

### Plugin Definition

```typescript
// plugins/api.ts
export default defineNuxtPlugin((nuxtApp) => {
  const config = useRuntimeConfig()

  const api = $fetch.create({
    baseURL: config.public.apiBase,
    onRequest({ options }) {
      const token = useCookie('auth-token')
      if (token.value) {
        options.headers = {
          ...options.headers,
          Authorization: `Bearer ${token.value}`
        }
      }
    },
    onResponseError({ response }) {
      if (response.status === 401) {
        navigateTo('/login')
      }
    }
  })

  return {
    provide: {
      api
    }
  }
})
```

### Using Plugins

```vue
<script setup lang="ts">
const { $api } = useNuxtApp()

const { data } = await $api('/posts')
</script>
```

---

## 8. State Management (Pinia)

### Store Definition

```typescript
// stores/user.ts
import { defineStore } from 'pinia'

export const useUserStore = defineStore('user', () => {
  // State
  const user = ref<User | null>(null)
  const users = ref<User[]>([])

  // Getters
  const isAuthenticated = computed(() => !!user.value)
  const userName = computed(() => user.value?.name || 'Guest')

  // Actions
  async function fetchUser(id: number) {
    const data = await $fetch(`/api/users/${id}`)
    user.value = data
  }

  async function fetchUsers() {
    const data = await $fetch('/api/users')
    users.value = data
  }

  function logout() {
    user.value = null
  }

  return {
    user,
    users,
    isAuthenticated,
    userName,
    fetchUser,
    fetchUsers,
    logout
  }
})
```

### Using Stores

```vue
<script setup lang="ts">
import { useUserStore } from '~/stores/user'

const userStore = useUserStore()

// Access state
const user = computed(() => userStore.user)

// Call actions
onMounted(() => {
  userStore.fetchUser(1)
})

// Destructure with storeToRefs
const { user, isAuthenticated } = storeToRefs(userStore)
const { logout } = userStore
</script>
```

---

## 9. Server Routes

### API Route

```typescript
// server/api/posts/index.get.ts
export default defineEventHandler(async (event) => {
  const query = getQuery(event)

  const posts = await db.posts.findMany({
    where: {
      published: true
    },
    take: Number(query.limit) || 10
  })

  return posts
})

// server/api/posts/[id].get.ts
export default defineEventHandler(async (event) => {
  const id = getRouterParam(event, 'id')

  const post = await db.posts.findUnique({
    where: { id: Number(id) }
  })

  if (!post) {
    throw createError({
      statusCode: 404,
      message: 'Post not found'
    })
  }

  return post
})

// server/api/posts/index.post.ts
export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  // Validate
  if (!body.title) {
    throw createError({
      statusCode: 400,
      message: 'Title is required'
    })
  }

  const post = await db.posts.create({
    data: body
  })

  return post
})
```

### Server Middleware

```typescript
// server/middleware/auth.ts
export default defineEventHandler(async (event) => {
  const token = getCookie(event, 'auth-token')

  if (!token) {
    throw createError({
      statusCode: 401,
      message: 'Unauthorized'
    })
  }

  // Verify token and attach user to event
  const user = await verifyToken(token)
  event.context.user = user
})
```

---

## 10. Configuration

### nuxt.config.ts

```typescript
export default defineNuxtConfig({
  // App config
  app: {
    head: {
      title: 'My App',
      meta: [
        { name: 'description', content: 'My amazing site' }
      ]
    }
  },

  // Runtime config
  runtimeConfig: {
    // Private (server-only)
    apiSecret: process.env.API_SECRET,

    // Public (client + server)
    public: {
      apiBase: process.env.API_BASE || 'http://localhost:3000'
    }
  },

  // Modules
  modules: [
    '@pinia/nuxt',
    '@nuxtjs/tailwindcss'
  ],

  // TypeScript
  typescript: {
    strict: true,
    typeCheck: true
  },

  // Dev tools
  devtools: {
    enabled: true
  }
})
```

---

## 11. SEO & Meta Tags

```vue
<script setup lang="ts">
// Page meta
useHead({
  title: 'My Page',
  meta: [
    { name: 'description', content: 'Page description' },
    { property: 'og:title', content: 'My Page' },
    { property: 'og:image', content: '/image.jpg' }
  ],
  link: [
    { rel: 'canonical', href: 'https://mysite.com/page' }
  ]
})

// Or use useSeoMeta
useSeoMeta({
  title: 'My Page',
  description: 'Page description',
  ogTitle: 'My Page',
  ogDescription: 'Page description',
  ogImage: '/image.jpg',
  twitterCard: 'summary_large_image'
})

// Dynamic meta
const post = ref<Post>()

useHead({
  title: () => post.value?.title,
  meta: [
    { name: 'description', content: () => post.value?.excerpt }
  ]
})
</script>
```

---

## 12. Error Handling

```vue
<script setup lang="ts">
// Throw error in component
throw createError({
  statusCode: 404,
  message: 'Page not found'
})

// Catch errors
const { data, error } = await useFetch('/api/posts')

if (error.value) {
  // Handle error
  console.error(error.value)
}
</script>
```

### Error Page

```vue
<!-- error.vue -->
<script setup lang="ts">
const props = defineProps<{
  error: {
    statusCode: number
    message: string
  }
}>()

const handleError = () => clearError({ redirect: '/' })
</script>

<template>
  <div>
    <h1>{{ error.statusCode }}</h1>
    <p>{{ error.message }}</p>
    <button @click="handleError">Go Home</button>
  </div>
</template>
```

---

## 13. Performance Best Practices

```vue
<script setup lang="ts">
// Lazy load components
const LazyComponent = defineAsyncComponent(() =>
  import('~/components/Heavy.vue')
)

// Prefetch routes
const router = useRouter()
router.prefetch('/about')

// Image optimization
</script>

<template>
  <!-- Lazy hydration -->
  <LazyComponent v-if="show" />

  <!-- Nuxt Image -->
  <NuxtImg
    src="/image.jpg"
    width="400"
    height="300"
    loading="lazy"
  />

  <!-- Client-only -->
  <ClientOnly>
    <HeavyComponent />
    <template #fallback>
      <Loading />
    </template>
  </ClientOnly>
</template>
```

---

## References

- [Nuxt 3 Documentation](https://nuxt.com/docs)
- [Nuxt 3 Examples](https://nuxt.com/docs/examples)
- [Pinia Documentation](https://pinia.vuejs.org/)
