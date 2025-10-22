// Memecoin Creation Types for MemeForge

export interface DeploymentParams {
  name: string;
  symbol: string;
  initialSupply: bigint;
  rewardRate: bigint;
  theme: string;
  logoURI: string;
  enableGovernance: boolean;
}

export interface GovernanceConfig {
  votingDelay: number;      // in blocks
  votingPeriod: number;      // in blocks
  proposalThreshold: bigint; // minimum tokens to create proposal
  quorumPercentage: number;  // percentage needed for quorum
  timelockDelay: number;     // in seconds
}

export interface DeploymentInfo {
  token: string;
  soulNFT: string;
  governor?: string;
  timelock?: string;
  creator: string;
  deployedAt: number;
  exists: boolean;
}

export interface MemecoinMetadata {
  name: string;
  symbol: string;
  theme: string;
  logoURI: string;
  description?: string;
  website?: string;
  social?: {
    twitter?: string;
    telegram?: string;
    discord?: string;
  };
}

// Wizard Step Types
export type WizardStep = 
  | "theme"
  | "basic-info"
  | "tokenomics"
  | "logo"
  | "governance"
  | "review"
  | "deploy";

export interface WizardState {
  currentStep: WizardStep;
  completedSteps: WizardStep[];
  data: Partial<DeploymentParams & MemecoinMetadata & GovernanceConfig>;
  errors: Record<string, string>;
}

// Theme Options
export const THEME_OPTIONS = [
  { value: "space", label: "Space & Cosmos", emoji: "🚀" },
  { value: "gaming", label: "Gaming", emoji: "🎮" },
  { value: "meme", label: "Classic Meme", emoji: "😂" },
  { value: "animal", label: "Animals", emoji: "🐕" },
  { value: "food", label: "Food & Drinks", emoji: "🍕" },
  { value: "tech", label: "Technology", emoji: "💻" },
  { value: "nature", label: "Nature", emoji: "🌿" },
  { value: "fantasy", label: "Fantasy", emoji: "🧙" },
  { value: "sports", label: "Sports", emoji: "⚽" },
  { value: "music", label: "Music", emoji: "🎵" },
] as const;

export type Theme = typeof THEME_OPTIONS[number]["value"];

// Logo Style Options
export const LOGO_STYLE_OPTIONS = [
  { value: "cartoon", label: "Cartoon", description: "Fun and playful" },
  { value: "realistic", label: "Realistic", description: "Detailed and lifelike" },
  { value: "abstract", label: "Abstract", description: "Modern and artistic" },
  { value: "minimalist", label: "Minimalist", description: "Clean and simple" },
  { value: "3d", label: "3D", description: "Three-dimensional" },
] as const;

export type LogoStyle = typeof LOGO_STYLE_OPTIONS[number]["value"];

// Deployment Status
export type DeploymentStatus = 
  | "idle"
  | "preparing"
  | "deploying-token"
  | "deploying-nft"
  | "deploying-governance"
  | "configuring"
  | "completed"
  | "failed";

export interface DeploymentProgress {
  status: DeploymentStatus;
  currentStep: string;
  progress: number; // 0-100
  txHash?: string;
  error?: string;
}

// Contract Addresses (update after deployment)
export interface ContractAddresses {
  factory: string;
  stakingVault: string;
  registry: string;
  implementation: string;
}

// User's Memecoins
export interface UserMemecoin {
  address: string;
  name: string;
  symbol: string;
  theme: string;
  logoURI: string;
  deployedAt: number;
  totalSupply: bigint;
  hasGovernance: boolean;
}
