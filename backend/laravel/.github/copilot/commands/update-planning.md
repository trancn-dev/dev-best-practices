---
type: command
name: update-planning
version: 2.0
scope: project
integration:
  - laravel
  - project-management
  - agile
---

# Command: Update Planning

## Mục tiêu
Lệnh `update-planning` được sử dụng để **cập nhật kế hoạch phát triển** khi có thay đổi về requirement, timeline, hoặc resource.

Mục tiêu chính:
- Đồng bộ kế hoạch với thực tế triển khai.
- Điều chỉnh timeline và phân bổ resource.
- Ghi nhận các thay đổi và lý do.
- Thông báo team về update.

---

## Quy trình cập nhật

### Step 1: Xác định loại thay đổi

**Câu hỏi:**
- Thay đổi gì? (Feature, Timeline, Resource, Priority)
- Lý do thay đổi?
- Ai yêu cầu thay đổi?
- Mức độ ảnh hưởng: High / Medium / Low

| Loại thay đổi | Mô tả | Cần approve? |
|---------------|-------|--------------|
| **Scope Change** | Thêm/bớt tính năng | ✅ Có |
| **Timeline Adjustment** | Điều chỉnh deadline | ✅ Có |
| **Resource Reallocation** | Đổi người phụ trách | ⚠️ Tùy trường hợp |
| **Priority Update** | Thay đổi độ ưu tiên | ✅ Có |
| **Bug Fix Addition** | Thêm bug cần fix | ☐ Không |
| **Technical Debt** | Refactor/optimize | ⚠️ Tùy trường hợp |

---

### Step 2: Đánh giá tác động

#### A. Impact Analysis Template

```markdown
## Impact Analysis

### Timeline Impact
- **Original deadline:** [YYYY-MM-DD]
- **New deadline:** [YYYY-MM-DD]
- **Delay:** [X] days
- **Reason:** [Mô tả]

### Resource Impact
- **Current team:** [Team members]
- **Additional resource needed:** [Yes/No]
- **Skill requirements:** [List]

### Budget Impact
- **Original estimate:** [X] days
- **New estimate:** [Y] days
- **Increase:** [Z] days (+X%)

### Risk Assessment
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk 1] | High/Medium/Low | High/Medium/Low | [Plan] |
| [Risk 2] | High/Medium/Low | High/Medium/Low | [Plan] |
```

#### B. Dependencies Check

- [ ] Có task nào bị block không?
- [ ] Có team nào bị ảnh hưởng không?
- [ ] Có deadline nào bị miss không?
- [ ] Có resource conflict không?

---

### Step 3: Cập nhật Sprint Backlog

```markdown
## Sprint [X] Backlog Update

**Date:** [YYYY-MM-DD]
**Sprint:** [Number/Name]
**Sprint Goal:** [Goal statement]

### Added Tasks
- [ ] Task A - [Estimate] - [Assignee] - [Priority]
- [ ] Task B - [Estimate] - [Assignee] - [Priority]

### Removed Tasks
- ~~Task C~~ - Reason: [Out of scope / Moved to Sprint Y / Cancelled]
- ~~Task D~~ - Reason: [...]

### Modified Tasks
| Task | Change | Old Value | New Value | Reason |
|------|--------|-----------|-----------|--------|
| Task E | Estimate | 2 days | 4 days | Additional requirements |
| Task F | Assignee | Dev1 | Dev2 | Dev1 on leave |
| Task G | Priority | Medium | High | Client request |

### Updated Timeline
| Task | Original | Updated | Status | Blocker |
|------|----------|---------|--------|---------|
| Task A | Week 1 | Week 2 | In Progress | Waiting for API |
| Task B | Week 2 | Week 3 | Not Started | Depends on Task A |
```

---

### Step 4: Cập nhật Roadmap

```markdown
## Roadmap Update

### Q4 2025
- ✅ Feature A (Completed - 2025-10-15)
- 🔄 Feature B (In Progress - 70%)
- ⏳ Feature C (Delayed to Q1 2026)
- 🆕 Feature D (New - High Priority)
- ❌ Feature E (Cancelled - Low ROI)

### Milestones
| Milestone | Original Date | Updated Date | Status | Notes |
|-----------|---------------|--------------|--------|-------|
| MVP Launch | 2025-11-01 | 2025-11-15 | On Track | +2 weeks buffer |
| Beta Release | 2025-12-01 | 2025-12-15 | Delayed | Waiting for feedback |
| Public Launch | 2026-01-01 | 2026-01-01 | On Track | No change |

### Capacity Planning
| Week | Available Hours | Planned Hours | Utilization |
|------|----------------|---------------|-------------|
| Week 43 | 160 | 140 | 87% |
| Week 44 | 160 | 170 | 106% ⚠️ Over capacity |
| Week 45 | 160 | 150 | 94% |
```

---

### Step 5: Ghi nhận Change Log

```markdown
## Change Log

### [Sprint 5] - 2025-10-28

#### Added
- ✅ User profile picture upload feature (3 days)
- ✅ Email notification settings (2 days)
- ✅ API rate limiting (1 day)

#### Changed
- 🔄 User registration flow - improved validation (was: 2 days → now: 3 days)
- 🔄 Password reset - added 2FA option (was: 1 day → now: 2 days)

#### Removed
- ❌ Social media integration - moved to Sprint 6
- ❌ Advanced search - cancelled (low priority)

#### Delayed
- ⏳ Payment gateway integration - blocked by vendor approval

#### Reason for Changes
- Client requested higher priority for security features
- Team capacity reduced: Dev1 sick leave (3 days)
- API documentation from vendor delayed by 1 week
```

---

### Step 6: Communication Plan

#### A. Notification Template

```markdown
## Sprint Update Notification

**Subject:** Sprint [X] Planning Update - [Date]

**Team:** @developers @qa @pm

**Summary:**
Sprint [X] planning has been updated due to [reason].

**Key Changes:**
- 🆕 Added: [Feature X] (High Priority)
- ⏳ Delayed: [Feature Y] → Sprint [X+1]
- 🔄 Modified: [Feature Z] estimate 2d → 4d

**Impact:**
- Sprint end date: [Old Date] → [New Date] (+X days)
- Team utilization: [Y]%
- Risk level: [Low/Medium/High]

**Action Required:**
- [ ] Review updated sprint backlog
- [ ] Attend sync meeting [Date/Time]
- [ ] Update your tasks in [Tool]

**Questions?** Reply in thread or DM @pm

---
📄 Full details: `docs/ai/planning/sprint-[X].md`
```

#### B. Stakeholder Communication

```markdown
## Stakeholder Update

**To:** Product Owner, Stakeholders
**Subject:** Project Timeline Update - [Date]

**Executive Summary:**
[Feature/Sprint X] timeline has been adjusted due to [reason]. New completion date: [Date].

**What Changed:**
- [List key changes]

**Why:**
- [Business/technical reasons]

**Impact:**
- Timeline: +[X] days delay
- Budget: +[Y] hours
- Scope: [No change / Reduced / Increased]

**Mitigation:**
- [Actions taken to minimize impact]

**Next Review:** [Date]
```

---

## Planning Update Template

```markdown
# Planning Update: Sprint [X]

**Date:** [YYYY-MM-DD]
**Updated by:** [Name]
**Approved by:** [Name]
**Status:** Draft | Pending Approval | Approved

---

## 1. Summary of Changes

**Type:** Scope Change | Timeline Adjustment | Resource Change | Priority Update
**Trigger:** [What caused this update?]
**Impact Level:** 🔴 High | 🟡 Medium | 🟢 Low

**Quick Summary:**
[2-3 sentences describing what changed and why]

---

## 2. Sprint Goals

### Before
- Goal 1: [Original goal]
- Goal 2: [Original goal]

### After
- Goal 1: [Modified goal]
- Goal 2: [Same]
- Goal 3: [New goal]

**Reason for change:** [Explanation]

---

## 3. Detailed Task Updates

### New Tasks
| Task ID | Description | Estimate | Assignee | Priority | Dependencies |
|---------|-------------|----------|----------|----------|--------------|
| TASK-101 | [Description] | 3d | Dev1 | High | TASK-90 |
| TASK-102 | [Description] | 2d | Dev2 | Medium | None |

### Modified Tasks
| Task ID | Field | Old Value | New Value | Reason |
|---------|-------|-----------|-----------|--------|
| TASK-85 | Estimate | 2 days | 4 days | Added validation layer |
| TASK-86 | Assignee | Dev1 | Dev2 | Dev1 reassigned |
| TASK-87 | Priority | Low | High | Client escalation |

### Removed Tasks
| Task ID | Description | Reason |
|---------|-------------|--------|
| TASK-88 | Social login | Moved to Sprint 6 |
| TASK-89 | Advanced filters | Cancelled - low ROI |

---

## 4. Timeline Comparison

### Sprint Timeline
- **Original start:** [YYYY-MM-DD]
- **Original end:** [YYYY-MM-DD]
- **New end:** [YYYY-MM-DD]
- **Extension:** +[X] days

### Key Milestones
| Milestone | Original | Updated | Variance | Status |
|-----------|----------|---------|----------|--------|
| API Complete | Week 1 | Week 1 | On time | ✅ |
| Frontend Complete | Week 2 | Week 3 | +1 week | ⚠️ |
| Testing Complete | Week 3 | Week 4 | +1 week | ⏳ |
| Deployment | Week 4 | Week 5 | +1 week | ⏳ |

---

## 5. Resource Allocation

### Team Capacity
| Team Member | Availability | Allocated | Utilization | Notes |
|-------------|--------------|-----------|-------------|-------|
| Dev1 | 40h | 35h | 87% | ✅ Optimal |
| Dev2 | 40h | 45h | 112% | ⚠️ Over-allocated |
| QA1 | 40h | 30h | 75% | ✅ Has capacity |

### Action Items
- [ ] Redistribute 5h from Dev2 to QA1
- [ ] Consider overtime for Dev2 (pending approval)
- [ ] Hire contractor if delay > 2 weeks

---

## 6. Risk Assessment

| Risk | Likelihood | Impact | Score | Mitigation Strategy | Owner |
|------|------------|--------|-------|---------------------|-------|
| Dev2 overload | High | Medium | 🟡 6 | Redistribute tasks | PM |
| API delay | Medium | High | 🟡 6 | Start frontend mockup | Dev1 |
| Scope creep | Low | High | 🟢 3 | Freeze requirements | PO |

**Risk Matrix:**
```
     Impact →
L    | 🟢 | 🟡 | 🔴 |
i    |----|----|----|
k  H | 🟢 | 🟡 | 🔴 |
e  M | 🟢 | 🟡 | 🔴 |
l  L | 🟢 | 🟢 | 🟡 |
i
h
o
o
d
↓
```

---

## 7. Budget Impact

### Time Budget
- **Original:** [X] person-days
- **Current:** [Y] person-days
- **Variance:** +[Z] person-days (+[P]%)

### Cost Estimate (if applicable)
- **Original budget:** $[X]
- **Current estimate:** $[Y]
- **Additional cost:** $[Z]

### Approval Status
- [ ] Within budget variance (+/- 10%) - No approval needed
- [ ] Requires PM approval (+/- 20%)
- [ ] Requires stakeholder approval (>20%)

---

## 8. Dependencies & Blockers

### Current Blockers
1. **Blocker:** [Description]
   - **Impact:** [Which tasks affected]
   - **ETA to resolve:** [Date]
   - **Owner:** [Name]
   - **Workaround:** [If any]

### New Dependencies
1. **Task A depends on Task B**
   - **Reason:** [Why]
   - **Impact if delayed:** [Describe]

---

## 9. Communication Log

### Meetings
- [x] Sprint planning update - 2025-10-28 10:00 AM
- [ ] Stakeholder briefing - 2025-10-29 2:00 PM
- [ ] Team retrospective - 2025-11-01 4:00 PM

### Notifications Sent
- [x] Team Slack announcement - 2025-10-28 11:00 AM
- [x] Email to stakeholders - 2025-10-28 2:00 PM
- [ ] Jira board updated - Pending

---

## 10. Approval & Sign-off

| Role | Name | Status | Date | Comments |
|------|------|--------|------|----------|
| Product Owner | [Name] | ✅ Approved | 2025-10-28 | Agree with priority changes |
| Tech Lead | [Name] | ✅ Approved | 2025-10-28 | Estimates are realistic |
| Project Manager | [Name] | ⏳ Pending | - | - |
| Stakeholder | [Name] | ⏳ Pending | - | - |

---

## 11. Next Steps

- [ ] Update project management tool (Jira/Trello/Linear)
- [ ] Update sprint board
- [ ] Notify all team members
- [ ] Schedule follow-up review [Date]
- [ ] Update project documentation
- [ ] Archive old planning version

---

## Appendix

### Related Documents
- Original planning: `docs/ai/planning/sprint-[X]-original.md`
- Requirements: `docs/ai/requirements/REQ-XXX.md`
- Design: `docs/ai/design/feature-[name].md`

### Change History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-20 | PM | Initial planning |
| 1.1 | 2025-10-28 | PM | Timeline adjustment |
```

---

## Quy tắc cập nhật

| Quy tắc | Mô tả |
|---------|-------|
| ✅ **Document all changes** | Mọi thay đổi phải được ghi nhận rõ ràng |
| ✅ **Get approval** | Thay đổi lớn cần approval từ PM/PO |
| ✅ **Communicate early** | Thông báo team càng sớm càng tốt |
| ✅ **Update all docs** | Đồng bộ roadmap, backlog, documentation |
| ✅ **Version control** | Lưu các version của planning |
| ⚠️ **Avoid scope creep** | Không thêm feature không cần thiết |
| ⚠️ **Realistic estimates** | Estimate phải dựa trên dữ liệu thực tế |
| ⚠️ **Consider team capacity** | Không over-allocate resources |

---

## Output mong đợi

```markdown
## Planning Update Summary

**Sprint:** Sprint 5
**Date:** 2025-10-28
**Updated by:** Project Manager

### Changes Made
- ✅ Added 2 new tasks (6 days total)
- ⏳ Delayed 1 feature to Sprint 6
- 🔄 Updated 3 task estimates (+4 days)

### Impact
- **Timeline:** +5 days (Sprint end: Nov 15 → Nov 20)
- **Budget:** +$2,500 (within 15% variance)
- **Team utilization:** 95% (healthy)

### Status
- ✅ PM approved
- ✅ Tech Lead approved
- ⏳ Stakeholder approval pending

### Next Actions
- [ ] Team notification sent
- [ ] Jira board updated
- [ ] Stakeholder meeting scheduled (Oct 29)

📄 Full document: `docs/ai/planning/sprint-5-v1.1.md`
```

---

## Tools & Commands

```bash
# Export current sprint from Jira (example)
jira sprint export --sprint=5 --format=json > sprint-5.json

# Generate planning diff
git diff docs/ai/planning/sprint-5-v1.0.md docs/ai/planning/sprint-5-v1.1.md

# Notify team via Slack (example)
slack-cli send --channel=#dev-team --file=planning-update.md
```

---

## Tham khảo

- [Agile Planning Best Practices](https://www.atlassian.com/agile/project-management/sprint-planning)
- [Change Management in Software Projects](https://www.pmi.org/learning/library/change-management-software-projects-6341)
- [Scrum Guide - Sprint Planning](https://scrumguides.org/)
- [Capacity Planning Guide](https://www.atlassian.com/agile/project-management/capacity-planning)
