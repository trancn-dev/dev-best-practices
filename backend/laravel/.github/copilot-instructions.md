# Copilot Instructions for AI Coding Agents

## Project Overview
- **Framework:** Laravel 12.x (PHP)
- **Purpose:** AI-optimized development kit with deep Copilot integration for rapid, standards-compliant Laravel app development.
- **Key Directories:**
  - `app/Http/Controllers/` – API & web controllers
  - `app/Models/` – Eloquent models
  - `app/Providers/` – Service providers
  - `config/` – Laravel configuration
  - `database/` – Migrations, seeders, factories
  - `routes/` – Route definitions
  - `.github/copilot/` – AI commands, prompts, rules, knowledge, and snippets

## AI Agent Guidance
- **Always consult `.github/copilot/rules/` and `.github/copilot/commands/` for project-specific standards and workflows.**
- **Use `.github/copilot/prompts/` for reusable prompt templates (API design, bug fixing, testing, etc).**
- **Automate repetitive tasks using Copilot commands (see below for examples).**

## Essential Workflows
- **Setup:**
  - `composer install` & `npm install` to install dependencies
  - `cp .env.example .env` then `php artisan key:generate`
  - `php artisan migrate --seed` to set up DB
  - `php artisan serve` and `npm run dev` to start servers
- **Testing:**
  - `php artisan test` (all tests)
  - `php artisan test --coverage` (with coverage)
- **Code Quality:**
  - `./vendor/bin/pint` (format)
  - `./vendor/bin/phpstan analyse` (static analysis)
- **Artisan:**
  - `php artisan list` (all commands)
  - `php artisan route:list` (routes)
  - `php artisan tinker` (REPL)

## Project-Specific Patterns & Conventions
- **Controllers:** RESTful, thin, delegate to Services (if present)
- **Models:** Eloquent, use relationships, scopes, and accessors
- **Migrations:** Use timestamped files, follow naming conventions
- **Testing:** Use `tests/Feature/` and `tests/Unit/`, follow `rules/testing.md`
- **API:** Follow `rules/api.md` for endpoint structure, responses, and error handling
- **Security:** Follow `rules/security.md` for validation, auth, and sensitive data
- **Git:** Branching, commit, and PR standards in `rules/git.md`

## Copilot Automation & Knowledge Capture
- **Commands:**
  - `/capture-knowledge` – Summarize code, architecture, or patterns
  - `/code-review` – Review code for standards
  - `/writing-test` – Generate tests for features/bugfixes
  - `/execute-plan` – Implement feature plans
- **Prompts:**
  - Use templates in `.github/copilot/prompts/` for API design, bug fixing, refactoring, etc.

## Integration Points
- **External:**
  - Database: MySQL/PostgreSQL (see `config/database.php`)
  - Optional: Redis for cache/queue
- **Internal:**
  - Service Providers register app services
  - Controllers communicate with Models and (optionally) Services

## Examples
- **To add a new API endpoint:**
  1. Define route in `routes/api.php`
  2. Create controller in `app/Http/Controllers/`
  3. Add logic, following `rules/api.md`
  4. Write tests in `tests/Feature/`

- **To add a migration:**
  1. Create migration in `database/migrations/`
  2. Follow `rules/database.md`
  3. Run `php artisan migrate`

## References
- `.github/copilot/rules/` – Coding standards (API, database, security, etc)
- `.github/copilot/commands/` – Workflow automations
- `.github/copilot/prompts/` – Prompt templates
- `README.md`, `QUICKSTART.md`, `SETUP.md` – Setup and usage docs

---
**For new patterns or unclear conventions, consult the relevant rule or command file, or ask for clarification in documentation.**
