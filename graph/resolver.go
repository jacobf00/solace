package graph

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jacobf00/solace/database"
	"github.com/jacobf00/solace/graph/model"
	"github.com/jacobf00/solace/internal/ai"
)

type Resolver struct {
	DB       *database.DB
	AIClient *ai.Client
}

func NewResolver(db *database.DB, aiClient *ai.Client) *Resolver {
	return &Resolver{DB: db, AIClient: aiClient}
}

func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }
func (r *Resolver) Query() QueryResolver       { return &queryResolver{r} }

// Helper functions
func (r *Resolver) getProblemsByUserID(ctx context.Context, userID uuid.UUID) ([]*model.Problem, error) {
	query := `SELECT id, title, description, context, category, created_at, advice
			  FROM problems WHERE user_id = $1`

	rows, err := r.DB.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var problems []*model.Problem
	for rows.Next() {
		var p model.Problem
		var pID uuid.UUID
		var dbContext, dbCategory, advice *string
		err := rows.Scan(&pID, &p.Title, &p.Description, &dbContext, &dbCategory, &p.CreatedAt, &advice)
		if err != nil {
			return nil, err
		}
		p.ID = pID
		p.Context = dbContext
		p.Category = dbCategory
		p.Advice = advice
		problems = append(problems, &p)
	}

	return problems, nil
}

func (r *Resolver) getReadingPlanByProblemID(ctx context.Context, problemID uuid.UUID) (*model.ReadingPlan, error) {
	query := `SELECT id, created_at FROM reading_plans WHERE problem_id = $1`
	var planID uuid.UUID
	var createdAt time.Time
	err := r.DB.QueryRow(ctx, query, problemID).Scan(&planID, &createdAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	items, err := r.getReadingPlanItems(ctx, planID)
	if err != nil {
		return nil, err
	}

	return &model.ReadingPlan{
		ID:        planID.String(),
		CreatedAt: createdAt,
		Items:     items,
	}, nil
}

func (r *Resolver) getReadingPlanItems(ctx context.Context, planID uuid.UUID) ([]*model.ReadingPlanItem, error) {
	query := `SELECT rpi.id, rpi.verse_id, rpi.item_order, rpi.is_read
			  FROM reading_plan_items rpi
			  WHERE rpi.reading_plan_id = $1
			  ORDER BY rpi.item_order`

	rows, err := r.DB.Query(ctx, query, planID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*model.ReadingPlanItem
	for rows.Next() {
		var item model.ReadingPlanItem
		var itemID, verseID uuid.UUID
		err := rows.Scan(&itemID, &verseID, &item.ItemOrder, &item.IsRead)
		if err != nil {
			return nil, err
		}

		verse, err := r.getVerseByID(ctx, verseID)
		if err != nil {
			return nil, err
		}
		item.ID = itemID
		item.Verse = verse

		items = append(items, &item)
	}

	return items, nil
}

// generateAdviceForProblem generates AI advice for a problem using OpenRouter
func (r *Resolver) generateAdviceForProblem(ctx context.Context, problemID uuid.UUID) error {
	// Get problem details
	query := `SELECT title, description FROM problems WHERE id = $1`
	var title, description string
	err := r.DB.QueryRow(ctx, query, problemID).Scan(&title, &description)
	if err != nil {
		return fmt.Errorf("failed to get problem: %w", err)
	}

	// TODO: Implement verse similarity search here
	// For now, use some example verses
	verses := []string{
		"Philippians 4:6-7 - Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.",
		"Jeremiah 29:11 - For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.",
		"Matthew 11:28-30 - Come to me, all you who are weary and burdened, and I will give you rest. Take my yoke upon you and learn from me, for I am gentle and humble in heart, and you will find rest for your souls. For my yoke is easy and my burden is light.",
	}

	// Generate advice
	advice, err := r.AIClient.GenerateAdvice(ctx, description, verses)
	if err != nil {
		return fmt.Errorf("failed to generate advice: %w", err)
	}

	// Update problem with advice
	updateQuery := `UPDATE problems SET advice = $1, updated_at = $2 WHERE id = $3`
	_, err = r.DB.Exec(ctx, updateQuery, advice, time.Now(), problemID)
	if err != nil {
		return fmt.Errorf("failed to update advice: %w", err)
	}

	return nil
}

func (r *Resolver) getVerseByID(ctx context.Context, verseID uuid.UUID) (*model.Verse, error) {
	query := `SELECT id, book, chapter, verse, text FROM verses WHERE id = $1`
	var verse model.Verse
	var vID uuid.UUID
	err := r.DB.QueryRow(ctx, query, verseID).Scan(&vID, &verse.Book, &verse.Chapter, &verse.Verse, &verse.Text)
	if err != nil {
		return nil, err
	}
	verse.ID = vID

	return &verse, nil
}
