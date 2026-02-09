-- Enable pgvector extension for AI embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Add embedding column to verses for vector similarity search
-- Note: Embeddings will be populated later via batch script
ALTER TABLE public.verses 
ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- Create index for vector similarity (will be used once embeddings are populated)
CREATE INDEX idx_verses_embedding_cosine 
ON public.verses 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100)
WHERE embedding IS NOT NULL;

COMMENT ON COLUMN public.verses.embedding IS '1536-dimensional vector embedding for AI similarity search (text-embedding-3-small)';
