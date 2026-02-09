const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';

export async function generateAdvice(
  problemDescription: string, 
  verses: string[]
): Promise<string> {
  const versesText = verses.map((v, i) => `${i + 1}. ${v}`).join('\n');
  
  const response = await fetch(OPENROUTER_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://solace.app',
      'X-Title': 'Solace',
    },
    body: JSON.stringify({
      model: 'arcee-ai/trinity-large-preview:free',
      messages: [{
        role: 'user',
        content: `You are a compassionate Christian counselor providing Biblical guidance.

Problem: ${problemDescription}

Relevant Bible verses:
${versesText}

Please provide concise, Biblical advice (under 200 words) that:
1. Shows empathy for the person's situation
2. Applies the provided Bible verses directly to their problem
3. Offers practical, Christ-centered guidance
4. Encourages spiritual growth and hope

Focus on hope, love, and God's promises rather than condemnation.`,
      }],
    }),
  });
  
  if (!response.ok) {
    const error = await response.text();
    throw new Error(`OpenRouter error: ${response.status} - ${error}`);
  }
  
  const data = await response.json();
  return data.choices[0].message.content;
}
