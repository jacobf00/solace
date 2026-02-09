import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
import { pgPool } from '@/lib/db/client';
import { generateEmbedding } from '@/lib/ai/openai';

// GET /api/verses - Get verses by book and optional chapter
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const book = searchParams.get('book');
    const chapter = searchParams.get('chapter');
    
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    let query = supabase.from('verses').select('*');
    
    if (book) {
      query = query.eq('book', book);
    }
    
    if (chapter) {
      query = query.eq('chapter', parseInt(chapter));
    }
    
    const { data: verses, error } = await query.order('chapter').order('verse');

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(verses);
  } catch (error) {
    console.error('Error fetching verses:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
