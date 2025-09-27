-- Migration: 000006_add_triggers_and_functions.up.sql
-- Description: Add database triggers and functions for automatic timestamp updates
-- Created: 2024-01-01
-- Author: System

-- Create function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for automatic updated_at timestamp updates
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_problems_updated_at 
    BEFORE UPDATE ON problems 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reading_plans_updated_at 
    BEFORE UPDATE ON reading_plans 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reading_plan_items_updated_at 
    BEFORE UPDATE ON reading_plan_items 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_advice_feedback_updated_at 
    BEFORE UPDATE ON advice_feedback 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to clean up expired sessions and tokens
CREATE OR REPLACE FUNCTION cleanup_expired_tokens()
RETURNS void AS $$
BEGIN
    -- Delete expired sessions
    DELETE FROM sessions WHERE expires_at < NOW();
    
    -- Delete expired refresh tokens
    DELETE FROM refresh_tokens WHERE expires_at < NOW();
    
    -- Delete expired password reset tokens
    DELETE FROM password_resets WHERE expires_at < NOW();
    
    -- Delete expired email verification tokens
    DELETE FROM email_verifications WHERE expires_at < NOW();
END;
$$ language 'plpgsql';

-- Create function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS TABLE(
    total_problems BIGINT,
    total_reading_plans BIGINT,
    verses_read BIGINT,
    avg_advice_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM problems WHERE user_id = user_uuid) as total_problems,
        (SELECT COUNT(*) FROM reading_plans rp 
         JOIN problems p ON rp.problem_id = p.id 
         WHERE p.user_id = user_uuid) as total_reading_plans,
        (SELECT COUNT(*) FROM reading_plan_items rpi
         JOIN reading_plans rp ON rpi.reading_plan_id = rp.id
         JOIN problems p ON rp.problem_id = p.id
         WHERE p.user_id = user_uuid AND rpi.is_read = true) as verses_read,
        (SELECT AVG(rating) FROM advice_feedback af
         JOIN problems p ON af.problem_id = p.id
         WHERE p.user_id = user_uuid AND af.rating IS NOT NULL) as avg_advice_rating;
END;
$$ language 'plpgsql';

-- Create function to search verses by similarity (for AI integration)
CREATE OR REPLACE FUNCTION search_similar_verses(
    query_embedding vector(384),
    similarity_threshold FLOAT DEFAULT 0.7,
    max_results INTEGER DEFAULT 10
)
RETURNS TABLE(
    verse_id UUID,
    book VARCHAR,
    chapter INTEGER,
    verse INTEGER,
    text TEXT,
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id,
        v.book,
        v.chapter,
        v.verse,
        v.text,
        1 - (v.embedding <=> query_embedding) as similarity
    FROM verses v
    WHERE v.embedding IS NOT NULL
    AND 1 - (v.embedding <=> query_embedding) > similarity_threshold
    ORDER BY v.embedding <=> query_embedding
    LIMIT max_results;
END;
$$ language 'plpgsql';

-- Add comments for documentation
COMMENT ON FUNCTION update_updated_at_column() IS 'Trigger function to automatically update updated_at timestamps';
COMMENT ON FUNCTION cleanup_expired_tokens() IS 'Function to clean up expired authentication tokens and sessions';
COMMENT ON FUNCTION get_user_stats(UUID) IS 'Function to retrieve user statistics including problems, reading plans, and ratings';
COMMENT ON FUNCTION search_similar_verses(vector, FLOAT, INTEGER) IS 'Function to perform vector similarity search on Bible verses for AI recommendations';
