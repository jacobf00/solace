-- Migration: 000002_add_pgvector_extension.up.sql
-- Description: Add pgvector extension for AI embeddings support
-- Created: 2024-01-01
-- Author: System

-- Enable pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Add embedding column to verses table for AI vector search
ALTER TABLE verses 
ADD COLUMN embedding vector(384);

-- Create index for vector similarity search using IVFFLAT
-- This index will be used for cosine similarity searches
CREATE INDEX idx_verses_embedding_cosine 
ON verses 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);

-- Add comment for documentation
COMMENT ON COLUMN verses.embedding IS '384-dimensional vector embedding for AI similarity search using all-MiniLM-L6-v2 model';
