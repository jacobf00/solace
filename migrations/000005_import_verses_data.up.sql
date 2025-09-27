-- Migration: 000005_import_verses_data.up.sql
-- Description: Import Bible verses from ASV.csv into the verses table
-- Created: 2024-01-01
-- Author: System

-- Note: This migration assumes the ASV.csv file is available at the specified path
-- In production, you would typically use a more robust data loading mechanism

-- Import verses from ASV.csv into the verses table
-- The CSV has headers: Book,Chapter,Verse,Text
-- The table has columns: id (auto), book, chapter, verse, text, embedding (null initially)

\echo 'Starting import of verses from ASV.csv...'

-- Copy data from CSV file into verses table
COPY verses (book, chapter, verse, text)
FROM '/Users/$USER/projects/solace/ASV.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    QUOTE '"',
    ESCAPE '"'
);

-- Display statistics after import
\echo 'Import completed. Checking results...'

SELECT COUNT(*) as total_verses FROM verses;

SELECT book, COUNT(*) as verse_count
FROM verses
GROUP BY book
ORDER BY MIN(id)
LIMIT 10;

\echo 'First 5 verses imported:'
SELECT id, book, chapter, verse, LEFT(text, 50) || '...' as text_preview
FROM verses
ORDER BY id
LIMIT 5;

\echo 'Import script completed successfully!'

-- Add a comment for documentation
COMMENT ON TABLE verses IS 'Bible verses from ASV translation, ready for embedding generation';
