# Git Workflow & Conventions - Quy Ước Git & Quy Trình Làm Việc

> Hướng dẫn chi tiết về Git workflow, branch strategy, commit conventions và best practices
>
> **Mục đích**: Đảm bảo team làm việc nhịp nhàng, history rõ ràng, dễ rollback và debug

---

## 📋 Mục Lục
- [Git Workflows](#git-workflows)
- [Branch Naming Conventions](#branch-naming-conventions)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Best Practices](#pull-request-best-practices)
- [Merge Strategies](#merge-strategies)
- [Git Hooks](#git-hooks)
- [Common Git Commands](#common-git-commands)
- [Troubleshooting](#troubleshooting)

---

## 🌊 GIT WORKFLOWS

### 1️⃣ Git Flow (Traditional)

**Phù hợp với**: Release-based projects, scheduled releases

```
main (production)
  ├── develop (integration)
  │   ├── feature/user-authentication
  │   ├── feature/payment-integration
  │   └── feature/email-notifications
  ├── release/v1.2.0 (release candidate)
  └── hotfix/critical-security-patch
```

**Branches:**

- **`main`**: Production code, luôn stable
- **`develop`**: Integration branch, latest development
- **`feature/*`**: New features
- **`release/*`**: Release preparation
- **`hotfix/*`**: Emergency fixes for production

**Workflow:**

```bash
# 1. Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/user-authentication

# 2. Work on feature
git add .
git commit -m "feat(auth): implement JWT authentication"

# 3. Keep feature branch updated
git checkout develop
git pull origin develop
git checkout feature/user-authentication
git rebase develop

# 4. Create Pull Request to develop
# After review and approval, merge

# 5. Create release branch
git checkout develop
git checkout -b release/v1.2.0

# 6. Deploy to staging, test, fix bugs
git commit -m "fix(release): update version number"

# 7. Merge to main and develop
git checkout main
git merge release/v1.2.0
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin main --tags

git checkout develop
git merge release/v1.2.0
git push origin develop

# 8. Delete release branch
git branch -d release/v1.2.0
```

**Hotfix workflow:**

```bash
# 1. Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/security-patch

# 2. Fix the issue
git commit -m "fix(security): patch XSS vulnerability"

# 3. Merge to main and develop
git checkout main
git merge hotfix/security-patch
git tag -a v1.2.1 -m "Hotfix: security patch"
git push origin main --tags

git checkout develop
git merge hotfix/security-patch
git push origin develop

# 4. Delete hotfix branch
git branch -d hotfix/security-patch
```

---

### 2️⃣ GitHub Flow (Simplified)

**Phù hợp với**: Continuous deployment, web applications

```
main (production)
  ├── feature/add-search-functionality
  ├── fix/login-button-bug
  └── docs/update-readme
```

**Workflow:**

```bash
# 1. Create branch from main
git checkout main
git pull origin main
git checkout -b feature/add-search-functionality

# 2. Work, commit, push
git add .
git commit -m "feat(search): add search bar component"
git push origin feature/add-search-functionality

# 3. Create Pull Request to main
# After review, merge to main

# 4. Deploy main to production automatically
# Delete feature branch after merge
```

**Rules:**

- ✅ `main` luôn deployable
- ✅ Branch naming rõ ràng
- ✅ Pull Request cho mọi thay đổi
- ✅ Deploy ngay sau khi merge
- ✅ Xóa branch sau khi merge

---

### 3️⃣ Trunk-Based Development

**Phù hợp với**: Large teams, continuous integration

```
main (trunk)
  ├── [short-lived branches < 1 day]
  └── release branches (optional)
```

**Workflow:**

```bash
# 1. Create short-lived branch
git checkout main
git pull origin main
git checkout -b add-login-button

# 2. Work in small increments
git add .
git commit -m "feat(auth): add login button to navbar"

# 3. Push and merge quickly (same day)
git push origin add-login-button
# Create PR, quick review, merge immediately

# 4. Use feature flags for incomplete features
if (featureFlags.newSearchEnabled) {
    // New search implementation
} else {
    // Old search
}
```

**Principles:**

- 🚀 Commit to trunk at least once per day
- 🔄 Keep branches short-lived (< 1 day)
- 🚦 Use feature flags
- ✅ Strong CI/CD pipeline
- 🧪 Comprehensive automated tests

---

## 🏷️ BRANCH NAMING CONVENTIONS

### Format:

```
<type>/<ticket-id>-<short-description>
```

### Types:

```bash
feature/    # New features
fix/        # Bug fixes
hotfix/     # Emergency production fixes
release/    # Release preparation
docs/       # Documentation changes
refactor/   # Code refactoring
test/       # Adding tests
chore/      # Maintenance tasks
```

### Examples:

```bash
# ✅ GOOD
feature/JIRA-123-user-authentication
fix/JIRA-456-login-button-styling
hotfix/critical-security-patch
release/v1.2.0
docs/update-api-documentation
refactor/extract-payment-service
test/add-unit-tests-for-auth
chore/upgrade-dependencies

# ❌ BAD
new-feature
bugfix
my-branch
test
johndoe-branch
```

### Rules:

- ✅ Lowercase only
- ✅ Use hyphens, not spaces or underscores
- ✅ Include ticket ID if available
- ✅ Keep it short but descriptive
- ✅ Use present tense

---

## 💬 COMMIT MESSAGE GUIDELINES

### Conventional Commits Format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types:

```
feat:     New feature
fix:      Bug fix
docs:     Documentation changes
style:    Code style (formatting, semicolons, etc.)
refactor: Code refactoring
perf:     Performance improvements
test:     Adding tests
build:    Build system changes
ci:       CI/CD changes
chore:    Maintenance tasks
revert:   Revert previous commit
```

### Examples:

```bash
# ✅ GOOD - Simple feature
git commit -m "feat(auth): add JWT token refresh mechanism"

# ✅ GOOD - Bug fix with scope
git commit -m "fix(api): handle null pointer in user service"

# ✅ GOOD - Breaking change
git commit -m "feat(api): change user endpoint response format

BREAKING CHANGE: User API now returns camelCase instead of snake_case"

# ✅ GOOD - Multiple paragraphs
git commit -m "perf(database): optimize user query performance

- Add index on email column
- Implement query result caching
- Reduce N+1 queries using eager loading

Closes #123"

# ✅ GOOD - With ticket reference
git commit -m "fix(payment): correct tax calculation logic

The tax calculation was using wrong rate for international orders.
Updated to use country-specific rates from configuration.

Fixes JIRA-456"
```

### Bad Examples:

```bash
# ❌ BAD - Too vague
git commit -m "fix bug"
git commit -m "update code"
git commit -m "changes"

# ❌ BAD - Too long subject
git commit -m "feat(auth): implement JWT authentication with refresh tokens and also update the user service to handle token validation and add middleware for protected routes"

# ❌ BAD - Wrong format
git commit -m "Fixed the login bug"
git commit -m "Adding new feature"
git commit -m "WIP"
```

### Commit Message Rules:

1. **Subject line** (first line):
   - ✅ Max 50-72 characters
   - ✅ Start with lowercase
   - ✅ No period at the end
   - ✅ Imperative mood ("add" not "added" or "adds")

2. **Body** (optional):
   - ✅ Wrap at 72 characters
   - ✅ Explain WHAT and WHY, not HOW
   - ✅ Separate from subject with blank line

3. **Footer** (optional):
   - ✅ Reference issues: "Closes #123" or "Fixes #456"
   - ✅ Breaking changes: "BREAKING CHANGE: description"

### Scopes (examples):

```
auth        Authentication
api         API endpoints
db          Database
ui          User Interface
payment     Payment processing
email       Email service
config      Configuration
deps        Dependencies
```

---

## 🔀 PULL REQUEST BEST PRACTICES

### Pull Request Template:

```markdown
## 📝 Description
Brief description of changes

## 🎯 Type of Change
- [ ] 🐛 Bug fix
- [ ] ✨ New feature
- [ ] 🔨 Refactoring
- [ ] 📚 Documentation
- [ ] 🎨 Style/UI changes
- [ ] ⚡ Performance improvement

## 🔗 Related Issues
Closes #123
Related to #456

## 🧪 How Has This Been Tested?
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing
- [ ] E2E tests

## 📸 Screenshots (if applicable)
[Add screenshots here]

## ✅ Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
- [ ] All tests passing
- [ ] Branch is up to date with base

## 💭 Additional Notes
Any additional context or notes for reviewers
```

### Pull Request Best Practices:

```bash
# 1. Keep PRs small
# ✅ GOOD: 200-400 lines changed
# ❌ BAD: 2000+ lines changed

# 2. One PR = One feature/fix
# ✅ GOOD: PR only for user authentication
# ❌ BAD: PR with auth + payment + email changes

# 3. Update branch before creating PR
git checkout feature/my-feature
git fetch origin
git rebase origin/main

# 4. Clean up commits (squash if needed)
git rebase -i HEAD~5  # Interactive rebase last 5 commits

# 5. Write good PR title
# ✅ GOOD: "feat(auth): Implement JWT authentication"
# ❌ BAD: "Auth feature"

# 6. Add reviewers and labels
# Use GitHub/GitLab interface to add appropriate reviewers and labels

# 7. Respond to feedback promptly
# Address comments within 24 hours

# 8. Request re-review after changes
# Tag reviewers after addressing their comments
```

### Draft Pull Requests:

```bash
# Create draft PR for work-in-progress
# Use when:
# - Want early feedback on approach
# - Need to show progress
# - Collaborative development

# Mark as "Ready for Review" when complete
```

---

## 🔄 MERGE STRATEGIES

### 1️⃣ Merge Commit

```bash
git checkout main
git merge feature/my-feature
```

**Result:**
```
* Merge branch 'feature/my-feature'
|\
| * feat: add feature
| * fix: update logic
|/
* Previous commit
```

**✅ Pros:**
- Preserves complete history
- Shows when feature was merged
- Easy to revert entire feature

**❌ Cons:**
- Cluttered history with merge commits
- Harder to read git log

**When to use:** Long-lived branches, important features

---

### 2️⃣ Squash and Merge

```bash
git checkout main
git merge --squash feature/my-feature
git commit -m "feat(api): implement user authentication"
```

**Result:**
```
* feat(api): implement user authentication (contains all feature commits)
* Previous commit
```

**✅ Pros:**
- Clean linear history
- One commit per feature
- Easy to read git log

**❌ Cons:**
- Loses individual commit history
- Harder to debug if issue in middle of feature

**When to use:** Feature branches with many small commits

---

### 3️⃣ Rebase and Merge

```bash
git checkout feature/my-feature
git rebase main
git checkout main
git merge feature/my-feature
```

**Result:**
```
* feat: add feature (commit 3)
* fix: update logic (commit 2)
* feat: initial implementation (commit 1)
* Previous commit
```

**✅ Pros:**
- Clean linear history
- Preserves individual commits
- No merge commits

**❌ Cons:**
- Rewrites history (dangerous if branch is shared)
- More complex process

**When to use:** Solo development, short-lived branches

---

### Recommendation by Project Type:

```bash
# Open Source / Public Projects
✅ Use: Merge Commit
# Reason: Preserve history, show contributions

# Fast-paced Startups / Web Apps
✅ Use: Squash and Merge
# Reason: Clean history, easy rollback

# Enterprise / Large Teams
✅ Use: Merge Commit or Rebase
# Reason: Traceability, audit requirements
```

---

## 🪝 GIT HOOKS

### Pre-commit Hook

**File**: `.git/hooks/pre-commit`

```bash
#!/bin/sh

# Run linter
npm run lint
if [ $? -ne 0 ]; then
    echo "❌ Linting failed. Please fix errors before committing."
    exit 1
fi

# Run tests
npm test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Please fix tests before committing."
    exit 1
fi

# Check for console.log
if git diff --cached | grep -E "console\.(log|error|warn)"; then
    echo "❌ Found console.log statements. Please remove them."
    exit 1
fi

echo "✅ Pre-commit checks passed"
exit 0
```

### Commit-msg Hook

**File**: `.git/hooks/commit-msg`

```bash
#!/bin/sh

# Check commit message format (Conventional Commits)
commit_msg=$(cat "$1")

# Regex for conventional commits
pattern="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?: .{1,50}"

if ! echo "$commit_msg" | grep -qE "$pattern"; then
    echo "❌ Invalid commit message format"
    echo "Format: <type>(<scope>): <subject>"
    echo "Example: feat(auth): add login functionality"
    exit 1
fi

echo "✅ Commit message format is valid"
exit 0
```

### Using Husky (Recommended)

```bash
# Install husky
npm install --save-dev husky

# Initialize husky
npx husky install

# Add pre-commit hook
npx husky add .husky/pre-commit "npm run lint && npm test"

# Add commit-msg hook
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
```

**package.json:**

```json
{
  "scripts": {
    "prepare": "husky install",
    "lint": "eslint .",
    "test": "jest"
  },
  "devDependencies": {
    "husky": "^8.0.0",
    "@commitlint/cli": "^17.0.0",
    "@commitlint/config-conventional": "^17.0.0"
  }
}
```

---

## 🛠️ COMMON GIT COMMANDS

### Basic Operations

```bash
# Clone repository
git clone https://github.com/username/repo.git

# Check status
git status

# Add files
git add .                    # All files
git add file.js              # Specific file
git add *.js                 # Pattern

# Commit
git commit -m "feat: add feature"
git commit -am "fix: bug fix"  # Add and commit tracked files

# Push
git push origin main
git push -u origin feature/my-branch  # Set upstream

# Pull
git pull origin main
git pull --rebase origin main   # Pull with rebase
```

### Branch Operations

```bash
# List branches
git branch                   # Local branches
git branch -r                # Remote branches
git branch -a                # All branches

# Create branch
git branch feature/new-feature
git checkout -b feature/new-feature  # Create and checkout

# Switch branch
git checkout main
git switch main              # Modern syntax

# Delete branch
git branch -d feature/old     # Delete local (if merged)
git branch -D feature/old     # Force delete local
git push origin --delete feature/old  # Delete remote

# Rename branch
git branch -m old-name new-name
```

### Undoing Changes

```bash
# Discard local changes
git checkout -- file.js      # Discard changes in file
git restore file.js          # Modern syntax

# Unstage files
git reset HEAD file.js
git restore --staged file.js # Modern syntax

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Revert commit (create new commit)
git revert <commit-hash>

# Amend last commit
git commit --amend -m "New message"
git commit --amend --no-edit  # Keep message, add changes
```

### Stashing

```bash
# Save work temporarily
git stash
git stash save "WIP: feature in progress"

# List stashes
git stash list

# Apply stash
git stash apply              # Apply latest, keep in stash
git stash apply stash@{2}    # Apply specific stash
git stash pop                # Apply and remove from stash

# Drop stash
git stash drop stash@{0}
git stash clear              # Clear all stashes
```

### History & Logs

```bash
# View history
git log
git log --oneline            # Compact view
git log --graph --oneline    # Graph view
git log --author="John"      # By author
git log --since="2 weeks ago"

# View changes
git diff                     # Working directory vs staging
git diff --staged            # Staging vs last commit
git diff main feature/branch # Between branches

# Show commit details
git show <commit-hash>

# Blame (see who changed each line)
git blame file.js
```

### Remote Operations

```bash
# List remotes
git remote -v

# Add remote
git remote add origin https://github.com/user/repo.git

# Change remote URL
git remote set-url origin https://github.com/user/new-repo.git

# Fetch from remote
git fetch origin             # Fetch all branches
git fetch origin main        # Fetch specific branch

# Pull from remote
git pull origin main

# Push to remote
git push origin main
git push --force-with-lease  # Force push (safer)
git push --tags              # Push tags
```

### Rebase

```bash
# Rebase onto branch
git checkout feature/my-branch
git rebase main

# Interactive rebase
git rebase -i HEAD~5         # Last 5 commits
# Commands in interactive mode:
# pick   = use commit
# reword = use commit, edit message
# edit   = use commit, stop for amending
# squash = combine with previous commit
# fixup  = like squash, discard message
# drop   = remove commit

# Continue after resolving conflicts
git rebase --continue

# Abort rebase
git rebase --abort
```

### Tags

```bash
# List tags
git tag

# Create tag
git tag v1.0.0
git tag -a v1.0.0 -m "Release version 1.0.0"  # Annotated tag

# Push tags
git push origin v1.0.0       # Push specific tag
git push origin --tags       # Push all tags

# Delete tag
git tag -d v1.0.0            # Delete local
git push origin --delete v1.0.0  # Delete remote

# Checkout tag
git checkout v1.0.0
```

---

## 🔧 TROUBLESHOOTING

### 1. Accidentally committed to wrong branch

```bash
# 1. Save commit hash
git log  # Copy commit hash

# 2. Switch to correct branch
git checkout correct-branch

# 3. Cherry-pick the commit
git cherry-pick <commit-hash>

# 4. Go back and remove from wrong branch
git checkout wrong-branch
git reset --hard HEAD~1
```

### 2. Need to undo pushed commit

```bash
# ⚠️ WARNING: Only if no one else pulled

# Option 1: Revert (create new commit)
git revert <commit-hash>
git push origin main

# Option 2: Reset and force push (dangerous!)
git reset --hard HEAD~1
git push --force-with-lease origin main
```

### 3. Resolve merge conflicts

```bash
# 1. Try to merge
git merge feature/branch
# CONFLICT appears

# 2. Check conflicted files
git status

# 3. Edit files manually
# <<<<<<< HEAD
# Current branch content
# =======
# Incoming branch content
# >>>>>>> feature/branch

# 4. Mark as resolved
git add conflicted-file.js

# 5. Complete merge
git commit
```

### 4. Accidentally deleted branch

```bash
# Find the commit hash
git reflog

# Create branch at that commit
git checkout -b recovered-branch <commit-hash>
```

### 5. Remove file from Git but keep locally

```bash
# Remove from Git, keep local file
git rm --cached file.txt

# Add to .gitignore
echo "file.txt" >> .gitignore

# Commit
git commit -m "chore: remove file from git"
```

### 6. Large file causing issues

```bash
# Remove from history using git filter-branch (old way)
git filter-branch --tree-filter 'rm -f large-file.zip' HEAD

# Or use BFG Repo-Cleaner (recommended)
bfg --delete-files large-file.zip
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

---

## 🎯 BEST PRACTICES SUMMARY

### ✅ DO

- ✅ Commit often with meaningful messages
- ✅ Pull before push
- ✅ Keep commits atomic (one logical change per commit)
- ✅ Write descriptive commit messages
- ✅ Use branches for features/fixes
- ✅ Review your own code before creating PR
- ✅ Keep branches up to date
- ✅ Delete merged branches
- ✅ Use `.gitignore` properly
- ✅ Tag releases

### ❌ DON'T

- ❌ Commit sensitive data (passwords, API keys)
- ❌ Commit large binary files
- ❌ Force push to shared branches
- ❌ Commit directly to main/production
- ❌ Use vague commit messages
- ❌ Mix unrelated changes in one commit
- ❌ Leave branches unmerged for weeks
- ❌ Ignore merge conflicts
- ❌ Commit commented-out code
- ❌ Commit with failing tests

---

## 📚 REFERENCES

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- [Git Official Documentation](https://git-scm.com/doc)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
