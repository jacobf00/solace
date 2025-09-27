-- Migration: 000001_initial_schema.down.sql
-- Description: Rollback initial database schema
-- Created: 2024-01-01
-- Author: System

-- Drop tables in reverse order (respecting foreign key constraints)
DROP TABLE IF EXISTS reading_plan_items;
DROP TABLE IF EXISTS reading_plans;
DROP TABLE IF EXISTS verses;
DROP TABLE IF EXISTS problems;
DROP TABLE IF EXISTS users;

-- Note: Extensions are not dropped as they might be used by other applications
