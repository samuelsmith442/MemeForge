// OpenAI Client Configuration for MemeForge
import OpenAI from "openai";

if (!process.env.OPENAI_API_KEY) {
  throw new Error("OPENAI_API_KEY is not set in environment variables");
}

// Initialize OpenAI client
export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  organization: process.env.OPENAI_ORG_ID,
});

// Default configurations
export const AI_CONFIG = {
  gpt: {
    model: process.env.GPT_MODEL || "gpt-4-turbo-preview",
    maxTokens: parseInt(process.env.GPT_MAX_TOKENS || "2000"),
    temperature: 0.7,
    topP: 1,
    frequencyPenalty: 0,
    presencePenalty: 0,
  },
  dalle: {
    model: (process.env.DALLE_MODEL || "dall-e-3") as "dall-e-2" | "dall-e-3",
    size: (process.env.DALLE_SIZE || "1024x1024") as "1024x1024" | "1792x1024" | "1024x1792",
    quality: (process.env.DALLE_QUALITY || "standard") as "standard" | "hd",
    n: 1,
  },
} as const;

// System prompts for different contexts
export const SYSTEM_PROMPTS = {
  memecoinCreation: `You are an expert memecoin advisor helping users create successful memecoins. 
You understand tokenomics, community building, and blockchain technology. 
Provide clear, actionable advice while being enthusiastic and supportive.
Always consider:
- Token supply and distribution
- Reward mechanisms
- Governance structure
- Community engagement
- Market trends`,

  parameterSuggestion: `You are a tokenomics expert. Analyze the user's requirements and suggest optimal parameters for their memecoin.
Consider:
- Initial supply (balance between scarcity and accessibility)
- Reward rate (sustainable and attractive)
- Governance parameters (balanced power distribution)
- Theme alignment (parameters should match the theme)
Provide reasoning for each suggestion.`,

  logoGeneration: `Generate a detailed, creative prompt for DALL·E to create a memecoin logo.
The prompt should:
- Capture the theme and essence of the memecoin
- Specify artistic style clearly
- Include color preferences if provided
- Be suitable for a circular logo format
- Avoid text/words in the image
- Create a memorable, unique design`,
} as const;

// Helper function to create chat completion
export async function createChatCompletion(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  options?: Partial<typeof AI_CONFIG.gpt>
) {
  try {
    const response = await openai.chat.completions.create({
      model: options?.model || AI_CONFIG.gpt.model,
      messages,
      max_tokens: options?.maxTokens || AI_CONFIG.gpt.maxTokens,
      temperature: options?.temperature ?? AI_CONFIG.gpt.temperature,
      top_p: options?.topP ?? AI_CONFIG.gpt.topP,
      frequency_penalty: options?.frequencyPenalty ?? AI_CONFIG.gpt.frequencyPenalty,
      presence_penalty: options?.presencePenalty ?? AI_CONFIG.gpt.presencePenalty,
    });

    return response;
  } catch (error) {
    console.error("OpenAI API Error:", error);
    throw error;
  }
}

// Helper function to create streaming chat completion
export async function createStreamingChatCompletion(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  options?: Partial<typeof AI_CONFIG.gpt>
) {
  try {
    const stream = await openai.chat.completions.create({
      model: options?.model || AI_CONFIG.gpt.model,
      messages,
      max_tokens: options?.maxTokens || AI_CONFIG.gpt.maxTokens,
      temperature: options?.temperature ?? AI_CONFIG.gpt.temperature,
      stream: true,
    });

    return stream;
  } catch (error) {
    console.error("OpenAI Streaming API Error:", error);
    throw error;
  }
}

// Helper function to generate images with DALL·E
export async function generateImage(
  prompt: string,
  options?: Partial<typeof AI_CONFIG.dalle>
) {
  try {
    const response = await openai.images.generate({
      model: options?.model || AI_CONFIG.dalle.model,
      prompt,
      n: options?.n || AI_CONFIG.dalle.n,
      size: options?.size || AI_CONFIG.dalle.size,
      quality: options?.quality || AI_CONFIG.dalle.quality,
      response_format: "url",
    });

    return response;
  } catch (error) {
    console.error("DALL·E API Error:", error);
    throw error;
  }
}

// Helper function to enhance logo prompt
export async function enhanceLogoPrompt(
  theme: string,
  name: string,
  style: string,
  additionalDetails?: string
): Promise<string> {
  const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
    {
      role: "system",
      content: SYSTEM_PROMPTS.logoGeneration,
    },
    {
      role: "user",
      content: `Create a DALL·E prompt for a memecoin logo with these details:
Theme: ${theme}
Name: ${name}
Style: ${style}
${additionalDetails ? `Additional details: ${additionalDetails}` : ""}

Generate a detailed, creative prompt that will produce an amazing logo.`,
    },
  ];

  const response = await createChatCompletion(messages, {
    maxTokens: 500,
    temperature: 0.7,
  });

  return response.choices[0]?.message?.content || prompt;
}

// Rate limiting helper
export class RateLimiter {
  private requests: number[] = [];
  private readonly maxRequests: number;
  private readonly windowMs: number;

  constructor(maxRequests: number = 10, windowMs: number = 60000) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
  }

  async checkLimit(): Promise<boolean> {
    const now = Date.now();
    this.requests = this.requests.filter((time) => now - time < this.windowMs);

    if (this.requests.length >= this.maxRequests) {
      return false;
    }

    this.requests.push(now);
    return true;
  }

  getRemainingRequests(): number {
    const now = Date.now();
    this.requests = this.requests.filter((time) => now - time < this.windowMs);
    return Math.max(0, this.maxRequests - this.requests.length);
  }

  getResetTime(): Date {
    if (this.requests.length === 0) {
      return new Date();
    }
    return new Date(this.requests[0] + this.windowMs);
  }
}

// Export singleton rate limiter
export const rateLimiter = new RateLimiter(
  parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || "10"),
  parseInt(process.env.RATE_LIMIT_WINDOW_MS || "60000")
);
