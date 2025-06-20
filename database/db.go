package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func InitDB() error {
	// Get database connection parameters from environment variables or use defaults
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "$USER")
	password := getEnv("DB_PASSWORD", "")
	dbname := getEnv("DB_NAME", "postgres")
	sslmode := getEnv("DB_SSLMODE", "disable")

	// Create connection string
	connStr := fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=%s",
		host, port, user, dbname, sslmode)

	if password != "" {
		connStr += fmt.Sprintf(" password=%s", password)
	}

	var err error
	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("failed to open database connection: %w", err)
	}

	// Test the connection
	if err = DB.Ping(); err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}

	log.Println("Successfully connected to PostgreSQL database")
	return nil
}

func CloseDB() {
	if DB != nil {
		DB.Close()
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
