# 🚀 Quick Start Guide - Day 11

## Step 1: Install Dependencies (5 min)

```bash
cd frontend
npm install
```

## Step 2: Set Up Environment (2 min)

```bash
cp .env.example .env.local
```

Edit `.env.local` and add your OpenAI API key:
```env
OPENAI_API_KEY=sk-your-key-here
OPENAI_ORG_ID=org-your-org-here
```

## Step 3: Start Development Server (1 min)

```bash
npm run dev
```

Open http://localhost:3000

---

## First API Route: Logo Generation

Create `src/app/api/ai/generate-logo/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { generateImage, enhanceLogoPrompt } from '@/lib/openai';
import { rateLimiter } from '@/lib/openai';

export async function POST(request: NextRequest) {
  // Rate limiting
  const canProceed = await rateLimiter.checkLimit();
  if (!canProceed) {
    return NextResponse.json(
      { error: 'Rate limit exceeded' },
      { status: 429 }
    );
  }

  try {
    const { theme, name, style, additionalPrompt } = await request.json();

    // Enhance prompt with GPT-4
    const enhancedPrompt = await enhanceLogoPrompt(
      theme,
      name,
      style,
      additionalPrompt
    );

    // Generate image with DALL·E 3
    const response = await generateImage(enhancedPrompt);

    return NextResponse.json({
      imageUrl: response.data[0].url,
      prompt: enhancedPrompt,
      revisedPrompt: response.data[0].revised_prompt,
    });
  } catch (error) {
    console.error('Logo generation error:', error);
    return NextResponse.json(
      { error: 'Failed to generate logo' },
      { status: 500 }
    );
  }
}
```

---

## Test It!

```bash
curl -X POST http://localhost:3000/api/ai/generate-logo \
  -H "Content-Type: application/json" \
  -d '{
    "theme": "space",
    "name": "MoonDoge",
    "style": "cartoon"
  }'
```

---

## Next: Parameter Suggestions

Create `src/app/api/ai/suggest-params/route.ts` following the same pattern.

---

## Useful Commands

```bash
# Development
npm run dev

# Type checking
npm run type-check

# Linting
npm run lint

# Build
npm run build
```

---

**That's it! You're ready to build AI features!** 🎨
