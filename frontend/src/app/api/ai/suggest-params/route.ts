import { NextRequest, NextResponse } from 'next/server';
import { createChatCompletion, rateLimiter } from '@/lib/openai';

// CORS headers for local development
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

/**
 * OPTIONS /api/ai/suggest-params
 * Handle CORS preflight requests
 */
export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}

/**
 * POST /api/ai/suggest-params
 * Generate AI-powered parameter suggestions for memecoin tokenomics
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
    const { theme, name, targetAudience, goals } = body;

    // Validate required fields
    if (!theme || !name) {
      return NextResponse.json(
        {
          error: 'Missing required fields',
          message: 'theme and name are required',
        },
        { status: 400, headers: corsHeaders }
      );
    }

    console.log('💡 Generating parameter suggestions:', { theme, name, targetAudience, goals });

    // Create prompt for GPT-4
    const messages = [
      {
        role: 'system' as const,
        content: `You are an expert blockchain tokenomics advisor specializing in memecoin economics. 
Your task is to suggest optimal parameters for a memecoin based on its theme and goals.
Provide practical, balanced recommendations that encourage community engagement while maintaining sustainability.
Return your response as a valid JSON object with the following structure:
{
  "tokenomics": {
    "totalSupply": "number (in millions/billions)",
    "initialPrice": "number (in USD)",
    "maxSupply": "number or 'unlimited'"
  },
  "distribution": {
    "publicSale": "percentage",
    "liquidity": "percentage",
    "team": "percentage",
    "marketing": "percentage",
    "treasury": "percentage"
  },
  "staking": {
    "minStakePeriod": "number (in days)",
    "maxStakePeriod": "number (in days)",
    "baseAPY": "percentage",
    "maxAPY": "percentage"
  },
  "governance": {
    "proposalThreshold": "number (tokens required)",
    "votingPeriod": "number (in days)",
    "quorumPercentage": "percentage"
  },
  "reasoning": {
    "tokenomics": "brief explanation",
    "distribution": "brief explanation",
    "staking": "brief explanation",
    "governance": "brief explanation"
  },
  "recommendations": ["list of 3-5 key recommendations"]
}`,
      },
      {
        role: 'user' as const,
        content: `Generate optimal tokenomics parameters for a memecoin with the following details:

Name: ${name}
Theme: ${theme}
${targetAudience ? `Target Audience: ${targetAudience}` : ''}
${goals ? `Goals: ${goals}` : ''}

Consider:
1. The theme and how it affects community expectations
2. Sustainable tokenomics that prevent pump-and-dump
3. Fair distribution that builds trust
4. Staking incentives that encourage long-term holding
5. Governance parameters that enable community participation

Provide specific numbers and percentages, not ranges.`,
      },
    ];

    // Call GPT-4
    const response = await createChatCompletion(messages, {
      maxTokens: 1500,
      temperature: 0.7,
    });

    const content = response.choices[0]?.message?.content;

    if (!content) {
      throw new Error('No response from AI');
    }

    // Parse JSON response
    let suggestions;
    try {
      // Extract JSON from markdown code blocks if present
      const jsonMatch = content.match(/```json\n([\s\S]*?)\n```/) || content.match(/```\n([\s\S]*?)\n```/);
      const jsonString = jsonMatch ? jsonMatch[1] : content;
      suggestions = JSON.parse(jsonString);
    } catch (parseError) {
      console.error('Failed to parse AI response:', content);
      throw new Error('Invalid JSON response from AI');
    }

    console.log('✅ Parameter suggestions generated successfully');

    // Return success response
    return NextResponse.json(
      {
        success: true,
        suggestions,
        metadata: {
          theme,
          name,
          targetAudience,
          goals,
          generatedAt: new Date().toISOString(),
        },
      },
      { headers: corsHeaders }
    );
  } catch (error: any) {
    console.error('❌ Parameter suggestion error:', error);

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
        error: 'Parameter suggestion failed',
        message: error.message || 'An unexpected error occurred',
      },
      { status: 500, headers: corsHeaders }
    );
  }
}

/**
 * GET /api/ai/suggest-params
 * Health check endpoint
 */
export async function GET() {
  return NextResponse.json(
    {
      status: 'ok',
      endpoint: '/api/ai/suggest-params',
      methods: ['POST'],
      description: 'Generate AI-powered tokenomics parameter suggestions',
    },
    { headers: corsHeaders }
  );
}
