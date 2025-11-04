# React Best Practices

Thư mục này sẵn sàng để chứa các GitHub Copilot rules và best practices dành riêng cho dự án React.

## Cấu trúc sẵn sàng

```
react/
└── .github/
    └── copilot/
        ├── commands/      # Custom commands (chưa có)
        ├── knowledge/     # Architecture & conventions (chưa có)
        ├── prompts/       # Reusable prompts (chưa có)
        ├── rules/         # React best practices (chưa có)
        └── snippets/      # Code snippets (chưa có)
```

## Để bổ sung

Khi cần phát triển dự án React, có thể thêm:

### Rules
- `react.md`: React best practices (Hooks, Components, State management)
- `react-typescript.md`: React + TypeScript patterns
- `next.md`: Next.js specific rules (nếu dùng Next.js)

### Commands
- Component creation workflows
- Testing helpers
- Refactoring tools

### Knowledge
- React architecture patterns
- State management strategies (Redux, Zustand, Context)
- Performance optimization

### Snippets
- React component templates
- Custom hooks patterns
- Context + Provider snippets
- Testing templates

## Sử dụng

Khi bắt đầu dự án React mới:

1. Copy nội dung từ `../common/.github/` để có các quy tắc chung (Git, TypeScript, Testing)
2. Thêm React-specific rules vào `.github/copilot/rules/`
3. Tùy chỉnh commands, knowledge, prompts theo nhu cầu dự án
