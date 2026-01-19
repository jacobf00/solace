# Makefile for Solace Application

# Default environment variables
SUPABASE_URL ?= $(SUPABASE_URL)
SUPABASE_SERVICE_KEY ?= $(SUPABASE_SERVICE_KEY)
ANON_KEY ?= $(ANON_KEY)

.PHONY: help supabase-start supabase-stop supabase-logs dev dev-backend dev-frontend test test-backend test-frontend clean deps generate

# Default target
help:
	@echo "Solace Application - Available Commands:"
	@echo ""
	@echo "Supabase:"
	@echo "  supabase-start    Start Supabase local development"
	@echo "  supabase-stop     Stop Supabase local development"
	@echo "  supabase-logs     Show Supabase logs"
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
	@echo "  generate          Generate GraphQL code"

# Supabase commands
supabase-start:
	@echo "Starting Supabase local development..."
	@cd supabase && supabase start

supabase-stop:
	@echo "Stopping Supabase local development..."
	@cd supabase && supabase stop

supabase-logs:
	@echo "Showing Supabase logs..."
	@cd supabase && supabase logs

# Development servers
dev:
	@echo "Starting development servers..."
	@echo "Backend will be available at http://localhost:8080"
	@echo "Frontend will be available at http://localhost:5173"
	@echo "Press Ctrl+C to stop all servers"
	@trap 'kill 0' EXIT; \
	SUPABASE_URL=$(SUPABASE_URL) SUPABASE_SERVICE_KEY=$(SUPABASE_SERVICE_KEY) ANON_KEY=$(ANON_KEY) go run server.go & \
	cd client && npm run dev & \
	wait

dev-backend:
	@echo "Starting backend server..."
	@echo "Backend will be available at http://localhost:8080"
	@SUPABASE_URL=$(SUPABASE_URL) SUPABASE_SERVICE_KEY=$(SUPABASE_SERVICE_KEY) ANON_KEY=$(ANON_KEY) go run server.go

dev-frontend:
	@echo "Starting frontend development server..."
	@echo "Frontend will be available at http://localhost:5173"
	@cd client && npm run dev

# Testing
test: test-backend test-frontend

test-backend:
	@echo "Running backend tests..."
	@go test -v -race ./...

test-frontend:
	@echo "Running frontend tests..."
	@cd client && npm test

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

# Generate GraphQL code
generate:
	@echo "Generating GraphQL code..."
	@go run github.com/99designs/gqlgen generate
