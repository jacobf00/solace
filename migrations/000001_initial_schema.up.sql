-- Migration: 000001_initial_schema.up.sql
-- Description: Create initial database schema for Solace application
-- Created: 2024-01-01
-- Author: System

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create users table
CREATE TABLE users (
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
CREATE TABLE problems (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    context TEXT,
    category VARCHAR(100),
    advice TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create verses table (for Bible text with embeddings)
CREATE TABLE verses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book VARCHAR(50) NOT NULL,
    chapter INTEGER NOT NULL,
    verse INTEGER NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(book, chapter, verse)
);

-- Create reading_plans table
CREATE TABLE reading_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    problem_id UUID NOT NULL REFERENCES problems(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create reading_plan_items table
CREATE TABLE reading_plan_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reading_plan_id UUID NOT NULL REFERENCES reading_plans(id) ON DELETE CASCADE,
    verse_id UUID NOT NULL REFERENCES verses(id) ON DELETE CASCADE,
    item_order INTEGER NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reading_plan_id, verse_id)
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_created_at ON users(created_at);

CREATE INDEX idx_problems_user_id ON problems(user_id);
CREATE INDEX idx_problems_created_at ON problems(created_at);
CREATE INDEX idx_problems_category ON problems(category);

CREATE INDEX idx_verses_book ON verses(book);
CREATE INDEX idx_verses_book_chapter ON verses(book, chapter);
CREATE INDEX idx_verses_created_at ON verses(created_at);

CREATE INDEX idx_reading_plans_problem_id ON reading_plans(problem_id);
CREATE INDEX idx_reading_plans_created_at ON reading_plans(created_at);

CREATE INDEX idx_reading_plan_items_plan_id ON reading_plan_items(reading_plan_id);
CREATE INDEX idx_reading_plan_items_verse_id ON reading_plan_items(verse_id);
CREATE INDEX idx_reading_plan_items_order ON reading_plan_items(reading_plan_id, item_order);

-- Add comments for documentation
COMMENT ON TABLE users IS 'User accounts for the Solace application';
COMMENT ON TABLE problems IS 'User-submitted life problems and their details';
COMMENT ON TABLE verses IS 'Bible verses with text content';
COMMENT ON TABLE reading_plans IS 'Generated reading plans for specific problems';
COMMENT ON TABLE reading_plan_items IS 'Individual verses within a reading plan';

COMMENT ON COLUMN users.password_hash IS 'Argon2id hashed password';
COMMENT ON COLUMN problems.advice IS 'AI-generated Biblical advice for the problem';
COMMENT ON COLUMN reading_plan_items.item_order IS 'Order of verses in the reading plan';
COMMENT ON COLUMN reading_plan_items.is_read IS 'Whether the user has marked this verse as read';
