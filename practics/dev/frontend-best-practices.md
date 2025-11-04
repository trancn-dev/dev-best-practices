# Frontend Best Practices - Thực Hành Tốt Nhất Frontend

> Comprehensive guide for modern frontend development
>
> **Mục đích**: Build performant, accessible, maintainable web applications

---

## 📋 Mục Lục
- [React Best Practices](#react-best-practices)
- [Vue.js Guidelines](#vuejs-guidelines)
- [State Management](#state-management)
- [Component Design](#component-design)
- [CSS Architecture](#css-architecture)
- [Performance Optimization](#performance-optimization)
- [Accessibility (a11y)](#accessibility-a11y)
- [SEO Best Practices](#seo-best-practices)

---

## ⚛️ REACT BEST PRACTICES

### Component Structure

```jsx
// ✅ GOOD - Functional component with hooks

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import PropTypes from 'prop-types';
import styles from './UserProfile.module.css';

/**
 * UserProfile component displays user information
 * @param {Object} props
 * @param {string} props.userId - The user's ID
 * @param {Function} props.onUpdate - Callback when user is updated
 */
function UserProfile({ userId, onUpdate }) {
    // State
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    // Effects
    useEffect(() => {
        let isMounted = true;

        async function fetchUser() {
            try {
                setLoading(true);
                const response = await fetch(`/api/users/${userId}`);
                const data = await response.json();

                if (isMounted) {
                    setUser(data);
                    setError(null);
                }
            } catch (err) {
                if (isMounted) {
                    setError(err.message);
                }
            } finally {
                if (isMounted) {
                    setLoading(false);
                }
            }
        }

        fetchUser();

        return () => {
            isMounted = false;
        };
    }, [userId]);

    // Callbacks
    const handleUpdate = useCallback((updatedData) => {
        setUser(prev => ({ ...prev, ...updatedData }));
        onUpdate?.(updatedData);
    }, [onUpdate]);

    // Computed values
    const displayName = useMemo(() => {
        return user ? `${user.firstName} ${user.lastName}` : '';
    }, [user]);

    // Render conditions
    if (loading) {
        return <LoadingSpinner />;
    }

    if (error) {
        return <ErrorMessage message={error} />;
    }

    if (!user) {
        return <NotFound />;
    }

    // Main render
    return (
        <div className={styles.profile}>
            <h1>{displayName}</h1>
            <p>{user.email}</p>
            <EditForm user={user} onSubmit={handleUpdate} />
        </div>
    );
}

// PropTypes for type checking
UserProfile.propTypes = {
    userId: PropTypes.string.isRequired,
    onUpdate: PropTypes.func
};

// Default props
UserProfile.defaultProps = {
    onUpdate: () => {}
};

export default UserProfile;

// ❌ BAD - Class component, mixed concerns
class UserProfile extends React.Component {
    constructor(props) {
        super(props);
        this.state = { user: null };
    }

    componentDidMount() {
        // Fetch logic mixed with component
        fetch(`/api/users/${this.props.userId}`)
            .then(res => res.json())
            .then(user => this.setState({ user }));
    }

    render() {
        return <div>{this.state.user?.name}</div>;
    }
}
```

### Custom Hooks

```jsx
// ✅ GOOD - Reusable custom hook

import { useState, useEffect } from 'react';

/**
 * Custom hook for data fetching
 * @param {string} url - API endpoint
 * @param {Object} options - Fetch options
 */
function useFetch(url, options = {}) {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        let isMounted = true;
        const controller = new AbortController();

        async function fetchData() {
            try {
                setLoading(true);
                const response = await fetch(url, {
                    ...options,
                    signal: controller.signal
                });

                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}`);
                }

                const json = await response.json();

                if (isMounted) {
                    setData(json);
                    setError(null);
                }
            } catch (err) {
                if (isMounted && err.name !== 'AbortError') {
                    setError(err.message);
                }
            } finally {
                if (isMounted) {
                    setLoading(false);
                }
            }
        }

        fetchData();

        return () => {
            isMounted = false;
            controller.abort();
        };
    }, [url, JSON.stringify(options)]);

    return { data, loading, error };
}

// Usage
function UserList() {
    const { data: users, loading, error } = useFetch('/api/users');

    if (loading) return <LoadingSpinner />;
    if (error) return <ErrorMessage message={error} />;

    return (
        <ul>
            {users.map(user => (
                <li key={user.id}>{user.name}</li>
            ))}
        </ul>
    );
}
```

### Performance Optimization

```jsx
// ✅ GOOD - Memoization and optimization

import React, { memo, useMemo, useCallback } from 'react';

// Memoize expensive component
const ExpensiveList = memo(({ items, onItemClick }) => {
    console.log('ExpensiveList rendered');

    return (
        <ul>
            {items.map(item => (
                <li key={item.id} onClick={() => onItemClick(item.id)}>
                    {item.name}
                </li>
            ))}
        </ul>
    );
}, (prevProps, nextProps) => {
    // Custom comparison
    return prevProps.items === nextProps.items &&
           prevProps.onItemClick === nextProps.onItemClick;
});

function ParentComponent() {
    const [items, setItems] = useState([]);
    const [filter, setFilter] = useState('');

    // Memoize filtered items
    const filteredItems = useMemo(() => {
        return items.filter(item =>
            item.name.toLowerCase().includes(filter.toLowerCase())
        );
    }, [items, filter]);

    // Memoize callback
    const handleItemClick = useCallback((id) => {
        console.log('Clicked:', id);
    }, []);

    return (
        <div>
            <input
                value={filter}
                onChange={(e) => setFilter(e.target.value)}
            />
            <ExpensiveList
                items={filteredItems}
                onItemClick={handleItemClick}
            />
        </div>
    );
}

// ❌ BAD - No optimization
function BadParent() {
    const [items, setItems] = useState([]);
    const [filter, setFilter] = useState('');

    // Re-filters on every render
    const filteredItems = items.filter(item =>
        item.name.includes(filter)
    );

    // New function on every render
    const handleClick = (id) => {
        console.log(id);
    };

    return <ExpensiveList items={filteredItems} onClick={handleClick} />;
}
```

### Error Boundaries

```jsx
// ✅ GOOD - Error boundary component

import React from 'react';

class ErrorBoundary extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            hasError: false,
            error: null,
            errorInfo: null
        };
    }

    static getDerivedStateFromError(error) {
        return { hasError: true };
    }

    componentDidCatch(error, errorInfo) {
        // Log to error reporting service
        console.error('Error caught:', error, errorInfo);

        this.setState({
            error,
            errorInfo
        });

        // Send to error tracking service
        if (window.Sentry) {
            window.Sentry.captureException(error);
        }
    }

    render() {
        if (this.state.hasError) {
            return (
                <div className="error-boundary">
                    <h1>Something went wrong</h1>
                    <p>{this.state.error?.toString()}</p>
                    {process.env.NODE_ENV === 'development' && (
                        <details>
                            <summary>Error details</summary>
                            <pre>{this.state.errorInfo?.componentStack}</pre>
                        </details>
                    )}
                    <button onClick={() => window.location.reload()}>
                        Reload page
                    </button>
                </div>
            );
        }

        return this.props.children;
    }
}

// Usage
function App() {
    return (
        <ErrorBoundary>
            <Router>
                <Routes />
            </Router>
        </ErrorBoundary>
    );
}
```

---

## 🎯 VUE.JS GUIDELINES

### Component Structure

```vue
<!-- ✅ GOOD - Well-structured Vue component -->

<template>
  <div class="user-profile">
    <LoadingSpinner v-if="loading" />
    <ErrorMessage v-else-if="error" :message="error" />
    <div v-else-if="user" class="profile-content">
      <h1>{{ displayName }}</h1>
      <p>{{ user.email }}</p>
      <button @click="handleUpdate">Update</button>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import LoadingSpinner from '@/components/LoadingSpinner.vue';
import ErrorMessage from '@/components/ErrorMessage.vue';

export default {
  name: 'UserProfile',

  components: {
    LoadingSpinner,
    ErrorMessage
  },

  props: {
    userId: {
      type: String,
      required: true
    }
  },

  emits: ['update'],

  setup(props, { emit }) {
    // Reactive state
    const user = ref(null);
    const loading = ref(true);
    const error = ref(null);

    // Computed properties
    const displayName = computed(() => {
      return user.value
        ? `${user.value.firstName} ${user.value.lastName}`
        : '';
    });

    // Methods
    async function fetchUser() {
      try {
        loading.value = true;
        const response = await fetch(`/api/users/${props.userId}`);
        user.value = await response.json();
        error.value = null;
      } catch (err) {
        error.value = err.message;
      } finally {
        loading.value = false;
      }
    }

    function handleUpdate() {
      emit('update', user.value);
    }

    // Lifecycle
    onMounted(() => {
      fetchUser();
    });

    onUnmounted(() => {
      // Cleanup
    });

    return {
      user,
      loading,
      error,
      displayName,
      handleUpdate
    };
  }
};
</script>

<style scoped>
.user-profile {
  padding: 20px;
}

.profile-content h1 {
  color: #333;
  margin-bottom: 10px;
}
</style>
```

### Composables (Vue 3)

```javascript
// ✅ GOOD - Reusable composable

import { ref, onMounted, onUnmounted } from 'vue';

/**
 * Composable for fetching data
 * @param {string} url - API endpoint
 */
export function useFetch(url) {
    const data = ref(null);
    const loading = ref(true);
    const error = ref(null);

    async function fetchData() {
        try {
            loading.value = true;
            const response = await fetch(url);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            data.value = await response.json();
            error.value = null;
        } catch (err) {
            error.value = err.message;
        } finally {
            loading.value = false;
        }
    }

    onMounted(() => {
        fetchData();
    });

    return {
        data,
        loading,
        error,
        refetch: fetchData
    };
}

// Usage in component
import { useFetch } from '@/composables/useFetch';

export default {
    setup() {
        const { data: users, loading, error } = useFetch('/api/users');

        return { users, loading, error };
    }
};
```

---

## 🗃️ STATE MANAGEMENT

### Redux Toolkit (React)

```javascript
// ✅ GOOD - Redux Toolkit slice

import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

// Async thunk
export const fetchUsers = createAsyncThunk(
    'users/fetchUsers',
    async (_, { rejectWithValue }) => {
        try {
            const response = await fetch('/api/users');

            if (!response.ok) {
                throw new Error('Failed to fetch users');
            }

            return await response.json();
        } catch (error) {
            return rejectWithValue(error.message);
        }
    }
);

// Slice
const usersSlice = createSlice({
    name: 'users',
    initialState: {
        items: [],
        loading: false,
        error: null
    },
    reducers: {
        addUser: (state, action) => {
            state.items.push(action.payload);
        },
        removeUser: (state, action) => {
            state.items = state.items.filter(
                user => user.id !== action.payload
            );
        }
    },
    extraReducers: (builder) => {
        builder
            .addCase(fetchUsers.pending, (state) => {
                state.loading = true;
                state.error = null;
            })
            .addCase(fetchUsers.fulfilled, (state, action) => {
                state.loading = false;
                state.items = action.payload;
            })
            .addCase(fetchUsers.rejected, (state, action) => {
                state.loading = false;
                state.error = action.payload;
            });
    }
});

export const { addUser, removeUser } = usersSlice.actions;
export default usersSlice.reducer;

// Usage in component
import { useDispatch, useSelector } from 'react-redux';
import { fetchUsers, addUser } from './usersSlice';

function UserList() {
    const dispatch = useDispatch();
    const { items, loading, error } = useSelector(state => state.users);

    useEffect(() => {
        dispatch(fetchUsers());
    }, [dispatch]);

    return (
        <div>
            {loading && <p>Loading...</p>}
            {error && <p>Error: {error}</p>}
            {items.map(user => (
                <div key={user.id}>{user.name}</div>
            ))}
        </div>
    );
}
```

### Vuex (Vue)

```javascript
// ✅ GOOD - Vuex store module

// store/modules/users.js
export default {
    namespaced: true,

    state: {
        items: [],
        loading: false,
        error: null
    },

    getters: {
        activeUsers: (state) => {
            return state.items.filter(user => user.active);
        },

        getUserById: (state) => (id) => {
            return state.items.find(user => user.id === id);
        }
    },

    mutations: {
        SET_LOADING(state, loading) {
            state.loading = loading;
        },

        SET_USERS(state, users) {
            state.items = users;
        },

        SET_ERROR(state, error) {
            state.error = error;
        },

        ADD_USER(state, user) {
            state.items.push(user);
        }
    },

    actions: {
        async fetchUsers({ commit }) {
            try {
                commit('SET_LOADING', true);
                const response = await fetch('/api/users');
                const users = await response.json();
                commit('SET_USERS', users);
                commit('SET_ERROR', null);
            } catch (error) {
                commit('SET_ERROR', error.message);
            } finally {
                commit('SET_LOADING', false);
            }
        },

        async createUser({ commit }, userData) {
            const response = await fetch('/api/users', {
                method: 'POST',
                body: JSON.stringify(userData)
            });
            const user = await response.json();
            commit('ADD_USER', user);
            return user;
        }
    }
};

// Usage in component
import { mapState, mapGetters, mapActions } from 'vuex';

export default {
    computed: {
        ...mapState('users', ['items', 'loading']),
        ...mapGetters('users', ['activeUsers'])
    },

    methods: {
        ...mapActions('users', ['fetchUsers', 'createUser'])
    },

    mounted() {
        this.fetchUsers();
    }
};
```

---

## 🧩 COMPONENT DESIGN

### Atomic Design Pattern

```
Atoms (Basic building blocks)
├── Button
├── Input
├── Label
└── Icon

Molecules (Simple combinations)
├── FormField (Label + Input)
├── SearchBar (Input + Button)
└── Card

Organisms (Complex components)
├── Form (Multiple FormFields)
├── Header (Logo + Navigation + SearchBar)
└── UserProfile (Card + Form)

Templates (Page layouts)
└── DashboardLayout

Pages (Specific instances)
└── UserDashboard
```

```jsx
// ✅ GOOD - Atomic design example

// Atoms
function Button({ children, variant = 'primary', ...props }) {
    return (
        <button className={`btn btn-${variant}`} {...props}>
            {children}
        </button>
    );
}

function Input({ label, error, ...props }) {
    return (
        <div className="input-wrapper">
            {label && <label>{label}</label>}
            <input {...props} />
            {error && <span className="error">{error}</span>}
        </div>
    );
}

// Molecules
function FormField({ label, name, value, onChange, error }) {
    return (
        <div className="form-field">
            <Input
                label={label}
                name={name}
                value={value}
                onChange={onChange}
                error={error}
            />
        </div>
    );
}

// Organisms
function LoginForm({ onSubmit }) {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [errors, setErrors] = useState({});

    const handleSubmit = (e) => {
        e.preventDefault();
        // Validation logic
        onSubmit({ email, password });
    };

    return (
        <form onSubmit={handleSubmit}>
            <FormField
                label="Email"
                name="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                error={errors.email}
            />
            <FormField
                label="Password"
                type="password"
                name="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                error={errors.password}
            />
            <Button type="submit">Login</Button>
        </form>
    );
}
```

### Compound Components

```jsx
// ✅ GOOD - Compound component pattern

import React, { createContext, useContext, useState } from 'react';

const TabsContext = createContext();

function Tabs({ children, defaultValue }) {
    const [activeTab, setActiveTab] = useState(defaultValue);

    return (
        <TabsContext.Provider value={{ activeTab, setActiveTab }}>
            <div className="tabs">{children}</div>
        </TabsContext.Provider>
    );
}

function TabList({ children }) {
    return <div className="tab-list">{children}</div>;
}

function Tab({ value, children }) {
    const { activeTab, setActiveTab } = useContext(TabsContext);
    const isActive = activeTab === value;

    return (
        <button
            className={`tab ${isActive ? 'active' : ''}`}
            onClick={() => setActiveTab(value)}
        >
            {children}
        </button>
    );
}

function TabPanels({ children }) {
    return <div className="tab-panels">{children}</div>;
}

function TabPanel({ value, children }) {
    const { activeTab } = useContext(TabsContext);

    if (activeTab !== value) {
        return null;
    }

    return <div className="tab-panel">{children}</div>;
}

// Export as compound component
Tabs.List = TabList;
Tabs.Tab = Tab;
Tabs.Panels = TabPanels;
Tabs.Panel = TabPanel;

export default Tabs;

// Usage
function App() {
    return (
        <Tabs defaultValue="profile">
            <Tabs.List>
                <Tabs.Tab value="profile">Profile</Tabs.Tab>
                <Tabs.Tab value="settings">Settings</Tabs.Tab>
                <Tabs.Tab value="billing">Billing</Tabs.Tab>
            </Tabs.List>

            <Tabs.Panels>
                <Tabs.Panel value="profile">
                    <ProfileContent />
                </Tabs.Panel>
                <Tabs.Panel value="settings">
                    <SettingsContent />
                </Tabs.Panel>
                <Tabs.Panel value="billing">
                    <BillingContent />
                </Tabs.Panel>
            </Tabs.Panels>
        </Tabs>
    );
}
```

---

## 🎨 CSS ARCHITECTURE

### BEM Methodology

```css
/* ✅ GOOD - BEM naming convention */

/* Block */
.card {
    border: 1px solid #ccc;
    border-radius: 8px;
    padding: 16px;
}

/* Element */
.card__header {
    font-size: 18px;
    font-weight: bold;
    margin-bottom: 12px;
}

.card__body {
    line-height: 1.5;
}

.card__footer {
    margin-top: 16px;
    display: flex;
    justify-content: space-between;
}

/* Modifier */
.card--featured {
    border-color: #0066cc;
    background-color: #f0f8ff;
}

.card--large {
    padding: 24px;
}

.card__header--primary {
    color: #0066cc;
}

/* ❌ BAD - Inconsistent naming */
.card {
    /* ... */
}

.cardHeader {  /* Should be card__header */
    /* ... */
}

.card .featured {  /* Should be card--featured */
    /* ... */
}
```

### CSS Modules

```jsx
// ✅ GOOD - CSS Modules

// Button.module.css
.button {
    padding: 10px 20px;
    border-radius: 4px;
    border: none;
    cursor: pointer;
}

.primary {
    background-color: #0066cc;
    color: white;
}

.secondary {
    background-color: #6c757d;
    color: white;
}

.small {
    padding: 5px 10px;
    font-size: 12px;
}

// Button.jsx
import styles from './Button.module.css';
import classNames from 'classnames';

function Button({ variant = 'primary', size, children, ...props }) {
    const className = classNames(
        styles.button,
        styles[variant],
        size && styles[size]
    );

    return (
        <button className={className} {...props}>
            {children}
        </button>
    );
}
```

### Styled Components

```jsx
// ✅ GOOD - Styled Components

import styled from 'styled-components';

const Button = styled.button`
    padding: 10px 20px;
    border-radius: 4px;
    border: none;
    cursor: pointer;
    font-size: 14px;
    transition: all 0.3s ease;

    ${props => props.variant === 'primary' && `
        background-color: #0066cc;
        color: white;

        &:hover {
            background-color: #0052a3;
        }
    `}

    ${props => props.variant === 'secondary' && `
        background-color: #6c757d;
        color: white;

        &:hover {
            background-color: #5a6268;
        }
    `}

    ${props => props.size === 'small' && `
        padding: 5px 10px;
        font-size: 12px;
    `}

    ${props => props.disabled && `
        opacity: 0.6;
        cursor: not-allowed;
    `}
`;

// Usage
function App() {
    return (
        <>
            <Button variant="primary">Primary</Button>
            <Button variant="secondary" size="small">Small</Button>
            <Button disabled>Disabled</Button>
        </>
    );
}
```

---

## ⚡ PERFORMANCE OPTIMIZATION

### Code Splitting

```jsx
// ✅ GOOD - Route-based code splitting

import React, { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';

// Lazy load route components
const Home = lazy(() => import('./pages/Home'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Profile = lazy(() => import('./pages/Profile'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
    return (
        <BrowserRouter>
            <Suspense fallback={<LoadingSpinner />}>
                <Routes>
                    <Route path="/" element={<Home />} />
                    <Route path="/dashboard" element={<Dashboard />} />
                    <Route path="/profile" element={<Profile />} />
                    <Route path="/settings" element={<Settings />} />
                </Routes>
            </Suspense>
        </BrowserRouter>
    );
}
```

### Image Optimization

```jsx
// ✅ GOOD - Responsive images with lazy loading

function ProductImage({ src, alt }) {
    return (
        <picture>
            <source
                type="image/webp"
                srcSet={`
                    ${src}-320w.webp 320w,
                    ${src}-640w.webp 640w,
                    ${src}-1024w.webp 1024w
                `}
                sizes="(max-width: 640px) 100vw, 640px"
            />
            <img
                src={`${src}-640w.jpg`}
                srcSet={`
                    ${src}-320w.jpg 320w,
                    ${src}-640w.jpg 640w,
                    ${src}-1024w.jpg 1024w
                `}
                sizes="(max-width: 640px) 100vw, 640px"
                alt={alt}
                loading="lazy"
                decoding="async"
                width="640"
                height="480"
            />
        </picture>
    );
}
```

### Virtual Scrolling

```jsx
// ✅ GOOD - Virtual scrolling for long lists

import { FixedSizeList } from 'react-window';

function VirtualList({ items }) {
    const Row = ({ index, style }) => (
        <div style={style} className="list-item">
            <h3>{items[index].title}</h3>
            <p>{items[index].description}</p>
        </div>
    );

    return (
        <FixedSizeList
            height={600}
            itemCount={items.length}
            itemSize={80}
            width="100%"
        >
            {Row}
        </FixedSizeList>
    );
}
```

---

## ♿ ACCESSIBILITY (A11Y)

### Semantic HTML

```jsx
// ✅ GOOD - Semantic HTML with ARIA

function Navigation() {
    return (
        <nav aria-label="Main navigation">
            <ul>
                <li><a href="/">Home</a></li>
                <li><a href="/about">About</a></li>
                <li><a href="/contact">Contact</a></li>
            </ul>
        </nav>
    );
}

function Dialog({ isOpen, onClose, title, children }) {
    if (!isOpen) return null;

    return (
        <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="dialog-title"
        >
            <div className="dialog-content">
                <h2 id="dialog-title">{title}</h2>
                {children}
                <button onClick={onClose} aria-label="Close dialog">
                    ×
                </button>
            </div>
        </div>
    );
}

// ❌ BAD - Non-semantic, no ARIA
function BadNav() {
    return (
        <div>
            <div onClick={() => navigate('/')}>Home</div>
            <div onClick={() => navigate('/about')}>About</div>
        </div>
    );
}
```

### Keyboard Navigation

```jsx
// ✅ GOOD - Keyboard accessible

function Dropdown({ options, onSelect }) {
    const [isOpen, setIsOpen] = useState(false);
    const [focusedIndex, setFocusedIndex] = useState(0);

    const handleKeyDown = (e) => {
        switch (e.key) {
            case 'ArrowDown':
                e.preventDefault();
                setFocusedIndex(prev =>
                    Math.min(prev + 1, options.length - 1)
                );
                break;

            case 'ArrowUp':
                e.preventDefault();
                setFocusedIndex(prev => Math.max(prev - 1, 0));
                break;

            case 'Enter':
            case ' ':
                e.preventDefault();
                onSelect(options[focusedIndex]);
                setIsOpen(false);
                break;

            case 'Escape':
                setIsOpen(false);
                break;
        }
    };

    return (
        <div
            role="combobox"
            aria-expanded={isOpen}
            aria-haspopup="listbox"
            onKeyDown={handleKeyDown}
        >
            <button onClick={() => setIsOpen(!isOpen)}>
                Select option
            </button>

            {isOpen && (
                <ul role="listbox">
                    {options.map((option, index) => (
                        <li
                            key={option.value}
                            role="option"
                            aria-selected={index === focusedIndex}
                            onClick={() => onSelect(option)}
                        >
                            {option.label}
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}
```

---

## 🔍 SEO BEST PRACTICES

### Meta Tags

```jsx
// ✅ GOOD - SEO-friendly meta tags

import { Helmet } from 'react-helmet-async';

function ProductPage({ product }) {
    return (
        <>
            <Helmet>
                <title>{product.name} | MyStore</title>
                <meta name="description" content={product.description} />

                {/* Open Graph */}
                <meta property="og:title" content={product.name} />
                <meta property="og:description" content={product.description} />
                <meta property="og:image" content={product.image} />
                <meta property="og:type" content="product" />

                {/* Twitter Card */}
                <meta name="twitter:card" content="summary_large_image" />
                <meta name="twitter:title" content={product.name} />
                <meta name="twitter:description" content={product.description} />
                <meta name="twitter:image" content={product.image} />

                {/* Canonical URL */}
                <link rel="canonical" href={`https://mystore.com/products/${product.id}`} />

                {/* JSON-LD Schema */}
                <script type="application/ld+json">
                    {JSON.stringify({
                        "@context": "https://schema.org",
                        "@type": "Product",
                        "name": product.name,
                        "description": product.description,
                        "image": product.image,
                        "offers": {
                            "@type": "Offer",
                            "price": product.price,
                            "priceCurrency": "USD"
                        }
                    })}
                </script>
            </Helmet>

            <article>
                <h1>{product.name}</h1>
                <p>{product.description}</p>
            </article>
        </>
    );
}
```

---

## ✅ FRONTEND CHECKLIST

### Development
- [ ] Component-based architecture
- [ ] Proper state management
- [ ] Custom hooks/composables for reusability
- [ ] Error boundaries implemented
- [ ] Loading and error states handled
- [ ] TypeScript for type safety
- [ ] Code splitting and lazy loading
- [ ] PropTypes or TypeScript props validation

### Performance
- [ ] Images optimized and lazy loaded
- [ ] Bundle size analyzed and optimized
- [ ] Memoization for expensive operations
- [ ] Virtual scrolling for long lists
- [ ] Service worker for offline support
- [ ] Code splitting by route
- [ ] Tree shaking enabled

### Accessibility
- [ ] Semantic HTML used
- [ ] ARIA attributes where needed
- [ ] Keyboard navigation works
- [ ] Focus management implemented
- [ ] Color contrast meets WCAG standards
- [ ] Screen reader tested
- [ ] Alt text for images

### SEO
- [ ] Meta tags configured
- [ ] Open Graph tags
- [ ] Structured data (JSON-LD)
- [ ] Canonical URLs
- [ ] Sitemap.xml generated
- [ ] robots.txt configured
- [ ] Server-side rendering (if needed)

---

## 📚 REFERENCES

- [React Documentation](https://react.dev/)
- [Vue.js Guide](https://vuejs.org/guide/)
- [web.dev](https://web.dev/)
- [MDN Web Docs](https://developer.mozilla.org/)
- [A11y Project](https://www.a11yproject.com/)
- [CSS-Tricks](https://css-tricks.com/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
