-- Migration: 000004_add_audit_and_ai_tables.up.sql
-- Description: Add audit logging and AI event tracking tables
-- Created: 2024-01-01
-- Author: System

-- Create audit_logs table for tracking important user actions
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create ai_events table for tracking AI operations and performance
CREATE TABLE ai_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL, -- 'embedding', 'similarity_search', 'advice_generation'
    model_name VARCHAR(100) NOT NULL,
    input_tokens INTEGER,
    output_tokens INTEGER,
    latency_ms INTEGER,
    cost_usd DECIMAL(10, 6),
    success BOOLEAN NOT NULL DEFAULT true,
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create advice_feedback table for user feedback on AI-generated advice
CREATE TABLE advice_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    problem_id UUID NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback_text TEXT,
    is_helpful BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(problem_id, user_id)
);

-- Create plan_revisions table for tracking reading plan updates
CREATE TABLE plan_revisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reading_plan_id UUID NOT NULL REFERENCES reading_plans(id) ON DELETE CASCADE,
    revision_number INTEGER NOT NULL,
    changes JSONB NOT NULL, -- Store the changes made in this revision
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create verse_topics table for categorizing verses by topic
CREATE TABLE verse_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verse_id UUID NOT NULL REFERENCES verses(id) ON DELETE CASCADE,
    topic VARCHAR(100) NOT NULL,
    confidence DECIMAL(3, 2) CHECK (confidence >= 0 AND confidence <= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(verse_id, topic)
);

-- Create indexes for performance
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

CREATE INDEX idx_ai_events_user_id ON ai_events(user_id);
CREATE INDEX idx_ai_events_event_type ON ai_events(event_type);
CREATE INDEX idx_ai_events_model_name ON ai_events(model_name);
CREATE INDEX idx_ai_events_created_at ON ai_events(created_at);
CREATE INDEX idx_ai_events_success ON ai_events(success);

CREATE INDEX idx_advice_feedback_problem_id ON advice_feedback(problem_id);
CREATE INDEX idx_advice_feedback_user_id ON advice_feedback(user_id);
CREATE INDEX idx_advice_feedback_rating ON advice_feedback(rating);
CREATE INDEX idx_advice_feedback_created_at ON advice_feedback(created_at);

CREATE INDEX idx_plan_revisions_plan_id ON plan_revisions(reading_plan_id);
CREATE INDEX idx_plan_revisions_revision_number ON plan_revisions(reading_plan_id, revision_number);
CREATE INDEX idx_plan_revisions_created_at ON plan_revisions(created_at);

CREATE INDEX idx_verse_topics_verse_id ON verse_topics(verse_id);
CREATE INDEX idx_verse_topics_topic ON verse_topics(topic);
CREATE INDEX idx_verse_topics_confidence ON verse_topics(confidence);

-- Add comments for documentation
COMMENT ON TABLE audit_logs IS 'Audit trail for important user actions and system events';
COMMENT ON TABLE ai_events IS 'Tracking of AI operations, performance metrics, and costs';
COMMENT ON TABLE advice_feedback IS 'User feedback on AI-generated advice quality';
COMMENT ON TABLE plan_revisions IS 'Version history for reading plan modifications';
COMMENT ON TABLE verse_topics IS 'AI-generated topic classifications for Bible verses';

COMMENT ON COLUMN audit_logs.details IS 'JSON details about the audited action';
COMMENT ON COLUMN ai_events.metadata IS 'Additional metadata about the AI operation';
COMMENT ON COLUMN advice_feedback.rating IS 'User rating from 1-5 stars';
COMMENT ON COLUMN plan_revisions.changes IS 'JSON representation of changes made in this revision';
COMMENT ON COLUMN verse_topics.confidence IS 'AI confidence score for topic classification (0.0-1.0)';
