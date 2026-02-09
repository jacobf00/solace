-- Auto-update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach triggers
CREATE TRIGGER update_problems_updated_at 
    BEFORE UPDATE ON public.problems 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_reading_plans_updated_at 
    BEFORE UPDATE ON public.reading_plans 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_reading_plan_items_updated_at 
    BEFORE UPDATE ON public.reading_plan_items 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_advice_feedback_updated_at 
    BEFORE UPDATE ON public.advice_feedback 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Get user stats
CREATE OR REPLACE FUNCTION public.get_user_stats(user_uuid UUID)
RETURNS TABLE(
    total_problems BIGINT,
    total_reading_plans BIGINT,
    verses_read BIGINT,
    avg_advice_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM public.problems WHERE user_id = user_uuid),
        (SELECT COUNT(*) FROM public.reading_plans rp 
         JOIN public.problems p ON rp.problem_id = p.id 
         WHERE p.user_id = user_uuid),
        (SELECT COUNT(*) FROM public.reading_plan_items rpi
         JOIN public.reading_plans rp ON rpi.reading_plan_id = rp.id
         JOIN public.problems p ON rp.problem_id = p.id
         WHERE p.user_id = user_uuid AND rpi.is_read = true),
        (SELECT AVG(rating) FROM public.advice_feedback af
         JOIN public.problems p ON af.problem_id = p.id
         WHERE p.user_id = user_uuid AND af.rating IS NOT NULL);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Vector similarity search
CREATE OR REPLACE FUNCTION public.search_similar_verses(
    query_embedding vector(1536),
    similarity_threshold FLOAT DEFAULT 0.7,
    max_results INTEGER DEFAULT 10
)
RETURNS TABLE(
    verse_id UUID,
    book VARCHAR,
    chapter INTEGER,
    verse_num INTEGER,
    text TEXT,
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id,
        v.book,
        v.chapter,
        v."verse",
        v.text,
        1 - (v.embedding <=> query_embedding) as similarity
    FROM public.verses v
    WHERE v.embedding IS NOT NULL
    AND 1 - (v.embedding <=> query_embedding) > similarity_threshold
    ORDER BY v.embedding <=> query_embedding
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Get all unique Bible books
CREATE OR REPLACE FUNCTION public.get_all_books()
RETURNS TABLE(book VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT v.book 
    FROM public.verses v
    ORDER BY v.book;
END;
$$ LANGUAGE plpgsql;

-- Comments
COMMENT ON FUNCTION public.update_updated_at_column() IS 'Auto-update updated_at timestamps';
COMMENT ON FUNCTION public.get_user_stats(UUID) IS 'Get user statistics';
COMMENT ON FUNCTION public.search_similar_verses(vector, FLOAT, INTEGER) IS 'Vector similarity search on verses';
