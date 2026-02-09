import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
import { pgPool } from '@/lib/db/client';
import { generateEmbedding } from '@/lib/ai/openai';

// POST /api/verses/search - Vector similarity search
export async function POST(request: Request) {
  try {
    const { query, limit = 10 } = await request.json();
    
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    if (!query) {
      return NextResponse.json(
        { error: 'Query is required' },
        { status: 400 }
      );
    }

    try {
      // Generate embedding for search query
      const embedding = await generateEmbedding(query);
      
      // Search for similar verses using pgvector
      const versesResult = await pgPool.query(
        `SELECT 
          v.id, v.book, v.chapter, v.verse, v.text,
          1 - (v.embedding <=> $1) as similarity
        FROM verses v
        WHERE v.embedding IS NOT NULL
        AND 1 - (v.embedding <=> $1) > 0.7
        ORDER BY v.embedding <=> $1
        LIMIT $2`,
        [JSON.stringify(embedding), limit]
      );
      
      // If vector search returns results, use them
      if (versesResult.rows.length > 0) {
        return NextResponse.json(versesResult.rows);
      }
      
      // Fallback to text search if no vector results
      const textResult = await pgPool.query(
        `SELECT 
          v.id, v.book, v.chapter, v.verse, v.text,
          ts_rank(to_tsvector('english', v.text), plainto_tsquery('english', $1)) as similarity
        FROM verses v
        WHERE to_tsvector('english', v.text) @@ plainto_tsquery('english', $1)
        ORDER BY similarity DESC
        LIMIT $2`,
        [query, limit]
      );
      
      return NextResponse.json(textResult.rows);
    } catch (error) {
      console.error('Search error:', error);
      
      // Final fallback: simple text search via Supabase
      const { data: verses, error: searchError } = await supabase
        .from('verses')
        .select('*')
        .textSearch('text', query)
        .limit(limit);
      
      if (searchError) {
        return NextResponse.json({ error: searchError.message }, { status: 500 });
      }
      
      return NextResponse.json(verses);
    }
  } catch (error) {
    console.error('Error searching verses:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
