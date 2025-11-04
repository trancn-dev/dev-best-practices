# Glossary & Terminology

This document defines all domain-specific terms, technical concepts, abbreviations, and business terminology used in the Laravel DevKit project.

---

## Table of Contents

1. [Domain Terms](#domain-terms)
2. [Technical Terms](#technical-terms)
3. [Laravel Terminology](#laravel-terminology)
4. [Abbreviations](#abbreviations)
5. [Business Terms](#business-terms)
6. [Status Values](#status-values)
7. [Role Types](#role-types)

---

## Domain Terms

### User
A person who has registered an account in the system. Can be an admin, developer, or guest.

### Project
A development project created and managed by a user. Contains features, deployments, and configuration.

### Feature
A specific functionality or component within a project. Has its own status, priority, and tasks.

### Deployment
A deployment instance of a project to a specific environment (development, staging, production).

### Profile
Extended user information including avatar, bio, social links, and preferences.

### Organization
A group or company that owns multiple projects and has multiple members.

### Template
A pre-configured project structure or pattern that can be used to quickly create new projects.

### Workspace
A collection of related projects, typically belonging to an organization or team.

### Repository
A version-controlled code storage location (e.g., GitHub, GitLab).

### Environment
A specific deployment target (development, staging, production).

### Task
A specific work item within a feature that needs to be completed.

### Permission
A specific action that can be performed in the system (e.g., create_project, delete_user).

### Role
A collection of permissions assigned to users (e.g., admin, developer, guest).

---

## Technical Terms

### API (Application Programming Interface)
A set of endpoints that allow external applications to interact with the system.

### Authentication
The process of verifying a user's identity (login).

### Authorization
The process of determining what actions a user can perform (permissions).

### CRUD
Create, Read, Update, Delete - the basic operations for data management.

### DTO (Data Transfer Object)
An object that carries data between processes or layers.

### Eloquent
Laravel's ORM (Object-Relational Mapping) system for database interactions.

### Eloquent Model
A PHP class that represents a database table and provides methods for querying and manipulating data.

### Factory
A class used to generate fake data for testing and seeding.

### Form Request
A class that handles validation and authorization for HTTP requests.

### Job
A queued task that runs asynchronously in the background.

### Middleware
Code that runs before or after an HTTP request is processed.

### Migration
A version-controlled file that defines database schema changes.

### ORM (Object-Relational Mapping)
A technique for converting data between incompatible type systems (objects and relational databases).

### Policy
A class that defines authorization logic for a specific model.

### Query Builder
Laravel's fluent interface for building database queries.

### Repository
A pattern that abstracts data access logic from business logic.

### Resource
A class that transforms models into JSON responses for APIs.

### Route
A URL endpoint that maps to a specific controller method.

### Sanctum
Laravel's token-based authentication system for APIs and SPAs.

### Seeder
A class that populates the database with initial or test data.

### Service
A class that contains business logic for a specific domain.

### Scope
A reusable query constraint defined in an Eloquent model.

### Soft Delete
A deletion method that marks records as deleted without removing them from the database.

### Validation
The process of checking if input data meets specified criteria.

### Value Object
An immutable object that represents a descriptive aspect of the domain with no conceptual identity.

---

## Laravel Terminology

### Artisan
Laravel's command-line interface for running tasks and generating code.

### Blade
Laravel's templating engine for creating views.

### Collection
An object that provides methods for working with arrays of data.

### Composer
PHP's dependency manager used to install Laravel packages.

### Facade
A static interface to classes in Laravel's service container.

### Guard
An authentication method (e.g., web, api).

### Horizon
Laravel's queue monitoring dashboard for Redis queues.

### Inertia
A framework for building SPAs using server-side routing and controllers.

### Livewire
A framework for building reactive interfaces without JavaScript.

### Mix / Vite
Asset build tools for compiling JavaScript and CSS.

### Nova
Laravel's administration panel package.

### Passport
Laravel's OAuth2 server implementation.

### Pint
Laravel's opinionated code formatter.

### Provider
A class that bootstraps application services.

### Sail
Laravel's Docker-based development environment.

### Sanctum
Laravel's lightweight authentication system.

### Scout
Laravel's full-text search package.

### Telescope
Laravel's debugging and monitoring tool.

### Tinker
Laravel's REPL (Read-Eval-Print Loop) for interacting with the application.

### Vapor
Laravel's serverless deployment platform for AWS.

---

## Abbreviations

### API
Application Programming Interface

### CORS
Cross-Origin Resource Sharing

### CSRF
Cross-Site Request Forgery

### CSS
Cascading Style Sheets

### DDD
Domain-Driven Design

### DI
Dependency Injection

### DTO
Data Transfer Object

### HTML
HyperText Markup Language

### HTTP
HyperText Transfer Protocol

### HTTPS
HyperText Transfer Protocol Secure

### IoC
Inversion of Control

### JS
JavaScript

### JSON
JavaScript Object Notation

### JWT
JSON Web Token

### MVC
Model-View-Controller

### OOP
Object-Oriented Programming

### ORM
Object-Relational Mapping

### PHP
PHP: Hypertext Preprocessor

### PSR
PHP Standard Recommendation

### RBAC
Role-Based Access Control

### REPL
Read-Eval-Print Loop

### REST
Representational State Transfer

### SPA
Single Page Application

### SQL
Structured Query Language

### SSL
Secure Sockets Layer

### TDD
Test-Driven Development

### UI
User Interface

### URI
Uniform Resource Identifier

### URL
Uniform Resource Locator

### UUID
Universally Unique Identifier

### XSS
Cross-Site Scripting

---

## Business Terms

### Active User
A user with status "active" who can access the system.

### Subscription
A paid plan that provides access to specific features or resources.

### Tier
A level of service or access (e.g., Free, Pro, Enterprise).

### License
A legal agreement granting permission to use the software.

### Trial
A limited-time period to test the system before purchasing.

### Quota
A limit on resource usage (e.g., number of projects, storage space).

### Usage
The amount of resources consumed by a user or organization.

### Invoice
A bill for services or subscription fees.

### Credit
A monetary unit used within the system for transactions.

### Billing Cycle
The recurring period for charging subscription fees (monthly, yearly).

### Renewal
The automatic continuation of a subscription at the end of a billing cycle.

### Cancellation
The termination of a subscription by the user.

### Refund
The return of payment to a user for services not rendered.

### Upgrade
Moving to a higher-tier subscription plan.

### Downgrade
Moving to a lower-tier subscription plan.

---

## Status Values

### User Status

| Status | Description |
|--------|-------------|
| `active` | User can access the system |
| `suspended` | User access is temporarily blocked |
| `deleted` | User account is marked for deletion |
| `pending` | User registration not yet verified |

### Project Status

| Status | Description |
|--------|-------------|
| `draft` | Project is being created |
| `active` | Project is in active development |
| `archived` | Project is no longer active |
| `suspended` | Project access is temporarily blocked |

### Feature Status

| Status | Description |
|--------|-------------|
| `planned` | Feature is planned for future development |
| `in_progress` | Feature is currently being developed |
| `completed` | Feature development is finished |
| `testing` | Feature is being tested |
| `deployed` | Feature is live in production |
| `cancelled` | Feature development was cancelled |

### Deployment Status

| Status | Description |
|--------|-------------|
| `pending` | Deployment is queued |
| `in_progress` | Deployment is running |
| `success` | Deployment completed successfully |
| `failed` | Deployment encountered an error |
| `rolled_back` | Deployment was reversed |

### Task Status

| Status | Description |
|--------|-------------|
| `todo` | Task is not started |
| `in_progress` | Task is being worked on |
| `review` | Task is being reviewed |
| `done` | Task is completed |
| `blocked` | Task cannot proceed |

---

## Role Types

### Admin
Full system access. Can:
- Manage all users
- Manage all projects
- Configure system settings
- View all analytics
- Assign roles and permissions

### Developer
Development access. Can:
- Create and manage own projects
- Access development tools
- Use AI assistance features
- Collaborate on projects
- Cannot manage other users

### Guest
Limited access. Can:
- View public content
- Access documentation
- Cannot create or modify data
- Cannot access restricted features

### Owner
Project-specific role. Can:
- Full control over the project
- Add/remove collaborators
- Deploy project
- Delete project

### Collaborator
Project-specific role. Can:
- Edit project content
- Create features
- View project analytics
- Cannot delete project
- Cannot manage other collaborators

### Viewer
Project-specific role. Can:
- View project content
- View project analytics
- Cannot edit or delete
- Read-only access

---

## Priority Levels

### Critical
Highest priority. Requires immediate attention.
- System-breaking bugs
- Security vulnerabilities
- Production outages

### High
Important and should be addressed soon.
- Major features
- Important bugs
- Performance issues

### Medium
Standard priority.
- Regular features
- Minor bugs
- Improvements

### Low
Nice to have, can be delayed.
- Small enhancements
- Documentation updates
- Cosmetic fixes

---

## Environment Types

### Development
Local development environment.
- Used by developers
- Frequent deployments
- Debug mode enabled
- Test data

### Staging
Pre-production environment.
- Mirrors production
- Used for testing
- QA validation
- Near-production data

### Production
Live environment.
- Public-facing
- Real users
- Real data
- High availability
- Monitored

### Testing
Automated testing environment.
- CI/CD pipelines
- Automated tests
- Clean state each run

---

## HTTP Methods

### GET
Retrieve a resource.
- Safe (no side effects)
- Idempotent
- Cacheable

### POST
Create a new resource.
- Not safe
- Not idempotent
- Not cacheable

### PUT
Replace a resource.
- Not safe
- Idempotent
- Not cacheable

### PATCH
Partially update a resource.
- Not safe
- Not idempotent
- Not cacheable

### DELETE
Remove a resource.
- Not safe
- Idempotent
- Not cacheable

---

## HTTP Status Codes

### 2xx Success

| Code | Name | Description |
|------|------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created |
| 204 | No Content | Success with no body |

### 3xx Redirection

| Code | Name | Description |
|------|------|-------------|
| 301 | Moved Permanently | Resource moved |
| 302 | Found | Temporary redirect |
| 304 | Not Modified | Cached version valid |

### 4xx Client Errors

| Code | Name | Description |
|------|------|-------------|
| 400 | Bad Request | Invalid request |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation failed |
| 429 | Too Many Requests | Rate limit exceeded |

### 5xx Server Errors

| Code | Name | Description |
|------|------|-------------|
| 500 | Internal Server Error | Server error |
| 502 | Bad Gateway | Gateway error |
| 503 | Service Unavailable | Server down |
| 504 | Gateway Timeout | Gateway timeout |

---

## Database Terms

### Primary Key
A unique identifier for a database record.

### Foreign Key
A field that references the primary key of another table.

### Index
A data structure that improves query performance.

### Migration
A version-controlled change to the database schema.

### Seeder
A class that populates the database with data.

### Transaction
A group of database operations that succeed or fail together.

### Rollback
Reverting database changes.

### Commit
Saving database changes permanently.

### Query
A request for data from the database.

### Join
Combining rows from multiple tables.

### Eager Loading
Loading related data in advance to avoid N+1 queries.

### N+1 Problem
A performance issue where queries are run in a loop.

### Soft Delete
Marking records as deleted without removing them.

### Pivot Table
A table that connects two other tables in a many-to-many relationship.

---

## Testing Terms

### Unit Test
Tests a single class or method in isolation.

### Feature Test
Tests application features through HTTP requests.

### Integration Test
Tests multiple components working together.

### Mock
A fake object used in testing.

### Stub
A simplified implementation for testing.

### Spy
A test double that records how it was used.

### Fake
Laravel's testing doubles (Mail::fake(), Queue::fake()).

### Factory
A class that generates test data.

### Assertion
A statement that checks if a condition is true.

### Test Coverage
The percentage of code exercised by tests.

### TDD (Test-Driven Development)
Writing tests before implementation code.

---

## Git Terms

### Repository (Repo)
A project's version control storage.

### Commit
A snapshot of code changes.

### Branch
A separate line of development.

### Merge
Combining branches together.

### Pull Request (PR)
A request to merge code changes.

### Clone
Copying a repository locally.

### Push
Uploading commits to remote.

### Pull
Downloading commits from remote.

### Conflict
When changes overlap and need resolution.

### Stash
Temporarily saving uncommitted changes.

---

## CI/CD Terms

### CI (Continuous Integration)
Automatically testing code changes.

### CD (Continuous Deployment)
Automatically deploying code to production.

### Pipeline
A series of automated steps.

### Build
Compiling and preparing code.

### Test
Running automated tests.

### Deploy
Releasing code to an environment.

### Artifact
A built file ready for deployment.

### Rollback
Reverting to a previous deployment.

---

## Security Terms

### Encryption
Converting data to unreadable format.

### Hashing
One-way conversion of data.

### Salt
Random data added to passwords before hashing.

### Token
A string used for authentication.

### JWT (JSON Web Token)
A compact, URL-safe token format.

### OAuth
An authorization framework.

### 2FA (Two-Factor Authentication)
Requiring two forms of identification.

### XSS (Cross-Site Scripting)
An injection attack through untrusted input.

### CSRF (Cross-Site Request Forgery)
An attack that tricks users into unwanted actions.

### SQL Injection
An attack through malicious SQL code.

### Rate Limiting
Restricting the number of requests.

### Throttling
Slowing down excessive requests.

---

## Quick Reference

### Common Commands
```bash
php artisan serve          # Start development server
php artisan migrate       # Run migrations
php artisan test          # Run tests
php artisan tinker        # Open REPL
composer install          # Install dependencies
npm install              # Install Node packages
npm run dev              # Build assets for development
```

### Common Status Checks
```php
$user->isActive()         // Check if user is active
$project->isActive()      // Check if project is active
$user->isAdmin()          // Check if user is admin
$user->hasPermission()    // Check user permission
```

### Common Relationships
```php
$user->projects           // User's projects
$project->user           // Project's owner
$project->features       // Project's features
$user->profile           // User's profile
```
