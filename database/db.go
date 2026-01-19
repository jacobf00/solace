package database

import (
	"context"
	"fmt"
	"log"
	"net/url"
	"os"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var Pool *pgxpool.Pool

func InitDB() error {
	supabaseURL := getEnv("SUPABASE_URL", "")
	serviceKey := getEnv("SUPABASE_SERVICE_KEY", "")

	if supabaseURL == "" || serviceKey == "" {
		return fmt.Errorf("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
	}

	// Parse host from SUPABASE_URL
	u, err := url.Parse(supabaseURL)
	if err != nil {
		return fmt.Errorf("invalid SUPABASE_URL: %w", err)
	}
	host := u.Host

	connStr := fmt.Sprintf("postgresql://postgres:%s@%s:5432/postgres?sslmode=require",
		serviceKey, host)

	poolConfig, err := pgxpool.ParseConfig(connStr)
	if err != nil {
		return fmt.Errorf("failed to parse pool config: %w", err)
	}

	pool, err := pgxpool.NewWithConfig(context.Background(), poolConfig)
	if err != nil {
		return fmt.Errorf("failed to create connection pool: %w", err)
	}

	if err = pool.Ping(context.Background()); err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}

	Pool = pool
	log.Println("Successfully connected to Supabase PostgreSQL database with pgx")
	return nil
}

func CloseDB() {
	if Pool != nil {
		Pool.Close()
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

type DB struct {
	Pool *pgxpool.Pool
}

func NewDB() *DB {
	return &DB{Pool: Pool}
}

func (db *DB) Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error) {
	return db.Pool.Query(ctx, sql, args...)
}

func (db *DB) QueryRow(ctx context.Context, sql string, args ...interface{}) pgx.Row {
	return db.Pool.QueryRow(ctx, sql, args...)
}

func (db *DB) Exec(ctx context.Context, sql string, args ...interface{}) (int64, error) {
	result, err := db.Pool.Exec(ctx, sql, args...)
	if err != nil {
		return 0, err
	}
	return result.RowsAffected(), nil
}

func (db *DB) GetTimeout() time.Duration {
	return 30 * time.Second
}
