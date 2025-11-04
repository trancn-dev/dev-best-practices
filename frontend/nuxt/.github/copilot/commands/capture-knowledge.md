---
type: command
name: capture-knowledge
version: 2.0
scope: project
integration:
  - nuxt
  - vue
  - documentation
  - knowledge-management
---

# Command: Capture Knowledge

## Mục tiêu
Lệnh `capture-knowledge` được sử dụng để **thu thập và ghi nhận kiến thức** về code, architecture, hoặc business logic vào tài liệu dự án.

Mục tiêu chính:
- Tạo tài liệu hiểu biết chi tiết về component/composable/page entry point.
- Phân tích dependencies và data flow.
- Ghi nhận patterns, best practices, và gotchas.
- Giúp onboarding và knowledge transfer.

---

## Quy trình thu thập kiến thức

### Step 1: Gather Context

**Câu hỏi cần trả lời:**

#### A. Entry Point Information
- Entry point type? (component, composable, page, layout, middleware, plugin)
- Location path?
- Why this entry point matters? (feature, bug fix, investigation)
- Relevant requirements/design docs?

#### B. Scope Definition
- Depth of analysis? (shallow overview vs deep dive)
- Focus areas? (UI logic, data flow, API calls, state management)
- Target audience? (new developers, team, external)

**Example:**
```markdown
**Entry Point:** `app/components/UserProfile.vue`
**Type:** Vue Component
**Purpose:** Display and manage user profile information
**Reason:** New developer onboarding + frequent UI bugs
**Depth:** Deep dive
**Focus:** Props, events, composables usage, state management
```

---

### Step 2: Validate Entry Point

```markdown
## Entry Point Validation

### Check Existence
- [ ] Entry point exists in codebase
- [ ] Accessible and readable
- [ ] Not deprecated or legacy code

### Identify Type
- [ ] Component: Vue SFC
- [ ] Composable: useXxx function
- [ ] Page: File-based routing
- [ ] Layout: Wrapper component
- [ ] Middleware: Route guard
- [ ] Plugin: Nuxt plugin

### Handle Ambiguity
If multiple matches found:
1. List all matches with paths
2. Ask for clarification
3. Suggest most likely match based on context

**Example:**
```
Multiple matches found for "UserProfile":
1. app/components/UserProfile.vue (Main component)
2. app/components/admin/UserProfile.vue (Admin version)
3. app/components/legacy/UserProfile.vue (Deprecated)

Recommend: #1 (Most commonly used)
Proceed with which one? [1]
```
```

---

### Step 3: Collect Source Context

#### A. Read Primary File/Module

```markdown
## Source Code Analysis

### Component: `app/components/UserProfile.vue`

**Purpose:** Displays user profile with editable fields and avatar upload.

**Props:**
- `userId: string | number` - User ID to fetch profile
- `editable: boolean` - Allow editing mode (default: false)

**Emits:**
- `update:profile` - When profile is updated
- `cancel` - When edit is cancelled

**Composables Used:**
- `useUser()` - Fetch and manage user data
- `useAuth()` - Check permissions
- `useToast()` - Show notifications

**API Calls:**
- GET `/api/users/{id}`
- PUT `/api/users/{id}`

**State:**
- Local reactive state for form data
- Pinia store for user cache
```

#### B. Map Dependencies

```markdown
## Dependencies

### Direct Dependencies
1. `composables/useUser.ts` - User data management
2. `composables/useAuth.ts` - Authentication
3. `stores/user.ts` - User Pinia store
4. `components/Avatar.vue` - Avatar display

### Indirect Dependencies
1. API client (`api/client.ts`)
2. Type definitions (`types/user.ts`)
```

---

### Step 4: Analyze Component Structure

```markdown
## Component Structure

### Template
- Conditional rendering based on `editable` prop
- Form inputs with v-model
- Event handlers for submit/cancel

### Script Setup
- Props definition with TypeScript
- Composables initialization
- Reactive state management
- Methods for CRUD operations

### Style
- Scoped styles
- Responsive design with Tailwind/UnoCSS
- BEM naming convention
```

---

### Step 5: Document Key Patterns

```markdown
## Key Patterns & Insights

### Pattern 1: Optimistic Updates
Component updates UI immediately before API confirmation for better UX.

### Pattern 2: Error Handling
All API calls wrapped in try-catch with toast notifications.

### Pattern 3: Permission Checks
Uses `useAuth().can('edit-profile')` before showing edit mode.

### Gotchas
- Must handle avatar upload separately (multipart/form-data)
- Profile cache must be invalidated after update
- Email change requires re-authentication
```

---

### Step 6: Generate Knowledge Document

**Template:**

```markdown
# Knowledge: [Component/Feature Name]

## Overview
[Brief description of purpose and context]

## Entry Point
- **Path:** `[file path]`
- **Type:** [Component/Composable/Page]
- **Dependencies:** [List key dependencies]

## Architecture

### Data Flow
[Describe how data flows through the component]

### State Management
[Explain state management approach]

### API Integration
[List API endpoints and methods]

## Key Features

### Feature 1: [Name]
[Description and implementation details]

### Feature 2: [Name]
[Description and implementation details]

## Best Practices

### Do's
- ✅ [Best practice 1]
- ✅ [Best practice 2]

### Don'ts
- ❌ [Anti-pattern 1]
- ❌ [Anti-pattern 2]

## Common Issues & Solutions

### Issue 1: [Problem]
**Symptom:** [Description]
**Root Cause:** [Explanation]
**Solution:** [How to fix]

## Testing

### Unit Tests
[Location and coverage]

### Integration Tests
[E2E scenarios]

## Related Documentation
- [Link to design doc]
- [Link to API doc]
- [Link to related components]

## Maintenance Notes
- Last updated: [Date]
- Owner: [Team/Person]
- Known limitations: [List]
```

---

## Deliverable

Save knowledge document to:
```
.github/copilot/knowledge/[domain]/[feature-name].md
```

**Example:**
```
.github/copilot/knowledge/user/user-profile-component.md
.github/copilot/knowledge/auth/login-flow.md
.github/copilot/knowledge/ui/responsive-layout.md
```

---

## Quality Checklist

- [ ] Entry point clearly identified and validated
- [ ] All dependencies mapped
- [ ] Data flow documented
- [ ] Key patterns explained
- [ ] Gotchas and edge cases noted
- [ ] Examples provided where helpful
- [ ] Document is readable by newcomers
- [ ] Links to related docs included
- [ ] Maintenance info added

---

## Example Output

See:
- `.github/copilot/knowledge/user/user-profile-component.md`
- `.github/copilot/knowledge/auth/authentication-flow.md`
