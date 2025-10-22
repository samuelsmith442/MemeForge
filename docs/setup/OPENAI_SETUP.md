# 🔑 OpenAI API Setup Guide

Complete guide to setting up OpenAI API for MemeForge.

---

## 📋 Prerequisites

- OpenAI account
- Credit card for API billing (OpenAI requires payment method)
- Node.js 18+ installed

---

## Step 1: Get OpenAI API Key

### 1.1 Create OpenAI Account

1. Go to https://platform.openai.com/
2. Click "Sign up" or "Log in"
3. Complete registration

### 1.2 Add Payment Method

**Important:** OpenAI requires a payment method for API access.

1. Go to https://platform.openai.com/account/billing
2. Click "Add payment method"
3. Add credit card details
4. Set usage limits (recommended: $10-20/month for development)

### 1.3 Generate API Key

1. Go to https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Name it: "MemeForge Development"
4. **Copy the key immediately** (starts with `sk-...`)
5. Store it securely - you can't view it again!

### 1.4 Get Organization ID (Optional)

1. Go to https://platform.openai.com/account/organization
2. Copy your Organization ID (starts with `org-...`)

---

## Step 2: Configure Environment Variables

### 2.1 Create .env.local

```bash
cd frontend
cp .env.example .env.local
```

### 2.2 Add Your API Key

Edit `frontend/.env.local`:

```bash
# OpenAI Configuration
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxx  # Your actual key
OPENAI_ORG_ID=org-xxxxxxxxxxxxxxxxxxxxxxxx    # Your org ID (optional)

# DALL·E Configuration
DALLE_MODEL=dall-e-3
DALLE_SIZE=1024x1024
DALLE_QUALITY=standard

# GPT Configuration
GPT_MODEL=gpt-4-turbo-preview
GPT_MAX_TOKENS=2000

# Rate Limiting
RATE_LIMIT_MAX_REQUESTS=10
RATE_LIMIT_WINDOW_MS=60000

# Application
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 2.3 Verify Configuration

```bash
# Check if key is set (won't show the actual key)
grep -q "OPENAI_API_KEY=sk-" frontend/.env.local && echo "✅ API key configured" || echo "❌ API key not set"
```

---

## Step 3: Install Dependencies

### 3.1 Run Setup Script

```bash
./setup-frontend.sh
```

Or manually:

```bash
cd frontend
npm install
```

### 3.2 Verify Installation

```bash
# Check if OpenAI package is installed
npm list openai
```

Expected output:
```
memeforge-frontend@0.1.0
└── openai@4.20.0
```

---

## Step 4: Test OpenAI Connection

### 4.1 Create Test Script

Create `frontend/test-openai.js`:

```javascript
const OpenAI = require('openai');
require('dotenv').config({ path: '.env.local' });

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

async function testConnection() {
  try {
    console.log('🧪 Testing OpenAI connection...\n');
    
    const response = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: 'Say "Hello from MemeForge!"' }],
      max_tokens: 20,
    });
    
    console.log('✅ Connection successful!');
    console.log('Response:', response.choices[0].message.content);
    console.log('\n📊 Usage:', response.usage);
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.status === 401) {
      console.error('\n⚠️  Invalid API key. Check your OPENAI_API_KEY in .env.local');
    }
  }
}

testConnection();
```

### 4.2 Run Test

```bash
cd frontend
node test-openai.js
```

Expected output:
```
🧪 Testing OpenAI connection...

✅ Connection successful!
Response: Hello from MemeForge!

📊 Usage: { prompt_tokens: 15, completion_tokens: 5, total_tokens: 20 }
```

---

## Step 5: Understanding Costs

### Pricing (as of 2024)

**GPT-4 Turbo:**
- Input: $10 / 1M tokens
- Output: $30 / 1M tokens

**GPT-3.5 Turbo:**
- Input: $0.50 / 1M tokens
- Output: $1.50 / 1M tokens

**DALL·E 3:**
- Standard (1024x1024): $0.040 per image
- HD (1024x1024): $0.080 per image

### Cost Estimation for Development

**Typical usage per day:**
- 50 GPT-4 requests (avg 500 tokens): ~$0.75
- 20 DALL·E images: ~$0.80
- **Total: ~$1.55/day** or **~$45/month**

### Setting Usage Limits

1. Go to https://platform.openai.com/account/billing/limits
2. Set "Hard limit": $20-50 (recommended for development)
3. Set "Soft limit": $10 (get notified)

---

## Step 6: Security Best Practices

### ✅ Do's

- ✅ Store API key in `.env.local` (gitignored)
- ✅ Never commit `.env.local` to git
- ✅ Use environment variables in production
- ✅ Set usage limits
- ✅ Rotate keys regularly
- ✅ Use separate keys for dev/prod

### ❌ Don'ts

- ❌ Never hardcode API keys in code
- ❌ Never commit keys to GitHub
- ❌ Never share keys publicly
- ❌ Never use production keys in development
- ❌ Never expose keys in client-side code

### Checking for Exposed Keys

```bash
# Make sure .env.local is gitignored
git check-ignore frontend/.env.local

# Should output: frontend/.env.local
```

---

## Step 7: Rate Limiting

Our OpenAI client includes rate limiting:

```typescript
// In src/lib/openai.ts
export const rateLimiter = new RateLimiter(
  parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || "10"),
  parseInt(process.env.RATE_LIMIT_WINDOW_MS || "60000")
);
```

**Default:** 10 requests per minute

Adjust in `.env.local`:
```bash
RATE_LIMIT_MAX_REQUESTS=20  # More requests
RATE_LIMIT_WINDOW_MS=60000  # Per minute
```

---

## 🐛 Troubleshooting

### Error: "Invalid API key"

**Solution:**
1. Check `.env.local` has correct key
2. Verify key starts with `sk-`
3. Ensure no extra spaces
4. Regenerate key if needed

### Error: "Insufficient quota"

**Solution:**
1. Add payment method: https://platform.openai.com/account/billing
2. Check usage limits
3. Add credits to account

### Error: "Rate limit exceeded"

**Solution:**
1. Wait 60 seconds
2. Increase `RATE_LIMIT_MAX_REQUESTS`
3. Upgrade OpenAI plan

### Error: "Module not found: openai"

**Solution:**
```bash
cd frontend
npm install openai
```

### Error: "Cannot find module 'dotenv'"

**Solution:**
```bash
npm install dotenv
```

---

## 📊 Monitoring Usage

### Check Usage

1. Go to https://platform.openai.com/usage
2. View daily/monthly usage
3. Monitor costs

### Set Up Alerts

1. Go to https://platform.openai.com/account/billing/limits
2. Set soft limit (e.g., $10)
3. Get email when reached

---

## ✅ Verification Checklist

- [ ] OpenAI account created
- [ ] Payment method added
- [ ] API key generated
- [ ] Organization ID copied (optional)
- [ ] `.env.local` created
- [ ] API key added to `.env.local`
- [ ] Dependencies installed
- [ ] Test script runs successfully
- [ ] Usage limits set
- [ ] `.env.local` is gitignored

---

## 🎯 Next Steps

Once OpenAI is configured:

1. **Create API Routes**
   - See [Quick Start Guide](../frontend/QUICK_START.md)

2. **Build Logo Generator**
   - Create `/api/ai/generate-logo/route.ts`

3. **Test AI Features**
   - Logo generation
   - Parameter suggestions
   - Chat assistant

---

## 📚 Resources

- [OpenAI Platform](https://platform.openai.com/)
- [OpenAI API Docs](https://platform.openai.com/docs)
- [Pricing](https://openai.com/pricing)
- [Usage Dashboard](https://platform.openai.com/usage)
- [API Keys](https://platform.openai.com/api-keys)

---

**Your OpenAI API is now ready for MemeForge!** 🚀
