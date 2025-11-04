# Rule: Frontend Best Practices (React/Vue/Modern Web)

## Intent
Enforce modern frontend development practices for React, Vue, and vanilla JavaScript applications. Focus on component design, state management, performance, and accessibility.

## Scope
Applies to all frontend code including React components, Vue components, hooks, state management, CSS, and UI interactions.

---

## 1. React Best Practices

### Component Structure

- ✅ **MUST** use functional components with hooks
- ✅ **MUST** follow single responsibility principle
- ✅ **MUST** define PropTypes or TypeScript types
- ✅ **MUST** cleanup effects (return function)
- ❌ **MUST NOT** use class components (unless legacy)

```jsx
// ✅ GOOD
import { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

function UserProfile({ userId, onUpdate }) {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        let isMounted = true;

        async function fetchUser() {
            const data = await fetch(`/api/users/${userId}`);
            if (isMounted) setUser(data);
        }

        fetchUser();
        return () => { isMounted = false; };
    }, [userId]);

    if (loading) return <LoadingSpinner />;
    return <div>{user?.name}</div>;
}

UserProfile.propTypes = {
    userId: PropTypes.string.isRequired,
    onUpdate: PropTypes.func
};
```

### Custom Hooks

- ✅ **MUST** start with "use" prefix
- ✅ **MUST** extract reusable logic
- ✅ **MUST** cleanup subscriptions

```jsx
// ✅ GOOD - Custom hook
function useFetch(url) {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const controller = new AbortController();

        fetch(url, { signal: controller.signal })
            .then(res => res.json())
            .then(setData)
            .catch(setError)
            .finally(() => setLoading(false));

        return () => controller.abort();
    }, [url]);

    return { data, loading, error };
}

// Usage
function UserList() {
    const { data: users, loading } = useFetch('/api/users');
    return loading ? <Spinner /> : <ul>{users.map(u => <li>{u.name}</li>)}</ul>;
}
```

### Performance

- ✅ **MUST** use React.memo for expensive components
- ✅ **MUST** use useMemo for expensive calculations
- ✅ **MUST** use useCallback for callback props
- ❌ **MUST NOT** create functions inside render

```jsx
// ✅ GOOD
import { memo, useMemo, useCallback } from 'react';

const ExpensiveList = memo(({ items, onItemClick }) => {
    return items.map(item => <Item key={item.id} onClick={onItemClick} />);
});

function Parent({ items }) {
    const handleClick = useCallback((id) => console.log(id), []);
    const sortedItems = useMemo(() => [...items].sort(), [items]);

    return <ExpensiveList items={sortedItems} onItemClick={handleClick} />;
}
```

---

## 2. Vue.js Best Practices

### Component Structure

```vue
<!-- ✅ GOOD - Composition API -->
<script setup>
import { ref, computed, watch, onMounted } from 'vue';

const props = defineProps({
    userId: { type: String, required: true }
});

const emit = defineEmits(['update']);

const user = ref(null);
const loading = ref(true);

const fullName = computed(() =>
    user.value ? `${user.value.firstName} ${user.value.lastName}` : ''
);

watch(() => props.userId, async (newId) => {
    loading.value = true;
    user.value = await fetch(`/api/users/${newId}`).then(r => r.json());
    loading.value = false;
}, { immediate: true });

function handleUpdate(data) {
    emit('update', data);
}
</script>

<template>
    <div v-if="loading">Loading...</div>
    <div v-else>{{ fullName }}</div>
</template>
```

### Computed vs Methods

- ✅ **MUST** use computed for derived state (cached)
- ✅ **MUST** use methods for actions (not cached)

```vue
<script setup>
// ✅ GOOD - computed (cached)
const fullPrice = computed(() => price.value * quantity.value * TAX);

// ✅ GOOD - method (action)
function submitForm() {
    // ...
}
</script>
```

---

## 3. State Management

### React Context

```jsx
// ✅ GOOD - Context for global state
import { createContext, useContext, useState } from 'react';

const AuthContext = createContext();

export function AuthProvider({ children }) {
    const [user, setUser] = useState(null);

    const login = async (credentials) => {
        const user = await auth.login(credentials);
        setUser(user);
    };

    const logout = () => setUser(null);

    return (
        <AuthContext.Provider value={{ user, login, logout }}>
            {children}
        </AuthContext.Provider>
    );
}

export const useAuth = () => useContext(AuthContext);

// Usage
function Profile() {
    const { user, logout } = useAuth();
    return <div>{user.name} <button onClick={logout}>Logout</button></div>;
}
```

### Redux/Pinia Rules

- ✅ **MUST** normalize state shape
- ✅ **MUST** keep state minimal and derived
- ✅ **MUST** use selectors for computed state
- ❌ **MUST NOT** mutate state directly

```javascript
// ✅ GOOD - Redux Toolkit
import { createSlice } from '@reduxjs/toolkit';

const usersSlice = createSlice({
    name: 'users',
    initialState: { entities: {}, ids: [] },
    reducers: {
        userAdded(state, action) {
            const user = action.payload;
            state.entities[user.id] = user;
            state.ids.push(user.id);
        }
    }
});
```

---

## 4. Forms & Validation

- ✅ **MUST** use controlled components
- ✅ **MUST** validate on submit (and blur for UX)
- ✅ **MUST** show field-specific errors
- ✅ **SHOULD** use form libraries (React Hook Form, Formik)

```jsx
// ✅ GOOD - React Hook Form
import { useForm } from 'react-hook-form';

function LoginForm() {
    const { register, handleSubmit, formState: { errors } } = useForm();

    const onSubmit = (data) => {
        console.log(data);
    };

    return (
        <form onSubmit={handleSubmit(onSubmit)}>
            <input
                {...register('email', {
                    required: 'Email is required',
                    pattern: {
                        value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                        message: 'Invalid email'
                    }
                })}
            />
            {errors.email && <span>{errors.email.message}</span>}

            <input
                type="password"
                {...register('password', {
                    required: 'Password is required',
                    minLength: { value: 8, message: 'Min 8 characters' }
                })}
            />
            {errors.password && <span>{errors.password.message}</span>}

            <button type="submit">Login</button>
        </form>
    );
}
```

---

## 5. CSS & Styling

### CSS-in-JS / Modules

```jsx
// ✅ GOOD - CSS Modules
import styles from './Button.module.css';

function Button({ children, variant }) {
    return (
        <button className={`${styles.button} ${styles[variant]}`}>
            {children}
        </button>
    );
}
```

### Tailwind CSS

```jsx
// ✅ GOOD - Utility classes
function Card({ title, children }) {
    return (
        <div className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition">
            <h2 className="text-2xl font-bold mb-4">{title}</h2>
            <div className="text-gray-700">{children}</div>
        </div>
    );
}
```

### CSS Best Practices

- ✅ **MUST** use BEM or scoped CSS
- ✅ **MUST** avoid !important
- ✅ **SHOULD** use CSS variables for theming
- ❌ **MUST NOT** use inline styles (except dynamic values)

---

## 6. Accessibility (a11y)

### Semantic HTML

```jsx
// ✅ GOOD - Semantic HTML
<header>
    <nav>
        <ul>
            <li><a href="/">Home</a></li>
        </ul>
    </nav>
</header>

<main>
    <article>
        <h1>Title</h1>
        <p>Content</p>
    </article>
</main>

<footer>© 2025</footer>

// ❌ BAD - Divs everywhere
<div className="header">
    <div className="nav">
        <div className="link">Home</div>
    </div>
</div>
```

### ARIA Attributes

- ✅ **MUST** add aria-label for icon buttons
- ✅ **MUST** use aria-describedby for form errors
- ✅ **MUST** manage focus for modals/dialogs
- ✅ **MUST** support keyboard navigation

```jsx
// ✅ GOOD - Accessible button
<button
    aria-label="Close modal"
    onClick={handleClose}
>
    <CloseIcon />
</button>

// ✅ GOOD - Accessible form
<input
    id="email"
    aria-invalid={errors.email ? 'true' : 'false'}
    aria-describedby={errors.email ? 'email-error' : undefined}
/>
{errors.email && <span id="email-error" role="alert">{errors.email}</span>}
```

### Keyboard Navigation

```jsx
// ✅ GOOD - Keyboard support
function Dropdown() {
    const [open, setOpen] = useState(false);

    const handleKeyDown = (e) => {
        if (e.key === 'Escape') setOpen(false);
        if (e.key === 'Enter' || e.key === ' ') setOpen(!open);
    };

    return (
        <div
            role="button"
            tabIndex={0}
            onKeyDown={handleKeyDown}
            onClick={() => setOpen(!open)}
        >
            {/* ... */}
        </div>
    );
}
```

---

## 7. SEO Best Practices

### Meta Tags

```jsx
// ✅ GOOD - React Helmet
import { Helmet } from 'react-helmet';

function ProductPage({ product }) {
    return (
        <>
            <Helmet>
                <title>{product.name} | My Store</title>
                <meta name="description" content={product.description} />
                <meta property="og:title" content={product.name} />
                <meta property="og:image" content={product.image} />
                <link rel="canonical" href={`https://mystore.com/products/${product.id}`} />
            </Helmet>
            {/* ... */}
        </>
    );
}
```

### Server-Side Rendering

- ✅ **SHOULD** use SSR/SSG for public pages (Next.js, Nuxt)
- ✅ **MUST** provide meaningful content on first load
- ✅ **SHOULD** implement proper caching

---

## 8. Error Handling

### Error Boundaries (React)

```jsx
// ✅ GOOD - Error boundary
class ErrorBoundary extends React.Component {
    state = { hasError: false };

    static getDerivedStateFromError(error) {
        return { hasError: true };
    }

    componentDidCatch(error, info) {
        console.error('Error:', error, info);
    }

    render() {
        if (this.state.hasError) {
            return <ErrorMessage />;
        }
        return this.props.children;
    }
}

// Usage
<ErrorBoundary>
    <App />
</ErrorBoundary>
```

---

## 9. Copilot-Specific Instructions

### Code Generation Rules

When generating frontend code, Copilot **MUST**:

1. **USE** functional components with hooks
2. **ADD** PropTypes or TypeScript types
3. **IMPLEMENT** proper cleanup in useEffect
4. **SUGGEST** memoization for expensive operations
5. **ADD** accessibility attributes (ARIA)
6. **USE** semantic HTML elements
7. **IMPLEMENT** loading and error states
8. **SUGGEST** code splitting for large components

### Response Pattern

```markdown
✅ **Component Generated:**

\`\`\`jsx
import { useState, useEffect } from 'react';
import PropTypes from 'prop-types';

function UserList({ onUserSelect }) {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetch('/api/users')
            .then(r => r.json())
            .then(setUsers)
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div role="status">Loading...</div>;

    return (
        <ul role="list">
            {users.map(user => (
                <li key={user.id}>
                    <button onClick={() => onUserSelect(user)}>
                        {user.name}
                    </button>
                </li>
            ))}
        </ul>
    );
}

UserList.propTypes = {
    onUserSelect: PropTypes.func.isRequired
};
\`\`\`

**Features:**
- ✅ Loading state
- ✅ Semantic HTML (ul/li)
- ✅ ARIA roles
- ✅ PropTypes defined
- ✅ Key prop for list items
```

---

## 10. Checklist

### Component Quality
- [ ] Functional component with hooks
- [ ] PropTypes/TypeScript types defined
- [ ] Loading and error states
- [ ] Effect cleanup functions
- [ ] Memoization where needed

### Accessibility
- [ ] Semantic HTML used
- [ ] ARIA attributes added
- [ ] Keyboard navigation supported
- [ ] Focus management for modals
- [ ] Alt text for images

### Performance
- [ ] Code splitting implemented
- [ ] Images lazy loaded
- [ ] Components memoized
- [ ] Expensive calculations memoized

### SEO
- [ ] Meta tags defined
- [ ] Semantic structure
- [ ] SSR/SSG considered

---

## References

- React Documentation
- Vue 3 Documentation
- WAI-ARIA Authoring Practices
- Web Content Accessibility Guidelines (WCAG)
