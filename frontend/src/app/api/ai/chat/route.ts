import { NextRequest, NextResponse } from 'next/server';
import { openai, rateLimiter } from '@/lib/openai';

// CORS headers for local development
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

/**
 * OPTIONS /api/ai/chat
 * Handle CORS preflight requests
 */
export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}

/**
 * POST /api/ai/chat
 * AI chat assistant for memecoin creation guidance
 * Supports both regular and streaming responses
 */
export async function POST(request: NextRequest) {
  try {
    // Rate limiting
    const canProceed = await rateLimiter.checkLimit();
    if (!canProceed) {
      return NextResponse.json(
        {
          error: 'Rate limit exceeded',
          message: 'Too many requests. Please try again in a minute.',
        },
        { status: 429, headers: corsHeaders }
      );
    }

    // Parse request body
    const body = await request.json();
    const { messages, stream = false, context } = body;

    // Validate required fields
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return NextResponse.json(
        {
          error: 'Missing required fields',
          message: 'messages array is required',
        },
        { status: 400, headers: corsHeaders }
      );
    }

    console.log('💬 Chat request:', { messageCount: messages.length, stream, hasContext: !!context });

    // System prompt for the AI assistant
    const systemPrompt = {
      role: 'system' as const,
      content: `You are MemeForge AI, an expert assistant for creating memecoins on the blockchain.

Your expertise includes:
- Memecoin themes and branding
- Tokenomics and distribution strategies
- Staking mechanisms and APY calculations
- DAO governance structures
- Community building and marketing
- Smart contract best practices
- Web3 and blockchain technology

Your personality:
- Friendly and enthusiastic about memecoins
- Professional but not overly formal
- Educational - explain concepts clearly
- Practical - provide actionable advice
- Creative - suggest unique ideas

Guidelines:
1. Keep responses concise but informative (2-4 paragraphs max)
2. Use emojis sparingly to add personality
3. Provide specific numbers and examples when relevant
4. If asked about MemeForge features, explain:
   - AI-powered logo generation
   - Smart tokenomics suggestions
   - One-click deployment
   - Built-in staking and governance
   - ERC-6551 token-bound accounts for unique identity
5. Always encourage responsible tokenomics and community focus
6. If unsure, admit it and suggest alternatives

${context ? `\nCurrent Context:\n${JSON.stringify(context, null, 2)}` : ''}`,
    };

    // Combine system prompt with user messages
    const allMessages = [systemPrompt, ...messages];

    // Handle streaming response
    if (stream) {
      const streamResponse = await openai.chat.completions.create({
        model: 'gpt-4-turbo-preview',
        messages: allMessages,
        max_tokens: 800,
        temperature: 0.8,
        stream: true,
      });

      // Create a readable stream
      const encoder = new TextEncoder();
      const readable = new ReadableStream({
        async start(controller) {
          try {
            for await (const chunk of streamResponse) {
              const content = chunk.choices[0]?.delta?.content || '';
              if (content) {
                controller.enqueue(encoder.encode(`data: ${JSON.stringify({ content })}\n\n`));
              }
            }
            controller.enqueue(encoder.encode('data: [DONE]\n\n'));
            controller.close();
          } catch (error) {
            controller.error(error);
          }
        },
      });

      return new Response(readable, {
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      });
    }

    // Handle regular (non-streaming) response
    const response = await openai.chat.completions.create({
      model: 'gpt-4-turbo-preview',
      messages: allMessages,
      max_tokens: 800,
      temperature: 0.8,
    });

    const assistantMessage = response.choices[0]?.message?.content;

    if (!assistantMessage) {
      throw new Error('No response from AI');
    }

    console.log('✅ Chat response generated');

    // Return success response
    return NextResponse.json(
      {
        success: true,
        message: assistantMessage,
        usage: {
          promptTokens: response.usage?.prompt_tokens,
          completionTokens: response.usage?.completion_tokens,
          totalTokens: response.usage?.total_tokens,
        },
        metadata: {
          model: response.model,
          generatedAt: new Date().toISOString(),
        },
      },
      { headers: corsHeaders }
    );
  } catch (error: any) {
    console.error('❌ Chat error:', error);

    // Handle specific OpenAI errors
    if (error.status === 401) {
      return NextResponse.json(
        {
          error: 'Authentication failed',
          message: 'Invalid OpenAI API key',
        },
        { status: 401, headers: corsHeaders }
      );
    }

    if (error.status === 429) {
      return NextResponse.json(
        {
          error: 'OpenAI rate limit',
          message: 'OpenAI rate limit exceeded. Please try again later.',
        },
        { status: 429, headers: corsHeaders }
      );
    }

    // Generic error response
    return NextResponse.json(
      {
        error: 'Chat failed',
        message: error.message || 'An unexpected error occurred',
      },
      { status: 500, headers: corsHeaders }
    );
  }
}

/**
 * GET /api/ai/chat
 * Health check endpoint
 */
export async function GET() {
  return NextResponse.json(
    {
      status: 'ok',
      endpoint: '/api/ai/chat',
      methods: ['POST'],
      description: 'AI chat assistant for memecoin creation guidance',
      features: ['regular responses', 'streaming responses', 'context-aware'],
    },
    { headers: corsHeaders }
  );
}
