-- Migration: 000004_add_audit_and_ai_tables.down.sql
-- Description: Rollback audit logging and AI event tracking tables
-- Created: 2024-01-01
-- Author: System

-- Drop tables in reverse order
DROP TABLE IF EXISTS verse_topics;
DROP TABLE IF EXISTS plan_revisions;
DROP TABLE IF EXISTS advice_feedback;
DROP TABLE IF EXISTS ai_events;
DROP TABLE IF EXISTS audit_logs;
