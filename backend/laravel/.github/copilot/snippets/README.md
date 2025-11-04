# Code Snippets

This directory contains code snippets for rapid development across different programming languages and frameworks.

---

## Structure

```
snippets/
├── laravel-*.json       # PHP/Laravel snippets (current project)
├── php/                 # Additional PHP snippets (optional)
├── nodejs/              # Node.js/Express/NestJS snippets
├── python/              # Python/Django/Flask snippets
└── README.md            # This file
```

---

## Current Snippets

### PHP/Laravel (15 files)

Located in root `snippets/` directory:

| File | Purpose | Trigger |
|------|---------|---------|
| `laravel-action.json` | Action class | `action` |
| `laravel-api.json` | API controller | `api`, `apiresource` |
| `laravel-controller.json` | Controller | `controller` |
| `laravel-model.json` | Eloquent model | `model` |
| `laravel-request.json` | Form request | `request` |
| `laravel-repository.json` | Repository | `repository` |
| `laravel-policy.json` | Policy | `policy` |
| `laravel-resource.json` | API resource | `resource` |
| `laravel-event.json` | Event | `event` |
| `laravel-job.json` | Queue job | `job` |
| `laravel-factory.json` | Model factory | `factory` |
| `laravel-middleware.json` | Middleware | `middleware` |
| `laravel-migration.json` | Migration | `migration` |
| `laravel-service.json` | Service | `service` |
| `laravel-test.json` | Test case | `test`, `feature` |

### Usage Example

1. Create new file: `app/Actions/CreateUserAction.php`
2. Type: `action`
3. Press: `Tab` or `Enter`
4. Fill in placeholders

---

## Extending for Other Languages

### For Node.js Projects

Create `nodejs/` directory with these snippets:

**express-route.json**:
```json
{
  "Express Router": {
    "prefix": "express-route",
    "body": [
      "import { Router, Request, Response } from 'express';",
      "",
      "const router = Router();",
      "",
      "router.get('/${1:path}', async (req: Request, res: Response) => {",
      "    try {",
      "        ${2:// Implementation}",
      "        res.json({ success: true });",
      "    } catch (error) {",
      "        res.status(500).json({ error: error.message });",
      "    }",
      "});",
      "",
      "export default router;"
    ]
  }
}
```

**nest-controller.json**:
```json
{
  "NestJS Controller": {
    "prefix": "nest-controller",
    "body": [
      "import { Controller, Get, Post, Body, Param } from '@nestjs/common';",
      "import { ${1:Service}Service } from './${1/(.*)/${1:/downcase}/}.service';",
      "",
      "@Controller('${2:route}')",
      "export class ${1}Controller {",
      "    constructor(private readonly ${1/(.*)/${1:/downcase}/}Service: ${1}Service) {}",
      "",
      "    @Get()",
      "    findAll() {",
      "        return this.${1/(.*)/${1:/downcase}/}Service.findAll();",
      "    }",
      "",
      "    @Get(':id')",
      "    findOne(@Param('id') id: string) {",
      "        return this.${1/(.*)/${1:/downcase}/}Service.findOne(+id);",
      "    }",
      "",
      "    @Post()",
      "    create(@Body() createDto: Create${1}Dto) {",
      "        return this.${1/(.*)/${1:/downcase}/}Service.create(createDto);",
      "    }",
      "}"
    ]
  }
}
```

### For Python/Django Projects

Create `python/` directory with these snippets:

**django-view.json**:
```json
{
  "Django Class-Based View": {
    "prefix": "django-view",
    "body": [
      "from django.views.generic import ${1|ListView,DetailView,CreateView,UpdateView,DeleteView|}",
      "from django.contrib.auth.mixins import LoginRequiredMixin",
      "from .models import ${2:Model}",
      "",
      "class ${2}${1}(LoginRequiredMixin, ${1}):",
      "    model = ${2}",
      "    template_name = '${3:app}/${2/(.*)/${1:/downcase}/}.html'",
      "    context_object_name = '${2/(.*)/${1:/downcase}/}'",
      "    ${4:# Additional configuration}"
    ]
  }
}
```

**django-serializer.json**:
```json
{
  "Django REST Serializer": {
    "prefix": "drf-serializer",
    "body": [
      "from rest_framework import serializers",
      "from .models import ${1:Model}",
      "",
      "class ${1}Serializer(serializers.ModelSerializer):",
      "    class Meta:",
      "        model = ${1}",
      "        fields = ${2|'__all__',['id', 'name']|}",
      "        read_only_fields = ['id', 'created_at', 'updated_at']",
      "",
      "    def validate(self, attrs):",
      "        ${3:# Custom validation}",
      "        return attrs"
    ]
  }
}
```

---

## Creating Custom Snippets

### Snippet File Format

```json
{
  "Snippet Name": {
    "prefix": "trigger-word",
    "body": [
      "Line 1 of code",
      "Line 2 with ${1:placeholder}",
      "Line 3 with ${2:another_placeholder}",
      "$0"
    ],
    "description": "What this snippet does"
  }
}
```

### Placeholders

- `$1`, `$2`, `$3`: Tab stops (tab to next)
- `${1:default}`: Placeholder with default value
- `${1|option1,option2|}`: Dropdown selection
- `$0`: Final cursor position

### Variables

- `$TM_FILENAME`: Current filename
- `$TM_FILENAME_BASE`: Filename without extension
- `$TM_DIRECTORY`: Directory path
- `$CLIPBOARD`: Clipboard content
- `$CURRENT_YEAR`: Current year

---

## Best Practices

### ✅ Do's

- **Use descriptive prefixes**: `laravel-model`, not just `model`
- **Include imports**: Add necessary import statements
- **Add PHPDoc/JSDoc**: Include documentation comments
- **Use placeholders**: Make customizable parts obvious
- **Test snippets**: Verify they work as expected

### ❌ Don'ts

- **Don't hardcode**: Use placeholders for names, paths
- **Don't skip namespaces**: Include proper namespace declarations
- **Don't create conflicts**: Avoid common prefixes like `class`, `function`
- **Don't over-complicate**: Keep snippets focused and simple

---

## Snippet Categories

### By Complexity

**Simple Snippets** (< 10 lines):
- Property declarations
- Method signatures
- Import statements

**Medium Snippets** (10-30 lines):
- Class structures
- Controller methods
- Service methods

**Complex Snippets** (30+ lines):
- Full class implementations
- Complete API resources
- Test suites

### By Usage Frequency

**High Frequency** (daily use):
- Models, Controllers
- Services, Repositories
- Tests

**Medium Frequency** (weekly use):
- Middleware, Policies
- Events, Jobs
- Migrations

**Low Frequency** (as needed):
- Custom validation rules
- Complex queries
- Advanced patterns

---

## Multi-Language Project Setup

For projects using multiple languages:

```
snippets/
├── README.md                 # This file
├── php/
│   ├── laravel/              # Laravel-specific
│   ├── symfony/              # Symfony-specific
│   └── generic/              # Generic PHP
├── javascript/
│   ├── express/              # Express.js
│   ├── nest/                 # NestJS
│   └── vanilla/              # Plain JS
├── typescript/
│   ├── nest/                 # NestJS
│   ├── angular/              # Angular
│   └── react/                # React
└── python/
    ├── django/               # Django
    ├── flask/                # Flask
    └── fastapi/              # FastAPI
```

---

## VS Code Integration

### Enable Snippets

1. **File** → **Preferences** → **User Snippets**
2. Select language
3. Add snippet JSON

### Or Use Workspace Snippets

File location: `.vscode/copilot/snippets/*.json`

These are automatically available in the workspace.

### Snippet Shortcuts

- `Ctrl + Space`: Trigger IntelliSense
- `Tab`: Next placeholder
- `Shift + Tab`: Previous placeholder
- `Esc`: Cancel snippet

---

## Maintenance

### Regular Updates

**Monthly**:
- Review snippet usage
- Add commonly typed patterns
- Remove unused snippets

**Quarterly**:
- Update for framework changes
- Review best practices
- Optimize trigger words

### Team Collaboration

1. **Share snippets**: Commit to version control
2. **Document changes**: Update this README
3. **Gather feedback**: Ask team what snippets they need
4. **Standardize**: Agree on naming conventions

---

## Examples by Framework

### Laravel Snippets

```php
// Trigger: action
namespace App\Actions;

class CreateUserAction
{
    public function execute(array $data): User
    {
        // Implementation
    }
}
```

### Express Snippets

```javascript
// Trigger: express-route
import { Router } from 'express';

const router = Router();

router.get('/users', async (req, res) => {
    // Implementation
});
```

### Django Snippets

```python
# Trigger: django-view
from django.views.generic import ListView
from .models import User

class UserListView(ListView):
    model = User
    template_name = 'users/list.html'
```

---

## Contributing

### Adding New Snippets

1. Create JSON file in appropriate directory
2. Follow naming convention: `{framework}-{component}.json`
3. Test thoroughly
4. Update this README
5. Commit with descriptive message

### Snippet Template

```json
{
  "Component Name": {
    "prefix": "trigger",
    "body": [
      "// Your code here",
      "${1:placeholder}",
      "$0"
    ],
    "description": "Brief description"
  }
}
```

---

## Resources

- [VS Code Snippets Guide](https://code.visualstudio.com/docs/editor/userdefinedsnippets)
- [Snippet Generator](https://snippet-generator.app/)
- [TextMate Grammar](https://macromates.com/manual/en/snippets)

---

**Last Updated**: 2024
**Maintained by**: [Your Team]
**Version**: 1.0
