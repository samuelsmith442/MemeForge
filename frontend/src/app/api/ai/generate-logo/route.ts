import { NextRequest, NextResponse } from 'next/server';
import { generateImage, enhanceLogoPrompt, rateLimiter } from '@/lib/openai';

// CORS headers for local development
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

/**
 * OPTIONS /api/ai/generate-logo
 * Handle CORS preflight requests
 */
export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}

/**
 * POST /api/ai/generate-logo
 * Generate a memecoin logo using DALL·E 3
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
    const { theme, name, style, additionalPrompt } = body;

    // Validate required fields
    if (!theme || !name || !style) {
      return NextResponse.json(
        { 
          error: 'Missing required fields',
          message: 'theme, name, and style are required',
        },
        { status: 400, headers: corsHeaders }
      );
    }

    console.log('🎨 Generating logo:', { theme, name, style });

    // Step 1: Enhance prompt with GPT-4
    const enhancedPrompt = await enhanceLogoPrompt(
      theme,
      name,
      style,
      additionalPrompt
    );

    console.log('📝 Enhanced prompt:', enhancedPrompt);

    // Step 2: Generate image with DALL·E 3
    const response = await generateImage(enhancedPrompt);

    const imageUrl = response.data[0]?.url;
    const revisedPrompt = response.data[0]?.revised_prompt;

    if (!imageUrl) {
      throw new Error('No image URL returned from DALL·E');
    }

    console.log('✅ Logo generated successfully');

    // Return success response
    return NextResponse.json({
      success: true,
      imageUrl,
      prompt: enhancedPrompt,
      revisedPrompt,
      metadata: {
        theme,
        name,
        style,
        generatedAt: new Date().toISOString(),
      },
    }, { headers: corsHeaders });

  } catch (error: any) {
    console.error('❌ Logo generation error:', error);

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

    if (error.status === 400) {
      return NextResponse.json(
        { 
          error: 'Invalid request',
          message: error.message || 'Invalid request to OpenAI',
        },
        { status: 400, headers: corsHeaders }
      );
    }

    // Generic error response
    return NextResponse.json(
      { 
        error: 'Logo generation failed',
        message: error.message || 'An unexpected error occurred',
      },
      { status: 500, headers: corsHeaders }
    );
  }
}

/**
 * GET /api/ai/generate-logo
 * Health check endpoint
 */
export async function GET() {
  return NextResponse.json({
    status: 'ok',
    endpoint: '/api/ai/generate-logo',
    methods: ['POST'],
    description: 'Generate memecoin logos using DALL·E 3',
  }, { headers: corsHeaders });
}
