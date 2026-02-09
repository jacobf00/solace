import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
import { pgPool } from '@/lib/db/client';
import { generateEmbedding } from '@/lib/ai/openai';
import { generateAdvice } from '@/lib/ai/openrouter';

// POST /api/problems/[id]/advice - Regenerate AI advice
export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Get problem
    const { data: problem, error: problemError } = await supabase
      .from('problems')
      .select('*')
      .eq('id', params.id)
      .eq('user_id', user.id)
      .single();

    if (problemError || !problem) {
      return NextResponse.json({ error: 'Problem not found' }, { status: 404 });
    }

    // Find relevant verses
    let verses: any[] = [];
    try {
      const embedding = await generateEmbedding(problem.description);
      
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
      
      if (verses.length === 0) {
        const textResult = await pgPool.query(
          `SELECT 
            v.id, v.book, v.chapter, v.verse, v.text
          FROM verses v
          WHERE to_tsvector('english', v.text) @@ plainto_tsquery('english', $1)
          LIMIT 5`,
          [problem.description]
        );
        verses = textResult.rows;
      }
    } catch (error) {
      console.error('Error finding verses:', error);
    }

    // Generate new advice
    let advice = '';
    if (verses.length > 0) {
      try {
        advice = await generateAdvice(
          problem.description,
          verses.map(v => v.text)
        );
      } catch (error) {
        console.error('Error generating advice:', error);
        return NextResponse.json(
          { error: 'Failed to generate advice' },
          { status: 500 }
        );
      }
    } else {
      advice = 'No specific Bible verses were found for this problem. Consider speaking with a pastor or counselor for personalized guidance.';
    }

    // Update problem
    const { data: updatedProblem, error: updateError } = await supabase
      .from('problems')
      .update({ advice })
      .eq('id', params.id)
      .eq('user_id', user.id)
      .select()
      .single();

    if (updateError) {
      return NextResponse.json({ error: updateError.message }, { status: 500 });
    }

    return NextResponse.json(updatedProblem);
  } catch (error) {
    console.error('Error regenerating advice:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
