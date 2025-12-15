-- Migration: import_verses_data
-- Description: Import Bible verses from ASV.csv into the verses table
-- Note: The CSV file path may need to be adjusted based on your Supabase setup
-- In production, you may want to use a different data loading mechanism

-- Import verses from ASV.csv into the verses table
-- The CSV has headers: Book,Chapter,Verse,Text
-- The table has columns: id (auto), book, chapter, verse, text, embedding (null initially)

-- Copy data from CSV file into verses table
-- Note: Adjust the file path as needed for your Supabase environment
COPY public.verses (book, chapter, verse, text)
FROM '/var/lib/postgresql/data/ASV.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    QUOTE '"',
    ESCAPE '"'
);

-- Add a comment for documentation
COMMENT ON TABLE public.verses IS 'Bible verses from ASV translation, ready for embedding generation';

