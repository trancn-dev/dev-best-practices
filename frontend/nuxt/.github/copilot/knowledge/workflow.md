# Development Workflow

## Daily Workflow

### 1. Start Development
```bash
# Pull latest changes
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/PROJ-123/new-feature

# Install dependencies (if needed)
npm install

# Start dev server
npm run dev
```

### 2. Development
- Write code following `.github/copilot/rules/`
- Test locally
- Commit frequently with meaningful messages
- Keep branch up-to-date with develop

### 3. Testing
```bash
# Run tests
npm run test

# Run lint
npm run lint

# Type check
npm run type-check
```

### 4. Code Review
- Create pull request
- Address review comments
- Ensure CI passes

### 5. Merge & Deploy
- Squash/merge to develop
- Delete feature branch
- Deploy to staging/production

---

## Branch Strategy

- `main` - Production
- `develop` - Integration
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Urgent production fixes

---

## References

- See `.github/copilot/rules/git.md` for Git workflow details
