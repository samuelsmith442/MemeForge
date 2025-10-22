#!/usr/bin/env node

/**
 * Test script to verify OpenAI and Pinata API keys
 * Run: node test-api-keys.js
 */

require('dotenv').config({ path: '.env.local' });

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

console.log(`\n${colors.blue}🧪 Testing API Keys...${colors.reset}\n`);

// Check environment variables
const checks = {
  openai: process.env.OPENAI_API_KEY,
  openaiOrg: process.env.OPENAI_ORG_ID,
  pinataKey: process.env.PINATA_API_KEY,
  pinataSecret: process.env.PINATA_SECRET_KEY,
};

console.log('📋 Environment Variables:');
console.log(`  OPENAI_API_KEY: ${checks.openai ? colors.green + '✅ Set' + colors.reset : colors.red + '❌ Missing' + colors.reset}`);
console.log(`  OPENAI_ORG_ID: ${checks.openaiOrg ? colors.green + '✅ Set' + colors.reset : colors.yellow + '⚠️  Optional' + colors.reset}`);
console.log(`  PINATA_API_KEY: ${checks.pinataKey ? colors.green + '✅ Set' + colors.reset : colors.yellow + '⚠️  Optional' + colors.reset}`);
console.log(`  PINATA_SECRET_KEY: ${checks.pinataSecret ? colors.green + '✅ Set' + colors.reset : colors.yellow + '⚠️  Optional' + colors.reset}`);
console.log('');

// Test OpenAI connection
async function testOpenAI() {
  if (!checks.openai) {
    console.log(`${colors.red}❌ OpenAI: API key not set${colors.reset}\n`);
    return false;
  }

  try {
    const OpenAI = require('openai');
    const openai = new OpenAI({
      apiKey: checks.openai,
      organization: checks.openaiOrg,
    });

    console.log('🤖 Testing OpenAI connection...');
    
    const response = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: 'Say "MemeForge is ready!"' }],
      max_tokens: 10,
    });

    console.log(`${colors.green}✅ OpenAI: Connected successfully!${colors.reset}`);
    console.log(`   Response: "${response.choices[0].message.content}"`);
    console.log(`   Tokens used: ${response.usage.total_tokens}`);
    console.log('');
    return true;
  } catch (error) {
    console.log(`${colors.red}❌ OpenAI: ${error.message}${colors.reset}`);
    if (error.status === 401) {
      console.log(`   ${colors.yellow}⚠️  Invalid API key. Check OPENAI_API_KEY in .env.local${colors.reset}`);
    }
    console.log('');
    return false;
  }
}

// Test Pinata connection
async function testPinata() {
  if (!checks.pinataKey || !checks.pinataSecret) {
    console.log(`${colors.yellow}⚠️  Pinata: API keys not set (optional for now)${colors.reset}\n`);
    return true; // Not critical
  }

  try {
    const axios = require('axios');
    
    console.log('📌 Testing Pinata connection...');
    
    const response = await axios.get('https://api.pinata.cloud/data/testAuthentication', {
      headers: {
        pinata_api_key: checks.pinataKey,
        pinata_secret_api_key: checks.pinataSecret,
      },
    });

    console.log(`${colors.green}✅ Pinata: Connected successfully!${colors.reset}`);
    console.log(`   Message: ${response.data.message}`);
    console.log('');
    return true;
  } catch (error) {
    console.log(`${colors.red}❌ Pinata: ${error.message}${colors.reset}`);
    if (error.response?.status === 401) {
      console.log(`   ${colors.yellow}⚠️  Invalid credentials. Check PINATA keys in .env.local${colors.reset}`);
    }
    console.log('');
    return false;
  }
}

// Run tests
async function runTests() {
  const openaiOk = await testOpenAI();
  const pinataOk = await testPinata();

  console.log('━'.repeat(50));
  console.log('\n📊 Summary:\n');
  
  if (openaiOk) {
    console.log(`${colors.green}✅ OpenAI: Ready to use${colors.reset}`);
  } else {
    console.log(`${colors.red}❌ OpenAI: Not configured${colors.reset}`);
  }

  if (pinataOk) {
    console.log(`${colors.green}✅ Pinata: Ready to use${colors.reset}`);
  } else {
    console.log(`${colors.yellow}⚠️  Pinata: Not configured (optional)${colors.reset}`);
  }

  console.log('');

  if (openaiOk) {
    console.log(`${colors.green}🎉 You're ready to start building AI features!${colors.reset}\n`);
    console.log('Next steps:');
    console.log('1. Run: npm run dev');
    console.log('2. Create your first API route');
    console.log('3. See: docs/frontend/QUICK_START.md\n');
  } else {
    console.log(`${colors.red}⚠️  Please configure OpenAI API key to continue${colors.reset}\n`);
    console.log('Steps:');
    console.log('1. Get API key: https://platform.openai.com/api-keys');
    console.log('2. Edit: frontend/.env.local');
    console.log('3. Add: OPENAI_API_KEY=sk-your-key\n');
  }
}

// Check if required packages are installed
try {
  require('openai');
  require('axios');
  require('dotenv');
  runTests().catch(console.error);
} catch (error) {
  console.log(`${colors.yellow}⚠️  Missing dependencies. Run: npm install${colors.reset}\n`);
  console.log('Required packages:');
  console.log('  - openai');
  console.log('  - axios');
  console.log('  - dotenv\n');
}
