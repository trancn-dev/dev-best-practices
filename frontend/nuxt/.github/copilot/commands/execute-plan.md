---
type: command
name: execute-plan
version: 2.0
scope: project
integration:
  - nuxt
  - vue
  - project-management
---

# Command: Execute Plan

## Mục tiêu
Lệnh `execute-plan` được sử dụng để **triển khai feature plan** một cách có hệ thống.

Mục tiêu chính:
- Triển khai feature theo plan đã được approve.
- Đảm bảo code quality và standards.
- Track progress và deliverables.
- Minimize bugs và rework.

---

## Quy trình thực thi

### Step 1: Review Plan

**Checklist:**

- [ ] Plan đã được approve
- [ ] Requirements rõ ràng
- [ ] Design/mockups available
- [ ] API contracts defined
- [ ] Dependencies identified
- [ ] Timeline agreed

---

### Step 2: Setup Development Environment

```bash
# Create feature branch
git checkout -b feature/PROJ-123/user-profile

# Install dependencies (if needed)
npm install

# Start dev server
npm run dev
```

---

### Step 3: Implement According to Plan

#### Phase 1: Setup Structure

```markdown
## Tasks
- [ ] Create pages/components as per design
- [ ] Setup composables for business logic
- [ ] Define TypeScript interfaces/types
- [ ] Setup API client methods
- [ ] Create Pinia stores if needed
```

#### Phase 2: Core Implementation

```markdown
## Tasks
- [ ] Implement UI components
- [ ] Connect to API endpoints
- [ ] Add state management
- [ ] Handle loading/error states
- [ ] Add form validation
- [ ] Implement business logic
```

#### Phase 3: Polish & Testing

```markdown
## Tasks
- [ ] Add unit tests
- [ ] Add component tests
- [ ] Add E2E tests
- [ ] Responsive design check
- [ ] Accessibility audit
- [ ] Performance optimization
- [ ] Error handling
```

---

### Step 4: Code Review Checklist

Before creating PR:

- [ ] Code follows conventions (`.github/copilot/rules/`)
- [ ] All tests pass
- [ ] No console.log or debug code
- [ ] TypeScript types complete
- [ ] Components documented
- [ ] No hardcoded values
- [ ] Error handling in place
- [ ] Responsive design works
- [ ] Accessibility checked

---

### Step 5: Create Pull Request

**PR Template:**

```markdown
## Feature: [Feature Name]

**Ticket:** PROJ-123

### Description
[Brief description of what this PR does]

### Changes
- Added UserProfile component
- Created useUserProfile composable
- Added profile edit functionality
- Integrated with /api/users endpoint

### Testing
- [ ] Unit tests added and passing
- [ ] Component tests added and passing
- [ ] E2E tests added and passing
- [ ] Manual testing completed

### Screenshots/Videos
[Add screenshots or video demo]

### Checklist
- [ ] Code follows project conventions
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No breaking changes
- [ ] Ready for review

### Related Issues
- Closes #123
- Related to #456
```

---

### Step 6: Address Review Comments

```markdown
## Review Response

### Blocking Issues
- [x] Fixed prop validation in UserProfile.vue
- [x] Added error handling for API calls

### Important Suggestions
- [x] Extracted API logic to composable
- [x] Added TypeScript types for user data

### Optional
- [ ] Will address in follow-up PR (created #789)
```

---

### Step 7: Merge & Deploy

```bash
# After approval, merge to develop
git checkout develop
git pull origin develop
git merge feature/PROJ-123/user-profile

# Tag release if needed
git tag -a v1.2.0 -m "Release v1.2.0 - User Profile Feature"
git push origin v1.2.0
```

---

## Progress Tracking

### Daily Standup Format

```markdown
**Yesterday:**
- Completed UserProfile component UI
- Setup useUserProfile composable

**Today:**
- Integrate API endpoints
- Add form validation
- Write unit tests

**Blockers:**
- Waiting for API endpoint deployment
```

---

## Quality Gates

### Before Commit
- Code compiles without errors
- ESLint passes
- Types are correct

### Before PR
- All tests pass
- Code reviewed locally
- Documentation updated

### Before Merge
- PR approved by 1+ reviewer
- CI/CD pipeline green
- No merge conflicts

---

## Rollback Plan

If issues found in production:

```bash
# Revert the merge commit
git revert -m 1 <merge-commit-hash>

# Or revert specific commit
git revert <commit-hash>

# Push to trigger redeployment
git push origin main
```

---

## Post-Implementation

### Documentation Updates
- [ ] Update README if needed
- [ ] Update API documentation
- [ ] Add to knowledge base
- [ ] Update changelog

### Knowledge Capture
- [ ] Run `/capture-knowledge` for complex parts
- [ ] Document gotchas and lessons learned
- [ ] Share with team

### Monitoring
- [ ] Check error logs
- [ ] Monitor performance metrics
- [ ] Gather user feedback

---

## Example Execution

See:
- `.github/copilot/knowledge/examples/user-profile-implementation.md`
