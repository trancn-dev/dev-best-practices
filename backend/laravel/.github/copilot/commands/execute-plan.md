---
type: command
name: execute-plan
version: 2.0
scope: project
integration:
  - laravel
  - git
  - ci-cd
---

# Command: Execute Plan

## Mục tiêu
Lệnh `execute-plan` được sử dụng khi cần **thực hiện một kế hoạch phát triển hoặc thay đổi** đã được xác nhận trước đó (ví dụ: sau `review-requirements`, `design`, hoặc `update-planning`).

Mục tiêu chính:
- Triển khai code theo kế hoạch đã duyệt.
- Tuân thủ quy trình phát triển chuẩn (requirement → design → implement → test → deploy).
- Đảm bảo mỗi bước có log và justification rõ ràng.

---

## Quy trình thực thi

### 1. Xác nhận đầu vào
Trước khi bắt đầu, đảm bảo có đủ các thông tin sau:
- Mục tiêu hoặc user story cụ thể.
- Kế hoạch hành động (task breakdown, thời gian, người phụ trách).
- Thiết kế đã được duyệt (`review-design.md`).
- Các ràng buộc kỹ thuật hoặc nghiệp vụ liên quan.

> ⚠️ Nếu thiếu bất kỳ thông tin nào, dừng lại và yêu cầu bổ sung.

---

### 2. Thực hiện từng bước có kiểm soát

Khi thực thi, cần tuần tự theo các pha sau:

#### Pha 1: Chuẩn bị môi trường
- Đảm bảo branch hoặc environment phù hợp (`feature/`, `bugfix/`, `hotfix/`).
- Cập nhật dependency bằng `composer install` hoặc `npm install`.
- Chạy test hiện có để đảm bảo hệ thống đang ổn định.

#### Pha 2: Thực thi kế hoạch
- Thực hiện đúng logic và phạm vi đã định trong kế hoạch.
- Giữ commit nhỏ, rõ ràng, mô tả chính xác thay đổi.
- Dán nhãn commit theo quy ước (ví dụ: `feat:`, `fix:`, `refactor:`).

#### Pha 3: Ghi nhận thay đổi
- Ghi chú lại các file, class, hoặc module đã được chỉnh sửa.
- Nếu có thay đổi về cấu trúc hoặc dependency, cập nhật tài liệu kỹ thuật tương ứng (`docs/ai/` hoặc `README.md`).
- Nếu có ảnh hưởng đến nghiệp vụ, cập nhật `knowledge/business.md`.

#### Pha 4: Kiểm thử
- Viết hoặc cập nhật test liên quan (unit, feature, integration).
- Đảm bảo toàn bộ test pass (`php artisan test` hoặc `pest`).
- Thực hiện self-review (chạy `code-review` command).

---

### 3. Xử lý rủi ro & rollback

Nếu phát hiện lỗi hoặc sai lệch:
- Ghi lại nguyên nhân và hành động khắc phục.
- Rollback commit hoặc revert branch nếu cần.
- Cập nhật kế hoạch để tránh tái phạm.

#### Rollback Checklist
- [ ] Xác định commit gây lỗi và revert (`git revert <commit-hash>`)
- [ ] Khôi phục database nếu có migration (`php artisan migrate:rollback`)
- [ ] Chạy lại toàn bộ test suite (`php artisan test`)
- [ ] Cập nhật `CHANGELOG.md` với nguyên nhân rollback
- [ ] Thông báo team về rollback và impact
- [ ] Tạo task mới để fix issue gốc

---

## Quy tắc khi triển khai

| Quy tắc | Mô tả |
|----------|--------|
| ✅ **Atomic commits** | Mỗi commit chỉ nên chứa một thay đổi logic. |
| ✅ **Convention over configuration** | Tận dụng convention của Laravel thay vì tự config phức tạp. |
| ✅ **Không commit file build** | Bỏ qua `vendor/`, `node_modules/`, `storage/`, `.env`. |
| ⚠️ **Không thay đổi migration cũ** | Dùng migration mới thay vì sửa file cũ. |
| ⚠️ **Giữ backward compatibility** | Không thay đổi interface hoặc contract đang dùng. |

---

## Output mong đợi

Sau khi hoàn thành `execute-plan`, cần tạo báo cáo tóm tắt theo template sau:

### Execution Report Template

```markdown
## Execution Report

**Task:** [Tên task/feature]
**Branch:** [feature/bugfix/hotfix branch name]
**Date:** [YYYY-MM-DD]
**Developer:** [Tên người thực hiện]

### Files Changed
- `path/to/file1.php` - [Mô tả thay đổi]
- `path/to/file2.php` - [Mô tả thay đổi]
- `tests/Feature/ExampleTest.php` - [Mô tả test]

### Features Implemented
- [ ] Feature 1
- [ ] Feature 2

### Test Results
- ✅ Unit Tests: X/X passed
- ✅ Feature Tests: X/X passed
- ✅ Code Coverage: XX%

### Issues Encountered
[Mô tả vấn đề phát sinh và cách xử lý, hoặc ghi "None"]

### Next Steps
- [ ] Tạo Pull Request
- [ ] Review code
- [ ] Deploy to staging
```

> Báo cáo này nên lưu trong `docs/ai/execution-logs/YYYY-MM-DD-task-name.md` hoặc commit message cuối cùng.

---

## Mẫu phản hồi AI (khi thực thi)

**Ví dụ:**
> 🔧 Thực thi kế hoạch: "Tạo module User Registration".
>
> **Đã tạo:**
> - `app/Http/Controllers/Auth/RegisterController.php`
> - `app/Actions/User/CreateUserAction.php`
> - `tests/Feature/RegisterUserTest.php`
>
> **Kết quả:** 12 test passed ✅
> Không phát sinh issue. Đã commit và push branch `feature/user-register`.

---

## Automation & Enforcement

Để đảm bảo quy trình được tuân thủ tự động, khuyến nghị tích hợp các công cụ sau:

### 1. Pre-commit Hooks (Husky hoặc Git Hooks)
- **PHP_CodeSniffer**: Kiểm tra chuẩn PSR-12 tự động trước khi commit.
- **PHPStan/Larastan**: Phân tích tĩnh để phát hiện lỗi tiềm ẩn.
- **Prettier/PHP-CS-Fixer**: Tự động format code.

**Cài đặt:**
```bash
composer require --dev squizlabs/php_codesniffer
composer require --dev phpstan/phpstan
composer require --dev friendsofphp/php-cs-fixer
```

**Cấu hình `.git/hooks/pre-commit`:**
```bash
#!/bin/sh
vendor/bin/phpcs --standard=PSR12 app/
vendor/bin/phpstan analyse app/ --level=5
vendor/bin/php-cs-fixer fix --dry-run --diff
```

### 2. CI/CD Pipeline (GitHub Actions / GitLab CI)
Tự động chạy khi push hoặc tạo Pull Request:

**Ví dụ `.github/workflows/laravel.yml`:**
```yaml
name: Laravel CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      - name: Install Dependencies
        run: composer install
      - name: Run Tests
        run: php artisan test
      - name: Code Style Check
        run: vendor/bin/phpcs --standard=PSR12 app/
      - name: Static Analysis
        run: vendor/bin/phpstan analyse app/ --level=5
```

### 3. Validation Rules (tùy chỉnh theo team)

Mỗi team có thể điều chỉnh các quy tắc sau trong file `.phpcs.xml` hoặc `phpstan.neon`:

**Ví dụ `.phpcs.xml`:**
```xml
<?xml version="1.0"?>
<ruleset name="Laravel PSR-12">
    <rule ref="PSR12"/>
    <file>app/</file>
    <file>tests/</file>
    <exclude-pattern>*/vendor/*</exclude-pattern>
    <exclude-pattern>*/storage/*</exclude-pattern>
</ruleset>
```

**Ví dụ `phpstan.neon`:**
```neon
parameters:
    level: 5
    paths:
        - app
        - tests
    excludePaths:
        - vendor
        - storage
```

### 4. Pull Request Template

Tạo file `.github/pull_request_template.md` để checklist tự động:

```markdown
## Checklist trước khi merge

- [ ] Code tuân thủ PSR-12
- [ ] Tất cả test đã pass
- [ ] Đã viết test cho logic mới
- [ ] Đã cập nhật tài liệu (nếu cần)
- [ ] Không có breaking changes (hoặc đã ghi nhận)
- [ ] Đã self-review code
- [ ] Migration đã test trên môi trường staging
- [ ] Code coverage không giảm so với trước
```

### 5. Branch Protection Rules

Cấu hình trên GitHub/GitLab:
- Bắt buộc CI pass trước khi merge.
- Yêu cầu ít nhất 1 approval từ reviewer.
- Không cho phép force push lên `main` hoặc `develop`.
- Yêu cầu branch cập nhật với base branch trước khi merge.

---

## Tùy chỉnh cho từng loại dự án

Quy trình có thể linh hoạt theo ngữ cảnh:

| Loại dự án | Điều chỉnh |
|------------|------------|
| **Dự án nhỏ, MVP** | Bỏ qua static analysis, chỉ chạy test cơ bản |
| **Dự án enterprise** | Bắt buộc code coverage > 80%, static analysis level 8 |
| **Hotfix khẩn cấp** | Cho phép skip một số bước nhưng phải ghi log rõ ràng |
| **Library/Package** | Thêm compatibility test với nhiều PHP version |

---

## Tham khảo

- [PSR-12: Extended Coding Style](https://www.php-fig.org/psr/psr-12/)
- [Laravel Best Practices](https://github.com/alexeymezenin/laravel-best-practices)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
