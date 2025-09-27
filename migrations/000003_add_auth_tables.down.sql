-- Migration: 000003_add_auth_tables.down.sql
-- Description: Rollback authentication and session management tables
-- Created: 2024-01-01
-- Author: System

-- Drop tables in reverse order
DROP TABLE IF EXISTS email_verifications;
DROP TABLE IF EXISTS password_resets;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS sessions;
