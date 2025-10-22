# MemeForge Frontend

AI-powered memecoin creation platform built with Next.js 15, TypeScript, and OpenAI.

## ⚠️ Setup Note

**Next.js 15 Starter Files:** Located on Windows system at `folders/nextjs-15-starter-tailwindcss-v4-main`

See `WINDOWS_WSL_NOTES.md` in project root for instructions on copying starter files to WSL.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ 
- npm or yarn
- OpenAI API key
- Next.js 15 starter files (see note above)

### Installation

```bash
# First: Copy starter files from Windows (see WINDOWS_WSL_NOTES.md)

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env.local

# Add your OpenAI API key to .env.local

# Run development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## 📁 Project Structure

```
frontend/
├── src/
│   ├── app/              # Next.js App Router
│   │   ├── api/          # API routes
│   │   ├── create/       # Memecoin wizard
│   │   ├── dashboard/    # User dashboard
│   │   └── page.tsx      # Landing page
│   ├── components/       # React components
│   │   ├── ui/           # shadcn/ui components
│   │   ├── ai/           # AI-powered components
│   │   └── wizard/       # Creation wizard
│   ├── lib/              # Utilities
│   │   ├── openai.ts     # OpenAI client
│   │   ├── ipfs.ts       # IPFS integration
│   │   └── contracts.ts  # Smart contract ABIs
│   └── types/            # TypeScript types
├── public/               # Static assets
└── .env.local            # Environment variables
```

---

## 🎨 Features

### AI Integration
- **Logo Generation** - DALL·E 3 generates unique memecoin logos
- **Parameter Suggestions** - GPT-4 suggests optimal token parameters
- **AI Chat Assistant** - Guides users through creation process

### Web3 Integration
- **Wallet Connection** - RainbowKit for easy wallet connection
- **One-Click Deployment** - Deploy complete memecoin ecosystem
- **Real-time Updates** - Track deployment status

### Performance
- **Optimized Images** - Next.js Image component with WebP
- **Code Splitting** - Dynamic imports for faster load times
- **ISR** - Incremental Static Regeneration for static pages
- **Font Optimization** - next/font for Google Fonts

---

## 🔧 Tech Stack

### Core
- **Next.js 15** - React framework
- **TypeScript** - Type safety
- **Tailwind CSS v4** - Styling
- **shadcn/ui** - UI components

### AI
- **OpenAI SDK** - GPT-4 & DALL·E 3
- **Vercel AI SDK** - Streaming responses

### Web3
- **wagmi** - React hooks for Ethereum
- **viem** - TypeScript Ethereum library
- **RainbowKit** - Wallet connection

---

## 📝 Available Scripts

```bash
# Development
npm run dev          # Start dev server
npm run build        # Build for production
npm run start        # Start production server

# Code Quality
npm run lint         # Run ESLint
npm run type-check   # Run TypeScript compiler

# Analysis
npm run analyze      # Analyze bundle size
```

---

## 🔐 Environment Variables

See `.env.example` for all required environment variables.

### Required
- `OPENAI_API_KEY` - Your OpenAI API key
- `OPENAI_ORG_ID` - Your OpenAI organization ID

### Optional
- `PINATA_API_KEY` - For IPFS logo storage
- `NEXT_PUBLIC_FACTORY_ADDRESS` - Deployed factory contract

---

## 🎯 API Routes

### AI Endpoints

#### Generate Logo
```typescript
POST /api/ai/generate-logo
{
  "theme": "space",
  "name": "MoonDoge",
  "style": "cartoon"
}
```

#### Suggest Parameters
```typescript
POST /api/ai/suggest-params
{
  "theme": "gaming",
  "targetAudience": "gamers"
}
```

#### AI Chat
```typescript
POST /api/ai/chat
{
  "messages": [...],
  "context": "memecoin_creation"
}
```

---

## 🚀 Deployment

### Vercel (Recommended)

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel
```

### Environment Variables on Vercel
1. Go to Project Settings
2. Add all environment variables from `.env.example`
3. Redeploy

---

## 📊 Performance Optimization

### Images
- All images use `next/image`
- Lazy loading for non-critical images
- WebP format with fallbacks

### Fonts
- Google Fonts via `next/font`
- Preloaded critical fonts
- Subset to reduce size

### Code Splitting
- Dynamic imports for heavy components
- Route-based splitting (automatic)

### Caching
- ISR for static pages
- API route caching
- CDN for assets

---

## 🧪 Testing

```bash
# Unit tests
npm run test

# E2E tests
npm run test:e2e

# Coverage
npm run test:coverage
```

---

## 📚 Resources

- [Next.js Docs](https://nextjs.org/docs)
- [OpenAI API](https://platform.openai.com/docs)
- [shadcn/ui](https://ui.shadcn.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [wagmi](https://wagmi.sh/)

---

## 📄 License

MIT License - see LICENSE file for details
