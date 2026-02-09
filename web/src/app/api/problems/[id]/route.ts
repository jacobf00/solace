import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';

// GET /api/problems/[id] - Get specific problem
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { data: problem, error } = await supabase
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
      .eq('id', params.id)
      .eq('user_id', user.id)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return NextResponse.json({ error: 'Problem not found' }, { status: 404 });
      }
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(problem);
  } catch (error) {
    console.error('Error fetching problem:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// DELETE /api/problems/[id] - Delete problem
export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Verify ownership
    const { data: problem } = await supabase
      .from('problems')
      .select('id')
      .eq('id', params.id)
      .eq('user_id', user.id)
      .single();

    if (!problem) {
      return NextResponse.json({ error: 'Problem not found' }, { status: 404 });
    }

    const { error } = await supabase
      .from('problems')
      .delete()
      .eq('id', params.id)
      .eq('user_id', user.id);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting problem:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
