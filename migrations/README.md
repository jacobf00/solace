# Database Migrations

This directory contains SQL migration files for the Solace application database schema using [golang-migrate/migrate](https://github.com/golang-migrate/migrate).

## Migration Files

- `000001_initial_schema.up.sql` / `000001_initial_schema.down.sql` - Core application tables (users, problems, verses, reading_plans, reading_plan_items)
- `000002_add_pgvector_extension.up.sql` / `000002_add_pgvector_extension.down.sql` - Add pgvector extension and embedding support
- `000003_add_auth_tables.up.sql` / `000003_add_auth_tables.down.sql` - Authentication and session management tables
- `000004_add_audit_and_ai_tables.up.sql` / `000004_add_audit_and_ai_tables.down.sql` - Audit logging and AI event tracking
- `000005_import_verses_data.up.sql` / `000005_import_verses_data.down.sql` - Import Bible verses from ASV.csv
- `000006_add_triggers_and_functions.up.sql` / `000006_add_triggers_and_functions.down.sql` - Database triggers and utility functions

## Migration Best Practices

### File Naming Convention
- Use sequential numbering: `000001_`, `000002_`, etc. (6 digits with leading zeros)
- Use descriptive names: `add_user_table`, `create_indexes`
- Use snake_case for file names
- Each migration has both `.up.sql` and `.down.sql` files

### Migration Structure
Each migration file should include:
1. Header comment with migration number, description, and date
2. `CREATE EXTENSION` statements if needed
3. `CREATE TABLE` statements with proper constraints
4. `CREATE INDEX` statements for performance
5. `COMMENT` statements for documentation
6. Data migration if needed

### Safety Guidelines
- Always use `IF NOT EXISTS` for extensions
- Use `IF NOT EXISTS` for tables when appropriate
- Include proper foreign key constraints
- Add indexes for performance
- Include rollback considerations in comments
- Always provide both up and down migrations

### Running Migrations

#### Using golang-migrate CLI (Recommended)
```bash
# Install golang-migrate CLI
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Run all pending migrations
migrate -path migrations -database "postgres://user:password@localhost:5432/dbname?sslmode=disable" up

# Run specific number of migrations
migrate -path migrations -database "postgres://user:password@localhost:5432/dbname?sslmode=disable" up 2

# Rollback last migration
migrate -path migrations -database "postgres://user:password@localhost:5432/dbname?sslmode=disable" down 1

# Check migration status
migrate -path migrations -database "postgres://user:password@localhost:5432/dbname?sslmode=disable" version

# Create new migration
migrate create -ext sql -dir migrations -seq migration_name
```

#### Using Makefile (Convenient)
```bash
# Run all pending migrations
make migrate-up

# Rollback last migration
make migrate-down

# Check migration status
make migrate-status

# Create new migration
make migrate-create NAME=migration_name
```


## Database Schema Overview

### Core Tables
- **users** - User accounts and authentication
- **problems** - User-submitted life problems
- **verses** - Bible verses with embeddings for AI search
- **reading_plans** - Generated reading plans for problems
- **reading_plan_items** - Individual verses within reading plans

### Authentication Tables
- **sessions** - JWT session tracking
- **refresh_tokens** - JWT refresh token management
- **password_resets** - Password reset functionality
- **email_verifications** - Email verification

### Audit & AI Tables
- **audit_logs** - User action audit trail
- **ai_events** - AI operation tracking and metrics
- **advice_feedback** - User feedback on AI advice
- **plan_revisions** - Reading plan version history
- **verse_topics** - AI-generated verse topic classifications

## Environment Variables

Set these environment variables for database connection:
```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=your_username
export DB_PASSWORD=your_password
export DB_NAME=postgres
export DB_SSLMODE=disable
```

## Prerequisites

- PostgreSQL 13+ with pgvector extension
- golang-migrate CLI (install with `make deps` or `go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest`)
- ASV.csv file in project root (for verse import)
