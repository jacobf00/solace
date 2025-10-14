# Makefile for Solace Application

# Default environment variables
DB_HOST ?= localhost
DB_PORT ?= 5432
DB_USER ?= $USER
DB_PASSWORD ?= 
DB_NAME ?= postgres
DB_SSLMODE ?= disable

.PHONY: help setup-db migrate-up migrate-down migrate-status migrate-create test clean

# Default target
help:
	@echo "Solace Application - Available Commands:"
	@echo ""
	@echo "Database:"
	@echo "  setup-db          Set up the database with all migrations"
	@echo "  migrate-up        Run all pending migrations"
	@echo "  migrate-down      Rollback the last migration"
	@echo "  migrate-status    Show migration status"
	@echo "  migrate-create    Create a new migration (usage: make migrate-create NAME=migration_name)"
	@echo ""
	@echo "Development:"
	@echo "  dev               Start development servers (backend + frontend)"
	@echo "  dev-backend       Start only the backend server"
	@echo "  dev-frontend      Start only the frontend development server"
	@echo ""
	@echo "Testing:"
	@echo "  test              Run all tests"
	@echo "  test-backend      Run backend tests"
	@echo "  test-frontend     Run frontend tests"
	@echo ""
	@echo "Utilities:"
	@echo "  clean             Clean build artifacts and dependencies"
	@echo "  deps              Install all dependencies"

# Database setup
setup-db:
	@echo "Setting up database..."
	@./scripts/setup-database.sh

# Migration commands
migrate-up:
	@echo "Running migrations..."
	@go tool migrate -path migrations -database "postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSLMODE)" up

migrate-down:
	@echo "Rolling back last migration..."
	@go tool migrate -path migrations -database "postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSLMODE)" down 1

migrate-status:
	@echo "Migration status:"
	@go tool migrate -path migrations -database "postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=$(DB_SSLMODE)" version

migrate-create:
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make migrate-create NAME=migration_name"; \
		exit 1; \
	fi
	@go tool migrate create -ext sql -dir migrations -seq $(NAME)

# Development servers
dev:
	@echo "Starting development servers..."
	@echo "Backend will be available at http://localhost:8080"
	@echo "Frontend will be available at http://localhost:5173"
	@echo "Press Ctrl+C to stop all servers"
	@trap 'kill 0' EXIT; \
	go run server.go & \
	cd client && npm run dev & \
	wait

dev-backend:
	@echo "Starting backend server..."
	@echo "Backend will be available at http://localhost:8080"
	@go run server.go

dev-frontend:
	@echo "Starting frontend development server..."
	@echo "Frontend will be available at http://localhost:5173"
	@cd client && npm run dev

# Testing
test: test-backend test-frontend

test-backend: test-unit test-integration

test-unit:
	@echo "Running unit tests..."
	@go test -v -race -coverprofile=coverage.out -covermode=atomic ./graph/... -run "TestCreate|TestUser|TestProblem|TestMarkVerse"

test-integration:
	@echo "Running integration tests..."
	@go test -v -race -coverprofile=coverage-integration.out -covermode=atomic ./graph/... -run "TestSimpleIntegration"

test-integration-docker:
	@echo "Running integration tests with Docker PostgreSQL..."
	@docker-compose -f docker-compose.test.yml up -d test-postgres
	@echo "Waiting for PostgreSQL to be ready..."
	@timeout 30s bash -c 'until docker-compose -f docker-compose.test.yml exec test-postgres pg_isready -U testuser -d testdb; do sleep 1; done'
	@TEST_USE_SQLITE=false TEST_USE_DOCKER=true go test -v -race ./graph/... -run "TestIntegration.*"
	@docker-compose -f docker-compose.test.yml down -v

test-coverage:
	@echo "Running tests with coverage..."
	@go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

test-coverage-func:
	@echo "Running tests with function coverage..."
	@go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
	@go tool cover -func=coverage.out


test-race:
	@echo "Running race condition tests..."
	@go test -v -race ./...

test-frontend:
	@echo "Running frontend tests..."
	@cd client && npm test

test-all: test-unit test-integration test-coverage test-race

# Test utilities
test-clean:
	@echo "Cleaning test artifacts..."
	@rm -f coverage.out coverage-integration.out coverage.html
	@docker-compose -f docker-compose.test.yml down -v 2>/dev/null || true

test-setup:
	@echo "Setting up test environment..."
	@go mod download
	@go mod tidy

# Dependencies
deps:
	@echo "Installing Go dependencies..."
	@go mod tidy
	@echo "Installing frontend dependencies..."
	@cd client && npm install

# Clean up
clean:
	@echo "Cleaning build artifacts..."
	@go clean
	@cd client && npm run clean 2>/dev/null || true
	@rm -rf client/node_modules
	@rm -rf client/dist
