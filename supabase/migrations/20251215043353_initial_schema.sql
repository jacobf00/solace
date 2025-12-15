-- Migration: initial_schema
-- Description: Create initial database schema for Solace application
-- Created: 2024-01-01

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create users table
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    email_verified_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

-- Create problems table
CREATE TABLE public.problems (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    context TEXT,
    category VARCHAR(100),
    advice TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create verses table (for Bible text with embeddings)
CREATE TABLE public.verses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book VARCHAR(50) NOT NULL,
    chapter INTEGER NOT NULL,
    verse INTEGER NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(book, chapter, verse)
);

-- Create reading_plans table
CREATE TABLE public.reading_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    problem_id UUID NOT NULL REFERENCES public.problems(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create reading_plan_items table
CREATE TABLE public.reading_plan_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reading_plan_id UUID NOT NULL REFERENCES public.reading_plans(id) ON DELETE CASCADE,
    verse_id UUID NOT NULL REFERENCES public.verses(id) ON DELETE CASCADE,
    item_order INTEGER NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reading_plan_id, verse_id)
);

-- Create advice_feedback table for user feedback on AI-generated advice
CREATE TABLE public.advice_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    problem_id UUID NOT NULL REFERENCES public.problems(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback_text TEXT,
    is_helpful BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(problem_id, user_id)
);

-- Create plan_revisions table for tracking reading plan updates
CREATE TABLE public.plan_revisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reading_plan_id UUID NOT NULL REFERENCES public.reading_plans(id) ON DELETE CASCADE,
    revision_number INTEGER NOT NULL,
    changes JSONB NOT NULL, -- Store the changes made in this revision
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create verse_topics table for categorizing verses by topic
CREATE TABLE public.verse_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verse_id UUID NOT NULL REFERENCES public.verses(id) ON DELETE CASCADE,
    topic VARCHAR(100) NOT NULL,
    confidence DECIMAL(3, 2) CHECK (confidence >= 0 AND confidence <= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(verse_id, topic)
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_username ON public.users(username);
CREATE INDEX idx_users_created_at ON public.users(created_at);

CREATE INDEX idx_problems_user_id ON public.problems(user_id);
CREATE INDEX idx_problems_created_at ON public.problems(created_at);
CREATE INDEX idx_problems_category ON public.problems(category);

CREATE INDEX idx_verses_book ON public.verses(book);
CREATE INDEX idx_verses_book_chapter ON public.verses(book, chapter);
CREATE INDEX idx_verses_created_at ON public.verses(created_at);

CREATE INDEX idx_reading_plans_problem_id ON public.reading_plans(problem_id);
CREATE INDEX idx_reading_plans_created_at ON public.reading_plans(created_at);

CREATE INDEX idx_reading_plan_items_plan_id ON public.reading_plan_items(reading_plan_id);
CREATE INDEX idx_reading_plan_items_verse_id ON public.reading_plan_items(verse_id);
CREATE INDEX idx_reading_plan_items_order ON public.reading_plan_items(reading_plan_id, item_order);

CREATE INDEX idx_advice_feedback_problem_id ON public.advice_feedback(problem_id);
CREATE INDEX idx_advice_feedback_user_id ON public.advice_feedback(user_id);
CREATE INDEX idx_advice_feedback_rating ON public.advice_feedback(rating);
CREATE INDEX idx_advice_feedback_created_at ON public.advice_feedback(created_at);

CREATE INDEX idx_plan_revisions_plan_id ON public.plan_revisions(reading_plan_id);
CREATE INDEX idx_plan_revisions_revision_number ON public.plan_revisions(reading_plan_id, revision_number);
CREATE INDEX idx_plan_revisions_created_at ON public.plan_revisions(created_at);

CREATE INDEX idx_verse_topics_verse_id ON public.verse_topics(verse_id);
CREATE INDEX idx_verse_topics_topic ON public.verse_topics(topic);
CREATE INDEX idx_verse_topics_confidence ON public.verse_topics(confidence);

-- Add comments for documentation
COMMENT ON TABLE public.users IS 'User accounts for the Solace application';
COMMENT ON TABLE public.problems IS 'User-submitted life problems and their details';
COMMENT ON TABLE public.verses IS 'Bible verses with text content';
COMMENT ON TABLE public.reading_plans IS 'Generated reading plans for specific problems';
COMMENT ON TABLE public.reading_plan_items IS 'Individual verses within a reading plan';
COMMENT ON TABLE public.advice_feedback IS 'User feedback on AI-generated advice quality';
COMMENT ON TABLE public.plan_revisions IS 'Version history for reading plan modifications';
COMMENT ON TABLE public.verse_topics IS 'AI-generated topic classifications for Bible verses';

COMMENT ON COLUMN public.users.password_hash IS 'Argon2id hashed password';
COMMENT ON COLUMN public.problems.advice IS 'AI-generated Biblical advice for the problem';
COMMENT ON COLUMN public.reading_plan_items.item_order IS 'Order of verses in the reading plan';
COMMENT ON COLUMN public.reading_plan_items.is_read IS 'Whether the user has marked this verse as read';
COMMENT ON COLUMN public.advice_feedback.rating IS 'User rating from 1-5 stars';
COMMENT ON COLUMN public.plan_revisions.changes IS 'JSON representation of changes made in this revision';
COMMENT ON COLUMN public.verse_topics.confidence IS 'AI confidence score for topic classification (0.0-1.0)';

