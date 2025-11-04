# Business Logic & Domain Knowledge

This document describes the business logic, domain rules, and business-specific knowledge for the Laravel DevKit project.

---

## Business Domain

### Project Purpose
Laravel DevKit is a comprehensive starter template and development toolkit designed to:
- Accelerate Laravel project setup
- Enforce best practices and coding standards
- Provide AI-assisted development capabilities
- Offer reusable components and patterns
- Enable rapid prototyping and development

---

## Core Business Concepts

### 1. User Management

#### User Roles
- **Admin**: Full system access
  - Manage all users
  - Configure system settings
  - Access all features
  - View analytics and reports

- **Developer**: Development access
  - Create and manage projects
  - Access development tools
  - Use AI assistance features
  - Cannot manage other users

- **Guest**: Limited access
  - View public content
  - Access documentation
  - Cannot modify data

#### User Lifecycle
```
Registration → Email Verification → Profile Setup → Active → [Suspended] → Deleted
```

**Business Rules:**
- Email must be unique
- Email verification required within 24 hours
- Password must meet security requirements (min 12 chars, mixed case, numbers, symbols)
- Failed login attempts: 5 attempts = 5-minute lockout
- Inactive accounts (180 days) are marked for review
- Soft delete users to maintain data integrity

---

### 2. Project Management

#### Project Types
1. **API Project**
   - RESTful API backend
   - Authentication via Sanctum
   - API versioning required
   - Rate limiting enabled

2. **Full-Stack Project**
   - Backend + Frontend
   - Session-based authentication
   - Server-side rendering or SPA
   - Asset compilation with Vite

3. **Microservice**
   - Single responsibility service
   - Event-driven communication
   - Independent deployment
   - Service discovery

#### Project Lifecycle
```
Creation → Setup → Development → Testing → Staging → Production → Maintenance
```

**Business Rules:**
- Project name must be unique per user
- Slug auto-generated from name (can be customized)
- Default template selected based on project type
- Git repository auto-initialized
- CI/CD pipeline auto-configured
- Minimum PHP version: 8.2
- Minimum Laravel version: 11.0

---

### 3. Code Generation

#### Generation Types

**1. CRUD Operations**
- Model with relationships
- Migration with indexes
- Controller with standard methods
- Form Requests for validation
- API Resources for transformation
- Test suite (Feature + Unit)
- Routes registration
- Policy for authorization

**2. API Endpoints**
- Controller with RESTful methods
- Form Requests
- API Resources
- Tests
- Documentation (OpenAPI)
- Rate limiting
- Versioning support

**3. Database Migrations**
- Table creation
- Column modifications
- Index management
- Foreign keys with constraints
- Reversible operations

**Business Rules:**
- All generated code must follow PSR-12
- Tests are mandatory for all features
- Documentation auto-generated
- Security checks included by default
- Performance considerations applied
- Type hints and return types required

---

### 4. AI-Assisted Development

#### AI Features

**Code Completion**
- Context-aware suggestions
- Framework-specific patterns
- Project conventions respected
- Security best practices enforced

**Code Review**
- Security vulnerability detection
- Performance issue identification
- Code smell detection
- Best practice validation

**Code Refactoring**
- Pattern recognition
- Architecture suggestions
- Performance optimization
- Test coverage improvement

**Business Rules:**
- AI suggestions must follow project rules
- Security-critical code requires human review
- All AI-generated code must have tests
- Changes tracked in version control
- Audit trail maintained

---

## Business Rules by Domain

### Authentication & Authorization

**Registration Rules:**
- Email format validation
- Password strength requirements
- Age verification (18+) if required
- Terms of service acceptance required
- Privacy policy acceptance required
- Optional newsletter opt-in

**Login Rules:**
- Support email/password login
- Support social authentication (OAuth)
- Remember me option (30 days max)
- Session timeout: 2 hours inactivity
- Multi-device login allowed
- Suspicious activity detection

**Password Rules:**
- Minimum 12 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character
- Cannot contain user's name or email
- Cannot be in breach database
- Password history: Cannot reuse last 5 passwords
- Password expiry: 90 days for admin, 180 days for others

**Authorization Rules:**
- Role-based access control (RBAC)
- Permission-based granular control
- Resource ownership validation
- Team-based access for projects
- Audit logging for admin actions

---

### Data Management

**Data Creation Rules:**
- All inputs must be validated
- XSS protection applied
- SQL injection prevention
- Mass assignment protection
- File upload validation
- Rate limiting on creation endpoints

**Data Update Rules:**
- Ownership verification required
- Partial updates allowed (PATCH)
- Full updates allowed (PUT)
- Optimistic locking for concurrent updates
- Change history tracking
- Audit trail maintenance

**Data Deletion Rules:**
- Soft delete by default
- Hard delete for admin only
- Cascade delete for dependent records
- Confirmation required for bulk delete
- Restore capability within 30 days
- Permanent deletion after 90 days

**Data Export Rules:**
- CSV, JSON, XML formats supported
- Pagination for large datasets
- Filtering and sorting options
- Access control enforced
- Audit logging enabled
- Rate limiting applied

---

### API Business Rules

**Rate Limiting:**
- Authenticated: 60 requests/minute
- Unauthenticated: 10 requests/minute
- Admin: 300 requests/minute
- Burst allowed: 2x normal rate for 10 seconds
- Rate limit headers included in response

**Versioning:**
- Current version: v1
- Deprecation notice: 6 months before removal
- Version in URL: `/api/v1/`
- Version in header: `Accept: application/vnd.api.v1+json`
- Backward compatibility maintained

**Response Times (SLA):**
- List endpoints: < 500ms
- Detail endpoints: < 200ms
- Create/Update: < 1000ms
- Complex queries: < 2000ms
- Batch operations: < 5000ms

**Pagination:**
- Default per page: 15
- Maximum per page: 100
- Cursor-based for large datasets
- Metadata included in response

---

### Performance Requirements

**Database:**
- Query execution: < 100ms (p95)
- Transaction time: < 500ms
- Connection pooling enabled
- Query caching for read-heavy tables
- Indexing on foreign keys mandatory

**Cache:**
- Redis primary cache
- TTL based on data volatility
- Cache warming on deploy
- Cache tags for easy invalidation
- Cache hit rate target: > 80%

**Queue:**
- Redis queue driver
- Job retry: 3 attempts
- Job timeout: 5 minutes default
- Failed job retention: 7 days
- Queue monitoring enabled

---

### Security Requirements

**Input Validation:**
- All user input validated
- Whitelist approach preferred
- Type casting enforced
- Length limits applied
- Format validation

**Output Encoding:**
- HTML entities escaped
- JSON properly encoded
- SQL parameterized queries
- Command injection prevention
- Path traversal prevention

**Authentication:**
- JWT tokens for API
- Session-based for web
- Token expiry: 24 hours
- Refresh tokens: 30 days
- CSRF protection enabled

**Authorization:**
- Policy-based authorization
- Resource ownership checks
- Team-based permissions
- Admin-only actions logged
- Failed authorization logged

**Data Protection:**
- PII encrypted at rest
- SSL/TLS for data in transit
- Database encryption enabled
- Backup encryption enabled
- Key rotation quarterly

---

## Business Workflows

### User Registration Workflow

```
1. User submits registration form
   ↓
2. Validate input (email, password, etc.)
   ↓
3. Check email uniqueness
   ↓
4. Hash password (bcrypt)
   ↓
5. Create user record (transaction)
   ↓
6. Generate email verification token
   ↓
7. Send verification email (queued)
   ↓
8. Return success response with user data
   ↓
9. [Background] Track registration event
   ↓
10. [Background] Send welcome email
```

**Error Handling:**
- Email exists → Return 422 with error
- Validation fails → Return 422 with errors
- Database error → Rollback, return 500
- Queue fails → Log, retry, fallback to sync

---

### Project Creation Workflow

```
1. User initiates project creation
   ↓
2. Validate project data
   ↓
3. Check project name uniqueness
   ↓
4. Generate project slug
   ↓
5. Create project directory structure
   ↓
6. Initialize Git repository
   ↓
7. Copy template files
   ↓
8. Install dependencies (queued)
   ↓
9. Configure environment
   ↓
10. Run database migrations
    ↓
11. Generate API documentation
    ↓
12. Setup CI/CD pipeline
    ↓
13. Return project details
    ↓
14. [Background] Send notification
    ↓
15. [Background] Track analytics
```

---

### Code Generation Workflow

```
1. User requests code generation
   ↓
2. Analyze requirements
   ↓
3. Select appropriate templates
   ↓
4. Generate code files
   ↓
5. Apply code formatting (Pint)
   ↓
6. Run static analysis (PHPStan)
   ↓
7. Generate tests
   ↓
8. Run tests
   ↓
9. Generate documentation
   ↓
10. Create Git commit
    ↓
11. Return generated files list
```

---

## Domain-Specific Terminology

### Common Terms

- **Action**: Single-purpose class that performs one business operation
- **Service**: Class that contains complex business logic
- **Repository**: Data access layer abstraction
- **DTO**: Data Transfer Object - immutable data structure
- **Resource**: API response transformer
- **Policy**: Authorization logic container
- **Job**: Queued background task
- **Event**: Something that happened in the system
- **Listener**: Responds to events
- **Observer**: Monitors model lifecycle events

### Project-Specific Terms

- **DevKit**: The development toolkit itself
- **Scaffold**: Generate code structure automatically
- **Copilot Integration**: AI-assisted coding features
- **Template**: Pre-configured project starter
- **Pattern**: Reusable code structure
- **Convention**: Agreed-upon coding standard

---

## Blog & Portfolio System (API v1)

### Purpose
Personal blog and online CV to showcase projects, share knowledge, and document learning journey.

### 5. Blog Post Management

#### Post Types
1. **Article**: Technical articles and tutorials
2. **Project Showcase**: Detailed project presentations
3. **Learning Notes**: Study notes and summaries
4. **Experience Sharing**: Personal insights and lessons learned

#### Post Status
- **draft**: Being written, not visible to public
- **published**: Live and visible to readers
- **archived**: Removed from main listing but accessible via direct link
- **scheduled**: Will be published at specified time

#### Post Lifecycle
```
Draft → Review → Published → [Updated] → [Archived]
```

**Business Rules:**
- Slug auto-generated from title (editable)
- Published date required for published posts
- Featured image recommended (1200x630px for SEO)
- Excerpt auto-generated from content (first 160 chars)
- View count tracked per unique IP per 24 hours
- Only one post can be featured per category
- Meta title max 60 chars, meta description max 160 chars
- Minimum content length: 300 characters
- Maximum featured posts: 3 at a time

---

### 6. Category Management

#### Category Types
- **Projects**: Completed work and case studies
- **Learning**: Study notes, courses, books
- **Experience**: Career insights, best practices
- **Technical**: Coding tutorials, technical deep-dives
- **Personal**: Personal development, soft skills

**Business Rules:**
- Category name must be unique
- Slug auto-generated from name
- Support nested categories (max depth: 2 levels)
- Cannot delete category with posts (must reassign first)
- Order determines display sequence (lower number = higher priority)
- Parent category cannot have posts directly

---

### 7. Tag Management

**Business Rules:**
- Tag name must be unique (case-insensitive)
- Slug auto-generated and URL-friendly
- Unused tags (no posts) auto-archived after 90 days
- Maximum 10 tags per post
- Tag cloud shows top 50 most used tags
- Related posts based on shared tags (minimum 2 shared)

---

### 8. Project Portfolio

#### Project Status
- **planning**: Idea/planning phase
- **in-progress**: Active development
- **completed**: Finished and deployed
- **maintenance**: Post-launch support
- **discontinued**: No longer maintained

**Business Rules:**
- Demo URL validation (must be valid URL)
- GitHub URL validation (must be github.com domain)
- Technologies stored as JSON array
- Featured projects shown on homepage (max 6)
- Projects sortable by date, popularity, or manual order
- Started date must be before completed date
- Completion percentage calculated from milestones

---

### 9. Skills Management

#### Skill Categories
- **Backend**: PHP, Laravel, Node.js, Python, etc.
- **Frontend**: Vue.js, React, JavaScript, HTML, CSS
- **Database**: MySQL, PostgreSQL, MongoDB, Redis
- **DevOps**: Docker, CI/CD, AWS, Linux
- **Tools**: Git, VS Code, Postman, etc.
- **Soft Skills**: Communication, Leadership, Problem Solving

#### Proficiency Levels
1. **Beginner**: Basic knowledge, learning
2. **Intermediate**: Comfortable using, some experience
3. **Advanced**: Proficient, can teach others
4. **Expert**: Deep expertise, significant experience

**Business Rules:**
- Skill name must be unique per category
- Icon supports Font Awesome, Devicon, or custom image
- Skills shown in radar chart or bar chart
- Order determines display sequence
- Skills linked to projects (many-to-many)
- Auto-suggest skills from existing projects

---

### 10. Comments System

#### Comment Status
- **pending**: Awaiting moderation
- **approved**: Visible to public
- **spam**: Marked as spam
- **rejected**: Manually rejected

**Business Rules:**
- Email validation required
- Author name required (3-50 characters)
- Content minimum 10 characters, maximum 1000 characters
- Support nested comments (replies, max depth: 3)
- Auto-approve comments from verified emails
- New commenters require moderation
- IP address logged for spam prevention
- Rate limiting: 3 comments per hour per IP
- Markdown supported in content
- URL auto-converted to links (nofollow)
- Email notifications to post author

---

### 11. Media Library

**Business Rules:**
- Supported image formats: jpg, jpeg, png, gif, webp, svg
- Maximum image size: 5MB
- Supported video formats: mp4, webm (for demos)
- Maximum video size: 50MB
- Supported document formats: pdf, doc, docx
- Maximum document size: 10MB
- Images auto-optimized on upload
- Generate multiple sizes: thumbnail (150x150), medium (600x400), large (1200x800)
- File names sanitized (remove special chars)
- Alt text required for accessibility
- Storage: local or S3-compatible

---

### 12. About/CV Sections

#### Section Types
1. **Introduction**: Brief personal intro and photo
2. **Experience**: Work history and achievements
3. **Education**: Academic background
4. **Skills**: Technical and soft skills showcase
5. **Contact**: Contact information and social links
6. **Achievements**: Awards, certifications, publications

**Business Rules:**
- Content stored as JSON for flexibility
- Each section can be toggled visible/hidden
- Order determines display sequence
- Contact email obfuscated to prevent scraping
- Social links validated (proper URL format)
- Experience dates validated (start < end)

---

### Blog API Business Rules

**Public Endpoints (No Auth Required):**
- GET /api/v1/posts - List published posts
- GET /api/v1/posts/{slug} - View single post
- GET /api/v1/categories - List categories
- GET /api/v1/tags - List tags
- GET /api/v1/projects - List projects
- GET /api/v1/projects/{slug} - View project
- GET /api/v1/skills - List skills
- POST /api/v1/comments - Submit comment
- GET /api/v1/about - Get about sections

**Protected Endpoints (Auth Required - CMS):**
- POST /api/v1/admin/posts - Create post
- PUT /api/v1/admin/posts/{id} - Update post
- DELETE /api/v1/admin/posts/{id} - Delete post
- POST /api/v1/admin/categories - Create category
- POST /api/v1/admin/projects - Create project
- PUT /api/v1/admin/projects/{id} - Update project
- POST /api/v1/admin/media - Upload media
- GET /api/v1/admin/comments - Manage comments
- PUT /api/v1/admin/comments/{id} - Moderate comment

**Rate Limiting (Blog API):**
- Public read endpoints: 100 requests/minute
- Comment submission: 3 requests/hour per IP
- Admin endpoints: 300 requests/minute
- Media upload: 10 requests/hour

**Caching Strategy:**
- Post list: 15 minutes
- Single post: 1 hour
- Categories/Tags: 1 hour
- Projects: 30 minutes
- Skills: 1 day
- About sections: 1 day
- Cache invalidated on content update

**SEO Requirements:**
- Canonical URLs for all content
- Open Graph tags for social sharing
- Twitter Card metadata
- Structured data (JSON-LD) for articles
- XML sitemap auto-generated
- RSS feed for posts
- Robots.txt configured

---

### Blog Workflows

#### Post Publishing Workflow
```
1. Author creates draft post
   ↓
2. Add title, content, excerpt
   ↓
3. Select category and tags
   ↓
4. Upload featured image
   ↓
5. Set SEO metadata
   ↓
6. Preview post
   ↓
7. Set publish date (now or scheduled)
   ↓
8. Publish post
   ↓
9. [Background] Generate sitemap
   ↓
10. [Background] Clear cache
    ↓
11. [Background] Send notifications (if subscribed)
    ↓
12. [Background] Post to social media (optional)
```

#### Comment Moderation Workflow
```
1. User submits comment
   ↓
2. Validate input
   ↓
3. Check spam score
   ↓
4. If new commenter → Status: pending
   If verified → Status: approved
   If spam detected → Status: spam
   ↓
5. Store comment
   ↓
6. Notify post author (if approved)
   ↓
7. [Admin] Review pending comments
   ↓
8. Approve/Reject/Mark as spam
```

---

## Business Metrics & KPIs

### User Metrics
- Monthly Active Users (MAU)
- Daily Active Users (DAU)
- User retention rate (30-day)
- Average session duration
- Feature adoption rate

### Project Metrics
- Projects created per day
- Average project completion time
- Code quality score (PHPStan)
- Test coverage percentage
- Deployment success rate

### Performance Metrics
- API response time (p50, p95, p99)
- Error rate
- Uptime percentage
- Cache hit rate
- Queue processing time

### AI Metrics
- AI suggestion acceptance rate
- Code review automation rate
- Bug detection rate
- Time saved per developer

---

## Compliance & Regulations

### Data Privacy (GDPR)
- User consent for data collection
- Right to data portability
- Right to be forgotten
- Data retention policies
- Privacy policy transparency

### Security Standards
- OWASP Top 10 compliance
- Regular security audits
- Penetration testing quarterly
- Vulnerability disclosure program
- Incident response plan

---

## Integration Points

### External Services
- **GitHub**: Repository management, CI/CD
- **Email Provider**: SendGrid/Mailgun for transactional emails
- **Payment Gateway**: Stripe for payments (if needed)
- **Analytics**: Google Analytics, Mixpanel
- **Monitoring**: Sentry, New Relic
- **Logging**: Papertrail, Loggly

### Webhooks
- GitHub push events
- Payment confirmations
- Email delivery status
- Error notifications
- Analytics events

---

**Last Updated**: 2025-10-30
**Version**: 1.0
**Owner**: Development Team
