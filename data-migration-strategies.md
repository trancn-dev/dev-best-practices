# Data Migration Strategies - Chiến Lược Di Chuyển Dữ Liệu

> Best practices cho database migration, zero-downtime deployment, và data versioning
>
> **Mục đích**: Di chuyển dữ liệu an toàn, không downtime, có khả năng rollback

---

## 📋 Mục Lục
- [Migration Types](#migration-types)
- [Zero-Downtime Migrations](#zero-downtime-migrations)
- [Schema Versioning](#schema-versioning)
- [Data Transformation](#data-transformation)
- [Rollback Strategies](#rollback-strategies)
- [Migration Tools](#migration-tools)
- [Testing Migrations](#testing-migrations)

---

## 🔄 MIGRATION TYPES

### Schema Migration

```sql
-- ✅ GOOD - Adding column with default
ALTER TABLE users
ADD COLUMN phone VARCHAR(20) DEFAULT NULL;

-- ✅ GOOD - Making non-nullable in steps
-- Step 1: Add nullable column
ALTER TABLE users ADD COLUMN email VARCHAR(255);

-- Step 2: Backfill data
UPDATE users SET email = CONCAT(username, '@example.com')
WHERE email IS NULL;

-- Step 3: Add constraint
ALTER TABLE users ALTER COLUMN email SET NOT NULL;

-- ❌ BAD - Direct non-nullable addition (fails if data exists)
ALTER TABLE users ADD COLUMN email VARCHAR(255) NOT NULL;
```

### Data Migration

```javascript
// ✅ GOOD - Batch migration with progress tracking
async function migrateUserData() {
    const batchSize = 1000;
    let offset = 0;
    let processed = 0;

    const total = await db.users.countDocuments({ migrated: { $ne: true } });
    console.log(`Starting migration of ${total} users...`);

    while (true) {
        const users = await db.users
            .find({ migrated: { $ne: true } })
            .limit(batchSize)
            .toArray();

        if (users.length === 0) break;

        const operations = users.map(user => ({
            updateOne: {
                filter: { _id: user._id },
                update: {
                    $set: {
                        full_name: `${user.first_name} ${user.last_name}`,
                        migrated: true,
                        migrated_at: new Date()
                    }
                }
            }
        }));

        await db.users.bulkWrite(operations);

        processed += users.length;
        console.log(`Progress: ${processed}/${total} (${(processed/total*100).toFixed(1)}%)`);

        // Avoid overwhelming the database
        await new Promise(resolve => setTimeout(resolve, 100));
    }

    console.log('Migration completed!');
}
```

### Backward Compatible Migration

```javascript
// ✅ GOOD - Multi-phase migration
// Phase 1: Support both old and new formats
class User {
    get fullName() {
        // Support new format
        if (this.full_name) {
            return this.full_name;
        }
        // Fallback to old format
        return `${this.first_name} ${this.last_name}`;
    }

    set fullName(value) {
        this.full_name = value;
        // Also update old fields for backward compatibility
        const parts = value.split(' ');
        this.first_name = parts[0];
        this.last_name = parts.slice(1).join(' ');
    }
}

// Phase 2: Migrate data (background job)
// Phase 3: Remove old fields after all data migrated
```

---

## ⚡ ZERO-DOWNTIME MIGRATIONS

### Expand-Contract Pattern

```
Phase 1: EXPAND
- Add new column/table
- Deploy code that writes to both old and new
- Backfill data to new structure

Phase 2: MIGRATE
- Verify data integrity
- Monitor performance

Phase 3: CONTRACT
- Deploy code that reads from new only
- Remove old column/table
```

### Example: Renaming a Column

```sql
-- ✅ GOOD - Zero-downtime column rename

-- PHASE 1: EXPAND (Add new column)
ALTER TABLE users ADD COLUMN email_address VARCHAR(255);

-- Deploy application code v1:
-- - Writes to both 'email' and 'email_address'
-- - Reads from 'email' (fallback to 'email_address')
```

```javascript
// Application code v1
async function updateUser(userId, data) {
    if (data.email) {
        // Write to both columns
        await db.query(`
            UPDATE users
            SET email = $1, email_address = $1
            WHERE id = $2
        `, [data.email, userId]);
    }
}

async function getUser(userId) {
    const user = await db.query(`
        SELECT
            id,
            name,
            COALESCE(email, email_address) as email
        FROM users
        WHERE id = $1
    `, [userId]);
    return user;
}
```

```sql
-- PHASE 2: BACKFILL
-- Copy data from old to new column
UPDATE users
SET email_address = email
WHERE email_address IS NULL AND email IS NOT NULL;

-- Verify
SELECT COUNT(*) FROM users WHERE email IS NOT NULL AND email_address IS NULL;
-- Should return 0
```

```javascript
// Deploy application code v2:
// - Reads from 'email_address'
// - Still writes to both (for safety)

async function getUser(userId) {
    const user = await db.query(`
        SELECT id, name, email_address as email
        FROM users
        WHERE id = $1
    `, [userId]);
    return user;
}
```

```sql
-- PHASE 3: CONTRACT (Remove old column)
-- After monitoring for a few days/weeks
ALTER TABLE users DROP COLUMN email;

-- Deploy application code v3:
-- - Only uses 'email_address'
```

### Adding an Index (Zero-Downtime)

```sql
-- ✅ GOOD - Non-blocking index creation

-- PostgreSQL
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- MySQL
ALTER TABLE users
ADD INDEX idx_users_email (email)
ALGORITHM=INPLACE, LOCK=NONE;

-- ❌ BAD - Blocking index (locks table)
CREATE INDEX idx_users_email ON users(email);
```

---

## 📦 SCHEMA VERSIONING

### Migration Files Structure

```
migrations/
├── 001_create_users_table.sql
├── 002_add_users_email.sql
├── 003_create_orders_table.sql
├── 004_add_orders_status_index.sql
└── 005_migrate_user_profiles.js

Each file contains:
- Up migration (apply changes)
- Down migration (rollback)
- Timestamp/version number
```

### SQL Migration Example

```sql
-- ✅ GOOD - 001_create_users_table.sql

-- UP
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- DOWN
DROP INDEX IF EXISTS idx_users_created_at;
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;
```

### Programmatic Migration (Node.js)

```javascript
// ✅ GOOD - migrations/003_migrate_user_data.js

module.exports = {
    up: async (db) => {
        console.log('Starting user data migration...');

        // Create new collection
        await db.createCollection('user_profiles');

        // Migrate data
        const users = await db.collection('users').find({}).toArray();

        for (const user of users) {
            await db.collection('user_profiles').insertOne({
                user_id: user._id,
                bio: user.bio || '',
                avatar_url: user.avatar || null,
                preferences: {
                    theme: 'light',
                    language: 'en'
                },
                created_at: user.created_at
            });
        }

        console.log(`Migrated ${users.length} user profiles`);
    },

    down: async (db) => {
        console.log('Rolling back user data migration...');
        await db.collection('user_profiles').drop();
        console.log('Rollback complete');
    }
};
```

### Migration Tracking Table

```sql
-- ✅ GOOD - Track applied migrations
CREATE TABLE schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    execution_time INTEGER,  -- milliseconds
    checksum VARCHAR(64)     -- MD5 hash of migration file
);

-- Check current version
SELECT version, name, applied_at
FROM schema_migrations
ORDER BY applied_at DESC
LIMIT 1;
```

---

## 🔀 DATA TRANSFORMATION

### ETL Pattern (Extract, Transform, Load)

```javascript
// ✅ GOOD - ETL pipeline for data migration

class DataMigrationPipeline {
    constructor(source, destination) {
        this.source = source;
        this.destination = destination;
    }

    // Extract
    async *extract(batchSize = 1000) {
        let offset = 0;

        while (true) {
            const batch = await this.source.find({})
                .skip(offset)
                .limit(batchSize)
                .toArray();

            if (batch.length === 0) break;

            yield batch;
            offset += batchSize;
        }
    }

    // Transform
    transform(record) {
        return {
            id: record._id,
            full_name: `${record.first_name} ${record.last_name}`,
            email: record.email.toLowerCase(),
            phone: this.normalizePhone(record.phone),
            metadata: {
                legacy_id: record.old_id,
                migrated_at: new Date()
            }
        };
    }

    // Load
    async load(records) {
        if (records.length === 0) return;

        await this.destination.insertMany(records, {
            ordered: false  // Continue on errors
        });
    }

    // Execute pipeline
    async run() {
        let total = 0;
        let errors = [];

        for await (const batch of this.extract()) {
            try {
                const transformed = batch.map(r => this.transform(r));
                await this.load(transformed);
                total += batch.length;
                console.log(`Processed ${total} records`);
            } catch (error) {
                errors.push({ batch, error: error.message });
                console.error(`Error in batch: ${error.message}`);
            }
        }

        return { total, errors };
    }

    normalizePhone(phone) {
        if (!phone) return null;
        return phone.replace(/\D/g, '');  // Remove non-digits
    }
}

// Usage
const pipeline = new DataMigrationPipeline(
    db.collection('legacy_users'),
    db.collection('users')
);

const result = await pipeline.run();
console.log(`Migration complete: ${result.total} records, ${result.errors.length} errors`);
```

### Data Validation

```javascript
// ✅ GOOD - Validate data before and after migration

class MigrationValidator {
    async validateBefore(sourceDb) {
        const checks = {
            totalRecords: await sourceDb.users.countDocuments(),
            uniqueEmails: await sourceDb.users.distinct('email').length,
            nullEmails: await sourceDb.users.countDocuments({ email: null }),
            duplicateEmails: await this.findDuplicates(sourceDb, 'email')
        };

        console.log('Pre-migration checks:', checks);

        if (checks.nullEmails > 0) {
            throw new Error(`Found ${checks.nullEmails} users without email`);
        }

        return checks;
    }

    async validateAfter(sourceDb, targetDb, preMigrationChecks) {
        const checks = {
            totalRecords: await targetDb.users.countDocuments(),
            uniqueEmails: await targetDb.users.distinct('email').length,
            nullEmails: await targetDb.users.countDocuments({ email: null })
        };

        console.log('Post-migration checks:', checks);

        // Verify counts match
        if (checks.totalRecords !== preMigrationChecks.totalRecords) {
            throw new Error('Record count mismatch!');
        }

        if (checks.uniqueEmails !== preMigrationChecks.uniqueEmails) {
            throw new Error('Unique email count mismatch!');
        }

        return checks;
    }

    async findDuplicates(db, field) {
        const duplicates = await db.users.aggregate([
            { $group: { _id: `$${field}`, count: { $sum: 1 } } },
            { $match: { count: { $gt: 1 } } }
        ]).toArray();

        return duplicates;
    }
}
```

---

## ↩️ ROLLBACK STRATEGIES

### Automatic Rollback

```javascript
// ✅ GOOD - Transaction with automatic rollback

async function migrateWithRollback() {
    const session = client.startSession();

    try {
        await session.withTransaction(async () => {
            // Migration operations
            await db.users.updateMany(
                { version: 1 },
                {
                    $set: { version: 2 },
                    $rename: { 'oldField': 'newField' }
                },
                { session }
            );

            // Validation
            const invalidCount = await db.users.countDocuments(
                { version: 2, newField: null },
                { session }
            );

            if (invalidCount > 0) {
                throw new Error(`Found ${invalidCount} invalid records`);
            }

            console.log('Migration successful');
        });
    } catch (error) {
        console.error('Migration failed, rolled back:', error);
        throw error;
    } finally {
        await session.endSession();
    }
}
```

### Manual Rollback with Backup

```bash
# ✅ GOOD - Backup before migration

# PostgreSQL backup
pg_dump -U postgres -d myapp -F c -f backup_before_migration_$(date +%Y%m%d_%H%M%S).dump

# Run migration
psql -U postgres -d myapp -f migration_005.sql

# If rollback needed
pg_restore -U postgres -d myapp -c backup_before_migration_20250101_120000.dump

# MongoDB backup
mongodump --db myapp --out backup_$(date +%Y%m%d_%H%M%S)

# Run migration
node migrations/005_migrate_data.js

# If rollback needed
mongorestore --db myapp --drop backup_20250101_120000/myapp
```

### Point-in-Time Recovery

```javascript
// ✅ GOOD - Track migration state for partial rollback

class MigrationTracker {
    async trackProgress(migrationId, recordId, status) {
        await db.migration_progress.insertOne({
            migration_id: migrationId,
            record_id: recordId,
            status: status,  // 'processing', 'completed', 'failed'
            timestamp: new Date()
        });
    }

    async rollbackPartial(migrationId) {
        // Find all records that were migrated
        const completed = await db.migration_progress.find({
            migration_id: migrationId,
            status: 'completed'
        }).toArray();

        console.log(`Rolling back ${completed.length} records...`);

        for (const record of completed) {
            try {
                await this.rollbackRecord(record.record_id);
                await db.migration_progress.updateOne(
                    { _id: record._id },
                    { $set: { status: 'rolled_back' } }
                );
            } catch (error) {
                console.error(`Failed to rollback ${record.record_id}:`, error);
            }
        }
    }

    async rollbackRecord(recordId) {
        // Revert changes for specific record
        await db.users.updateOne(
            { _id: recordId },
            { $unset: { new_field: '' }, $set: { version: 1 } }
        );
    }
}
```

---

## 🛠️ MIGRATION TOOLS

### Node.js - Knex Migrations

```javascript
// ✅ GOOD - knexfile.js
module.exports = {
    development: {
        client: 'postgresql',
        connection: {
            database: 'myapp_dev',
            user: 'postgres',
            password: 'password'
        },
        migrations: {
            directory: './migrations',
            tableName: 'knex_migrations'
        }
    }
};

// migrations/20250101_create_users.js
exports.up = function(knex) {
    return knex.schema.createTable('users', table => {
        table.bigIncrements('id').primary();
        table.string('username', 50).unique().notNullable();
        table.string('email', 255).unique().notNullable();
        table.timestamps(true, true);
    });
};

exports.down = function(knex) {
    return knex.schema.dropTable('users');
};

// Run migrations
// npx knex migrate:latest
// npx knex migrate:rollback
```

### Python - Alembic

```python
# ✅ GOOD - Alembic migration

# migrations/versions/001_create_users.py
from alembic import op
import sqlalchemy as sa

def upgrade():
    op.create_table(
        'users',
        sa.Column('id', sa.BigInteger(), primary_key=True),
        sa.Column('username', sa.String(50), unique=True, nullable=False),
        sa.Column('email', sa.String(255), unique=True, nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now())
    )

    op.create_index('idx_users_email', 'users', ['email'])

def downgrade():
    op.drop_index('idx_users_email')
    op.drop_table('users')

# Run: alembic upgrade head
# Rollback: alembic downgrade -1
```

### Ruby on Rails - Active Record

```ruby
# ✅ GOOD - Rails migration

# db/migrate/20250101_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :username, null: false, limit: 50
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
  end
end

# Run: rails db:migrate
# Rollback: rails db:rollback
```

### Flyway (Java)

```sql
-- ✅ GOOD - V1__Create_users_table.sql

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);

-- Run: flyway migrate
-- Repair: flyway repair
```

---

## 🧪 TESTING MIGRATIONS

### Migration Testing Checklist

```javascript
// ✅ GOOD - Test suite for migrations

describe('User Migration', () => {
    let db;

    beforeEach(async () => {
        // Setup test database
        db = await setupTestDb();
        await seedTestData(db);
    });

    afterEach(async () => {
        await db.close();
    });

    it('should migrate all users successfully', async () => {
        const beforeCount = await db.users.countDocuments();

        await runMigration('005_migrate_users');

        const afterCount = await db.users.countDocuments();
        expect(afterCount).toBe(beforeCount);
    });

    it('should transform data correctly', async () => {
        await db.users.insertOne({
            first_name: 'John',
            last_name: 'Doe',
            email: 'JOHN@EXAMPLE.COM'
        });

        await runMigration('005_migrate_users');

        const user = await db.users.findOne({ email: 'john@example.com' });
        expect(user.full_name).toBe('John Doe');
        expect(user.email).toBe('john@example.com');
    });

    it('should be idempotent', async () => {
        await runMigration('005_migrate_users');
        const firstRun = await db.users.find({}).toArray();

        await runMigration('005_migrate_users');
        const secondRun = await db.users.find({}).toArray();

        expect(secondRun).toEqual(firstRun);
    });

    it('should rollback on error', async () => {
        const beforeState = await db.users.find({}).toArray();

        try {
            await runMigration('006_failing_migration');
        } catch (error) {
            // Expected to fail
        }

        const afterState = await db.users.find({}).toArray();
        expect(afterState).toEqual(beforeState);
    });
});
```

### Load Testing

```javascript
// ✅ GOOD - Performance testing

async function testMigrationPerformance() {
    const testSizes = [1000, 10000, 100000];

    for (const size of testSizes) {
        console.log(`Testing with ${size} records...`);

        // Create test data
        await seedLargeDataset(size);

        const startTime = Date.now();
        await runMigration('005_migrate_users');
        const duration = Date.now() - startTime;

        console.log(`Completed in ${duration}ms (${(size/duration*1000).toFixed(0)} records/sec)`);

        // Cleanup
        await db.users.deleteMany({});
    }
}
```

---

## 📝 MIGRATION BEST PRACTICES

### ✅ DO

- ✅ Always backup before migration
- ✅ Test migrations on staging first
- ✅ Make migrations reversible
- ✅ Use transactions when possible
- ✅ Migrate in small batches
- ✅ Monitor during migration
- ✅ Version control migrations
- ✅ Document complex migrations
- ✅ Validate data integrity
- ✅ Plan for zero-downtime

### ❌ DON'T

- ❌ Run migrations without backup
- ❌ Mix data and schema changes
- ❌ Skip testing on staging
- ❌ Ignore rollback strategy
- ❌ Migrate everything at once
- ❌ Forget to track progress
- ❌ Use direct SQL in production
- ❌ Ignore performance impact

---

## 🚀 MIGRATION CHECKLIST

```
Pre-Migration:
□ Backup database
□ Test on staging environment
□ Review migration code
□ Prepare rollback plan
□ Schedule during low traffic
□ Alert team members
□ Monitor setup ready

During Migration:
□ Run migration
□ Monitor database performance
□ Check error logs
□ Validate sample records
□ Track progress

Post-Migration:
□ Verify data integrity
□ Run test suite
□ Monitor application metrics
□ Check for errors
□ Document any issues
□ Keep backup for N days
□ Update documentation
```

---

## 📚 REFERENCES

- [Flyway Documentation](https://flywaydb.org/documentation/)
- [Liquibase Best Practices](https://www.liquibase.org/get-started/best-practices)
- [Alembic Tutorial](https://alembic.sqlalchemy.org/en/latest/tutorial.html)
- [Rails Migrations Guide](https://guides.rubyonrails.org/active_record_migrations.html)
- [MongoDB Migration Patterns](https://www.mongodb.com/docs/manual/tutorial/migrate-sharded-cluster-to-new-hardware/)

---

*Document Version: 1.0*
*Last Updated: 2025-11-01*
