package graph

import (
	"context"
	"testing"

	"github.com/jacobf00/solace/graph/testutils"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIntegrationCreateUser(t *testing.T) {
	db := testutils.NewSQLiteTestDB(t)
	defer testutils.CleanupTestDB(t, db)

	resolver := &Resolver{DB: db}
	mutationResolver := &mutationResolver{resolver}

	tests := []struct {
		name          string
		username      string
		email         string
		password      string
		expectedError bool
	}{
		{
			name:          "successful user creation",
			username:      "integrationuser",
			email:         "integration@example.com",
			password:      "password123",
			expectedError: false,
		},
		{
			name:          "duplicate username",
			username:      "testuser1", // This already exists in test data
			email:         "duplicate@example.com",
			password:      "password123",
			expectedError: true,
		},
		{
			name:          "duplicate email",
			username:      "newuser",
			email:         "test1@example.com", // This already exists in test data
			password:      "password123",
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			user, err := mutationResolver.CreateUser(context.Background(), tt.username, tt.email, tt.password)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, user)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, user)
				assert.Equal(t, tt.username, user.Username)
				assert.Equal(t, tt.email, user.Email)
				assert.NotEmpty(t, user.ID)
				assert.NotNil(t, user.Problems)
			}
		})
	}
}

func TestIntegrationCreateProblem(t *testing.T) {
	db := testutils.NewSQLiteTestDB(t)
	defer testutils.CleanupTestDB(t, db)

	resolver := &Resolver{DB: db}
	mutationResolver := &mutationResolver{resolver}

	tests := []struct {
		name        string
		title       string
		description string
		context     *string
		category    *string
		expectError bool
	}{
		{
			name:        "successful problem creation with all fields",
			title:       "Integration Test Problem",
			description: "This is an integration test problem",
		context:     testutils.StringPtr("work"),
		category:    testutils.StringPtr("stress"),
			expectError: false,
		},
		{
			name:        "successful problem creation with minimal fields",
			title:       "Minimal Problem",
			description: "Minimal description",
			context:     nil,
			category:    nil,
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			problem, err := mutationResolver.CreateProblem(context.Background(), tt.title, tt.description, tt.context, tt.category)

			if tt.expectError {
				assert.Error(t, err)
				assert.Nil(t, problem)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, problem)
				assert.Equal(t, tt.title, problem.Title)
				assert.Equal(t, tt.description, problem.Description)
				assert.Equal(t, tt.context, problem.Context)
				assert.Equal(t, tt.category, problem.Category)
				assert.NotEmpty(t, problem.ID)
				assert.NotZero(t, problem.CreatedAt)
			}
		})
	}
}

func TestIntegrationUser(t *testing.T) {
	db := testutils.NewSQLiteTestDB(t)
	defer testutils.CleanupTestDB(t, db)

	resolver := &Resolver{DB: db}
	queryResolver := &queryResolver{resolver}

	tests := []struct {
		name          string
		userID        string
		expectedError bool
		expectedUser  *ExpectedUser
	}{
		{
			name:          "successful user retrieval",
			userID:        "1",
			expectedError: false,
			expectedUser: &ExpectedUser{
				Username: "testuser1",
				Email:    "test1@example.com",
				ProblemCount: 2, // Based on test data
			},
		},
		{
			name:          "user not found",
			userID:        "999",
			expectedError: true,
		},
		{
			name:          "invalid user ID",
			userID:        "invalid",
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			user, err := queryResolver.User(context.Background(), tt.userID)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, user)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, user)
				assert.Equal(t, tt.userID, user.ID)
				assert.Equal(t, tt.expectedUser.Username, user.Username)
				assert.Equal(t, tt.expectedUser.Email, user.Email)
				assert.Len(t, user.Problems, tt.expectedUser.ProblemCount)
			}
		})
	}
}

func TestIntegrationProblem(t *testing.T) {
	db := testutils.NewSQLiteTestDB(t)
	defer testutils.CleanupTestDB(t, db)

	resolver := &Resolver{DB: db}
	queryResolver := &queryResolver{resolver}

	tests := []struct {
		name          string
		problemID     string
		expectedError bool
		expectedTitle string
	}{
		{
			name:          "successful problem retrieval",
			problemID:     "1",
			expectedError: false,
			expectedTitle: "Test Problem 1",
		},
		{
			name:          "problem not found",
			problemID:     "999",
			expectedError: true,
		},
		{
			name:          "invalid problem ID",
			problemID:     "invalid",
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			problem, err := queryResolver.Problem(context.Background(), tt.problemID)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, problem)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, problem)
				assert.Equal(t, tt.problemID, problem.ID)
				assert.Equal(t, tt.expectedTitle, problem.Title)
				assert.NotZero(t, problem.CreatedAt)
			}
		})
	}
}

func TestIntegrationReadingPlan(t *testing.T) {
	db := testutils.NewSQLiteTestDB(t)
	defer testutils.CleanupTestDB(t, db)

	resolver := &Resolver{DB: db}
	queryResolver := &queryResolver{resolver}

	tests := []struct {
		name          string
		planID        string
		expectedError bool
		expectedItems int
	}{
		{
			name:          "successful reading plan retrieval",
			planID:        "1",
			expectedError: false,
			expectedItems: 3, // Based on test data
		},
		{
			name:          "reading plan not found",
			planID:        "999",
			expectedError: true,
		},
		{
			name:          "invalid plan ID",
			planID:        "invalid",
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			plan, err := queryResolver.ReadingPlan(context.Background(), tt.planID)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, plan)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, plan)
				assert.Equal(t, tt.planID, plan.ID)
				assert.Len(t, plan.Items, tt.expectedItems)
				assert.NotNil(t, plan.Problem)
				assert.NotZero(t, plan.CreatedAt)

				// Verify items are ordered correctly
				for i, item := range plan.Items {
					assert.Equal(t, int32(i+1), item.ItemOrder)
					assert.NotNil(t, item.Verse)
					assert.NotEmpty(t, item.Verse.Text)
				}
			}
		})
	}
}

func TestIntegrationMarkVerseAsRead(t *testing.T) {
	db := testutils.NewSQLiteTestDB(t)
	defer testutils.CleanupTestDB(t, db)

	resolver := &Resolver{DB: db}
	mutationResolver := &mutationResolver{resolver}

	tests := []struct {
		name           string
		readingPlanID  string
		verseID        string
		isRead         bool
		expectedError  bool
		expectedIsRead bool
	}{
		{
			name:           "successful mark as read",
			readingPlanID:  "1",
			verseID:        "1",
			isRead:         true,
			expectedError:  false,
			expectedIsRead: true,
		},
		{
			name:           "successful mark as unread",
			readingPlanID:  "1",
			verseID:        "2",
			isRead:         false,
			expectedError:  false,
			expectedIsRead: false,
		},
		{
			name:          "verse not found in plan",
			readingPlanID: "1",
			verseID:       "999",
			isRead:        true,
			expectedError: true,
		},
		{
			name:          "invalid reading plan ID",
			readingPlanID: "invalid",
			verseID:       "1",
			isRead:        true,
			expectedError: true,
		},
		{
			name:          "invalid verse ID",
			readingPlanID: "1",
			verseID:       "invalid",
			isRead:        true,
			expectedError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			item, err := mutationResolver.MarkVerseAsRead(context.Background(), tt.readingPlanID, tt.verseID, tt.isRead)

			if tt.expectedError {
				assert.Error(t, err)
				assert.Nil(t, item)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, item)
				assert.Equal(t, tt.expectedIsRead, item.IsRead)
				assert.NotNil(t, item.Verse)
				assert.NotEmpty(t, item.Verse.Text)
			}
		})
	}
}

func TestIntegrationEndToEndWorkflow(t *testing.T) {
	db := testutils.NewSQLiteTestDB(t)
	defer testutils.CleanupTestDB(t, db)

	resolver := &Resolver{DB: db}
	mutationResolver := &mutationResolver{resolver}
	queryResolver := &queryResolver{resolver}

	// Step 1: Create a user
	user, err := mutationResolver.CreateUser(context.Background(), "workflowuser", "workflow@example.com", "password123")
	require.NoError(t, err)
	require.NotNil(t, user)
	userID := user.ID

	// Step 2: Create a problem for the user
	problem, err := mutationResolver.CreateProblem(
		context.Background(),
		"Workflow Test Problem",
		"This is a test problem for the workflow",
		testutils.StringPtr("personal"),
		testutils.StringPtr("anxiety"),
	)
	require.NoError(t, err)
	require.NotNil(t, problem)
	problemID := problem.ID

	// Step 3: Retrieve the user and verify the problem is associated
	retrievedUser, err := queryResolver.User(context.Background(), userID)
	require.NoError(t, err)
	require.NotNil(t, retrievedUser)
	assert.Equal(t, user.Username, retrievedUser.Username)
	assert.Len(t, retrievedUser.Problems, 1)
	assert.Equal(t, problem.Title, retrievedUser.Problems[0].Title)

	// Step 4: Retrieve the problem
	retrievedProblem, err := queryResolver.Problem(context.Background(), problemID)
	require.NoError(t, err)
	require.NotNil(t, retrievedProblem)
	assert.Equal(t, problem.Title, retrievedProblem.Title)
	assert.Equal(t, problem.Description, retrievedProblem.Description)

	// Step 5: Test reading plan functionality (if available)
	// Note: This assumes a reading plan exists for the problem
	// In a real scenario, you might need to create one first
}

// Helper struct for expected user data
type ExpectedUser struct {
	Username     string
	Email        string
	ProblemCount int
}

