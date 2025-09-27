#!/bin/bash

# Database Setup Script for Solace Application
# This script sets up the PostgreSQL database with all required extensions and migrations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-$USER}
DB_NAME=${DB_NAME:-postgres}
DB_SSLMODE=${DB_SSLMODE:-disable}

echo -e "${GREEN}Setting up Solace database...${NC}"

# Check if PostgreSQL is running
echo -e "${YELLOW}Checking PostgreSQL connection...${NC}"
if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to PostgreSQL database${NC}"
    echo "Please ensure PostgreSQL is running and accessible"
    echo "Connection details: host=$DB_HOST port=$DB_PORT user=$DB_USER dbname=$DB_NAME"
    exit 1
fi

echo -e "${GREEN}PostgreSQL connection successful${NC}"

# Check if pgvector extension is available
echo -e "${YELLOW}Checking for pgvector extension...${NC}"
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1 FROM pg_extension WHERE extname = 'vector';" | grep -q "1"; then
    echo -e "${YELLOW}Installing pgvector extension...${NC}"
    
    # Try to install pgvector (this might require superuser privileges)
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>/dev/null; then
        echo -e "${GREEN}pgvector extension installed successfully${NC}"
    else
        echo -e "${RED}Error: Failed to install pgvector extension${NC}"
        echo "Please install pgvector manually or run as a superuser:"
        echo "  CREATE EXTENSION vector;"
        exit 1
    fi
else
    echo -e "${GREEN}pgvector extension already installed${NC}"
fi

# Check if ASV.csv exists
if [ ! -f "ASV.csv" ]; then
    echo -e "${YELLOW}Warning: ASV.csv not found in project root${NC}"
    echo "The verse import migration will be skipped"
    echo "Please ensure ASV.csv is available for the verse import migration"
fi

# Check if go tool migrate is available
echo -e "${YELLOW}Checking for go tool migrate...${NC}"
if ! go tool migrate -help >/dev/null 2>&1; then
    echo -e "${RED}Error: go tool migrate not available${NC}"
    echo "Please ensure Go is installed and the migrate tool is available"
    echo "  or run: make deps"
    exit 1
fi

echo -e "${GREEN}go tool migrate found${NC}"

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"

# Create database URL
DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}"

# Run migrations
if go tool migrate -path migrations -database "$DB_URL" up; then
    echo -e "${GREEN}✓ Migrations completed successfully${NC}"
else
    echo -e "${RED}✗ Migration failed${NC}"
    exit 1
fi

# Verify database setup
echo -e "${YELLOW}Verifying database setup...${NC}"

# Check if all tables exist
tables=("users" "problems" "verses" "reading_plans" "reading_plan_items" "sessions" "refresh_tokens" "audit_logs" "ai_events")
for table in "${tables[@]}"; do
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1 FROM information_schema.tables WHERE table_name = '$table';" | grep -q "1"; then
        echo -e "${GREEN}✓ Table '$table' exists${NC}"
    else
        echo -e "${RED}✗ Table '$table' missing${NC}"
        exit 1
    fi
done

# Check if verses table has data
verse_count=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM verses;" 2>/dev/null | tr -d ' ')
if [ -n "$verse_count" ] && [ "$verse_count" -gt 0 ]; then
    echo -e "${GREEN}✓ Verses table contains $verse_count records${NC}"
else
    echo -e "${YELLOW}⚠ Verses table is empty (ASV.csv import may have been skipped)${NC}"
fi

echo -e "${GREEN}Database setup completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Start the Go server: go run server.go"
echo "2. Start the Svelte client: cd client && npm run dev"
echo "3. Access the application at http://localhost:5173"
