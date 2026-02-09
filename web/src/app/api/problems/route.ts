import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
import { pgPool } from '@/lib/db/client';
import { generateEmbedding } from '@/lib/ai/openai';
import { generateAdvice } from '@/lib/ai/openrouter';

// GET /api/problems - Get current user's problems
export async function GET() {
  try {
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { data: problems, error } = await supabase
      .from('problems')
      .select(`
        *,
        reading_plans (
          id,
          created_at,
          reading_plan_items (
            id,
            item_order,
            is_read,
            verses (
              id,
              book,
              chapter,
              verse,
              text
            )
          )
        )
      `)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching problems:', error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(problems);
  } catch (error) {
    console.error('Unexpected error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// POST /api/problems - Create new problem with AI advice
export async function POST(request: Request) {
  try {
    const { title, description, context, category } = await request.json();
    
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Validate required fields
    if (!title || !description) {
      return NextResponse.json(
        { error: 'Title and description are required' },
        { status: 400 }
      );
    }

    // 1. Create problem
    const { data: problem, error: problemError } = await supabase
      .from('problems')
      .insert({
        user_id: user.id,
        title,
        description,
        context,
        category,
      })
      .select()
      .single();

    if (problemError || !problem) {
      console.error('Error creating problem:', problemError);
      return NextResponse.json(
        { error: problemError?.message || 'Failed to create problem' },
        { status: 500 }
      );
    }

    // 2. Find relevant verses
    let verses: any[] = [];
    try {
      // Generate embedding for the problem
      const embedding = await generateEmbedding(description);
      
      // Search for similar verses using pgvector
      const versesResult = await pgPool.query(
        `SELECT 
          v.id, v.book, v.chapter, v.verse, v.text,
          1 - (v.embedding <=> $1) as similarity
        FROM verses v
        WHERE v.embedding IS NOT NULL
        AND 1 - (v.embedding <=> $1) > 0.7
        ORDER BY v.embedding <=> $1
        LIMIT 5`,
        [JSON.stringify(embedding)]
      );
      
      verses = versesResult.rows;
      
      // If no vector results, fall back to text search
      if (verses.length === 0) {
        const textResult = await pgPool.query(
          `SELECT 
            v.id, v.book, v.chapter, v.verse, v.text
          FROM verses v
          WHERE to_tsvector('english', v.text) @@ plainto_tsquery('english', $1)
          LIMIT 5`,
          [description]
        );
        verses = textResult.rows;
      }
    } catch (error) {
      console.error('Error finding verses:', error);
      // Continue without verses
    }

    // 3. Generate AI advice
    let advice = '';
    if (verses.length > 0) {
      try {
        advice = await generateAdvice(
          description,
          verses.map(v => v.text)
        );
      } catch (error) {
        console.error('Error generating advice:', error);
        advice = 'Unable to generate advice at this time. Please try again later.';
      }
    } else {
      advice = 'No specific Bible verses were found for this problem. Consider speaking with a pastor or counselor for personalized guidance.';
    }

    // 4. Update problem with advice
    const { error: updateError } = await supabase
      .from('problems')
      .update({ advice })
      .eq('id', problem.id);

    if (updateError) {
      console.error('Error updating problem with advice:', updateError);
    }

    // 5. Create reading plan with verses
    if (verses.length > 0) {
      try {
        const { data: readingPlan, error: planError } = await supabase
          .from('reading_plans')
          .insert({ problem_id: problem.id })
          .select()
          .single();

        if (!planError && readingPlan) {
          const planItems = verses.map((verse, index) => ({
            reading_plan_id: readingPlan.id,
            verse_id: verse.id,
            item_order: index + 1,
            is_read: false,
          }));

          await supabase.from('reading_plan_items').insert(planItems);
        }
      } catch (error) {
        console.error('Error creating reading plan:', error);
      }
    }

    // Return complete problem data
    const { data: completeProblem } = await supabase
      .from('problems')
      .select(`
        *,
        reading_plans (
          id,
          created_at,
          reading_plan_items (
            id,
            item_order,
            is_read,
            verses (
              id,
              book,
              chapter,
              verse,
              text
            )
          )
        )
      `)
      .eq('id', problem.id)
      .single();

    return NextResponse.json(completeProblem || { ...problem, advice });
  } catch (error) {
    console.error('Unexpected error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
