// AI Integration Types for MemeForge

export interface Message {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
  createdAt?: Date;
}

export interface ChatRequest {
  messages: Message[];
  model?: string;
  context?: "memecoin_creation" | "general" | "support";
}

export interface ChatResponse {
  message: Message;
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

// Logo Generation Types
export interface LogoGenerationRequest {
  theme: string;
  name: string;
  style?: "cartoon" | "realistic" | "abstract" | "minimalist" | "3d";
  colors?: string[];
  additionalPrompt?: string;
}

export interface LogoGenerationResponse {
  imageUrl: string;
  ipfsUrl?: string;
  prompt: string;
  revisedPrompt?: string;
  metadata: {
    model: string;
    size: string;
    quality: string;
    generatedAt: Date;
  };
}

// Parameter Suggestion Types
export interface ParameterSuggestionRequest {
  theme: string;
  targetAudience?: string;
  goals?: string[];
  existingParams?: Partial<MemecoinParameters>;
}

export interface MemecoinParameters {
  name: string;
  symbol: string;
  initialSupply: string;
  rewardRate: string;
  theme: string;
  votingDelay: number;
  votingPeriod: number;
  proposalThreshold: string;
  quorumPercentage: number;
  timelockDelay: number;
}

export interface ParameterSuggestionResponse {
  suggestions: MemecoinParameters;
  reasoning: {
    name: string;
    symbol: string;
    supply: string;
    rewardRate: string;
    governance: string;
  };
  alternatives?: Partial<MemecoinParameters>[];
}

// AI Service Types
export interface AIServiceConfig {
  model: string;
  maxTokens: number;
  temperature: number;
  topP?: number;
  frequencyPenalty?: number;
  presencePenalty?: number;
}

export interface AIError {
  code: string;
  message: string;
  details?: any;
}

// Streaming Types
export interface StreamChunk {
  id: string;
  content: string;
  done: boolean;
}

export interface StreamOptions {
  onChunk?: (chunk: StreamChunk) => void;
  onComplete?: (fullContent: string) => void;
  onError?: (error: AIError) => void;
}

// Rate Limiting Types
export interface RateLimitInfo {
  remaining: number;
  reset: Date;
  limit: number;
}

export interface RateLimitedResponse<T> {
  data: T;
  rateLimit: RateLimitInfo;
}
