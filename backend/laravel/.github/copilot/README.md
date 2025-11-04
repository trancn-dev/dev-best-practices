# GitHub Copilot Configuration

Cấu hình GitHub Copilot cho dự án Laravel với đầy đủ commands, rules, và prompts để hỗ trợ AI-assisted development.

## 📁 Cấu trúc

```
.github/copilot/
├── commands/           # Workflow automation commands (9 files)
├── rules/             # Coding standards & best practices (8 files)
├── prompts/           # Reusable prompt templates (10 files)
└── README.md          # Documentation này
```

---

## 🎯 Commands - Workflow Automation (9 files)

Commands giúp tự động hóa các workflow phát triển phổ biến.

| Command | Mục đích | Khi nào dùng |
|---------|----------|--------------|
| `capture-knowledge` | Thu thập và ghi nhận kiến thức về code, architecture | Onboarding, documentation, knowledge transfer |
| `check-implementation` | Kiểm tra implementation có đúng requirements | Sau khi code xong, trước khi commit |
| `code-review` | Review code theo standards | Pull request review, quality assurance |
| `execute-plan` | Thực hiện kế hoạch phát triển đã duyệt | Implement features, bug fixes |
| `new-requirement` | Phân tích và xử lý requirement mới | Planning phase, feature requests |
| `review-design` | Review thiết kế hệ thống | Architecture review, design phase |
| `review-requirements` | Kiểm tra và validate requirements | Requirements gathering, planning |
| `update-planning` | Cập nhật và điều chỉnh kế hoạch | Sprint planning, backlog refinement |
| `writing-test` | Tạo test cases toàn diện | TDD, quality assurance, coverage |

### Cách sử dụng Commands

1. Gọi command trong GitHub Copilot Chat:
   ```
   @workspace /capture-knowledge explain UserService class
   ```

2. Hoặc tham khảo quy trình trong file để thực hiện thủ công

---

## 📋 Rules - Coding Standards (8 files)

Rules định nghĩa coding standards và best practices cho dự án.

| Rule | Coverage | Áp dụng cho |
|------|----------|-------------|
| `api.md` | RESTful API design, endpoints, responses | API controllers, resources |
| `database.md` | Database schema, migrations, queries | Migrations, models, queries |
| `git.md` | Git workflow, branches, commits | Version control, collaboration |
| `laravel.md` | Laravel conventions, patterns | All Laravel code |
| `performance.md` | Query optimization, caching, scaling | Performance-critical code |
| `psr-12.md` | PHP coding style, formatting | All PHP files |
| `security.md` | Security best practices, OWASP | Authentication, validation, sensitive data |
| `testing.md` | Test structure, coverage, quality | All test files |

### Highlights

- ✅ **690+ dòng** Laravel best practices
- ✅ **770+ dòng** Performance optimization guides
- ✅ **790+ dòng** Git workflow standards
- ✅ **795+ dòng** PSR-12 PHP standards
- ✅ **700+ dòng** Testing guidelines

---

## 🔧 Prompts - Reusable Templates (10 files)

Prompt templates cho các tác vụ phát triển phổ biến.

### Development & Code Quality

| Prompt | Mục đích | Use Case |
|--------|----------|----------|
| `code-explanation` | Giải thích code chi tiết | Understanding, documentation, onboarding |
| `refactoring-suggestions` | Gợi ý cải thiện code | Code cleanup, optimization |
| `bug-fix-assistant` | Hỗ trợ debug và fix bugs | Bug fixing, troubleshooting |

### Architecture & Design

| Prompt | Mục đích | Use Case |
|--------|----------|----------|
| `api-design` | Thiết kế RESTful API | API development, endpoint planning |
| `database-design` | Thiết kế database schema | Data modeling, migrations |

### Quality & Performance

| Prompt | Mục đích | Use Case |
|--------|----------|----------|
| `testing-strategy` | Tạo test strategy toàn diện | TDD, quality assurance |
| `performance-optimization` | Tối ưu hiệu suất | Performance tuning, scaling |
| `security-audit` | Kiểm tra bảo mật | Security review, vulnerability scanning |

### Documentation & Deployment

| Prompt | Mục đích | Use Case |
|--------|----------|----------|
| `documentation-generation` | Tạo documentation | API docs, PHPDoc, README |
| `deployment-checklist` | Checklist triển khai | Production deployment, release |

### Cách sử dụng Prompts

1. Copy template từ file prompt
2. Thay thế placeholders bằng thông tin cụ thể
3. Paste vào GitHub Copilot Chat hoặc IDE

**Ví dụ:**
```
Sử dụng template từ api-design.md:

I need to design an API for:

**Feature**: User management
**Resources**: Users, Roles, Permissions
**Operations**: CRUD + assign roles
**Authentication**: JWT tokens
...
```

---

## 🚀 Quick Start

### 1. Onboarding Developer Mới

```bash
# Bước 1: Đọc Laravel rules
.github/copilot/rules/laravel.md

# Bước 2: Đọc Git workflow
.github/copilot/rules/git.md

# Bước 3: Sử dụng capture-knowledge để hiểu codebase
@workspace /capture-knowledge explain app/Services/
```

### 2. Phát triển Feature Mới

```bash
# Bước 1: Analyze requirement
@workspace /new-requirement [mô tả feature]

# Bước 2: Design API (nếu cần)
Sử dụng: prompts/api-design.md

# Bước 3: Design database (nếu cần)
Sử dụng: prompts/database-design.md

# Bước 4: Execute plan
@workspace /execute-plan [implement feature]

# Bước 5: Write tests
@workspace /writing-test [test cho feature]

# Bước 6: Code review
@workspace /code-review [review code]
```

### 3. Bug Fixing

```bash
# Bước 1: Sử dụng bug-fix-assistant
Sử dụng: prompts/bug-fix-assistant.md

# Bước 2: Fix bug
[Implement fix]

# Bước 3: Add test
@workspace /writing-test [test for bug fix]

# Bước 4: Review
@workspace /code-review [review fix]
```

### 4. Performance Optimization

```bash
# Bước 1: Analyze performance
Sử dụng: prompts/performance-optimization.md

# Bước 2: Apply fixes
[Implement optimizations]

# Bước 3: Measure improvements
[Run benchmarks]
```

### 5. Security Review

```bash
# Bước 1: Security audit
Sử dụng: prompts/security-audit.md

# Bước 2: Check rules
Đọc: rules/security.md

# Bước 3: Fix vulnerabilities
[Implement security fixes]
```

### 6. Pre-Deployment

```bash
# Bước 1: Deployment checklist
Sử dụng: prompts/deployment-checklist.md

# Bước 2: Run all checks
- Tests: php artisan test
- Static analysis: vendor/bin/phpstan
- Code style: vendor/bin/pint
- Security: composer audit

# Bước 3: Deploy
[Follow deployment steps]
```

---

## 💡 Best Practices

### Khi sử dụng Commands

1. ✅ Đọc kỹ quy trình trong command trước khi thực hiện
2. ✅ Follow checklist đầy đủ
3. ✅ Document decisions và changes
4. ✅ Review output trước khi commit

### Khi sử dụng Rules

1. ✅ Tham khảo rules khi code
2. ✅ Review code theo rules trước khi PR
3. ✅ Cập nhật rules khi có patterns mới
4. ✅ Chia sẻ rules với team

### Khi sử dụng Prompts

1. ✅ Customize template cho context cụ thể
2. ✅ Provide đủ thông tin trong placeholders
3. ✅ Review và adjust output từ AI
4. ✅ Iterate nếu cần thiết

---

## 📊 Statistics

- **Total Files**: 27
- **Total Size**: ~423 KB
- **Commands**: 9 workflow automations
- **Rules**: 8 coding standards (5,000+ lines)
- **Prompts**: 10 reusable templates (5,500+ lines)

---

## 🔗 Cross-References

Các files thường được sử dụng cùng nhau:

### API Development
- `prompts/api-design.md` → Design API
- `rules/api.md` → API standards
- `rules/laravel.md` → Laravel conventions
- `commands/writing-test.md` → Test API

### Database Work
- `prompts/database-design.md` → Design schema
- `rules/database.md` → Database standards
- `rules/performance.md` → Query optimization
- `commands/check-implementation.md` → Verify implementation

### Security
- `prompts/security-audit.md` → Audit security
- `rules/security.md` → Security standards
- `commands/code-review.md` → Review for security

### Performance
- `prompts/performance-optimization.md` → Optimize
- `rules/performance.md` → Performance standards
- `rules/database.md` → Query optimization

### Testing
- `prompts/testing-strategy.md` → Plan tests
- `rules/testing.md` → Testing standards
- `commands/writing-test.md` → Write tests

---

## 🎓 Learning Path

### Beginner
1. Đọc `rules/laravel.md` - Laravel basics
2. Đọc `rules/psr-12.md` - PHP coding style
3. Sử dụng `prompts/code-explanation.md` - Understand code

### Intermediate
4. Đọc `rules/testing.md` - Testing
5. Đọc `rules/database.md` - Database design
6. Sử dụng `prompts/refactoring-suggestions.md` - Improve code

### Advanced
7. Đọc `rules/performance.md` - Optimization
8. Đọc `rules/security.md` - Security
9. Sử dụng `prompts/api-design.md` - Architecture

---

## 🤝 Contributing

Khi muốn thêm hoặc cập nhật configuration:

### Thêm Command mới
```markdown
---
type: command
name: your-command
version: 2.0
scope: project
integration:
  - laravel
---

# Command: Your Command

## Mục tiêu
[Mô tả mục tiêu]

## Quy trình
[Quy trình thực hiện]
...
```

### Thêm Rule mới
```markdown
# Rule: Your Rule Name

## Intent
[Mục đích của rule]

## Scope
[Phạm vi áp dụng]

## Examples
✅ Good examples
❌ Bad examples
```

### Thêm Prompt mới
```markdown
# Prompt: Your Prompt Name

## Purpose
[Mục đích]

## When to Use
[Khi nào sử dụng]

## Prompt Template
[Template]

## Example Usage
[Ví dụ]
```

---

## 📝 Version History

- **v2.0** (2025-10-28)
  - Initial comprehensive framework
  - 9 commands with YAML metadata
  - 8 detailed rules (5,000+ lines)
  - 10 practical prompts (5,500+ lines)

---

## 📞 Support

Nếu có câu hỏi hoặc cần hỗ trợ:

1. Đọc documentation trong từng file
2. Xem examples trong prompts
3. Tham khảo rules cho standards
4. Sử dụng commands cho workflow

---

## ⚡ Quick Reference

### Most Used Commands
```bash
/capture-knowledge    # Hiểu code
/code-review         # Review code
/writing-test        # Viết tests
/execute-plan        # Implement feature
```

### Most Used Rules
```bash
rules/laravel.md     # Laravel standards
rules/security.md    # Security practices
rules/testing.md     # Testing guidelines
rules/performance.md # Performance tips
```

### Most Used Prompts
```bash
prompts/code-explanation.md      # Explain code
prompts/bug-fix-assistant.md     # Fix bugs
prompts/refactoring-suggestions.md # Refactor
prompts/api-design.md            # Design API
```

---

**🎉 Happy Coding with AI Assistance!**
