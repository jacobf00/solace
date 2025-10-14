package graph

import (
	"context"
	"database/sql"
	"testing"

	_ "github.com/mattn/go-sqlite3"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Simple integration test that creates its own schema
func TestSimpleIntegration(t *testing.T) {
	// Create a temporary SQLite database
	tmpDir := t.TempDir()
	dbPath := tmpDir + "/test.db"
	
	db, err := sql.Open("sqlite3", dbPath)
	require.NoError(t, err)
	defer db.Close()

	// Create simple schema for testing
	schema := `
	CREATE TABLE users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT UNIQUE NOT NULL,
		email TEXT UNIQUE NOT NULL,
		password_hash TEXT NOT NULL
	);

	CREATE TABLE problems (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER NOT NULL,
		title TEXT NOT NULL,
		description TEXT NOT NULL,
		context TEXT,
		category TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		advice TEXT
	);

	CREATE TABLE verses (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		book TEXT NOT NULL,
		chapter INTEGER NOT NULL,
		verse INTEGER NOT NULL,
		text TEXT NOT NULL
	);

	CREATE TABLE reading_plans (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		problem_id INTEGER NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE reading_plan_items (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		reading_plan_id INTEGER NOT NULL,
		verse_id INTEGER NOT NULL,
		item_order INTEGER NOT NULL,
		is_read BOOLEAN DEFAULT FALSE
	);
	`

	_, err = db.Exec(schema)
	require.NoError(t, err)

	// Create resolver
	resolver := &Resolver{DB: db}
	mutationResolver := &mutationResolver{resolver}
	queryResolver := &queryResolver{resolver}

	// Test CreateUser
	t.Run("CreateUser", func(t *testing.T) {
		user, err := mutationResolver.CreateUser(context.Background(), "testuser", "test@example.com", "password123")
		require.NoError(t, err)
		assert.NotNil(t, user)
		assert.Equal(t, "1", user.ID)
		assert.Equal(t, "testuser", user.Username)
		assert.Equal(t, "test@example.com", user.Email)
	})

	// Test CreateProblem
	t.Run("CreateProblem", func(t *testing.T) {
		work := "work"
		stress := "stress"
		problem, err := mutationResolver.CreateProblem(
			context.Background(),
			"Test Problem",
			"Test Description",
			&work,
			&stress,
		)
		require.NoError(t, err)
		assert.NotNil(t, problem)
		assert.Equal(t, "1", problem.ID)
		assert.Equal(t, "Test Problem", problem.Title)
		assert.Equal(t, "Test Description", problem.Description)
	})

	// Test User query
	t.Run("UserQuery", func(t *testing.T) {
		user, err := queryResolver.User(context.Background(), "1")
		require.NoError(t, err)
		assert.NotNil(t, user)
		assert.Equal(t, "1", user.ID)
		assert.Equal(t, "testuser", user.Username)
		assert.Equal(t, "test@example.com", user.Email)
	})

	// Test Problem query
	t.Run("ProblemQuery", func(t *testing.T) {
		problem, err := queryResolver.Problem(context.Background(), "1")
		require.NoError(t, err)
		assert.NotNil(t, problem)
		assert.Equal(t, "1", problem.ID)
		assert.Equal(t, "Test Problem", problem.Title)
	})

	// Test MarkVerseAsRead (with test data)
	t.Run("MarkVerseAsRead", func(t *testing.T) {
		// Insert test verse
		_, err = db.Exec("INSERT INTO verses (book, chapter, verse, text) VALUES (?, ?, ?, ?)", 
			"John", 3, 16, "For God so loved the world...")
		require.NoError(t, err)

		// Insert test reading plan
		_, err = db.Exec("INSERT INTO reading_plans (problem_id) VALUES (?)", 1)
		require.NoError(t, err)

		// Insert test reading plan item
		_, err = db.Exec("INSERT INTO reading_plan_items (reading_plan_id, verse_id, item_order, is_read) VALUES (?, ?, ?, ?)", 
			1, 1, 1, false)
		require.NoError(t, err)

		// Test marking as read
		item, err := mutationResolver.MarkVerseAsRead(context.Background(), "1", "1", true)
		require.NoError(t, err)
		assert.NotNil(t, item)
		assert.Equal(t, true, item.IsRead)
		assert.NotNil(t, item.Verse)
		assert.Equal(t, "John", item.Verse.Book)
	})
}
