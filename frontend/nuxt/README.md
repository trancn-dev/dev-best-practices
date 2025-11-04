# Nuxt.js Best Practices

Thư mục này chứa các GitHub Copilot rules, commands, knowledge và best practices đầy đủ cho dự án Nuxt.js.

## Nội dung

### Rules
- **nuxt.md**: Nuxt 3 best practices (bao gồm cả Vue 3)

### Commands
- **capture-knowledge.md**: Thu thập và ghi nhận kiến thức về code
- **code-review.md**: Hướng dẫn code review
- **execute-plan.md**: Thực thi kế hoạch phát triển
- **writing-test.md**: Viết tests

### Knowledge
- **architecture.md**: Kiến trúc dự án
- **conventions.md**: Các quy ước coding
- **glossary.md**: Thuật ngữ dự án
- **workflow.md**: Quy trình làm việc

### Prompts
- **bug-fix-assistant.md**: Hỗ trợ fix bugs
- **component-design.md**: Thiết kế components
- **refactoring-suggestions.md**: Gợi ý refactoring
- **testing-strategy.md**: Chiến lược testing

### Snippets
- Code templates cho: components, composables, pages, stores, API calls

### Workflows (GitHub Actions)
- CI/CD pipelines
- Code quality checks
- Deploy preview
- PR labeler

## Sử dụng

Khi bắt đầu dự án Nuxt.js mới:

1. Copy nội dung từ `../common/.github/` để có các quy tắc chung (Git, TypeScript, Testing)
2. Copy toàn bộ `.github/` từ thư mục này vào root của dự án Nuxt

## Ghi chú

- Nuxt rules đã bao gồm cả Vue 3 Composition API
- Đây là bộ quy tắc đầy đủ nhất, phù hợp cho production project
- Có thể tùy chỉnh workflows theo nhu cầu deployment cụ thể
