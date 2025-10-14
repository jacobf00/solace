package testutils

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	_ "github.com/mattn/go-sqlite3"
)

// DatabaseHelper provides utilities for test database operations
type DatabaseHelper struct {
	db *sql.DB
}

// NewDatabaseHelper creates a new database helper
func NewDatabaseHelper(db *sql.DB) *DatabaseHelper {
	return &DatabaseHelper{db: db}
}

// ResetDatabase truncates all tables and resets sequences
func (h *DatabaseHelper) ResetDatabase() error {
	tables := []string{
		"reading_plan_items",
		"reading_plans", 
		"problems",
		"verses",
		"users",
	}

	for _, table := range tables {
		_, err := h.db.Exec(fmt.Sprintf("DELETE FROM %s", table))
		if err != nil {
			return fmt.Errorf("failed to truncate table %s: %w", table, err)
		}
	}

	// Reset SQLite sequences
	_, err := h.db.Exec("DELETE FROM sqlite_sequence")
	if err != nil {
		// Ignore error if table doesn't exist
	}

	return nil
}

// SeedMinimalData seeds the database with minimal test data
func (h *DatabaseHelper) SeedMinimalData() error {
	// Insert a test user
	_, err := h.db.Exec(`
		INSERT INTO users (username, email, password_hash) 
		VALUES ('testuser', 'test@example.com', 'password123')
	`)
	if err != nil {
		return fmt.Errorf("failed to insert test user: %w", err)
	}

	// Insert a test problem
	_, err = h.db.Exec(`
		INSERT INTO problems (user_id, title, description, context, category) 
		VALUES (1, 'Test Problem', 'Test Description', 'work', 'stress')
	`)
	if err != nil {
		return fmt.Errorf("failed to insert test problem: %w", err)
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

	for _, v := range verses {
		_, err = h.db.Exec(`
			INSERT INTO verses (book, chapter, verse, text) 
			VALUES (?, ?, ?, ?)
		`, v.book, v.chapter, v.verse, v.text)
		if err != nil {
			return fmt.Errorf("failed to insert test verse: %w", err)
		}
	}

	// Insert a test reading plan
	_, err = h.db.Exec(`
		INSERT INTO reading_plans (problem_id, created_at) 
		VALUES (1, datetime('now'))
	`)
	if err != nil {
		return fmt.Errorf("failed to insert test reading plan: %w", err)
	}

	// Insert test reading plan items
	items := []struct {
		readingPlanID int
		verseID       int
		itemOrder     int32
		isRead        bool
	}{
		{1, 1, 1, false},
		{1, 2, 2, true},
		{1, 3, 3, false},
	}

	for _, item := range items {
		_, err = h.db.Exec(`
			INSERT INTO reading_plan_items (reading_plan_id, verse_id, item_order, is_read) 
			VALUES (?, ?, ?, ?)
		`, item.readingPlanID, item.verseID, item.itemOrder, item.isRead)
		if err != nil {
			return fmt.Errorf("failed to insert test reading plan item: %w", err)
		}
	}

	return nil
}

// GetTableRowCount returns the number of rows in a table
func (h *DatabaseHelper) GetTableRowCount(tableName string) (int, error) {
	var count int
	err := h.db.QueryRow(fmt.Sprintf("SELECT COUNT(*) FROM %s", tableName)).Scan(&count)
	return count, err
}

// ExecuteSQL executes a SQL statement
func (h *DatabaseHelper) ExecuteSQL(sql string, args ...interface{}) error {
	_, err := h.db.Exec(sql, args...)
	return err
}

// QuerySQL executes a SQL query and returns the result
func (h *DatabaseHelper) QuerySQL(sql string, args ...interface{}) (*sql.Rows, error) {
	return h.db.Query(sql, args...)
}

// GetMigrationFiles returns a list of migration files
func GetMigrationFiles() ([]string, error) {
	migrationDir := filepath.Join("..", "..", "migrations")
	files, err := os.ReadDir(migrationDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read migrations directory: %w", err)
	}

	var migrationFiles []string
	for _, file := range files {
		if strings.HasSuffix(file.Name(), ".up.sql") {
			migrationFiles = append(migrationFiles, filepath.Join(migrationDir, file.Name()))
		}
	}

	return migrationFiles, nil
}

// RunMigrationsFromFiles runs migrations from a list of files
func (h *DatabaseHelper) RunMigrationsFromFiles(files []string) error {
	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			return fmt.Errorf("failed to read migration file %s: %w", file, err)
		}

		// Skip pgvector and trigger migrations for SQLite
		if strings.Contains(string(content), "CREATE EXTENSION") || 
		   strings.Contains(string(content), "CREATE TRIGGER") ||
		   strings.Contains(string(content), "CREATE FUNCTION") {
			continue
		}

		_, err = h.db.Exec(string(content))
		if err != nil {
			return fmt.Errorf("failed to execute migration %s: %w", file, err)
		}
	}

	return nil
}

