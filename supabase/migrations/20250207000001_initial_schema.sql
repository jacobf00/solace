-- Initial Schema for Solace App
-- Uses auth.users for authentication (no custom users table)
-- Username = email

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Bible verses table
CREATE TABLE public.verses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book VARCHAR(50) NOT NULL,
    chapter INTEGER NOT NULL,
    "verse" INTEGER NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(book, chapter, "verse")
);

-- User problems table
CREATE TABLE public.problems (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    context TEXT,
    category VARCHAR(100),
    advice TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reading plans for problems
CREATE TABLE public.reading_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    problem_id UUID NOT NULL REFERENCES public.problems(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Individual verses in reading plans
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

-- Feedback on AI advice
CREATE TABLE public.advice_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    problem_id UUID NOT NULL REFERENCES public.problems(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback_text TEXT,
    is_helpful BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(problem_id, user_id)
);

-- Reading plan revision history
CREATE TABLE public.plan_revisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reading_plan_id UUID NOT NULL REFERENCES public.reading_plans(id) ON DELETE CASCADE,
    revision_number INTEGER NOT NULL,
    changes JSONB NOT NULL,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI-classified verse topics
CREATE TABLE public.verse_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verse_id UUID NOT NULL REFERENCES public.verses(id) ON DELETE CASCADE,
    topic VARCHAR(100) NOT NULL,
    confidence DECIMAL(3, 2) CHECK (confidence >= 0 AND confidence <= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(verse_id, topic)
);

-- Indexes for performance
CREATE INDEX idx_problems_user_id ON public.problems(user_id);
CREATE INDEX idx_problems_created_at ON public.problems(created_at);
CREATE INDEX idx_problems_category ON public.problems(category);

CREATE INDEX idx_verses_book ON public.verses(book);
CREATE INDEX idx_verses_book_chapter ON public.verses(book, chapter);

CREATE INDEX idx_reading_plans_problem_id ON public.reading_plans(problem_id);
CREATE INDEX idx_reading_plan_items_plan_id ON public.reading_plan_items(reading_plan_id);
CREATE INDEX idx_reading_plan_items_verse_id ON public.reading_plan_items(verse_id);
CREATE INDEX idx_reading_plan_items_order ON public.reading_plan_items(reading_plan_id, item_order);

CREATE INDEX idx_advice_feedback_problem_id ON public.advice_feedback(problem_id);
CREATE INDEX idx_advice_feedback_user_id ON public.advice_feedback(user_id);

CREATE INDEX idx_verse_topics_verse_id ON public.verse_topics(verse_id);
CREATE INDEX idx_verse_topics_topic ON public.verse_topics(topic);

-- Comments
COMMENT ON TABLE public.verses IS 'Bible verses with text content';
COMMENT ON TABLE public.problems IS 'User-submitted life problems and AI-generated advice';
COMMENT ON TABLE public.reading_plans IS 'Generated reading plans for specific problems';
COMMENT ON TABLE public.reading_plan_items IS 'Individual verses within a reading plan';
COMMENT ON TABLE public.advice_feedback IS 'User feedback on AI-generated advice quality';
COMMENT ON TABLE public.plan_revisions IS 'Version history for reading plan modifications';
COMMENT ON TABLE public.verse_topics IS 'AI-generated topic classifications for Bible verses';
