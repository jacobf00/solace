-- Migration: 000005_import_verses_data.down.sql
-- Description: Rollback verse data import
-- Created: 2024-01-01
-- Author: System

-- Clear all verse data
DELETE FROM verses;

-- Reset the sequence if using auto-increment (though we're using UUIDs)
-- This is just for completeness
