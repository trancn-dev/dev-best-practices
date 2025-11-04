# .github/copilot for Nuxt Frontend

This directory contains comprehensive documentation, rules, and templates to guide GitHub Copilot and AI coding agents when working on the Nuxt 3 frontend.

## 📁 Directory Structure

```
.github/copilot/
├── commands/           # Workflow automations and command templates
│   ├── capture-knowledge.md
│   ├── code-review.md
│   ├── writing-test.md
│   └── execute-plan.md
├── knowledge/          # Project knowledge base
│   ├── conventions.md
│   ├── architecture.md
│   ├── workflow.md
│   └── glossary.md
├── prompts/            # Reusable prompt templates
│   ├── bug-fix-assistant.md
│   ├── component-design.md
│   ├── testing-strategy.md
│   └── refactoring-suggestions.md
├── rules/              # Coding standards and conventions
│   ├── git.md
│   ├── vue.md
│   ├── nuxt.md
│   ├── typescript.md
│   └── testing.md
├── snippets/           # Code snippets and templates
│   ├── vue-component.json
│   ├── composable.json
│   ├── nuxt-page.json
│   ├── pinia-store.json
│   ├── api-composable.json
│   └── README.md
├── copilot-instructions.md  # Main instructions for Copilot
├── context.md          # Project context
├── config.json         # Configuration
├── STRUCTURE.md        # Structure documentation
└── README.md           # This file
```

## 🎯 Purpose

This structure helps Copilot and AI agents:
- Understand project conventions and standards
- Generate code following best practices
- Provide consistent code reviews
- Assist with debugging and refactoring
- Automate repetitive development tasks

## 📖 How to Use

### For Developers

1. **Before coding**: Review relevant rules in `rules/`
2. **Creating components**: Use templates from `snippets/`
3. **Need help**: Refer to `prompts/` for guidance templates
4. **Learning project**: Check `knowledge/` for project overview

### For Copilot/AI Agents

1. **Always consult** `copilot-instructions.md` first
2. **Follow standards** defined in `rules/`
3. **Use commands** from `commands/` for structured workflows
4. **Reference prompts** from `prompts/` for specific tasks
5. **Check knowledge** in `knowledge/` for project context

## 🔑 Key Files

### Essential Reading

- **`copilot-instructions.md`** - Start here! Main instructions for AI agents
- **`rules/vue.md`** - Vue 3 Composition API standards
- **`rules/nuxt.md`** - Nuxt 3 best practices
- **`rules/git.md`** - Git workflow and commit standards

### Common Tasks

- **Code Review**: Use `commands/code-review.md`
- **Writing Tests**: Use `commands/writing-test.md`
- **Bug Fixing**: Use `prompts/bug-fix-assistant.md`
- **Component Design**: Use `prompts/component-design.md`

## 🚀 Quick Start Examples

### Creating a New Component

1. Check `rules/vue.md` for component standards
2. Use template from `snippets/vue-component.json`
3. Follow naming conventions in `knowledge/conventions.md`

### Adding a Feature

1. Create feature branch (see `rules/git.md`)
2. Use `commands/execute-plan.md` for workflow
3. Write tests using `commands/writing-test.md`
4. Request review using `commands/code-review.md`

### Fixing a Bug

1. Use `prompts/bug-fix-assistant.md` template
2. Follow debugging guidelines in `knowledge/workflow.md`
3. Add tests to prevent regression

## 📚 Documentation Standards

All documentation follows these principles:
- **Clear and concise**: Easy to understand
- **Actionable**: Provide specific steps
- **Example-driven**: Show, don't just tell
- **Up-to-date**: Regularly reviewed and updated

## 🔄 Keeping Up-to-Date

When project conventions change:
1. Update relevant files in `rules/`
2. Update examples in `snippets/`
3. Add notes to `knowledge/`
4. Notify team of changes

## 🤝 Contributing

To improve this documentation:
1. Identify gaps or outdated information
2. Create PR with updates
3. Follow the existing structure and format
4. Update this README if structure changes

## 📞 Getting Help

- **Questions about conventions**: Check `rules/` directory
- **Need code examples**: Check `snippets/` directory
- **Want to understand architecture**: Check `knowledge/` directory
- **Need prompt templates**: Check `prompts/` directory

## 🎓 Learning Path

For new team members:
1. Read `copilot-instructions.md` (5 min)
2. Review `knowledge/architecture.md` (10 min)
3. Study `rules/vue.md` and `rules/nuxt.md` (20 min)
4. Browse `snippets/` for code examples (10 min)
5. Try creating a component following the standards

---

**Last Updated**: November 2025
**Maintained by**: Frontend Team
**For Questions**: See project documentation or ask the team
