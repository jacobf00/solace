-- Import Bible verses from CSV
-- Embeddings column is NULL initially - will be populated later

CREATE TEMP TABLE temp_verses (
    book VARCHAR(50),
    chapter INTEGER,
    verse_num INTEGER,
    text TEXT
);

-- Copy from CSV (adjust path for Supabase local vs production)
\COPY temp_verses(book, chapter, verse_num, text) 
FROM '/supabase/ASV.csv' 
WITH (FORMAT csv, HEADER true);

-- Insert into verses table (embedding will be NULL)
INSERT INTO public.verses (book, chapter, "verse", text)
SELECT book, chapter, verse_num, text
FROM temp_verses;

DROP TABLE temp_verses;

-- Create index for text search (fallback when embeddings aren't ready)
CREATE INDEX idx_verses_text_search ON public.verses 
USING gin(to_tsvector('english', text));

COMMENT ON INDEX idx_verses_text_search IS 'Full-text search index for verses (fallback)';
