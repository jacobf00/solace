-- Migration: 000002_add_pgvector_extension.down.sql
-- Description: Rollback pgvector extension changes
-- Created: 2024-01-01
-- Author: System

-- Drop the vector similarity index
DROP INDEX IF EXISTS idx_verses_embedding_cosine;

-- Remove the embedding column
ALTER TABLE verses DROP COLUMN IF EXISTS embedding;

-- Note: pgvector extension is not dropped as it might be used by other applications
