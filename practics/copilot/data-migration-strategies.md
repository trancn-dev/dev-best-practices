# Rule: Data Migration Strategies

## Intent
Enforce safe, reversible, and zero-downtime database migration practices for schema changes, data transformations, and database version management.

## Scope
Applies to all database schema changes, data migrations, versioning, and deployment strategies.

---

## 1. Migration Principles

### Golden Rules

- ✅ **MUST** be reversible (up/down migrations)
- ✅ **MUST** be idempotent (safe to run multiple times)
- ✅ **MUST** be tested in staging before production
- ✅ **MUST** include rollback plan
- ❌ **MUST NOT** lose data
- ❌ **MUST NOT** cause downtime

---

## 2. Schema Migration Tools

### Knex.js Migration

```javascript
// ✅ GOOD - Reversible migration
// migrations/20240115_add_users_table.js
exports.up = function(knex) {
    return knex.schema.createTable('users', (table) => {
        table.increments('id').primary();
        table.string('email').notNullable().unique();
        table.string('name').notNullable();
        table.timestamp('created_at').defaultTo(knex.fn.now());
        table.timestamp('updated_at').defaultTo(knex.fn.now());

        table.index('email');
    });
};

exports.down = function(knex) {
    return knex.schema.dropTable('users');
};
```

### Sequelize Migration

```javascript
// ✅ GOOD - Add column with default value
// migrations/20240115-add-status-column.js
module.exports = {
    async up(queryInterface, Sequelize) {
        await queryInterface.addColumn('orders', 'status', {
            type: Sequelize.ENUM('pending', 'processing', 'completed'),
            defaultValue: 'pending',
            allowNull: false
        });
    },

    async down(queryInterface) {
        await queryInterface.removeColumn('orders', 'status');
    }
};
```

### TypeORM Migration

```typescript
// ✅ GOOD - TypeORM migration
import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddEmailVerifiedColumn1705300000000 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.addColumn('users', new TableColumn({
            name: 'email_verified',
            type: 'boolean',
            default: false
        }));
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.dropColumn('users', 'email_verified');
    }
}
```

---

## 3. Zero-Downtime Migrations

### Expand-Migrate-Contract Pattern

#### Phase 1: Expand (Add New Column)

```javascript
// ✅ GOOD - Step 1: Add nullable column
exports.up = function(knex) {
    return knex.schema.table('users', (table) => {
        table.string('full_name').nullable(); // New column, nullable
    });
};

// Deploy code that writes to both old and new columns
app.post('/users', async (req, res) => {
    await db.users.create({
        name: req.body.name,              // Old column
        full_name: req.body.name          // New column (duplicate)
    });
});
```

#### Phase 2: Migrate (Copy Data)

```javascript
// ✅ GOOD - Step 2: Backfill data
exports.up = async function(knex) {
    // Batch update to avoid long-running transaction
    const batchSize = 1000;
    let lastId = 0;

    while (true) {
        const users = await knex('users')
            .where('id', '>', lastId)
            .whereNull('full_name')
            .limit(batchSize);

        if (users.length === 0) break;

        for (const user of users) {
            await knex('users')
                .where('id', user.id)
                .update({ full_name: user.name });
        }

        lastId = users[users.length - 1].id;
    }
};
```

#### Phase 3: Contract (Remove Old Column)

```javascript
// ✅ GOOD - Step 3: Make new column required, drop old
exports.up = async function(knex) {
    await knex.schema.table('users', (table) => {
        table.string('full_name').notNullable().alter();
    });

    // After deploying code that only uses full_name
    await knex.schema.table('users', (table) => {
        table.dropColumn('name');
    });
};
```

---

## 4. Renaming Columns/Tables

### Safe Column Rename

```javascript
// ❌ BAD - Direct rename causes downtime
exports.up = function(knex) {
    return knex.schema.table('users', (table) => {
        table.renameColumn('name', 'full_name');
    });
};

// ✅ GOOD - Multi-step rename
// Step 1: Add new column
exports.up = function(knex) {
    return knex.schema.table('users', (table) => {
        table.string('full_name').nullable();
    });
};

// Step 2: Dual writes (app code)
await db.users.update({
    name: newName,
    full_name: newName  // Write to both
});

// Step 3: Backfill data (migration)
exports.up = function(knex) {
    return knex.raw('UPDATE users SET full_name = name WHERE full_name IS NULL');
};

// Step 4: Make new column required
exports.up = function(knex) {
    return knex.schema.table('users', (table) => {
        table.string('full_name').notNullable().alter();
    });
};

// Step 5: Drop old column (after deploying code that only uses full_name)
exports.up = function(knex) {
    return knex.schema.table('users', (table) => {
        table.dropColumn('name');
    });
};
```

---

## 5. Data Transformation Migrations

### Large Data Migrations

```javascript
// ✅ GOOD - Batch processing for large tables
exports.up = async function(knex) {
    const batchSize = 1000;
    let offset = 0;

    while (true) {
        const users = await knex('users')
            .limit(batchSize)
            .offset(offset);

        if (users.length === 0) break;

        for (const user of users) {
            // Transform data
            const normalizedEmail = user.email.toLowerCase().trim();

            await knex('users')
                .where('id', user.id)
                .update({ email: normalizedEmail });
        }

        offset += batchSize;

        // Optional: Add delay to reduce load
        await new Promise(resolve => setTimeout(resolve, 100));
    }
};
```

---

## 6. Index Management

### Adding Indexes Without Blocking

```sql
-- ✅ GOOD - PostgreSQL concurrent index
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- ✅ GOOD - MySQL online DDL (MySQL 5.6+)
ALTER TABLE users ADD INDEX idx_email (email), ALGORITHM=INPLACE, LOCK=NONE;
```

```javascript
// ✅ GOOD - Knex concurrent index
exports.up = function(knex) {
    return knex.raw(
        'CREATE INDEX CONCURRENTLY idx_users_email ON users(email)'
    );
};

exports.down = function(knex) {
    return knex.raw(
        'DROP INDEX CONCURRENTLY idx_users_email'
    );
};
```

---

## 7. Seeding Data

### Database Seeds

```javascript
// ✅ GOOD - Idempotent seed
// seeds/01_users.js
exports.seed = async function(knex) {
    // Delete existing data (dev/test only)
    await knex('users').del();

    // Insert seed data
    await knex('users').insert([
        {
            email: 'admin@example.com',
            name: 'Admin User',
            role: 'admin'
        },
        {
            email: 'user@example.com',
            name: 'Regular User',
            role: 'user'
        }
    ]);
};
```

---

## 8. Migration Testing

### Test Migrations Locally

```bash
# ✅ GOOD - Test migration workflow
# Run migration
npm run migrate:up

# Verify schema
npm run db:schema

# Test rollback
npm run migrate:down

# Re-apply migration
npm run migrate:up

# Run application tests
npm test
```

### Migration Test Script

```javascript
// ✅ GOOD - Automated migration test
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

async function testMigration() {
    try {
        // Apply migration
        await execPromise('npm run migrate:up');
        console.log('✅ Migration applied');

        // Run tests
        await execPromise('npm test');
        console.log('✅ Tests passed');

        // Rollback
        await execPromise('npm run migrate:down');
        console.log('✅ Rollback successful');

        // Re-apply
        await execPromise('npm run migrate:up');
        console.log('✅ Re-apply successful');

    } catch (error) {
        console.error('❌ Migration test failed:', error);
        process.exit(1);
    }
}

testMigration();
```

---

## 9. Copilot Instructions

When generating migrations, Copilot **MUST**:

1. **CREATE** both up and down functions
2. **USE** transactions for consistency
3. **BATCH** large data updates
4. **ADD** indexes concurrently (PostgreSQL)
5. **INCLUDE** default values for new columns
6. **AVOID** direct renames (use multi-step)
7. **TEST** rollback before production

---

## 10. Checklist

### Before Migration
- [ ] Migration tested locally
- [ ] Rollback tested
- [ ] Backup created
- [ ] Deployment plan documented
- [ ] Team notified

### Migration File
- [ ] Up function implemented
- [ ] Down function implemented
- [ ] Idempotent (safe to run multiple times)
- [ ] Uses transactions
- [ ] Includes appropriate indexes

### For Breaking Changes
- [ ] Multi-step migration planned
- [ ] Old and new columns coexist
- [ ] Dual writes implemented
- [ ] Backfill completed
- [ ] Old column removal scheduled

### After Migration
- [ ] Schema verified
- [ ] Data integrity checked
- [ ] Application tests passed
- [ ] Performance monitored

---

## References

- Refactoring Databases - Scott Ambler & Pramod Sadalage
- Knex.js Documentation
- Database Reliability Engineering - Laine Campbell & Charity Majors

**Remember:** Migrations are permanent. Test twice, deploy once.
