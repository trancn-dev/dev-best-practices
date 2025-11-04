# Common Frontend Best Practices

Thư mục này chứa các quy tắc chung áp dụng cho TẤT CẢ các dự án frontend, bất kể framework (Vue, React, Nuxt, Next.js, v.v.).

## Nội dung

### Rules

#### git.md
- Branch naming conventions
- Commit message standards
- Git workflow best practices
- Pull request guidelines

#### typescript.md
- Type definitions (interface vs type)
- Component typing patterns
- Utility types usage
- Type safety best practices

#### testing.md
- Test file naming conventions
- Test structure và organization
- Unit test, Component test, E2E test standards
- Coverage goals

## Sử dụng

### Cho bất kỳ dự án frontend nào:

1. **Bước 1**: Copy toàn bộ `.github/` từ thư mục này vào dự án
2. **Bước 2**: Thêm framework-specific rules từ thư mục tương ứng:
   - Vue → `../vue/.github/`
   - Nuxt → `../nuxt/.github/`
   - React → `../react/.github/`

### Ví dụ setup dự án Nuxt:

```bash
# Copy common rules
cp -r frontend/common/.github project/my-nuxt-app/

# Merge với Nuxt-specific rules
cp -r frontend/nuxt/.github/* project/my-nuxt-app/.github/
```

## Tại sao cần Common?

- **Consistency**: Đảm bảo codebase nhất quán về Git, TypeScript, Testing
- **Reusability**: Không cần duplicate rules giống nhau cho mỗi framework
- **Maintainability**: Cập nhật rules chung ở một nơi, áp dụng cho tất cả projects
- **Onboarding**: Developer mới dễ dàng hiểu standards chung của team

## Ghi chú

- Rules trong thư mục này là framework-agnostic
- Nên được apply cho TẤT CẢ dự án frontend
- Có thể override/extend bởi framework-specific rules nếu cần
