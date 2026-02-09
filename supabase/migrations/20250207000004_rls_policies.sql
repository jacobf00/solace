-- Enable RLS on all tables
ALTER TABLE public.problems ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_plan_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advice_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verse_topics ENABLE ROW LEVEL SECURITY;

-- Problems: Users can only access their own
CREATE POLICY "Users can view own problems" ON public.problems
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own problems" ON public.problems
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own problems" ON public.problems
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own problems" ON public.problems
    FOR DELETE USING (auth.uid() = user_id);

-- Verses: Public read-only
CREATE POLICY "Public read access to verses" ON public.verses
    FOR SELECT USING (true);

-- Reading Plans: Access through problem ownership
CREATE POLICY "Users can view own reading plans" ON public.reading_plans
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.problems
            WHERE problems.id = reading_plans.problem_id
            AND problems.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own reading plans" ON public.reading_plans
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.problems
            WHERE problems.id = reading_plans.problem_id
            AND problems.user_id = auth.uid()
        )
    );

-- Reading Plan Items: Access through reading plan
CREATE POLICY "Users can view own reading plan items" ON public.reading_plan_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.reading_plans rp
            JOIN public.problems p ON rp.problem_id = p.id
            WHERE rp.id = reading_plan_items.reading_plan_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own reading plan items" ON public.reading_plan_items
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.reading_plans rp
            JOIN public.problems p ON rp.problem_id = p.id
            WHERE rp.id = reading_plan_items.reading_plan_id
            AND p.user_id = auth.uid()
        )
    );

-- Advice Feedback: Users can only access their own
CREATE POLICY "Users can view own feedback" ON public.advice_feedback
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feedback" ON public.advice_feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Plan Revisions: View through reading plan
CREATE POLICY "Users can view own plan revisions" ON public.plan_revisions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.reading_plans rp
            JOIN public.problems p ON rp.problem_id = p.id
            WHERE rp.id = plan_revisions.reading_plan_id
            AND p.user_id = auth.uid()
        )
    );

-- Verse Topics: Public read-only
CREATE POLICY "Public read access to verse_topics" ON public.verse_topics
    FOR SELECT USING (true);

-- Service role bypass (for admin operations)
CREATE POLICY "Service role full access" ON public.problems
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
CREATE POLICY "Service role full access" ON public.verses
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
CREATE POLICY "Service role full access" ON public.reading_plans
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
CREATE POLICY "Service role full access" ON public.reading_plan_items
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
CREATE POLICY "Service role full access" ON public.advice_feedback
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
CREATE POLICY "Service role full access" ON public.plan_revisions
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
CREATE POLICY "Service role full access" ON public.verse_topics
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');
