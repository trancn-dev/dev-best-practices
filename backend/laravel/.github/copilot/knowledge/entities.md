# Domain Entities & Data Models

This document describes all domain entities, their relationships, attributes, and business rules for the Laravel DevKit project.

---

## Entity Relationship Overview

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│    User     │────────▶│   Project    │────────▶│   Feature   │
│             │  1:N    │              │  1:N    │             │
└─────────────┘         └──────────────┘         └─────────────┘
      │                       │                         │
      │ 1:N                   │ 1:N                     │ 1:N
      ▼                       ▼                         ▼
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Profile   │         │  Deployment  │         │    Task     │
└─────────────┘         └──────────────┘         └─────────────┘
      │                       │
      │ N:M                   │ N:M
      ▼                       ▼
┌─────────────┐         ┌──────────────┐
│    Role     │         │ Environment  │
└─────────────┘         └──────────────┘
      │
      │ N:M
      ▼
┌─────────────┐
│ Permission  │
└─────────────┘
```

---

## Core Entities

### 1. User

**Description**: System user who can create and manage projects.

**Table**: `users`

**Attributes**:
```php
id: bigint (PK, auto_increment)
uuid: string (unique, indexed)
name: string (required, max:255)
email: string (required, unique, indexed)
email_verified_at: timestamp (nullable)
password: string (hashed)
remember_token: string (nullable)
two_factor_secret: text (encrypted, nullable)
two_factor_recovery_codes: text (encrypted, nullable)
two_factor_confirmed_at: timestamp (nullable)
current_team_id: bigint (FK: teams.id, nullable)
profile_photo_path: string (nullable)
last_login_at: timestamp (nullable)
last_login_ip: string (nullable)
login_count: integer (default: 0)
status: enum (active, suspended, deleted) (default: active, indexed)
is_admin: boolean (default: false, indexed)
created_at: timestamp
updated_at: timestamp
deleted_at: timestamp (nullable, soft delete)
```

**Relationships**:
- `hasOne` Profile
- `hasMany` Projects
- `belongsToMany` Roles
- `belongsToMany` Permissions
- `hasMany` ApiTokens
- `hasMany` Activities (audit log)
- `belongsToMany` Teams
- `hasMany` Notifications

**Business Rules**:
- Email must be unique and validated
- Password must be hashed with bcrypt/argon2
- Email verification required for full access
- Two-factor authentication optional but recommended for admins
- Soft delete preserves data integrity
- UUID for external references
- Login tracking for security auditing

**Validation**:
```php
'name' => 'required|string|max:255',
'email' => 'required|email|unique:users,email|max:255',
'password' => [
    'required',
    'string',
    'min:12',
    Password::min(12)->mixedCase()->numbers()->symbols()->uncompromised()
],
```

**Indexes**:
```php
$table->index('email');
$table->index('uuid');
$table->index('status');
$table->index('is_admin');
$table->index(['status', 'is_admin']);
$table->index('created_at');
```

---

### 2. Profile

**Description**: Extended user profile information.

**Table**: `profiles`

**Attributes**:
```php
id: bigint (PK, auto_increment)
user_id: bigint (FK: users.id, unique, cascades)
bio: text (nullable, max:1000)
avatar_url: string (nullable)
website: string (nullable, max:255)
location: string (nullable, max:255)
company: string (nullable, max:255)
job_title: string (nullable, max:255)
github_username: string (nullable, max:255, indexed)
twitter_username: string (nullable, max:255)
linkedin_url: string (nullable, max:255)
timezone: string (default: UTC)
locale: string (default: en)
preferences: json (nullable)
created_at: timestamp
updated_at: timestamp
```

**Relationships**:
- `belongsTo` User

**Business Rules**:
- One profile per user
- URLs must be validated
- GitHub username used for integrations
- Preferences stored as JSON
- Timezone affects notification scheduling

**Validation**:
```php
'bio' => 'nullable|string|max:1000',
'website' => 'nullable|url|max:255',
'github_username' => 'nullable|string|max:255|alpha_dash',
'timezone' => 'nullable|timezone',
'locale' => 'nullable|string|in:en,vi,ja,zh',
```

---

### 3. Project

**Description**: Development project created by users.

**Table**: `projects`

**Attributes**:
```php
id: bigint (PK, auto_increment)
uuid: string (unique, indexed)
user_id: bigint (FK: users.id, cascades, indexed)
team_id: bigint (FK: teams.id, nullable, cascades)
name: string (required, max:255, indexed)
slug: string (required, unique, indexed)
description: text (nullable)
type: enum (api, fullstack, microservice) (required, indexed)
status: enum (active, archived, deleted) (default: active, indexed)
repository_url: string (nullable)
repository_provider: enum (github, gitlab, bitbucket) (nullable)
php_version: string (default: 8.2)
laravel_version: string (default: 11.0)
database_type: enum (mysql, postgresql, sqlite) (default: mysql)
has_api: boolean (default: false)
has_queue: boolean (default: false)
has_cache: boolean (default: true)
settings: json (nullable)
last_deployed_at: timestamp (nullable)
created_at: timestamp
updated_at: timestamp
deleted_at: timestamp (nullable, soft delete)
```

**Relationships**:
- `belongsTo` User (owner)
- `belongsTo` Team
- `hasMany` Features
- `hasMany` Deployments
- `hasMany` Environments
- `belongsToMany` Users (collaborators)
- `hasMany` Activities

**Business Rules**:
- Slug auto-generated from name (can be customized)
- Name must be unique per user
- Repository URL validated if provided
- Type determines available features
- Settings stored as JSON for flexibility
- Soft delete preserves history

**Validation**:
```php
'name' => 'required|string|max:255',
'slug' => 'required|string|max:255|alpha_dash|unique:projects,slug',
'type' => 'required|in:api,fullstack,microservice',
'php_version' => 'required|string|regex:/^\d+\.\d+$/',
'laravel_version' => 'required|string|regex:/^\d+\.\d+$/',
'repository_url' => 'nullable|url',
```

**Indexes**:
```php
$table->index('user_id');
$table->index('team_id');
$table->index('uuid');
$table->index('slug');
$table->index('name');
$table->index('status');
$table->index('type');
$table->index(['user_id', 'status']);
$table->index('created_at');
```

---

### 4. Feature

**Description**: Generated feature/module within a project.

**Table**: `features`

**Attributes**:
```php
id: bigint (PK, auto_increment)
project_id: bigint (FK: projects.id, cascades, indexed)
name: string (required, max:255)
slug: string (required, indexed)
type: enum (crud, api, auth, payment, etc.) (required, indexed)
description: text (nullable)
status: enum (planned, in_progress, completed, failed) (default: planned, indexed)
generated_files: json (nullable)
configuration: json (nullable)
has_tests: boolean (default: false)
test_coverage: decimal (nullable, 0-100)
has_documentation: boolean (default: false)
generated_at: timestamp (nullable)
created_by: bigint (FK: users.id, nullable)
created_at: timestamp
updated_at: timestamp
```

**Relationships**:
- `belongsTo` Project
- `belongsTo` User (creator)
- `hasMany` Tasks
- `hasMany` Files

**Business Rules**:
- Slug unique within project
- Type determines generation template
- Generated files tracked for rollback
- Configuration stored as JSON
- Test coverage tracked
- Status transitions: planned → in_progress → completed/failed

**Validation**:
```php
'name' => 'required|string|max:255',
'type' => 'required|string|in:crud,api,auth,payment,notification',
'status' => 'required|in:planned,in_progress,completed,failed',
'test_coverage' => 'nullable|numeric|min:0|max:100',
```

---

### 5. Role

**Description**: User role for authorization.

**Table**: `roles`

**Attributes**:
```php
id: bigint (PK, auto_increment)
name: string (required, unique, max:255)
slug: string (required, unique, indexed)
description: text (nullable)
level: integer (default: 0, indexed)
is_system: boolean (default: false)
created_at: timestamp
updated_at: timestamp
```

**System Roles**:
- **super_admin** (level: 100) - Full system access
- **admin** (level: 80) - Administrative access
- **developer** (level: 50) - Development access
- **user** (level: 10) - Standard user access
- **guest** (level: 0) - Guest access

**Relationships**:
- `belongsToMany` Users
- `belongsToMany` Permissions
- `belongsToMany` Teams

**Business Rules**:
- System roles cannot be deleted
- Level determines hierarchy
- Slug immutable after creation

---

### 6. Permission

**Description**: Granular permission for authorization.

**Table**: `permissions`

**Attributes**:
```php
id: bigint (PK, auto_increment)
name: string (required, unique, max:255)
slug: string (required, unique, indexed)
description: text (nullable)
group: string (required, indexed)
is_system: boolean (default: false)
created_at: timestamp
updated_at: timestamp
```

**Permission Groups**:
- **projects**: Project management
- **features**: Feature generation
- **users**: User management
- **teams**: Team management
- **settings**: System settings
- **analytics**: Analytics access

**Permission Examples**:
```
projects.create
projects.update
projects.delete
projects.view
features.generate
features.delete
users.create
users.update
users.delete
users.impersonate
settings.update
analytics.view
```

**Relationships**:
- `belongsToMany` Roles
- `belongsToMany` Users (direct permissions)

---

### 7. Team

**Description**: Team/organization for collaborative work.

**Table**: `teams`

**Attributes**:
```php
id: bigint (PK, auto_increment)
uuid: string (unique, indexed)
owner_id: bigint (FK: users.id, cascades, indexed)
name: string (required, max:255, indexed)
slug: string (required, unique, indexed)
description: text (nullable)
logo_path: string (nullable)
website: string (nullable)
settings: json (nullable)
personal_team: boolean (default: false)
created_at: timestamp
updated_at: timestamp
deleted_at: timestamp (nullable, soft delete)
```

**Relationships**:
- `belongsTo` User (owner)
- `belongsToMany` Users (members)
- `hasMany` Projects
- `hasMany` Invitations

**Business Rules**:
- Each user has one personal team
- Team name must be unique
- Owner has full permissions
- Soft delete preserves data

---

### 8. Deployment

**Description**: Project deployment record.

**Table**: `deployments`

**Attributes**:
```php
id: bigint (PK, auto_increment)
project_id: bigint (FK: projects.id, cascades, indexed)
environment_id: bigint (FK: environments.id, cascades)
deployed_by: bigint (FK: users.id, nullable)
version: string (required)
commit_hash: string (nullable)
branch: string (default: main)
status: enum (pending, in_progress, success, failed, rolled_back) (indexed)
started_at: timestamp (nullable)
completed_at: timestamp (nullable)
duration_seconds: integer (nullable)
log_output: text (nullable)
error_message: text (nullable)
metadata: json (nullable)
created_at: timestamp
updated_at: timestamp
```

**Relationships**:
- `belongsTo` Project
- `belongsTo` Environment
- `belongsTo` User (deployer)

**Business Rules**:
- Version follows semantic versioning
- Duration calculated from timestamps
- Logs stored for debugging
- Status transitions tracked
- Rollback capability maintained

---

### 9. Environment

**Description**: Deployment environment configuration.

**Table**: `environments`

**Attributes**:
```php
id: bigint (PK, auto_increment)
project_id: bigint (FK: projects.id, cascades, indexed)
name: string (required, max:255)
slug: string (required, indexed)
type: enum (development, staging, production) (required, indexed)
url: string (nullable)
branch: string (default: main)
auto_deploy: boolean (default: false)
configuration: json (nullable)
last_deployed_at: timestamp (nullable)
created_at: timestamp
updated_at: timestamp
```

**Relationships**:
- `belongsTo` Project
- `hasMany` Deployments

**Business Rules**:
- Type determines deployment strategy
- Configuration encrypted for sensitive data
- Auto-deploy only for non-production
- URL validated if provided

---

### 10. ApiToken

**Description**: API authentication tokens.

**Table**: `personal_access_tokens` (Laravel Sanctum)

**Attributes**:
```php
id: bigint (PK, auto_increment)
tokenable_type: string (polymorphic)
tokenable_id: bigint (polymorphic)
name: string (required)
token: string (unique, hashed)
abilities: text (nullable)
last_used_at: timestamp (nullable)
expires_at: timestamp (nullable)
created_at: timestamp
updated_at: timestamp
```

**Relationships**:
- `morphTo` Tokenable (User)

**Business Rules**:
- Token hashed before storage
- Abilities define permissions
- Expiry enforced
- Last used tracked for security

---

## Pivot Tables

### user_role
```php
user_id: bigint (FK: users.id, cascades)
role_id: bigint (FK: roles.id, cascades)
created_at: timestamp

Primary: (user_id, role_id)
Index: user_id, role_id
```

### role_permission
```php
role_id: bigint (FK: roles.id, cascades)
permission_id: bigint (FK: permissions.id, cascades)
created_at: timestamp

Primary: (role_id, permission_id)
Index: role_id, permission_id
```

### user_permission (direct permissions)
```php
user_id: bigint (FK: users.id, cascades)
permission_id: bigint (FK: permissions.id, cascades)
created_at: timestamp

Primary: (user_id, permission_id)
Index: user_id, permission_id
```

### project_user (collaborators)
```php
project_id: bigint (FK: projects.id, cascades)
user_id: bigint (FK: users.id, cascades)
role: enum (owner, admin, developer, viewer)
invited_by: bigint (FK: users.id, nullable)
joined_at: timestamp
created_at: timestamp

Primary: (project_id, user_id)
Index: project_id, user_id, role
```

### team_user
```php
team_id: bigint (FK: teams.id, cascades)
user_id: bigint (FK: users.id, cascades)
role: enum (owner, admin, member)
created_at: timestamp

Primary: (team_id, user_id)
Index: team_id, user_id, role
```

---

## Value Objects

### Address (JSON field)
```json
{
  "street": "123 Main St",
  "city": "San Francisco",
  "state": "CA",
  "postal_code": "94102",
  "country": "US"
}
```

### Money (stored as cents)
```php
amount: integer (cents)
currency: string (USD, EUR, etc.)
```

### Settings (JSON field)
```json
{
  "notifications": {
    "email": true,
    "push": false,
    "sms": false
  },
  "theme": "dark",
  "language": "en"
}
```

---

## Enums (PHP 8.1+)

### UserStatus
```php
enum UserStatus: string
{
    case ACTIVE = 'active';
    case SUSPENDED = 'suspended';
    case DELETED = 'deleted';
}
```

### ProjectType
```php
enum ProjectType: string
{
    case API = 'api';
    case FULLSTACK = 'fullstack';
    case MICROSERVICE = 'microservice';
}
```

### DeploymentStatus
```php
enum DeploymentStatus: string
{
    case PENDING = 'pending';
    case IN_PROGRESS = 'in_progress';
    case SUCCESS = 'success';
    case FAILED = 'failed';
    case ROLLED_BACK = 'rolled_back';
}
```

---

## Data Integrity Rules

### Cascading Deletes
- User deleted → Profile deleted
- User deleted → Projects soft deleted
- Project deleted → Features deleted
- Team deleted → Projects reassigned to personal team

### Foreign Key Constraints
- All foreign keys enforced at database level
- ON DELETE CASCADE where appropriate
- ON DELETE RESTRICT for critical relationships
- ON UPDATE CASCADE for all foreign keys

### Unique Constraints
- email (users)
- slug (projects, roles, permissions)
- (user_id, role_id) in user_role
- token (personal_access_tokens)

---

**Last Updated**: 2025-10-30
**Version**: 1.0
**Schema Version**: 1.0.0
