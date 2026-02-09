import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';

// POST /api/reading-plans - Create reading plan for a problem
export async function POST(request: Request) {
  try {
    const { problem_id, verse_ids } = await request.json();
    
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Validate
    if (!problem_id || !verse_ids || !Array.isArray(verse_ids) || verse_ids.length === 0) {
      return NextResponse.json(
        { error: 'Problem ID and verse IDs are required' },
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

    // Check if reading plan already exists
    const { data: existingPlan } = await supabase
      .from('reading_plans')
      .select('id')
      .eq('problem_id', problem_id)
      .single();

    if (existingPlan) {
      return NextResponse.json(
        { error: 'Reading plan already exists for this problem' },
        { status: 409 }
      );
    }

    // Create reading plan
    const { data: readingPlan, error: planError } = await supabase
      .from('reading_plans')
      .insert({ problem_id })
      .select()
      .single();

    if (planError || !readingPlan) {
      return NextResponse.json(
        { error: planError?.message || 'Failed to create reading plan' },
        { status: 500 }
      );
    }

    // Create plan items
    const planItems = verse_ids.map((verseId: string, index: number) => ({
      reading_plan_id: readingPlan.id,
      verse_id: verseId,
      item_order: index + 1,
      is_read: false,
    }));

    const { error: itemsError } = await supabase
      .from('reading_plan_items')
      .insert(planItems);

    if (itemsError) {
      // Rollback: delete reading plan
      await supabase.from('reading_plans').delete().eq('id', readingPlan.id);
      return NextResponse.json({ error: itemsError.message }, { status: 500 });
    }

    // Return complete reading plan
    const { data: completePlan } = await supabase
      .from('reading_plans')
      .select(`
        *,
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
      `)
      .eq('id', readingPlan.id)
      .single();

    return NextResponse.json(completePlan || readingPlan);
  } catch (error) {
    console.error('Error creating reading plan:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
