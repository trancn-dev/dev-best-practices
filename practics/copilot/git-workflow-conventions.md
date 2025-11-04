# Rule: Git Workflow & Commit Conventions

## Intent
Enforce consistent Git workflow, branch naming, commit messages, and PR practices. Copilot must guide developers to maintain clean git history and follow team conventions.

## Scope
Applies to all git operations including branching, committing, merging, and pull requests.

---

## 1. Branch Naming Convention

### Format
```
<type>/<ticket-id>-<short-description>
```

### Branch Types

| Type | Purpose | Example |
|------|---------|---------|
| `feature/` | New features | `feature/JIRA-123-user-authentication` |
| `fix/` | Bug fixes | `fix/JIRA-456-login-button-styling` |
| `hotfix/` | Emergency production fixes | `hotfix/critical-security-patch` |
| `release/` | Release preparation | `release/v1.2.0` |
| `docs/` | Documentation only | `docs/update-api-documentation` |
| `refactor/` | Code refactoring | `refactor/extract-payment-service` |
| `test/` | Adding tests | `test/add-unit-tests-for-auth` |
| `chore/` | Maintenance tasks | `chore/upgrade-dependencies` |

### Rules
- ✅ **MUST** use lowercase only
- ✅ **MUST** use hyphens, not spaces or underscores
- ✅ **MUST** include ticket ID when available
- ✅ **MUST** be descriptive but concise
- ✅ **MUST** use present tense
- ❌ **MUST NOT** use generic names like `test`, `bugfix`, `new-feature`
- ❌ **MUST NOT** include developer names

### Examples

```bash
# ✅ GOOD
feature/JIRA-123-user-authentication
fix/JIRA-456-null-pointer-in-payment
hotfix/security-patch-xss
release/v1.2.0
docs/update-readme
refactor/extract-user-service
test/add-auth-integration-tests
chore/upgrade-nodejs-to-20

# ❌ BAD
new-feature
bugfix
my-branch
test
johndoe-branch
Feature/UserAuth
fix_button
```

---

## 2. Commit Message Convention (Conventional Commits)

### Format
```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Commit Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add JWT token refresh` |
| `fix` | Bug fix | `fix(api): handle null pointer exception` |
| `docs` | Documentation | `docs(readme): update installation steps` |
| `style` | Formatting, semicolons, etc. | `style(lint): fix eslint warnings` |
| `refactor` | Code restructuring | `refactor(payment): extract service layer` |
| `perf` | Performance improvement | `perf(db): optimize user query with index` |
| `test` | Adding tests | `test(auth): add JWT validation tests` |
| `build` | Build system changes | `build(webpack): update to v5` |
| `ci` | CI/CD changes | `ci(github): add auto-deploy workflow` |
| `chore` | Maintenance | `chore(deps): upgrade express to v4.18` |
| `revert` | Revert commit | `revert: feat(auth): add JWT tokens` |

### Subject Line Rules
- ✅ **MUST** be 50-72 characters max
- ✅ **MUST** use lowercase
- ✅ **MUST** use imperative mood ("add" not "added" or "adds")
- ✅ **MUST** not end with a period
- ✅ **MUST** be clear and descriptive
- ❌ **MUST NOT** be vague like "fix bug", "update code"

### Body Rules (Optional)
- ✅ **SHOULD** explain WHAT and WHY, not HOW
- ✅ **MUST** wrap at 72 characters
- ✅ **MUST** separate from subject with blank line
- ✅ **SHOULD** use bullet points for multiple changes

### Footer Rules (Optional)
- ✅ **MUST** reference issues: `Closes #123`, `Fixes JIRA-456`
- ✅ **MUST** indicate breaking changes: `BREAKING CHANGE: description`

### Good Examples

```bash
# Simple feature
feat(auth): add JWT token refresh mechanism

# Bug fix with context
fix(api): handle null pointer in user service

The service was throwing NPE when user profile was incomplete.
Added validation to check for null values before processing.

Fixes #123

# Breaking change
feat(api): change user endpoint response format

BREAKING CHANGE: User API now returns camelCase instead of snake_case
to align with frontend conventions.

Migration guide: https://docs.example.com/migration

# Performance improvement with details
perf(database): optimize user query performance

- Add index on email column
- Implement query result caching
- Reduce N+1 queries using eager loading

Improves query time from 500ms to 50ms on large datasets.

Closes #456

# Multiple related changes
refactor(payment): extract payment service

- Move payment logic from controller to service
- Add payment gateway abstraction
- Implement retry mechanism for failed payments

This refactoring makes payment processing more testable
and easier to extend with new payment providers.
```

### Bad Examples

```bash
# ❌ BAD - Too vague
fix bug
update code
changes
WIP
stuff

# ❌ BAD - Wrong format
Fixed the login bug
Adding new feature
Update

# ❌ BAD - Subject too long
feat(auth): implement JWT authentication with refresh tokens and also update the user service to handle token validation and add middleware

# ❌ BAD - Wrong mood
feat(auth): added login feature
fix(api): fixed bug
docs(readme): updated documentation
```

### Scope Examples (Customize per project)

```
auth        - Authentication
api         - API endpoints
db          - Database
ui          - User Interface
payment     - Payment processing
email       - Email service
config      - Configuration
deps        - Dependencies
build       - Build system
ci          - CI/CD
test        - Testing
docs        - Documentation
```

---

## 3. Workflow Guidelines

### Git Flow Workflow

```bash
# Feature development
git checkout develop
git pull origin develop
git checkout -b feature/JIRA-123-user-auth

# Work and commit
git add .
git commit -m "feat(auth): implement JWT authentication"

# Keep branch updated
git checkout develop
git pull origin develop
git checkout feature/JIRA-123-user-auth
git rebase develop

# Create PR to develop
# After merge, branch auto-deleted
```

### GitHub Flow (Simplified)

```bash
# Create branch from main
git checkout main
git pull origin main
git checkout -b feature/add-search

# Work and push
git add .
git commit -m "feat(search): add search functionality"
git push origin feature/add-search

# Create PR to main
# After merge to main, auto-deploy to production
```

### Branch Lifecycle Rules
- ✅ **MUST** create branch from latest main/develop
- ✅ **MUST** keep branch updated with base branch
- ✅ **MUST** delete branch after merge
- ✅ **SHOULD** keep branches short-lived (< 3 days for features)
- ❌ **MUST NOT** commit directly to main/develop
- ❌ **MUST NOT** merge without review

---

## 4. Pull Request Best Practices

### PR Size Guidelines
- ✅ **IDEAL**: 200-400 lines changed
- ⚠️ **ACCEPTABLE**: 400-800 lines changed
- ❌ **TOO LARGE**: 800+ lines changed (split into multiple PRs)

### PR Rules
- ✅ **MUST** have clear, descriptive title following commit convention
- ✅ **MUST** describe changes in PR description
- ✅ **MUST** link related issues (Closes #123, Fixes #456)
- ✅ **MUST** add reviewers
- ✅ **MUST** pass all CI checks before merge
- ✅ **MUST** resolve all review comments
- ✅ **SHOULD** add screenshots for UI changes
- ✅ **SHOULD** update documentation if needed
- ❌ **MUST NOT** merge your own PR without review
- ❌ **MUST NOT** force push to PR branch after review started

### PR Title Format

```bash
# ✅ GOOD
feat(auth): Implement JWT authentication
fix(api): Handle null pointer in user service
docs(readme): Update installation instructions

# ❌ BAD
Auth feature
Fixed bug
Updates
```

### PR Description Template

```markdown
## Description
Brief description of what this PR does

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Closes #123
Fixes #456

## How Has This Been Tested?
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests passing
- [ ] Branch up to date with base
```

---

## 5. Merge Strategies

### Merge Commit (Default for important features)
```bash
git checkout main
git merge --no-ff feature/my-feature
```
**Use when:** Preserving complete feature history is important

### Squash and Merge (Recommended for small features)
```bash
git checkout main
git merge --squash feature/my-feature
git commit -m "feat(api): implement user authentication"
```
**Use when:** Want clean linear history, one commit per feature

### Rebase and Merge (For linear history)
```bash
git checkout feature/my-feature
git rebase main
git checkout main
git merge feature/my-feature
```
**Use when:** Want linear history with individual commits preserved

---

## 6. Common Patterns and Commands

### Update branch with latest main/develop

```bash
# Option 1: Rebase (cleaner history)
git checkout feature/my-feature
git fetch origin
git rebase origin/main

# Option 2: Merge (safer for shared branches)
git checkout feature/my-feature
git fetch origin
git merge origin/main
```

### Fix commit message (before push)

```bash
# Fix last commit message
git commit --amend -m "feat(auth): correct commit message"

# Fix last commit (add files)
git add forgotten-file.js
git commit --amend --no-edit
```

### Interactive rebase (clean up commits)

```bash
# Squash last 3 commits
git rebase -i HEAD~3

# In editor:
# pick abc123 first commit
# squash def456 second commit
# squash ghi789 third commit
```

### Stash changes temporarily

```bash
# Stash current changes
git stash save "WIP: working on feature"

# List stashes
git stash list

# Apply stash
git stash apply stash@{0}

# Pop stash (apply and remove)
git stash pop
```

---

## 7. Copilot-Specific Instructions

### When Reviewing Commits
1. **CHECK** commit message format
2. **VERIFY** conventional commits syntax
3. **SUGGEST** improvements if format is incorrect
4. **WARN** if commit is too large (suggest splitting)

### When Creating Branches
1. **SUGGEST** proper branch name based on task
2. **INCLUDE** ticket ID if available in context
3. **USE** appropriate type prefix

### Response Pattern for Violations

```
❌ Issue: Commit message doesn't follow conventional commits format
Current: "fixed bug in login"

✅ Suggested Fix:
fix(auth): resolve login validation error

- Validate email format before authentication
- Add proper error messages for invalid credentials

Fixes #123

📝 Reason: Conventional commits enable:
- Automated changelog generation
- Semantic versioning
- Better git history readability
```

### Auto-Generate Commit Messages

When asked to generate commit message, use this template:

```
<type>(<scope>): <clear subject line>

[If complex, add body explaining:]
- What changed
- Why it changed
- Any important notes

[If applicable:]
Closes #issue-number
BREAKING CHANGE: description
```

---

## 8. Quick Reference

### Branch Name Format
```
<type>/<ticket-id>-<description>
feature/JIRA-123-add-login
```

### Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Common Types
```
feat     - New feature
fix      - Bug fix
docs     - Documentation
refactor - Code refactoring
test     - Tests
chore    - Maintenance
```

### Before Push Checklist
- [ ] Commits follow conventional format?
- [ ] Branch name is correct?
- [ ] Branch up to date with base?
- [ ] All tests passing?
- [ ] No debug code or console.logs?
- [ ] Ready for review?

---

## References
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

---

**Priority Enforcement:**
1. Commit message format (most visible)
2. Branch naming
3. PR practices
4. Merge strategy

Always prioritize clarity and consistency over personal preference.
