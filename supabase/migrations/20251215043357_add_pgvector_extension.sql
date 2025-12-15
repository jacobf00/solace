-- Migration: add_pgvector_extension
-- Description: Add pgvector extension for AI embeddings support

-- Enable pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Add embedding column to verses table for AI vector search
ALTER TABLE public.verses 
ADD COLUMN embedding vector(384);

-- Create index for vector similarity search using IVFFLAT
-- This index will be used for cosine similarity searches
CREATE INDEX idx_verses_embedding_cosine 
ON public.verses 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);

-- Add comment for documentation
COMMENT ON COLUMN public.verses.embedding IS '384-dimensional vector embedding for AI similarity search using all-MiniLM-L6-v2 model';

