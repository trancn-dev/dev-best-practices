---
type: command
name: review-requirements
version: 2.0
scope: project
integration:
  - laravel
  - requirements
  - business-analysis
---

# Command: Review Requirements

## Mục tiêu
Lệnh `review-requirements` được sử dụng để **review và validate yêu cầu** trước khi chuyển sang design và implementation.

Mục tiêu chính:
- Đảm bảo requirements rõ ràng, đầy đủ, và khả thi.
- Phát hiện conflicts, ambiguity, hoặc gaps.
- Xác minh requirements đo lường được và testable.
- Đánh giá tác động và rủi ro.

---

## Quy trình review

### Step 1: Gather Requirements Context

**Câu hỏi cần trả lời:**

#### A. Document Information
- Requirements document location?
- Version và date?
- Author/Stakeholder?
- Related documents (design, technical specs)?

#### B. Scope Understanding
- Feature/functionality overview?
- Business objectives?
- Target users?
- Success metrics (KPIs)?

---

### Step 2: Requirements Quality Check

#### A. SMART Criteria

```markdown
## SMART Requirements Check

Each requirement should be:

### S - Specific
- [ ] Clear and unambiguous
- [ ] No vague terms (e.g., "fast", "better", "user-friendly")
- [ ] Concrete actions and outcomes defined

### M - Measurable
- [ ] Success criteria defined
- [ ] Quantifiable metrics
- [ ] Clear acceptance criteria

### A - Achievable
- [ ] Technically feasible
- [ ] Within team capabilities
- [ ] Resources available

### R - Relevant
- [ ] Aligns with business goals
- [ ] Adds value to users
- [ ] Supports overall strategy

### T - Time-bound
- [ ] Deadline specified
- [ ] Milestones defined
- [ ] Dependencies identified
```

#### B. Quality Assessment

```markdown
## Requirements Quality Matrix

| Requirement ID | Specific | Measurable | Achievable | Relevant | Time-bound | Score |
|----------------|----------|------------|------------|----------|------------|-------|
| REQ-001 | ✅ | ✅ | ✅ | ✅ | ✅ | 5/5 |
| REQ-002 | ✅ | ⚠️ | ✅ | ✅ | ✅ | 4/5 |
| REQ-003 | ⚠️ | ❌ | ✅ | ✅ | ⚠️ | 2/5 |

**Average Score:** 3.7/5

### Issues Found

**REQ-002: User Registration**
- ⚠️ Missing: Success rate target (measurable)
- Recommendation: "Registration success rate should be > 95%"

**REQ-003: System Performance**
- ⚠️ Vague: "System should be fast"
- ❌ Not measurable: No specific metrics
- ⚠️ No deadline
- Recommendation: "API response time < 200ms for 95th percentile by 2025-12-01"
```

---

### Step 3: Completeness Check

```markdown
## Requirements Completeness Checklist

### Functional Requirements
- [ ] ✅ User stories defined
- [ ] ✅ Input specifications
- [ ] ✅ Processing logic
- [ ] ✅ Output specifications
- [ ] ✅ Business rules
- [ ] ⚠️ Edge cases (incomplete)
- [ ] ✅ Error handling

### Non-Functional Requirements
- [ ] ✅ Performance requirements
- [ ] ✅ Security requirements
- [ ] ⚠️ Scalability requirements (missing)
- [ ] ✅ Usability requirements
- [ ] ⚠️ Availability requirements (missing)
- [ ] ✅ Compatibility requirements

### Constraints
- [ ] ✅ Technical constraints
- [ ] ✅ Budget constraints
- [ ] ✅ Timeline constraints
- [ ] ⚠️ Resource constraints (unclear)
- [ ] ✅ Regulatory constraints

### Dependencies
- [ ] ✅ External systems
- [ ] ✅ Third-party services
- [ ] ⚠️ Data dependencies (incomplete)
- [ ] ✅ Team dependencies

**Completeness Score:** 75%

### Missing Elements
1. **Scalability Requirements**
   - Expected: "System should handle 10,000 concurrent users"
   - Priority: High

2. **Availability Requirements**
   - Expected: "99.9% uptime (SLA)"
   - Priority: High

3. **Edge Cases**
   - Expected: List of error scenarios
   - Priority: Medium
```

---

### Step 4: User Story Review

```markdown
## User Story Assessment

### User Story Template
```
As a [role]
I want [feature/capability]
So that [business value]

Acceptance Criteria:
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

### Example Review

#### User Story: REQ-001
```
As a registered user
I want to reset my password
So that I can regain access if I forget it
```

**Assessment:**

| Criteria | Status | Comment |
|----------|--------|---------|
| Role clear | ✅ | "registered user" well-defined |
| Feature clear | ✅ | "reset password" specific |
| Value clear | ✅ | Business value stated |
| Testable | ✅ | Can verify password reset works |

**Acceptance Criteria Review:**
- [x] ✅ User receives reset email within 5 minutes
- [x] ✅ Reset link expires after 1 hour
- [x] ⚠️ "New password must be different from old one" - Missing: How many previous passwords to check?
- [ ] ❌ Missing: Password strength requirements
- [ ] ❌ Missing: Rate limiting for reset requests

**Recommendations:**
1. Add: "New password must not match last 3 passwords"
2. Add: "Password must be 8+ chars with uppercase, lowercase, number"
3. Add: "Max 3 reset attempts per hour per account"

**Score:** 3/5 (Needs improvement)

---

#### User Story: REQ-002
```
As an admin
I want to view user activity logs
So that I can monitor system usage
```

**Assessment:**

| Criteria | Status | Comment |
|----------|--------|---------|
| Role clear | ✅ | "admin" well-defined |
| Feature clear | ⚠️ | "view activity logs" - What specific activities? |
| Value clear | ⚠️ | "monitor system usage" - Too vague |
| Testable | ⚠️ | Unclear what to test |

**Issues:**
- 🔴 Not specific enough: What activities to log?
- 🔴 No acceptance criteria provided
- 🔴 No performance requirements (logs could be huge)

**Improved Version:**
```
As an admin
I want to view user login/logout events, data modifications, and API calls with timestamps
So that I can audit security incidents and troubleshoot issues

Acceptance Criteria:
- [ ] Display last 1000 events with pagination
- [ ] Filter by user, event type, date range
- [ ] Export logs to CSV
- [ ] Page loads in < 2 seconds
- [ ] Logs retained for 90 days
```

**Score:** 2/5 (Requires rewrite)
```

---

### Step 5: Consistency & Conflict Check

```markdown
## Consistency Analysis

### Internal Consistency
| Requirement | Conflict With | Issue | Resolution |
|-------------|---------------|-------|------------|
| REQ-001: Password min 8 chars | REQ-015: Password min 12 chars | Contradictory | ✅ Use REQ-015 (more secure) |
| REQ-005: Response < 200ms | REQ-010: Complex reporting | Unrealistic | ⚠️ Clarify: 200ms for simple queries only |
| REQ-008: Real-time updates | REQ-012: Support 10k users | Scalability concern | ⚠️ Use websockets with load balancing |

### External Consistency
| Requirement | External System | Issue | Resolution |
|-------------|-----------------|-------|------------|
| REQ-020: OAuth login | Facebook API | API rate limits | ✅ Implement caching |
| REQ-025: Payment processing | Stripe | PCI compliance | ✅ Use Stripe.js (no CC storage) |

### Priority Conflicts
| REQ-001 (Priority: Critical) | vs | REQ-005 (Priority: Critical) |
|------------------------------|----|-----------------------------|
| Both require same developer | Timeline conflict | ⚠️ Need to sequence or add resource |
```

---

### Step 6: Testability Review

```markdown
## Testability Assessment

### Testable Requirements

#### ✅ Good Example: REQ-001
**Requirement:** "User registration should complete in < 3 seconds"
**Why testable:**
- Specific metric (3 seconds)
- Measurable with tools
- Clear pass/fail criteria

**Test Case:**
```php
/** @test */
public function user_registration_completes_within_3_seconds(): void
{
    $start = microtime(true);

    $response = $this->postJson('/api/register', [
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'password' => 'password123',
    ]);

    $duration = microtime(true) - $start;

    $this->assertLessThan(3, $duration);
    $response->assertStatus(201);
}
```

#### ❌ Bad Example: REQ-002
**Requirement:** "System should be user-friendly"
**Why not testable:**
- Subjective term ("user-friendly")
- No measurable criteria
- No acceptance criteria

**Improved Version:**
"System should achieve:
- SUS (System Usability Scale) score > 80
- Task completion rate > 90%
- Average task time < 5 minutes
- User satisfaction rating > 4/5"

---

### Testability Checklist

For each requirement, verify:

- [ ] ✅ Has quantifiable metrics
- [ ] ✅ Clear pass/fail criteria
- [ ] ✅ Measurable with available tools
- [ ] ✅ Test cases can be written
- [ ] ✅ Independent (not dependent on untestable requirements)
```

---

### Step 7: Technical Feasibility Review

```markdown
## Feasibility Assessment

### Technical Feasibility

| Requirement | Technology Needed | Availability | Complexity | Feasible? |
|-------------|-------------------|--------------|------------|-----------|
| REQ-001: OAuth login | Laravel Socialite | ✅ Available | 🟢 Low | ✅ Yes |
| REQ-005: Real-time chat | WebSockets | ✅ Available | 🟡 Medium | ✅ Yes |
| REQ-010: AI recommendations | ML Model | ⚠️ Need training | 🔴 High | ⚠️ Maybe |
| REQ-015: Video processing | FFmpeg | ✅ Available | 🟡 Medium | ✅ Yes |

### Resource Feasibility

**Team Capacity:**
- Available: 3 developers × 40 hours/week = 120 hours/week
- Required: Estimated 200 hours total
- Timeline: 4 weeks = 480 hours available
- **Status:** ✅ Feasible

**Skill Gaps:**
- ✅ Laravel: Team has expertise
- ⚠️ WebSockets: 1 developer needs training
- ❌ Machine Learning: No expertise (need external consultant)

### Budget Feasibility

| Item | Cost Estimate | Budget Available | Status |
|------|---------------|------------------|--------|
| Development | $15,000 | $20,000 | ✅ |
| Third-party APIs | $500/month | $1,000/month | ✅ |
| ML Consultant | $10,000 | $0 | ❌ Not budgeted |
| Infrastructure | $200/month | $500/month | ✅ |

**Issues:**
- 🔴 ML requirement (REQ-010) not budgeted
- Options:
  1. Remove REQ-010
  2. Use pre-trained model (cheaper)
  3. Request budget increase
```

---

### Step 8: Risk Assessment

```markdown
## Risk Analysis

### Requirements Risks

| Risk | Probability | Impact | Score | Mitigation |
|------|-------------|--------|-------|------------|
| Scope creep | High | High | 🔴 9 | Freeze requirements after approval |
| Unclear requirements | Medium | High | 🟡 6 | Clarification sessions with stakeholders |
| Changing priorities | Medium | Medium | 🟡 4 | Regular priority reviews |
| Technical complexity | Low | High | 🟢 3 | Proof of concept for complex features |
| Resource unavailability | Low | Medium | 🟢 2 | Backup resource plan |

### Dependencies & Blockers

| Requirement | Depends On | Status | Blocker? |
|-------------|------------|--------|----------|
| REQ-005 | Third-party API approval | ⏳ Pending | ⚠️ Yes |
| REQ-010 | ML model training data | ❌ Not available | 🔴 Yes |
| REQ-015 | Infrastructure upgrade | ✅ Approved | ☐ No |

### Risk Mitigation Plan

**High-Risk Items:**
1. **REQ-010: ML Recommendations**
   - Risk: No training data available
   - Impact: Feature cannot be implemented
   - Mitigation:
     - Option A: Use existing recommendation algorithm
     - Option B: Delay this requirement to Phase 2
     - Option C: Purchase training dataset

2. **Scope Creep**
   - Risk: Requirements keep changing
   - Impact: Timeline延迟, budget overrun
   - Mitigation:
     - Implement change control process
     - Require formal approval for new requirements
     - Regular stakeholder sync meetings
```

---

### Step 9: Stakeholder Review

```markdown
## Stakeholder Validation

### Stakeholder Sign-off Checklist

| Stakeholder | Role | Review Status | Sign-off Date | Comments |
|-------------|------|---------------|---------------|----------|
| John Smith | Product Owner | ✅ Approved | 2025-10-25 | Request priority change for REQ-005 |
| Jane Doe | Tech Lead | ⚠️ Approved with changes | 2025-10-26 | Technical concerns on REQ-010 |
| Bob Johnson | QA Lead | ✅ Approved | 2025-10-26 | Need more test scenarios |
| Alice Brown | Business Analyst | ⏳ Pending | - | - |

### Open Questions

1. **REQ-005: Real-time updates**
   - **Question:** What is acceptable latency for "real-time"?
   - **Asked by:** Tech Lead
   - **Asked to:** Product Owner
   - **Status:** ⏳ Awaiting response

2. **REQ-010: AI recommendations**
   - **Question:** Can we use simpler collaborative filtering instead of ML?
   - **Asked by:** Tech Lead
   - **Asked to:** Product Owner
   - **Status:** ⏳ Awaiting response

3. **REQ-020: Data retention**
   - **Question:** Legal requirements for data retention period?
   - **Asked by:** Developer
   - **Asked to:** Legal team
   - **Status:** ⏳ Awaiting response
```

---

### Step 10: Documentation Quality

```markdown
## Documentation Review

### Documentation Checklist

#### Structure
- [ ] ✅ Clear table of contents
- [ ] ✅ Version history
- [ ] ✅ Document metadata (author, date, version)
- [ ] ⚠️ Glossary (missing some terms)

#### Content
- [ ] ✅ Executive summary
- [ ] ✅ Business objectives
- [ ] ✅ User personas
- [ ] ✅ Functional requirements
- [ ] ⚠️ Non-functional requirements (incomplete)
- [ ] ✅ Acceptance criteria
- [ ] ⚠️ Dependencies (not fully listed)
- [ ] ❌ Risk assessment (missing)

#### Formatting
- [ ] ✅ Consistent formatting
- [ ] ✅ Proper numbering/IDs
- [ ] ✅ Cross-references work
- [ ] ⚠️ Diagrams (some missing)

#### Language
- [ ] ⚠️ Clear and concise (some ambiguity)
- [ ] ✅ No jargon without explanation
- [ ] ✅ Active voice
- [ ] ✅ Consistent terminology

**Documentation Score:** 75%

### Improvement Areas
1. Add risk assessment section
2. Complete non-functional requirements
3. Add missing diagrams (user flow, architecture)
4. Clarify ambiguous terms
5. Add comprehensive glossary
```

---

## Requirements Review Report Template

```markdown
# Requirements Review Report

**Project:** [Project Name]
**Requirements Document:** [Link/Version]
**Reviewer:** [Name]
**Review Date:** [YYYY-MM-DD]

---

## Executive Summary

**Overall Assessment:** ✅ Approved | ⚠️ Approved with Changes | ❌ Rejected

**Quality Score:** [X]/100

**Quick Summary:**
[2-3 sentences describing overall quality and main findings]

---

## Detailed Assessment

### Requirements Quality: [Score]/25
- SMART criteria: [X]/5
- Completeness: [X]/5
- Clarity: [X]/5
- Consistency: [X]/5
- Testability: [X]/5

### Technical Feasibility: [Score]/25
- Technology availability: [X]/10
- Team capability: [X]/10
- Timeline realistic: [X]/5

### Business Value: [Score]/25
- Aligns with goals: [X]/10
- User value: [X]/10
- ROI potential: [X]/5

### Risk Level: [Score]/25
- Technical risks: [X]/10
- Business risks: [X]/10
- Mitigation plans: [X]/5

---

## Findings

### ✅ Strengths
1. Well-defined user stories
2. Clear acceptance criteria
3. Good stakeholder alignment

### 🔴 Critical Issues (Must Fix)
1. **REQ-010: Unclear ML requirements**
   - Issue: No training data available
   - Impact: Feature cannot be implemented
   - Recommendation: Use simpler algorithm or delay to Phase 2

### 🟡 Important Issues (Should Fix)
1. **REQ-005: Real-time definition vague**
   - Issue: "Real-time" not quantified
   - Impact: Cannot validate implementation
   - Recommendation: Specify max latency (e.g., < 100ms)

2. **Missing scalability requirements**
   - Issue: No concurrent user target
   - Impact: Cannot design for scale
   - Recommendation: Specify "Support 10,000 concurrent users"

### 🟢 Minor Issues (Nice to Fix)
1. **Documentation gaps**
   - Missing some diagrams
   - Recommendation: Add user flow diagrams

---

## Requirements Quality Matrix

| ID | Requirement | SMART | Complete | Feasible | Testable | Score |
|----|-------------|-------|----------|----------|----------|-------|
| REQ-001 | User registration | ✅ | ✅ | ✅ | ✅ | 5/5 |
| REQ-002 | Password reset | ✅ | ⚠️ | ✅ | ✅ | 4/5 |
| REQ-005 | Real-time updates | ⚠️ | ✅ | ✅ | ⚠️ | 3/5 |
| REQ-010 | AI recommendations | ❌ | ❌ | ❌ | ❌ | 0/5 |

**Average Score:** 3/5 (60%)

---

## Risks & Mitigation

| Risk | Level | Mitigation Strategy | Owner |
|------|-------|---------------------|-------|
| Unclear ML requirements | 🔴 High | Use simpler algorithm | PO |
| Scope creep | 🟡 Medium | Implement change control | PM |
| Technical complexity | 🟢 Low | Proof of concept | Tech Lead |

---

## Recommendations

### Before Proceeding to Design
1. ✅ Clarify REQ-010 (ML requirements)
2. ✅ Add scalability requirements
3. ✅ Define "real-time" with metrics
4. ⚠️ Add risk assessment section
5. ⚠️ Complete non-functional requirements

### Before Implementation
1. Get all stakeholder approvals
2. Resolve open questions
3. Create test plan based on requirements

---

## Approval

**Reviewer Decision:** ⚠️ Approved with mandatory changes

**Required Changes:**
1. Clarify or remove REQ-010
2. Add scalability requirements
3. Quantify performance requirements

**Optional Changes:**
1. Improve documentation
2. Add more diagrams

**Sign-off:**
- Requirements Author: [Name] - [Date]
- Reviewer: [Name] - [Date]
- Product Owner: [Name] - [Date]
- Tech Lead: [Name] - [Date]

---

## Next Steps

- [ ] Address critical issues
- [ ] Update requirements document
- [ ] Get stakeholder re-approval
- [ ] Schedule design phase
- [ ] Create project plan

**Follow-up Review:** [Date] (if needed)
```

---

## Quick Review Checklist

```markdown
## 5-Minute Quick Check

### Must Have (Block if missing)
- [ ] ✅ Clear business objectives
- [ ] ✅ User stories with acceptance criteria
- [ ] ✅ Success metrics defined
- [ ] ✅ Deadline specified
- [ ] ✅ Stakeholder approval

### Should Have (Flag if missing)
- [ ] ⚠️ Non-functional requirements
- [ ] ⚠️ Dependencies identified
- [ ] ⚠️ Risk assessment
- [ ] ⚠️ Test scenarios
- [ ] ⚠️ Budget estimate

### Red Flags (Reject if found)
- [ ] 🔴 Contradictory requirements
- [ ] 🔴 Technically impossible requirements
- [ ] 🔴 No acceptance criteria
- [ ] 🔴 Vague/ambiguous language
- [ ] 🔴 No stakeholder buy-in
```

---

## Tools & Templates

```bash
# Requirements traceability
requirements-trace --from=REQ-001 --to=design,code,tests

# Requirements validation
requirements-validator --input=requirements.md --rules=SMART

# Generate requirements report
requirements-report --format=pdf --output=review-report.pdf
```

---

## Tham khảo

- [IEEE 29148: Requirements Engineering](https://standards.ieee.org/standard/29148-2018.html)
- [Requirements Best Practices](https://www.reqview.com/doc/iso-iec-ieee-29148-requirements-engineering.html)
- [User Story Guide](https://www.atlassian.com/agile/project-management/user-stories)
- [INVEST Criteria](https://en.wikipedia.org/wiki/INVEST_(mnemonic))
- [Requirements Validation Techniques](https://www.pmi.org/learning/library/requirements-gathering-validation-techniques-6624)
