# Copilot Configuration Structure

## Directory Purpose

### `.github/copilot/` - Centralized Copilot Configuration
Comprehensive Copilot configuration that includes all standards, workflows, knowledge, and snippets.

**Purpose**:
- Define coding standards and rules
- Provide workflow automation commands
- Create reusable prompt templates for common tasks
- Store project knowledge base and domain information
- Provide code snippets for rapid development

**When to use**:
- Standards that all team members must follow
- Automation commands for development workflows
- Templates for repetitive tasks
- Project-specific context and business logic
- Domain knowledge and terminology
- Quick code generation templates

**Structure**:
```
.github/copilot/
├── commands/           # Workflow automation (9 files)
├── rules/             # Coding standards (8 files)
├── prompts/           # Reusable templates (10 files)
├── knowledge/         # Knowledge base (domain, tech, business)
├── snippets/          # Code snippets (language-specific)
├── config.json        # Copilot configuration
├── context.md         # Project context
└── README.md          # Documentation
```

---

## Content Guidelines

### Commands (`commands/`)
- Workflow automation scripts
- Step-by-step procedures
- Development process guides
- Examples: code review, requirement analysis, testing

### Rules (`rules/`)
- Coding standards (PSR-12, etc.)
- Framework conventions (Laravel, etc.)
- Security best practices
- Performance guidelines
- Database design rules
- API design standards
- Git workflow rules
- Testing standards

### Prompts (`prompts/`)
- Reusable prompt templates
- Architecture design prompts
- Code explanation templates
- Refactoring guides
- Security audit checklists
- Performance optimization guides
- Documentation generation templates

### Knowledge (`knowledge/`)
- Business domain knowledge
- Entity relationships
- Workflow descriptions
- Architecture documentation
- API specifications
- Database schema
- Security policies
- Testing strategies
- Coding conventions
- Glossary of terms
- Business constraints
- Language-specific guides (php.md, nodejs.md, etc.)

### Snippets (`snippets/`)
- Code generation templates
- Boilerplate code
- Common patterns
- Language-specific snippets
- Framework-specific templates

### Configuration Files
- `config.json`: Copilot settings, rules, prompts, knowledge, snippets mapping
- `context.md`: Project overview, tech stack, structure
- `README.md`: Usage instructions

---

## Avoid Duplication

### ❌ Don't Duplicate

**Coding Standards**:
- ✅ Define in `.github/copilot/rules/`
- ❌ Don't repeat in `.github/copilot/knowledge/`

**Framework Conventions**:
- ✅ Define in `.github/copilot/rules/[framework].md`
- ❌ Don't repeat in `.github/copilot/knowledge/`

### ✅ What Goes Where

**Project-Specific Information**:
- ✅ `.github/copilot/knowledge/business.md` - Business logic
- ✅ `.github/copilot/knowledge/entities.md` - Domain entities
- ✅ `.github/copilot/knowledge/workflow.md` - Business workflows

**Language/Framework Guides**:
- ✅ `.github/copilot/knowledge/php.md` - PHP/Laravel specifics
- ✅ `.github/copilot/knowledge/nodejs.md` - Node.js specifics
- ✅ `.github/copilot/knowledge/python.md` - Python specifics

**Generic Standards**:
- ✅ `.github/copilot/rules/[standard].md` - Apply to all projects
- ✅ `.github/copilot/rules/[framework].md` - Framework conventions

---

## Cross-References

### From `.github/copilot/config.json`

```json
{
  "context_files": [
    ".github/copilot/context.md",
    ".github/copilot/knowledge/*.md",
    ".github/copilot/rules/*.md",
    ".github/copilot/prompts/*.md"
  ],
  "rules": {
    "primary": [
      ".github/copilot/rules/[framework].md",
      ".github/copilot/rules/[coding-standard].md",
      ".github/copilot/rules/security.md"
    ]
  },
  "knowledge_base": {
    "directory": ".github/copilot/knowledge"
  },
  "snippets": {
    "directory": ".github/copilot/snippets"
  }
}
```

---

## Maintenance Guidelines

### `.github/copilot/`

**Update when**:
- Coding standards change
- New framework conventions adopted
- Security policies updated
- Team workflow changes
- Project requirements change
- New features added
- Domain knowledge evolves
- Architecture changes

**Review frequency**: Sprint-based or as needed

---

## Migration Guide

### From Single Directory to Dual Structure

1. **Identify Content Type**:
   - Standards/Rules → `.github/copilot/rules/`
   - Workflows/Commands → `.github/copilot/commands/`
   - Prompt Templates → `.github/copilot/prompts/`
   - Project Context → `.vscode/copilot/context.md`
   - Domain Knowledge → `.vscode/copilot/knowledge/`
   - Code Snippets → `.vscode/copilot/snippets/`

2. **Move Files**:
   ```powershell
   # Example: Move rules
   Move-Item -Path "copilot/rules/*" -Destination ".github/copilot/rules/"

   # Example: Move knowledge
   Move-Item -Path "copilot/knowledge/*" -Destination ".vscode/copilot/knowledge/"
   ```

3. **Update References**:
   - Update `config.json` paths
   - Update documentation links
   - Update team documentation

4. **Validate**:
   - Test Copilot suggestions
   - Verify file paths
   - Check cross-references

---

## Best Practices

### 1. Keep Rules Generic

`.github/copilot/rules/` should contain standards applicable across projects:

```markdown
# ✅ GOOD: Generic rule
## Security Best Practice
Never store credentials in code. Use environment variables.

# ❌ BAD: Project-specific
## UserService Security
The UserService in app/Services must hash passwords using bcrypt.
```

### 2. Keep Knowledge Specific

`.github/copilot/knowledge/` should contain project-specific information:

```markdown
# ✅ GOOD: Project-specific
## User Entity
Our User entity has three roles: admin, editor, viewer.
Admins can manage all resources...

# ❌ BAD: Generic standard (should be in rules/)
## REST API Design
Use proper HTTP methods: GET, POST, PUT, DELETE...
```

### 3. Reference, Don't Repeat

Use cross-references instead of duplication:

```markdown
# In .github/copilot/knowledge/architecture.md

## Coding Standards
Follow the coding standards defined in `.github/copilot/rules/psr-12.md`.

## API Design
Refer to `.github/copilot/rules/api.md` for API conventions.
```

### 4. Version Control

The `.github/copilot/` directory should be in version control:

```gitignore
# .gitignore

# Don't ignore Copilot configuration
!.github/copilot/

# But ignore environment-specific files
/.github/copilot/.env
```

---

## Summary

| Location | Content | Reusable? | Project-Specific? |
|----------|---------|-----------|-------------------|
| `.github/copilot/commands/` | Workflow automation | ✅ Yes | ❌ No |
| `.github/copilot/rules/` | Coding standards | ✅ Yes | ❌ No |
| `.github/copilot/prompts/` | Prompt templates | ✅ Yes | ❌ No |
| `.github/copilot/knowledge/` | Domain knowledge | ❌ No | ✅ Yes |
| `.github/copilot/snippets/` | Code templates | ⚠️ Partial | ✅ Yes |
| `.github/copilot/config.json` | Copilot settings | ⚠️ Template | ✅ Yes |
| `.github/copilot/context.md` | Project overview | ❌ No | ✅ Yes |

**Reusable**: Can be copied to other projects as-is
**Project-Specific**: Must be customized for each project
