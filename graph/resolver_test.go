package graph

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/jacobf00/solace/graph/model"
	"github.com/jacobf00/solace/graph/testutils"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCreateUser(t *testing.T) {
	tests := []struct {
		name           string
		username       string
		email          string
		password       string
		mockSetup      func(mock sqlmock.Sqlmock)
		expectedError  bool
		expectedUserID string
	}{
		{
			name:     "successful user creation",
			username: "testuser",
			email:    "test@example.com",
			password: "password123",
			mockSetup: func(mock sqlmock.Sqlmock) {
				mock.ExpectQuery(`INSERT INTO users \(username, email, password_hash\) VALUES \(\$1, \$2, \$3\) RETURNING id`).
					WithArgs("testuser", "test@example.com", "password123").
					WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(1))
			},
			expectedError:  false,
			expectedUserID: "1",
		},
		{
			name:     "database error",
			username: "testuser",
			email:    "test@example.com",
			password: "password123",
			mockSetup: func(mock sqlmock.Sqlmock) {
				mock.ExpectQuery(`INSERT INTO users \(username, email, password_hash\) VALUES \(\$1, \$2, \$3\) RETURNING id`).
					WithArgs("testuser", "test@example.com", "password123").
					WillReturnError(sql.ErrConnDone)
			},
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			db, mock, err := sqlmock.New()
			require.NoError(t, err)
			defer db.Close()

			tt.mockSetup(mock)

			resolver := &Resolver{DB: db}
			mutationResolver := &mutationResolver{resolver}

			user, err := mutationResolver.CreateUser(context.Background(), tt.username, tt.email, tt.password)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, user)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, user)
				assert.Equal(t, tt.expectedUserID, user.ID)
				assert.Equal(t, tt.username, user.Username)
				assert.Equal(t, tt.email, user.Email)
				assert.NotNil(t, user.Problems)
			}

			assert.NoError(t, mock.ExpectationsWereMet())
		})
	}
}

func TestCreateProblem(t *testing.T) {
	tests := []struct {
		name          string
		title         string
		description   string
		context       *string
		category      *string
		mockSetup     func(mock sqlmock.Sqlmock)
		expectedError bool
	}{
		{
			name:        "successful problem creation with context and category",
			title:       "Test Problem",
			description: "This is a test problem",
			context:     testutils.StringPtr("work"),
			category:    testutils.StringPtr("stress"),
			mockSetup: func(mock sqlmock.Sqlmock) {
				mock.ExpectQuery(`INSERT INTO problems \(user_id, title, description, context, category\)\s+VALUES \(\$1, \$2, \$3, \$4, \$5\)\s+RETURNING id, created_at`).
					WithArgs(1, "Test Problem", "This is a test problem", "work", "stress").
					WillReturnRows(sqlmock.NewRows([]string{"id", "created_at"}).AddRow(1, time.Date(2023, 1, 1, 0, 0, 0, 0, time.UTC)))
			},
			expectedError: false,
		},
		{
			name:        "successful problem creation without context and category",
			title:       "Test Problem",
			description: "This is a test problem",
			context:     nil,
			category:    nil,
			mockSetup: func(mock sqlmock.Sqlmock) {
				mock.ExpectQuery(`INSERT INTO problems \(user_id, title, description, context, category\)\s+VALUES \(\$1, \$2, \$3, \$4, \$5\)\s+RETURNING id, created_at`).
					WithArgs(1, "Test Problem", "This is a test problem", nil, nil).
					WillReturnRows(sqlmock.NewRows([]string{"id", "created_at"}).AddRow(1, time.Date(2023, 1, 1, 0, 0, 0, 0, time.UTC)))
			},
			expectedError: false,
		},
		{
			name:        "database error",
			title:       "Test Problem",
			description: "This is a test problem",
			context:     nil,
			category:    nil,
			mockSetup: func(mock sqlmock.Sqlmock) {
				mock.ExpectQuery(`INSERT INTO problems \(user_id, title, description, context, category\)\s+VALUES \(\$1, \$2, \$3, \$4, \$5\)\s+RETURNING id, created_at`).
					WithArgs(1, "Test Problem", "This is a test problem", nil, nil).
					WillReturnError(sql.ErrConnDone)
			},
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			db, mock, err := sqlmock.New()
			require.NoError(t, err)
			defer db.Close()

			tt.mockSetup(mock)

			resolver := &Resolver{DB: db}
			mutationResolver := &mutationResolver{resolver}

			problem, err := mutationResolver.CreateProblem(context.Background(), tt.title, tt.description, tt.context, tt.category)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, problem)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, problem)
				assert.Equal(t, "1", problem.ID)
				assert.Equal(t, tt.title, problem.Title)
				assert.Equal(t, tt.description, problem.Description)
				assert.Equal(t, tt.context, problem.Context)
				assert.Equal(t, tt.category, problem.Category)
			}

			assert.NoError(t, mock.ExpectationsWereMet())
		})
	}
}

func TestUser(t *testing.T) {
	tests := []struct {
		name          string
		userID        string
		mockSetup     func(mock sqlmock.Sqlmock)
		expectedError bool
		expectedUser  *model.User
	}{
		{
			name:   "successful user retrieval",
			userID: "1",
			mockSetup: func(mock sqlmock.Sqlmock) {
				// Mock user query
				mock.ExpectQuery(`SELECT id, username, email FROM users WHERE id = \$1`).
					WithArgs(1).
					WillReturnRows(sqlmock.NewRows([]string{"id", "username", "email"}).AddRow(1, "testuser", "test@example.com"))

				// Mock problems query
				mock.ExpectQuery(`SELECT id, title, description, context, category, created_at, advice\s+FROM problems WHERE user_id = \$1`).
					WithArgs(1).
					WillReturnRows(sqlmock.NewRows([]string{"id", "title", "description", "context", "category", "created_at", "advice"}))
			},
			expectedError: false,
			expectedUser: &model.User{
				ID:       "1",
				Username: "testuser",
				Email:    "test@example.com",
				Problems: []*model.Problem{},
			},
		},
		{
			name:   "user not found",
			userID: "999",
			mockSetup: func(mock sqlmock.Sqlmock) {
				mock.ExpectQuery(`SELECT id, username, email FROM users WHERE id = \$1`).
					WithArgs(999).
					WillReturnError(sql.ErrNoRows)
			},
			expectedError: true,
		},
		{
			name:   "invalid user ID",
			userID: "invalid",
			mockSetup: func(mock sqlmock.Sqlmock) {
				// No database calls expected for invalid ID
			},
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			db, mock, err := sqlmock.New()
			require.NoError(t, err)
			defer db.Close()

			tt.mockSetup(mock)

			resolver := &Resolver{DB: db}
			queryResolver := &queryResolver{resolver}

			user, err := queryResolver.User(context.Background(), tt.userID)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, user)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, user)
				assert.Equal(t, tt.expectedUser.ID, user.ID)
				assert.Equal(t, tt.expectedUser.Username, user.Username)
				assert.Equal(t, tt.expectedUser.Email, user.Email)
			}

			assert.NoError(t, mock.ExpectationsWereMet())
		})
	}
}

func TestProblem(t *testing.T) {
	tests := []struct {
		name          string
		problemID     string
		mockSetup     func(mock sqlmock.Sqlmock)
		expectedError bool
	}{
		{
			name:      "successful problem retrieval",
			problemID: "1",
			mockSetup: func(mock sqlmock.Sqlmock) {
				// Mock problem query
				mock.ExpectQuery(`SELECT id, title, description, context, category, created_at, advice\s+FROM problems WHERE id = \$1`).
					WithArgs(1).
					WillReturnRows(sqlmock.NewRows([]string{"id", "title", "description", "context", "category", "created_at", "advice"}).
						AddRow(1, "Test Problem", "Test Description", "work", "stress", time.Date(2023, 1, 1, 0, 0, 0, 0, time.UTC), ""))

				// Mock reading plan query (will return no rows)
				mock.ExpectQuery(`SELECT id, created_at FROM reading_plans WHERE problem_id = \$1`).
					WithArgs(1).
					WillReturnError(sql.ErrNoRows)
			},
			expectedError: false,
		},
		{
			name:      "problem not found",
			problemID: "999",
			mockSetup: func(mock sqlmock.Sqlmock) {
				mock.ExpectQuery(`SELECT id, title, description, context, category, created_at, advice\s+FROM problems WHERE id = \$1`).
					WithArgs(999).
					WillReturnError(sql.ErrNoRows)
			},
			expectedError: true,
		},
		{
			name:      "invalid problem ID",
			problemID: "invalid",
			mockSetup: func(mock sqlmock.Sqlmock) {
				// No database calls expected for invalid ID
			},
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			db, mock, err := sqlmock.New()
			require.NoError(t, err)
			defer db.Close()

			tt.mockSetup(mock)

			resolver := &Resolver{DB: db}
			queryResolver := &queryResolver{resolver}

			problem, err := queryResolver.Problem(context.Background(), tt.problemID)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, problem)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, problem)
				assert.Equal(t, "1", problem.ID)
				assert.Equal(t, "Test Problem", problem.Title)
				assert.Equal(t, "Test Description", problem.Description)
			}

			assert.NoError(t, mock.ExpectationsWereMet())
		})
	}
}

func TestMarkVerseAsRead(t *testing.T) {
	tests := []struct {
		name           string
		readingPlanID  string
		verseID        string
		isRead         bool
		mockSetup      func(mock sqlmock.Sqlmock)
		expectedError  bool
	}{
		{
			name:          "successful verse mark as read",
			readingPlanID: "1",
			verseID:       "1",
			isRead:        true,
			mockSetup: func(mock sqlmock.Sqlmock) {
				// Mock update query
				mock.ExpectQuery(`UPDATE reading_plan_items SET is_read = \$1\s+WHERE reading_plan_id = \$2 AND verse_id = \$3\s+RETURNING id, item_order`).
					WithArgs(true, 1, 1).
					WillReturnRows(sqlmock.NewRows([]string{"id", "item_order"}).AddRow(1, 1))

				// Mock verse query
				mock.ExpectQuery(`SELECT id, book, chapter, verse, text FROM verses WHERE id = \$1`).
					WithArgs(1).
					WillReturnRows(sqlmock.NewRows([]string{"id", "book", "chapter", "verse", "text"}).
						AddRow(1, "John", 3, 16, "For God so loved the world..."))
			},
			expectedError: false,
		},
		{
			name:          "invalid reading plan ID",
			readingPlanID: "invalid",
			verseID:       "1",
			isRead:        true,
			mockSetup: func(mock sqlmock.Sqlmock) {
				// No database calls expected for invalid ID
			},
			expectedError: true,
		},
		{
			name:          "invalid verse ID",
			readingPlanID: "1",
			verseID:       "invalid",
			isRead:        true,
			mockSetup: func(mock sqlmock.Sqlmock) {
				// No database calls expected for invalid ID
			},
			expectedError: true,
		},
		{
			name:          "verse not found in reading plan",
			readingPlanID: "1",
			verseID:       "999",
			isRead:        true,
			mockSetup: func(mock sqlmock.Sqlmock) {
				mock.ExpectQuery(`UPDATE reading_plan_items SET is_read = \$1\s+WHERE reading_plan_id = \$2 AND verse_id = \$3\s+RETURNING id, item_order`).
					WithArgs(true, 1, 999).
					WillReturnError(sql.ErrNoRows)
			},
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			db, mock, err := sqlmock.New()
			require.NoError(t, err)
			defer db.Close()

			tt.mockSetup(mock)

			resolver := &Resolver{DB: db}
			mutationResolver := &mutationResolver{resolver}

			item, err := mutationResolver.MarkVerseAsRead(context.Background(), tt.readingPlanID, tt.verseID, tt.isRead)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, item)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, item)
				assert.Equal(t, "1", item.ID)
				assert.Equal(t, int32(1), item.ItemOrder)
				assert.Equal(t, tt.isRead, item.IsRead)
				assert.NotNil(t, item.Verse)
			}

			assert.NoError(t, mock.ExpectationsWereMet())
		})
	}
}

