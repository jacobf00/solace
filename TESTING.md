# Testing Guide

This document describes the testing infrastructure for the Solace GraphQL API.

## Overview

The testing suite includes:
- **Unit Tests**: Test individual resolver functions with mocked dependencies
- **Integration Tests**: Test the complete system with a real database (SQLite or PostgreSQL)
- **Benchmark Tests**: Performance testing for critical operations
- **Race Condition Tests**: Detect concurrency issues

## Test Structure

```
graph/
├── resolver_test.go          # Unit tests with mocked database
├── integration_test.go       # Integration tests with real database
├── benchmark_test.go         # Performance benchmarks
├── testutils/
│   ├── testutils.go         # Test database setup utilities
│   └── db_helper.go         # Database helper functions
└── testconfig/
    └── testconfig.go        # Test configuration management
```

## Running Tests

### All Tests
```bash
make test
```

### Unit Tests Only
```bash
make test-unit
```

### Integration Tests Only
```bash
make test-integration
```

### Integration Tests with Docker PostgreSQL
```bash
make test-integration-docker
```

### Coverage Report
```bash
make test-coverage
```

### Benchmark Tests
```bash
make test-benchmark
```

### Race Condition Tests
```bash
make test-race
```

### All Test Types
```bash
make test-all
```

## Test Configuration

Tests can be configured using environment variables:

- `TEST_USE_SQLITE=true`: Use SQLite for integration tests (default: true)
- `TEST_USE_DOCKER=false`: Use Docker PostgreSQL for integration tests (default: false)
- `TEST_DATABASE_URL`: Custom database URL for integration tests
- `TEST_VERBOSE=false`: Enable verbose test output (default: false)
- `TEST_COVERAGE=true`: Generate coverage reports (default: true)
- `TEST_RACE=false`: Enable race detection (default: false)

## Database Testing

### SQLite (Default)
- Fast and lightweight
- No external dependencies
- Good for CI/CD pipelines
- Limited SQL features compared to PostgreSQL

### PostgreSQL with Docker
- Full feature compatibility with production
- More realistic testing environment
- Requires Docker to be installed
- Slower than SQLite

## Test Data

The test suite includes:
- **Test Users**: Pre-created users with known credentials
- **Test Problems**: Sample problems with various categories
- **Test Verses**: Biblical verses for reading plans
- **Test Reading Plans**: Complete reading plans with items

## Writing Tests

### Unit Tests
```go
func TestCreateUser(t *testing.T) {
    db, mock, err := sqlmock.New()
    require.NoError(t, err)
    defer db.Close()

    // Setup mock expectations
    mock.ExpectQuery(`INSERT INTO users...`).
        WithArgs("testuser", "test@example.com", "password123").
        WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(1))

    resolver := &Resolver{DB: db}
    mutationResolver := &mutationResolver{resolver}

    user, err := mutationResolver.CreateUser(context.Background(), "testuser", "test@example.com", "password123")
    
    assert.NoError(t, err)
    assert.NotNil(t, user)
    assert.Equal(t, "1", user.ID)
}
```

### Integration Tests
```go
func TestIntegrationCreateUser(t *testing.T) {
    db := testutils.NewSQLiteTestDB(t)
    defer testutils.CleanupTestDB(t, db)

    resolver := &Resolver{DB: db}
    mutationResolver := &mutationResolver{resolver}

    user, err := mutationResolver.CreateUser(context.Background(), "testuser", "test@example.com", "password123")
    
    assert.NoError(t, err)
    assert.NotNil(t, user)
    assert.Equal(t, "testuser", user.Username)
}
```

### Benchmark Tests
```go
func BenchmarkCreateUser(b *testing.B) {
    db := testutils.NewSQLiteTestDB(b)
    defer testutils.CleanupTestDB(b, db)

    resolver := &Resolver{DB: db}
    mutationResolver := &mutationResolver{resolver}

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        username := fmt.Sprintf("user%d", i)
        email := fmt.Sprintf("user%d@example.com", i)
        mutationResolver.CreateUser(context.Background(), username, email, "password123")
    }
}
```

## Best Practices

1. **Use Table-Driven Tests**: Structure tests with test cases for better coverage
2. **Mock External Dependencies**: Use sqlmock for unit tests
3. **Clean Up Resources**: Always clean up test databases and connections
4. **Test Error Cases**: Include tests for error conditions and edge cases
5. **Use Descriptive Names**: Test names should clearly describe what is being tested
6. **Keep Tests Fast**: Unit tests should be fast, integration tests can be slower
7. **Test Concurrency**: Use race detection to find concurrency issues

## Continuous Integration

The test suite is designed to work in CI/CD environments:

1. **Fast Unit Tests**: Run on every commit
2. **Integration Tests**: Run on pull requests
3. **Full Test Suite**: Run on main branch
4. **Coverage Reports**: Generated and uploaded to coverage services

## Troubleshooting

### Common Issues

1. **Database Connection Errors**: Ensure test database is properly set up
2. **Migration Failures**: Check that migration files are accessible
3. **Race Conditions**: Use `-race` flag to detect concurrency issues
4. **Memory Leaks**: Check for unclosed database connections

### Debug Mode

Run tests with verbose output:
```bash
TEST_VERBOSE=true go test -v ./...
```

### Coverage Analysis

Generate and view coverage report:
```bash
make test-coverage
open coverage.html
```

## Performance Considerations

- **SQLite**: Fastest for unit tests, limited SQL features
- **PostgreSQL**: Slower but more realistic, full SQL features
- **Mock Database**: Fastest but limited to unit tests
- **Concurrent Tests**: Use `-race` flag to detect issues

## Future Improvements

1. **Property-Based Testing**: Use quickcheck for property-based tests
2. **Load Testing**: Add load testing for performance validation
3. **Contract Testing**: Add API contract testing
4. **Mutation Testing**: Add mutation testing for test quality validation

