---
type: command
name: code-review
version: 2.0
scope: project
integration:
  - nuxt
  - vue
  - typescript
  - quality-assurance
---

# Command: Code Review

## Mục tiêu
Lệnh `code-review` được sử dụng để **đánh giá chất lượng code** trước khi merge vào branch chính.

Mục tiêu chính:
- Đảm bảo code đúng chức năng và requirement.
- Tuân thủ coding standards (Vue, Nuxt, TypeScript conventions).
- Phát hiện bugs, security issues, performance problems.
- Đảm bảo code maintainable và testable.

---

## Quy trình review

### Step 1: Chuẩn bị review

**Pre-review Checklist:**

- [ ] Code đã commit và push lên branch
- [ ] PR/MR description rõ ràng
- [ ] Link đến requirement/design document
- [ ] Tests đã pass
- [ ] CI/CD pipeline success

---

## Hướng dẫn Review

### 1. Kiểm tra cú pháp & chuẩn code

- **Vue 3 Composition API**: Sử dụng `<script setup>` khi có thể
- **TypeScript**: Type-safe, tránh `any`, sử dụng interfaces/types
- **Naming conventions**:
  - Components: PascalCase (`UserProfile.vue`)
  - Composables: camelCase với prefix `use` (`useAuth.ts`)
  - Files: kebab-case hoặc PascalCase
  - Props/Events: camelCase
- **Indentation**: 2 spaces (chuẩn Vue/JS)
- **No trailing spaces hoặc dòng trống dư**

### 2. Kiểm tra cấu trúc Vue/Nuxt

- **Components** nên nhỏ, có trách nhiệm rõ ràng (Single Responsibility)
- **Composables** xử lý logic tái sử dụng (API calls, state, utilities)
- **Pages** chỉ nên kết hợp components và layouts, ít logic
- **Layouts** là wrapper cho pages
- **Middleware** xử lý route guards, authentication
- **Stores (Pinia)** quản lý state toàn cục
- **Props**: Khai báo đầy đủ type, required, default
- **Emits**: Khai báo rõ ràng với `defineEmits`
- **Refs/Reactive**: Sử dụng đúng cách, tránh over-reactivity

### 3. Kiểm tra bảo mật

- **XSS**: Escape HTML, không dùng `v-html` với user input
- **CSRF**: Nuxt tự động xử lý với `useFetch`, `$fetch`
- **Authentication**: Check quyền trước khi render sensitive UI
- **Sensitive data**: Không log hoặc expose tokens, passwords
- **API keys**: Sử dụng runtime config, không hardcode
- **Input validation**: Validate form inputs client-side và server-side

### 4. Kiểm tra hiệu suất

- **Lazy loading**: Sử dụng `defineAsyncComponent` cho components nặng
- **Image optimization**: Dùng `<NuxtImg>` hoặc `<NuxtPicture>`
- **API calls**: Tránh duplicate requests, sử dụng cache khi có thể
- **Computed vs Methods**: Dùng computed cho derived data
- **v-show vs v-if**: Chọn đúng based on toggle frequency
- **Key attribute**: Luôn dùng `:key` trong `v-for`
- **Watchers**: Tránh watchers phức tạp, prefer computed

### 5. Kiểm tra accessibility (a11y)

- **Semantic HTML**: Dùng tags đúng nghĩa (`<button>`, `<nav>`, etc.)
- **ARIA attributes**: Thêm khi cần (aria-label, aria-describedby)
- **Keyboard navigation**: Đảm bảo navigate được bằng phím
- **Focus management**: Focus states rõ ràng
- **Alt text**: Tất cả images có alt attribute
- **Color contrast**: Đảm bảo đủ contrast ratio

### 6. Kiểm tra test coverage

- **Unit tests**: Test composables, utilities, business logic
- **Component tests**: Test component behavior với Vitest + Vue Test Utils
- **E2E tests**: Test user flows với Playwright hoặc Cypress
- **Coverage target**: >= 70% cho logic quan trọng

### 7. Kiểm tra maintainability

- **Code comments**: Giải thích "why", không "what"
- **Magic numbers**: Định nghĩa constants
- **Duplicated code**: Refactor thành composables hoặc utilities
- **File size**: Components không quá 300 lines
- **Props drilling**: Tránh truyền props quá nhiều cấp, dùng provide/inject
- **Error handling**: Xử lý errors gracefully, có fallback UI

---

## Review Checklist

### Functional Correctness
- [ ] Implement đúng requirement
- [ ] Edge cases được xử lý
- [ ] Error scenarios được cover
- [ ] Data validation đầy đủ

### Code Quality
- [ ] Tuân thủ naming conventions
- [ ] TypeScript types đầy đủ
- [ ] No console.log hoặc debugger statements
- [ ] No hardcoded values
- [ ] Comments hợp lý

### Vue/Nuxt Best Practices
- [ ] Sử dụng Composition API đúng cách
- [ ] Props/emits được khai báo đầy đủ
- [ ] Composables tái sử dụng logic
- [ ] File-based routing được sử dụng đúng
- [ ] Auto-imports được tận dụng

### Performance
- [ ] No N+1 API calls
- [ ] Lazy loading khi cần
- [ ] Images được optimize
- [ ] Bundle size hợp lý

### Security
- [ ] Input validation
- [ ] XSS protection
- [ ] Sensitive data không expose
- [ ] API keys trong config, không hardcode

### Testing
- [ ] Unit tests cho logic
- [ ] Component tests cho UI behavior
- [ ] Tests pass trên CI/CD

### Documentation
- [ ] Props/emits có JSDoc
- [ ] Complex logic có comments
- [ ] README updated nếu cần

---

## Review Comments Template

### Blocking Issues (Must Fix)
```markdown
🚨 **BLOCKING**: [Issue description]

**Problem:** [Explain the issue]
**Impact:** [Why this is critical]
**Suggestion:** [How to fix]
```

### Important (Should Fix)
```markdown
⚠️ **IMPORTANT**: [Issue description]

**Reason:** [Why this matters]
**Suggestion:** [How to improve]
```

### Optional (Nice to Have)
```markdown
💡 **SUGGESTION**: [Improvement idea]

**Benefit:** [What this improves]
**Example:** [Code example if applicable]
```

### Praise (Good Work)
```markdown
✅ **GOOD**: [What was done well]

**Why:** [Explain why this is good]
```

---

## Example Review

```markdown
## Review Summary

**Overall:** ✅ APPROVED with minor suggestions

### Blocking Issues
None

### Important Issues

⚠️ **IMPORTANT**: Missing prop validation in `UserCard.vue`

**Reason:** Props should have explicit types and validation
**Suggestion:**
\`\`\`typescript
const props = defineProps<{
  userId: string | number
  editable?: boolean
}>()

// Or with defaults
const props = withDefaults(defineProps<{
  userId: string | number
  editable?: boolean
}>(), {
  editable: false
})
\`\`\`

### Suggestions

💡 **SUGGESTION**: Extract API logic to composable

**Current:** API calls directly in component
**Better:** Create `useUserProfile()` composable
**Benefit:** Reusability and better testing

### Good Practices

✅ **GOOD**: Using TypeScript interfaces for data structures
✅ **GOOD**: Proper error handling with try-catch and toast notifications
✅ **GOOD**: Accessibility attributes included

---

## Next Steps
- [ ] Address blocking issues
- [ ] Consider important suggestions
- [ ] Update tests if needed
- [ ] Re-request review after changes
```

---

## Quality Standards

### Must Have (Blocking)
- No syntax errors
- No security vulnerabilities
- Implements requirements correctly
- Tests pass

### Should Have (Important)
- Follows naming conventions
- TypeScript types complete
- Performance optimized
- Accessibility considered

### Nice to Have (Optional)
- Comments for complex logic
- Extracted reusable code
- Documentation updated
- Additional test coverage

---

## Tools

- **ESLint**: Catch code issues automatically
- **Prettier**: Format code consistently
- **TypeScript**: Type checking
- **Vue DevTools**: Debug components
- **Lighthouse**: Performance and a11y audit
