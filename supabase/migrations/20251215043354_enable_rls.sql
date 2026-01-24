-- Migration: enable_rls
-- Description: Enable Row Level Security and create policies for all tables
-- Created: 2025-01-18

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.problems ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reading_plan_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advice_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verse_topics ENABLE ROW LEVEL SECURITY;

-- Policies for users table
-- Users can only see and modify their own data
CREATE POLICY "Users can view own user" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own user" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Service role can do everything (for backend operations)
CREATE POLICY "Service role full access on users" ON public.users
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policies for problems table
CREATE POLICY "Users can view own problems" ON public.problems
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own problems" ON public.problems
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own problems" ON public.problems
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own problems" ON public.problems
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role full access on problems" ON public.problems
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policies for verses table
-- Verses are public read-only
CREATE POLICY "Public read access to verses" ON public.verses
    FOR SELECT USING (true);

CREATE POLICY "Service role full access on verses" ON public.verses
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policies for reading_plans table
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

CREATE POLICY "Users can update own reading plans" ON public.reading_plans
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.problems
            WHERE problems.id = reading_plans.problem_id
            AND problems.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own reading plans" ON public.reading_plans
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.problems
            WHERE problems.id = reading_plans.problem_id
            AND problems.user_id = auth.uid()
        )
    );

CREATE POLICY "Service role full access on reading_plans" ON public.reading_plans
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policies for reading_plan_items table
CREATE POLICY "Users can view own reading plan items" ON public.reading_plan_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.reading_plans rp
            JOIN public.problems p ON rp.problem_id = p.id
            WHERE rp.id = reading_plan_items.reading_plan_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own reading plan items" ON public.reading_plan_items
    FOR INSERT WITH CHECK (
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

CREATE POLICY "Users can delete own reading plan items" ON public.reading_plan_items
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.reading_plans rp
            JOIN public.problems p ON rp.problem_id = p.id
            WHERE rp.id = reading_plan_items.reading_plan_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Service role full access on reading_plan_items" ON public.reading_plan_items
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policies for advice_feedback table
CREATE POLICY "Users can view own feedback" ON public.advice_feedback
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feedback" ON public.advice_feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own feedback" ON public.advice_feedback
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own feedback" ON public.advice_feedback
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role full access on advice_feedback" ON public.advice_feedback
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policies for plan_revisions table
CREATE POLICY "Users can view own plan revisions" ON public.plan_revisions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.reading_plans rp
            JOIN public.problems p ON rp.problem_id = p.id
            WHERE rp.id = plan_revisions.reading_plan_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own plan revisions" ON public.plan_revisions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.reading_plans rp
            JOIN public.problems p ON rp.problem_id = p.id
            WHERE rp.id = plan_revisions.reading_plan_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Service role full access on plan_revisions" ON public.plan_revisions
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policies for verse_topics table
-- Verse topics are public read-only
CREATE POLICY "Public read access to verse_topics" ON public.verse_topics
    FOR SELECT USING (true);

CREATE POLICY "Service role full access on verse_topics" ON public.verse_topics
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');