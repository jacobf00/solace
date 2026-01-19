package graph

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jacobf00/solace/graph/model"
)

type mutationResolver struct {
	*Resolver
}

func (r *mutationResolver) CreateUser(ctx context.Context, username string, email string, password string) (*model.User, error) {
	userID := uuid.New()
	now := time.Now()

	query := `INSERT INTO users (id, username, email, password_hash, created_at, updated_at)
			  VALUES ($1, $2, $3, $4, $5, $6)
			  RETURNING id, username, email`

	err := r.DB.QueryRow(ctx, query, userID, username, email, password, now, now).Scan(
		&userID, &username, &email)
	if err != nil {
		return nil, err
	}

	return &model.User{
		ID:       userID.String(),
		Username: username,
		Email:    email,
		Problems: []*model.Problem{},
	}, nil
}

func (r *mutationResolver) CreateProblem(ctx context.Context, title string, description string, context *string, category *string) (*model.Problem, error) {
	problemID := uuid.New()
	now := time.Now()

	query := `INSERT INTO problems (id, user_id, title, description, context, category, created_at, updated_at)
			  VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
			  RETURNING id, title, description, context, category, created_at`

	var dbContext, dbCategory *string
	if context != nil {
		dbContext = context
	}
	if category != nil {
		dbCategory = category
	}

	err := r.DB.QueryRow(ctx, query, problemID, uuid.Nil, title, description, dbContext, dbCategory, now, now).Scan(
		&problemID, &title, &description, &dbContext, &dbCategory, &now)
	if err != nil {
		return nil, err
	}

	return &model.Problem{
		ID:          problemID.String(),
		Title:       title,
		Description: description,
		Context:     dbContext,
		Category:    dbCategory,
		CreatedAt:   now,
	}, nil
}

func (r *mutationResolver) MarkVerseAsRead(ctx context.Context, readingPlanID string, verseID string, isRead bool) (*model.ReadingPlanItem, error) {
	planUUID, err := uuid.Parse(readingPlanID)
	if err != nil {
		return nil, err
	}
	verseUUID, err := uuid.Parse(verseID)
	if err != nil {
		return nil, err
	}

	query := `UPDATE reading_plan_items SET is_read = $1, updated_at = $2
			  WHERE reading_plan_id = $3 AND verse_id = $4
			  RETURNING id, item_order`

	var itemID uuid.UUID
	var itemOrder int32
	err = r.DB.QueryRow(ctx, query, isRead, time.Now(), planUUID, verseUUID).Scan(&itemID, &itemOrder)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	verse, err := r.getVerseByID(ctx, verseUUID)
	if err != nil {
		return nil, err
	}

	return &model.ReadingPlanItem{
		ID:        itemID.String(),
		Verse:     verse,
		ItemOrder: itemOrder,
		IsRead:    isRead,
	}, nil
}

type queryResolver struct {
	*Resolver
}

func (r *queryResolver) User(ctx context.Context, id string) (*model.User, error) {
	userID, err := uuid.Parse(id)
	if err != nil {
		return nil, err
	}

	query := `SELECT id, username, email FROM users WHERE id = $1`
	var username, email string
	err = r.DB.QueryRow(ctx, query, userID).Scan(&userID, &username, &email)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	problems, err := r.getProblemsByUserID(ctx, userID)
	if err != nil {
		return nil, err
	}

	return &model.User{
		ID:       userID.String(),
		Username: username,
		Email:    email,
		Problems: problems,
	}, nil
}

func (r *queryResolver) Problem(ctx context.Context, id string) (*model.Problem, error) {
	problemID, err := uuid.Parse(id)
	if err != nil {
		return nil, err
	}

	query := `SELECT id, title, description, context, category, created_at, advice
			  FROM problems WHERE id = $1`

	var title, description string
	var dbContext, dbCategory, advice *string
	var createdAt time.Time
	err = r.DB.QueryRow(ctx, query, problemID).Scan(
		&problemID, &title, &description, &dbContext, &dbCategory, &createdAt, &advice)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	problem := &model.Problem{
		ID:          problemID.String(),
		Title:       title,
		Description: description,
		Context:     dbContext,
		Category:    dbCategory,
		CreatedAt:   createdAt,
		Advice:      advice,
	}

	readingPlan, err := r.getReadingPlanByProblemID(ctx, problemID)
	if err == nil && readingPlan != nil {
		problem.ReadingPlan = readingPlan
	}

	return problem, nil
}

func (r *queryResolver) ReadingPlan(ctx context.Context, id string) (*model.ReadingPlan, error) {
	planID, err := uuid.Parse(id)
	if err != nil {
		return nil, err
	}

	query := `SELECT id, problem_id, created_at FROM reading_plans WHERE id = $1`
	var problemID uuid.UUID
	var createdAt time.Time
	err = r.DB.QueryRow(ctx, query, planID).Scan(&planID, &problemID, &createdAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	problem, err := r.Problem(ctx, problemID.String())
	if err != nil {
		return nil, err
	}

	items, err := r.getReadingPlanItems(ctx, planID)
	if err != nil {
		return nil, err
	}

	return &model.ReadingPlan{
		ID:        planID.String(),
		Problem:   problem,
		CreatedAt: createdAt,
		Items:     items,
	}, nil
}
