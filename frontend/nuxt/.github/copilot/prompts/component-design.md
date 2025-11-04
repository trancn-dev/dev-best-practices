# Prompt: Component Design

## Purpose
Help design and structure Vue components following best practices.

## When to Use
- Creating new components
- Refactoring existing components
- Need component architecture advice

---

## Prompt Template

```
I need to design a [COMPONENT_NAME] component:

**Purpose**: [What the component does]
**Features**:
- [Feature 1]
- [Feature 2]

**Requirements**:
- [Requirement 1]
- [Requirement 2]

**Data Sources**:
- [API endpoints, props, store, etc.]

Please help me:
1. Design component structure
2. Define props and emits
3. Suggest composables to use
4. Recommend state management approach
5. Identify reusable sub-components
```

---

## Example: UserProfile Component

**Input:**
```
I need to design a UserProfile component:

**Purpose**: Display and edit user profile information
**Features**:
- Show user avatar, name, email, bio
- Edit mode for updating profile
- Save/cancel buttons
- Loading and error states

**Requirements**:
- Must be responsive
- Support avatar upload
- Validate email format
- Show success/error messages

**Data Sources**:
- GET /api/users/:id
- PUT /api/users/:id
```

**Expected Output:**

### Component Structure
```vue
<script setup lang="ts">
import type { User } from '~/types'

// Props
const props = defineProps<{
  userId: string | number
  editable?: boolean
}>()

// Emits
const emit = defineEmits<{
  'update': [user: User]
  'cancel': []
}>()

// Composables
const { data: user, pending, error, refresh } = useFetch(`/api/users/${props.userId}`)
const toast = useToast()

// State
const isEditing = ref(false)
const formData = ref<Partial<User>>({})

// Methods
function startEdit() {
  isEditing.value = true
  formData.value = { ...user.value }
}

async function save() {
  try {
    await $fetch(`/api/users/${props.userId}`, {
      method: 'PUT',
      body: formData.value
    })
    toast.success('Profile updated')
    emit('update', formData.value as User)
    isEditing.value = false
  } catch (err) {
    toast.error('Failed to update profile')
  }
}

function cancel() {
  isEditing.value = false
  emit('cancel')
}
</script>

<template>
  <div class="user-profile">
    <div v-if="pending">Loading...</div>
    <div v-else-if="error">Error loading profile</div>
    <div v-else>
      <UserAvatar :src="user.avatar" />
      <UserInfo
        v-if="!isEditing"
        :user="user"
      />
      <UserForm
        v-else
        v-model="formData"
        @save="save"
        @cancel="cancel"
      />
    </div>
  </div>
</template>
```

### Sub-components
- `UserAvatar.vue` - Display avatar
- `UserInfo.vue` - Read-only user info
- `UserForm.vue` - Editable form

### Composables
- `useFetch()` - Data fetching
- `useToast()` - Notifications

---

## References

- [Vue Component Design](https://vuejs.org/guide/essentials/component-basics.html)
- [Nuxt Component Best Practices](https://nuxt.com/docs/guide/directory-structure/components)
