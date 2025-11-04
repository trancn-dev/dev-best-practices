---Hiện tại tôi **chưa thể trực tiếp tạo file `.md` để bạn tải về** do công cụ xuất file đang tạm ngừng,

type: commandnhưng tôi **có thể hiển thị toàn bộ nội dung ở đúng định dạng Markdown** — bạn chỉ cần:

name: new-requirement

version: 2.01. Sao chép nội dung tôi gửi bên dưới.

scope: project2. Dán vào file:

integration:

  - laravel   ```

  - requirements   D:\project\devkit\.github\copilot\commands\new-requirement.md

  - business-analysis   ```

---3. Lưu lại với encoding UTF-8.



# Command: New Requirement---



## Mục tiêuDưới đây là **toàn bộ nội dung file hoàn chỉnh**, sẵn để copy:

Lệnh `new-requirement` được sử dụng để **thu thập và ghi nhận yêu cầu mới** từ stakeholder hoặc product owner.

---

Mục tiêu chính:

- Thu thập đầy đủ thông tin về yêu cầu nghiệp vụ.````markdown

- Phân tích tác động đến hệ thống hiện tại.---

- Tạo tài liệu yêu cầu chuẩn để team review.type: command

- Đảm bảo yêu cầu rõ ràng, đo lường được, khả thi.name: new-requirement

version: 2.0

---scope: project

integration:

## Quy trình thu thập yêu cầu  - laravel

  - requirements

### Step 1: Thu thập thông tin cơ bản  - business-analysis

---

**Câu hỏi cần trả lời:**

# Command: New Requirement

#### A. Thông tin chung

- Tên yêu cầu/feature là gì?## Mục tiêu

- Người yêu cầu là ai? (Product Owner, Stakeholder, Customer)Lệnh `new-requirement` được sử dụng để **thu thập và ghi nhận yêu cầu mới** từ stakeholder hoặc product owner.

- Độ ưu tiên: Critical / High / Medium / Low

- Thời hạn mong muốn: [YYYY-MM-DD]Mục tiêu chính:

- Budget/Resource ước tính: [số giờ/ngày công]- Thu thập đầy đủ thông tin về yêu cầu nghiệp vụ.

- Phân tích tác động đến hệ thống hiện tại.

#### B. Mục tiêu nghiệp vụ- Tạo tài liệu yêu cầu chuẩn để team review.

- Vấn đề cần giải quyết là gì?- Đảm bảo yêu cầu rõ ràng, đo lường được, khả thi.

- Ai là người dùng cuối? (User persona)

- Kết quả mong đợi sau khi hoàn thành?---

- Metrics để đo lường thành công (KPI)?

## Quy trình thu thập yêu cầu

#### C. Phạm vi chức năng

- Chức năng chính cần thực hiện?### Step 1: Thu thập thông tin cơ bản

- Input data và nguồn dữ liệu?### Step 1: Thu thập thông tin cơ bản

- Output/kết quả trả về?

- Các rule/validation cần áp dụng?**Câu hỏi cần trả lời:**



#### D. Ràng buộc kỹ thuật#### A. Thông tin chung

- Có tích hợp với hệ thống bên ngoài không?- Tên yêu cầu/feature là gì?

- Yêu cầu về performance/security?- Người yêu cầu là ai? (Product Owner, Stakeholder, Customer)

- Yêu cầu về UI/UX (nếu có)?- Độ ưu tiên: Critical / High / Medium / Low

- Môi trường triển khai (staging, production)?- Thời hạn mong muốn: [YYYY-MM-DD]

- Budget/Resource ước tính: [số giờ/ngày công]

---

#### B. Mục tiêu nghiệp vụ

### Step 2: Phân tích tác động- Vấn đề cần giải quyết là gì?

- Ai là người dùng cuối? (User persona)

Đánh giá ảnh hưởng của yêu cầu mới:- Kết quả mong đợi sau khi hoàn thành?

- Metrics để đo lường thành công (KPI)?

| Khía cạnh | Câu hỏi | Đánh giá |

|-----------|---------|----------|#### C. Phạm vi chức năng

| **Database** | Có cần thêm bảng/cột mới? | ☐ Có ☐ Không |- Chức năng chính cần thực hiện?

| **API** | Có cần tạo endpoint mới? | ☐ Có ☐ Không |- Input data và nguồn dữ liệu?

| **Authentication** | Có ảnh hưởng đến quyền user? | ☐ Có ☐ Không |- Output/kết quả trả về?

| **Dependencies** | Có cần thêm package/library? | ☐ Có ☐ Không |- Các rule/validation cần áp dụng?

| **Breaking Changes** | Có phá vỡ tính tương thích? | ☐ Có ☐ Không |

| **Migration** | Có cần migrate dữ liệu cũ? | ☐ Có ☐ Không |#### D. Ràng buộc kỹ thuật

- Có tích hợp với hệ thống bên ngoài không?

---- Yêu cầu về performance/security?

- Yêu cầu về UI/UX (nếu có)?

### Step 3: Tạo User Story- Môi trường triển khai (staging, production)?



Chuyển yêu cầu thành User Story format:---



```markdown### Step 2: Phân tích tác động

**As a** [user role]

**I want** [feature/action]| Nhóm | Mô tả |

**So that** [business value]|------|-------|

| **Feature** | Thêm chức năng mới |

**Acceptance Criteria:**| **Enhancement** | Cải tiến hoặc tối ưu tính năng hiện có |

- [ ] Criterion 1| **Bugfix** | Khắc phục lỗi hiện tại |

- [ ] Criterion 2| **Refactor** | Cải thiện cấu trúc code mà không thay đổi hành vi |

- [ ] Criterion 3| **Research/Spike** | Thử nghiệm kỹ thuật hoặc khảo sát khả năng thực hiện |



**Definition of Done:**---

- [ ] Code complete và pass review

- [ ] Test coverage >= 80%### 3. Đặc tả yêu cầu (Requirement Specification)

- [ ] Documentation updated

- [ ] Deployed to staging và testedRequirement phải có cấu trúc rõ ràng theo mẫu sau:

```

```yaml

---id: RQ-[YYYYMMDD]-[slug]

title: "Tên yêu cầu"

### Step 4: Đánh giá độ phức tạptype: "Feature | Enhancement | Bugfix | Refactor | Research"

description: |

| Tiêu chí | Đơn giản (1-2 ngày) | Trung bình (3-5 ngày) | Phức tạp (>5 ngày) |  Mô tả ngắn gọn về yêu cầu, bao gồm:

|----------|---------------------|----------------------|-------------------|  - Bối cảnh (context)

| Logic nghiệp vụ | ☐ | ☐ | ☐ |  - Vấn đề cần giải quyết

| Database changes | ☐ | ☐ | ☐ |  - Mục tiêu nghiệp vụ

| Frontend work | ☐ | ☐ | ☐ |  - Phạm vi thực hiện (scope)

| Testing effort | ☐ | ☐ | ☐ |acceptance_criteria:

| Integration complexity | ☐ | ☐ | ☐ |  - [ ] Điều kiện 1

  - [ ] Điều kiện 2

**Estimate:** [X] ngày công  - [ ] Điều kiện 3

priority: "High | Medium | Low"

---risk_level: "Low | Medium | High"

dependencies:

### Step 5: Xác định dependencies  - RQ-20251020-user-login

  - ...

- Có yêu cầu nào cần hoàn thành trước không?related_modules:

- Có team/người nào cần phối hợp không?  - app/Http/Controllers/UserController.php

- Có tài liệu kỹ thuật nào cần tham khảo không?  - database/migrations/xxxx_create_users_table.php

````

---

---

## Template tài liệu yêu cầu

### 4. Xác nhận và phê duyệt

````markdown

# Requirement: [Tên yêu cầu]Sau khi requirement được mô tả, cần có xác nhận của:



**ID:** REQ-YYYY-MM-DD-XXX* ✅ **Product Owner (PO)** hoặc **Business Analyst (BA)** – xác nhận mục tiêu nghiệp vụ.

**Status:** Draft | Reviewing | Approved | Rejected* ✅ **Tech Lead** – xác nhận tính khả thi kỹ thuật.

**Priority:** Critical | High | Medium | Low* ✅ **Developer** – xác nhận ước lượng effort và độ phức tạp.

**Created:** [YYYY-MM-DD]

**Created by:** [Tên người yêu cầu]> Khi requirement được phê duyệt, gắn nhãn:

**Assigned to:** [Team/Person]> **`status: approved`** → có thể chuyển sang bước `execute-plan`.



------



## 1. Tổng quan### 5. Lưu trữ và liên kết



### Mục tiêu* Lưu requirement trong thư mục:

[Mô tả mục tiêu nghiệp vụ]  `docs/requirements/RQ-[slug].md`

* Liên kết với task tương ứng trong hệ thống quản lý (Jira, GitHub Issue, Linear, v.v.)

### User Story* Nếu có nhiều requirement liên quan, gom vào một **Epic**.

**As a** [role]

**I want** [feature]---

**So that** [value]

## Đầu ra mong đợi (Expected Output)

---

Sau khi chạy `new-requirement`, AI hoặc devkit cần tạo file Markdown mô tả đầy đủ requirement, ví dụ:

## 2. Yêu cầu chức năng

```markdown

### Input# Requirement: User can reset password via email

- Field 1: [Type, Required/Optional, Validation]

- Field 2: [...]**Type:** Feature

**Status:** Draft

### Process**Created:** 2025-10-28

1. Step 1: [Mô tả]**Owner:** @dev-team

2. Step 2: [Mô tả]

## Description

### OutputHiện tại hệ thống chưa có chức năng reset mật khẩu. Người dùng cần có khả năng gửi yêu cầu đặt lại mật khẩu qua email, và đặt lại mật khẩu mới sau khi xác thực.

- Success response: [Format]

- Error handling: [Các trường hợp lỗi]## Business Goal

Tăng trải nghiệm người dùng, giảm yêu cầu hỗ trợ từ CSKH.

---

## Acceptance Criteria

## 3. Yêu cầu phi chức năng- [x] Người dùng nhập email và nhận link reset.

- [x] Link có hiệu lực 15 phút.

- **Performance:** [Thời gian phản hồi, throughput]- [x] Có thông báo xác nhận khi đổi mật khẩu thành công.

- **Security:** [Authentication, Authorization, Data encryption]

- **Scalability:** [Số lượng user đồng thời]## Dependencies

- **Availability:** [Uptime requirement]- `users` table

- Mailer config

---

## Risk Level

## 4. Acceptance CriteriaMedium



- [ ] Criterion 1## Next Step

- [ ] Criterion 2→ Chuyển sang `execute-plan` sau khi phê duyệt.

- [ ] Criterion 3```



------



## 5. Tác động kỹ thuật## Best Practices



### Database Changes| Mục tiêu              | Hành động                                                                                      |

- [ ] New tables| --------------------- | ---------------------------------------------------------------------------------------------- |

- [ ] New columns| **Rõ ràng**           | Dùng ngôn ngữ trung lập, tránh mơ hồ (“cải thiện”, “tốt hơn” → “giảm thời gian phản hồi 30%”). |

- [ ] Indexes| **Đo lường được**     | Mỗi yêu cầu phải có ít nhất một chỉ số kiểm chứng.                                             |

- [ ] Migration plan| **Có thể kiểm thử**   | Mọi acceptance criteria đều có thể viết test tương ứng.                                        |

| **Tách biệt yêu cầu** | Không gộp nhiều yêu cầu khác nhau vào một.                                                     |

### API Changes

- [ ] New endpoints---

- [ ] Modified endpoints

- [ ] Breaking changes## Tài liệu tham khảo



### Dependencies* [IEEE 830 Software Requirements Specification](https://ieeexplore.ieee.org/document/720574)

- New packages: [List]* [Laravel Project Planning Guide](https://laravel.com/docs)

- External services: [List]* [Agile Epic & Story Definition – Atlassian](https://www.atlassian.com/agile/project-management/epics-stories-themes)



---

## 6. Rủi ro & Giảm thiểu

| Rủi ro | Mức độ | Giải pháp |
|--------|--------|-----------|
| [Risk 1] | High/Medium/Low | [Mitigation] |

---

## 7. Timeline & Resources

- **Estimate:** [X] ngày công
- **Developer:** [Tên]
- **Reviewer:** [Tên]
- **Deadline:** [YYYY-MM-DD]

---

## 8. Tài liệu tham khảo

- Design doc: [Link]
- API spec: [Link]
- UI mockup: [Link]
````

---

## Output mong đợi

Sau khi hoàn thành `new-requirement`, cần:

1. **Tạo file tài liệu** trong `docs/ai/requirements/REQ-YYYY-MM-DD-[name].md`
2. **Thông báo team** qua Slack/Email về yêu cầu mới
3. **Tạo task** trong project management tool (Jira, Trello, Linear...)
4. **Schedule meeting** review requirement (nếu cần)

---

## Quy tắc validation

Trước khi approve requirement, đảm bảo:

- ✅ Mục tiêu rõ ràng, đo lường được
- ✅ Acceptance criteria cụ thể
- ✅ Estimate hợp lý với scope
- ✅ Không có conflict với requirement khác
- ✅ Technical feasibility đã được đánh giá
- ✅ Stakeholder đã review và đồng ý

---

## Mẫu phản hồi AI

**Ví dụ:**

> 📋 **New Requirement Captured**
>
> **ID:** REQ-2025-10-28-001
> **Title:** User Profile Picture Upload
> **Priority:** High
> **Estimate:** 3 ngày
>
> **Summary:**
> Allow users to upload and manage profile pictures with image validation and automatic resizing.
>
> **Next Steps:**
> - [ ] Review with team lead
> - [ ] Create design document
> - [ ] Update sprint backlog
>
> 📄 Document saved: `docs/ai/requirements/REQ-2025-10-28-001.md`

---

## Tham khảo

- [IEEE 830: Software Requirements Specification](https://standards.ieee.org/standard/830-1998.html)
- [User Story Best Practices](https://www.atlassian.com/agile/project-management/user-stories)
- [Requirements Engineering](https://www.reqview.com/doc/iso-iec-ieee-29148-requirements-engineering.html)
