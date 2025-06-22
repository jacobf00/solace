-- Import verses from ASV.csv into the verses table
-- This script uses COPY to efficiently load the CSV data

\echo 'Starting import of verses from ASV.csv...'

-- Copy data from CSV file into verses table
-- The CSV has headers: Book,Chapter,Verse,Text
-- The table has columns: id (auto), book, chapter, verse, text, embedding (null)
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
