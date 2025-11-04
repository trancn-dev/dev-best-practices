# Frontend Best Practices

Thư mục này chứa các best practices, conventions và GitHub Copilot rules cho các dự án frontend.

## Cấu trúc

```
frontend/
├── common/          # Các quy tắc chung cho tất cả dự án frontend
│   └── .github/
│       └── copilot/
│           ├── rules/
│           │   ├── git.md           # Quy tắc Git workflow
│           │   ├── typescript.md    # TypeScript standards
│           │   └── testing.md       # Testing standards
│           └── README.md
│
├── vue/             # Quy tắc riêng cho Vue.js
│   └── .github/
│       └── copilot/
│           └── rules/
│               └── vue.md           # Vue 3 Composition API standards
│
├── nuxt/            # Quy tắc riêng cho Nuxt.js
│   └── .github/
│       ├── copilot/
│       │   ├── commands/            # Custom commands
│       │   ├── knowledge/           # Architecture & conventions
│       │   ├── prompts/             # Reusable prompts
│       │   ├── rules/
│       │   │   └── nuxt.md         # Nuxt 3 best practices
│       │   └── snippets/           # Code snippets
│       └── workflows/              # GitHub Actions
│
└── react/           # Quy tắc riêng cho React (sẵn sàng cho tương lai)
    └── .github/
        └── copilot/
            ├── commands/
            ├── knowledge/
            ├── prompts/
            ├── rules/
            └── snippets/
```

## Hướng dẫn sử dụng

### 1. Dự án Vue.js
Copy nội dung từ:
- `common/.github/` (quy tắc chung)
- `vue/.github/` (quy tắc Vue-specific)

### 2. Dự án Nuxt.js
Copy nội dung từ:
- `common/.github/` (quy tắc chung)
- `nuxt/.github/` (quy tắc Nuxt-specific, bao gồm cả Vue)

### 3. Dự án React
Copy nội dung từ:
- `common/.github/` (quy tắc chung)
- `react/.github/` (quy tắc React-specific)

## Ghi chú

- Thư mục `common/` chứa các quy tắc áp dụng cho tất cả các framework (Git, TypeScript, Testing)
- Mỗi framework có thư mục riêng chứa các quy tắc cụ thể
- Có thể kết hợp rules từ `common/` và framework-specific khi setup dự án mới
