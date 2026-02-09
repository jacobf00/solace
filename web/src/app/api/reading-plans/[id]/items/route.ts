import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';

// PATCH /api/reading-plans/[id]/items - Update reading progress
export async function PATCH(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const { item_id, is_read } = await request.json();
    
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Validate
    if (!item_id || typeof is_read !== 'boolean') {
      return NextResponse.json(
        { error: 'Item ID and is_read status are required' },
        { status: 400 }
      );
    }

    // Verify ownership through reading plan -> problem chain
    const { data: item, error: checkError } = await supabase
      .from('reading_plan_items')
      .select(`
        id,
        reading_plans!inner (
          problem_id,
          problems!inner (user_id)
        )
      `)
      .eq('id', item_id)
      .eq('reading_plan_id', params.id)
      .single();

    if (checkError || !item) {
      return NextResponse.json(
        { error: 'Reading plan item not found' },
        { status: 404 }
      );
    }

    // Update item
    const { data: updatedItem, error } = await supabase
      .from('reading_plan_items')
      .update({ is_read })
      .eq('id', item_id)
      .eq('reading_plan_id', params.id)
      .select(`
        *,
        verses (
          id,
          book,
          chapter,
          verse,
          text
        )
      `)
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(updatedItem);
  } catch (error) {
    console.error('Error updating reading progress:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
