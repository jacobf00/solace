package testutils

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	_ "github.com/mattn/go-sqlite3"
)

// TestDBConfig holds configuration for test database
type TestDBConfig struct {
	Driver   string
	DSN      string
	Migrate  bool
	SeedData bool
}

// NewTestDB creates a new test database connection
func NewTestDB(t testing.TB, config TestDBConfig) *sql.DB {
	db, err := sql.Open(config.Driver, config.DSN)
	if err != nil {
		if t, ok := t.(*testing.T); ok {
			t.Fatalf("Failed to open test database: %v", err)
		} else {
			panic(err)
		}
	}

	// Test the connection
	err = db.Ping()
	if err != nil {
		if t, ok := t.(*testing.T); ok {
			t.Fatalf("Failed to ping test database: %v", err)
		} else {
			panic(err)
		}
	}

	// Run migrations if requested
	if config.Migrate {
		err = runMigrations(db)
		if err != nil {
			if t, ok := t.(*testing.T); ok {
				t.Fatalf("Failed to run migrations: %v", err)
			} else {
				panic(err)
			}
		}
	}

	// Seed test data if requested
	if config.SeedData {
		err = seedTestData(db)
		if err != nil {
			if t, ok := t.(*testing.T); ok {
				t.Fatalf("Failed to seed test data: %v", err)
			} else {
				panic(err)
			}
		}
	}

	return db
}

// NewSQLiteTestDB creates a new SQLite test database
func NewSQLiteTestDB(t testing.TB) *sql.DB {
	// Create a temporary file for the database
	var tmpDir string
	if t, ok := t.(*testing.T); ok {
		tmpDir = t.TempDir()
	} else {
		// For benchmarks, create a temporary directory manually
		var err error
		tmpDir, err = os.MkdirTemp("", "testdb")
		if err != nil {
			panic(err)
		}
	}
	
	dbPath := filepath.Join(tmpDir, "test.db")

	config := TestDBConfig{
		Driver:   "sqlite3",
		DSN:      dbPath,
		Migrate:  true,
		SeedData: true,
	}

	return NewTestDB(t, config)
}

// NewMockDB creates a mock database for unit tests
func NewMockDB(t *testing.T) (*sql.DB, error) {
	t.Helper()
	// This will be implemented with go-sqlmock
	return nil, fmt.Errorf("mock database not implemented yet")
}

// runMigrations runs the database migrations
func runMigrations(db *sql.DB) error {
	// Read migration files and execute them
	migrationFiles := []string{
		"000001_initial_schema.up.sql",
		"000002_add_pgvector_extension.down.sql", // Skip pgvector for SQLite
		"000003_add_auth_tables.up.sql",
		"000004_add_audit_and_ai_tables.up.sql",
		"000005_import_verses_data.up.sql",
		"000006_add_triggers_and_functions.down.sql", // Skip triggers for SQLite
	}

	// Get the current working directory and find migrations
	wd, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("failed to get working directory: %w", err)
	}

	// Look for migrations directory
	migrationDir := filepath.Join(wd, "migrations")
	if _, err := os.Stat(migrationDir); os.IsNotExist(err) {
		// Try going up one level
		migrationDir = filepath.Join(wd, "..", "migrations")
		if _, err := os.Stat(migrationDir); os.IsNotExist(err) {
			return fmt.Errorf("migrations directory not found")
		}
	}

	for _, file := range migrationFiles {
		if filepath.Ext(file) == ".down.sql" {
			continue // Skip down migrations for tests
		}

		content, err := os.ReadFile(filepath.Join(migrationDir, file))
		if err != nil {
			return fmt.Errorf("failed to read migration file %s: %w", file, err)
		}

		// Skip pgvector and trigger migrations for SQLite
		if strings.Contains(string(content), "CREATE EXTENSION") || 
		   strings.Contains(string(content), "CREATE TRIGGER") ||
		   strings.Contains(string(content), "CREATE FUNCTION") ||
		   strings.Contains(string(content), "DROP EXTENSION") {
			continue
		}

		_, err = db.Exec(string(content))
		if err != nil {
			return fmt.Errorf("failed to execute migration %s: %w", file, err)
		}
	}

	return nil
}

// seedTestData seeds the database with test data
func seedTestData(db *sql.DB) error {
	// Insert test users
	users := []struct {
		username string
		email    string
		password string
	}{
		{"testuser1", "test1@example.com", "password123"},
		{"testuser2", "test2@example.com", "password456"},
	}

	for _, user := range users {
		_, err := db.Exec(
			"INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
			user.username, user.email, user.password,
		)
		if err != nil {
			return fmt.Errorf("failed to insert test user: %w", err)
		}
	}

	// Insert test problems
	problems := []struct {
		userID      int
		title       string
		description string
		context     *string
		category    *string
	}{
		{1, "Test Problem 1", "This is a test problem", StringPtr("work"), StringPtr("stress")},
		{1, "Test Problem 2", "Another test problem", StringPtr("personal"), StringPtr("anxiety")},
		{2, "Test Problem 3", "Third test problem", nil, nil},
	}

	for _, problem := range problems {
		_, err := db.Exec(
			"INSERT INTO problems (user_id, title, description, context, category) VALUES (?, ?, ?, ?, ?)",
			problem.userID, problem.title, problem.description, problem.context, problem.category,
		)
		if err != nil {
			return fmt.Errorf("failed to insert test problem: %w", err)
		}
	}

	// Insert test verses
	verses := []struct {
		book    string
		chapter int
		verse   int
		text    string
	}{
		{"John", 3, 16, "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."},
		{"Psalm", 23, 1, "The Lord is my shepherd, I lack nothing."},
		{"Matthew", 11, 28, "Come to me, all you who are weary and burdened, and I will give you rest."},
	}

	for _, verse := range verses {
		_, err := db.Exec(
			"INSERT INTO verses (book, chapter, verse, text) VALUES (?, ?, ?, ?)",
			verse.book, verse.chapter, verse.verse, verse.text,
		)
		if err != nil {
			return fmt.Errorf("failed to insert test verse: %w", err)
		}
	}

	// Insert test reading plans
	_, err := db.Exec(
		"INSERT INTO reading_plans (problem_id, created_at) VALUES (?, datetime('now'))",
		1,
	)
	if err != nil {
		return fmt.Errorf("failed to insert test reading plan: %w", err)
	}

	// Insert test reading plan items
	readingPlanItems := []struct {
		readingPlanID int
		verseID       int
		itemOrder     int32
		isRead        bool
	}{
		{1, 1, 1, false},
		{1, 2, 2, true},
		{1, 3, 3, false},
	}

	for _, item := range readingPlanItems {
		_, err := db.Exec(
			"INSERT INTO reading_plan_items (reading_plan_id, verse_id, item_order, is_read) VALUES (?, ?, ?, ?)",
			item.readingPlanID, item.verseID, item.itemOrder, item.isRead,
		)
		if err != nil {
			return fmt.Errorf("failed to insert test reading plan item: %w", err)
		}
	}

	return nil
}

// StringPtr returns a pointer to a string
func StringPtr(s string) *string {
	return &s
}

// CleanupTestDB cleans up test database resources
func CleanupTestDB(t testing.TB, db *sql.DB) {
	if db != nil {
		err := db.Close()
		if err != nil {
			if t, ok := t.(*testing.T); ok {
				t.Errorf("Failed to close test database: %v", err)
			} else {
				panic(err)
			}
		}
	}
}
