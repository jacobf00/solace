package model

import (
	"time"
)

type User struct {
	ID        string     `json:"id"`
	Username  string     `json:"username"`
	Email     string     `json:"email"`
	Problems  []*Problem `json:"problems"`
	CreatedAt time.Time  `json:"createdAt"`
}

type Problem struct {
	ID          string       `json:"id"`
	Title       string       `json:"title"`
	Description string       `json:"description"`
	Context     *string      `json:"context,omitempty"`
	Category    *string      `json:"category,omitempty"`
	CreatedAt   time.Time    `json:"createdAt"`
	UpdatedAt   *time.Time   `json:"updatedAt,omitempty"`
	ReadingPlan *ReadingPlan `json:"readingPlan,omitempty"`
	Advice      *string      `json:"advice,omitempty"`
	UserID      string       `json:"userId"`
}

type ReadingPlan struct {
	ID        string             `json:"id"`
	Problem   *Problem           `json:"problem"`
	CreatedAt time.Time          `json:"createdAt"`
	UpdatedAt *time.Time         `json:"updatedAt,omitempty"`
	Items     []*ReadingPlanItem `json:"items"`
}

type ReadingPlanItem struct {
	ID        string     `json:"id"`
	Verse     *Verse     `json:"verse"`
	ItemOrder int32      `json:"itemOrder"`
	IsRead    bool       `json:"isRead"`
	CreatedAt time.Time  `json:"createdAt,omitempty"`
	UpdatedAt *time.Time `json:"updatedAt,omitempty"`
}

type Verse struct {
	ID      string `json:"id"`
	Book    string `json:"book"`
	Chapter int32  `json:"chapter"`
	Verse   int32  `json:"verse"`
	Text    string `json:"text"`
}

type AuthResponse struct {
	User  *User  `json:"user"`
	Token string `json:"token"`
}

type Feedback struct {
	ID           string     `json:"id"`
	ProblemID    string     `json:"problemId"`
	UserID       *string    `json:"userId,omitempty"`
	Rating       int        `json:"rating"`
	FeedbackText *string    `json:"feedbackText,omitempty"`
	IsHelpful    *bool      `json:"isHelpful,omitempty"`
	CreatedAt    time.Time  `json:"createdAt"`
	UpdatedAt    *time.Time `json:"updatedAt,omitempty"`
}

type PlanRevision struct {
	ID             string    `json:"id"`
	ReadingPlanID  string    `json:"readingPlanId"`
	RevisionNumber int32     `json:"revisionNumber"`
	Changes        string    `json:"changes"`
	CreatedBy      *string   `json:"createdBy,omitempty"`
	CreatedAt      time.Time `json:"createdAt"`
}

type VerseTopic struct {
	ID         string    `json:"id"`
	VerseID    string    `json:"verseId"`
	Topic      string    `json:"topic"`
	Confidence float64   `json:"confidence"`
	CreatedAt  time.Time `json:"createdAt"`
}

type PlanChanges struct {
	AddedVerses     []string `json:"addedVerses,omitempty"`
	RemovedVerses   []string `json:"removedVerses,omitempty"`
	ReorderedVerses []string `json:"reorderedVerses,omitempty"`
	Notes           *string  `json:"notes,omitempty"`
}

type FeedbackInput struct {
	ProblemID    string  `json:"problemId"`
	Rating       int     `json:"rating"`
	FeedbackText *string `json:"feedbackText,omitempty"`
}

type Query struct {
}

type Mutation struct {
}
