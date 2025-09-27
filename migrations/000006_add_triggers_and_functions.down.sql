-- Migration: 000006_add_triggers_and_functions.down.sql
-- Description: Rollback database triggers and functions
-- Created: 2024-01-01
-- Author: System

-- Drop triggers
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_problems_updated_at ON problems;
DROP TRIGGER IF EXISTS update_reading_plans_updated_at ON reading_plans;
DROP TRIGGER IF EXISTS update_reading_plan_items_updated_at ON reading_plan_items;
DROP TRIGGER IF EXISTS update_advice_feedback_updated_at ON advice_feedback;

-- Drop functions
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS cleanup_expired_tokens();
DROP FUNCTION IF EXISTS get_user_stats(UUID);
DROP FUNCTION IF EXISTS search_similar_verses(vector, FLOAT, INTEGER);
