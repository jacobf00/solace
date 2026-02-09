import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';

// POST /api/feedback - Submit feedback on advice
export async function POST(request: Request) {
  try {
    const { problem_id, rating, feedback_text, is_helpful } = await request.json();
    
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Validate
    if (!problem_id || !rating || rating < 1 || rating > 5) {
      return NextResponse.json(
        { error: 'Problem ID and rating (1-5) are required' },
        { status: 400 }
      );
    }

    // Verify problem ownership
    const { data: problem } = await supabase
      .from('problems')
      .select('id')
      .eq('id', problem_id)
      .eq('user_id', user.id)
      .single();

    if (!problem) {
      return NextResponse.json({ error: 'Problem not found' }, { status: 404 });
    }

    // Insert or update feedback
    const { data: feedback, error } = await supabase
      .from('advice_feedback')
      .upsert({
        problem_id,
        user_id: user.id,
        rating,
        feedback_text,
        is_helpful,
      })
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(feedback);
  } catch (error) {
    console.error('Error submitting feedback:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
