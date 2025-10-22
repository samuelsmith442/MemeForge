#!/usr/bin/env node

/**
 * Comprehensive test script for all AI endpoints
 * Run: node test-all-endpoints.js
 */

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m',
};

const BASE_URL = 'http://localhost:3000';

console.log(`\n${colors.cyan}╔════════════════════════════════════════╗${colors.reset}`);
console.log(`${colors.cyan}║   MemeForge AI Endpoints Test Suite   ║${colors.reset}`);
console.log(`${colors.cyan}╚════════════════════════════════════════╝${colors.reset}\n`);

// Test results tracker
const results = {
  passed: 0,
  failed: 0,
  tests: [],
};

// Helper function to make requests
async function testEndpoint(name, url, method = 'GET', body = null) {
  console.log(`${colors.blue}▶${colors.reset} Testing: ${name}`);
  
  try {
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (body) {
      options.body = JSON.stringify(body);
    }

    const startTime = Date.now();
    const response = await fetch(url, options);
    const duration = Date.now() - startTime;
    const data = await response.json();

    if (response.ok) {
      console.log(`  ${colors.green}✓${colors.reset} Status: ${response.status} (${duration}ms)`);
      results.passed++;
      results.tests.push({ name, status: 'passed', duration });
      return { success: true, data, duration };
    } else {
      console.log(`  ${colors.red}✗${colors.reset} Status: ${response.status} - ${data.message || data.error}`);
      results.failed++;
      results.tests.push({ name, status: 'failed', error: data.message });
      return { success: false, error: data };
    }
  } catch (error) {
    console.log(`  ${colors.red}✗${colors.reset} Error: ${error.message}`);
    results.failed++;
    results.tests.push({ name, status: 'failed', error: error.message });
    return { success: false, error: error.message };
  }
}

// Test Suite
async function runTests() {
  console.log(`${colors.magenta}═══════════════════════════════════════${colors.reset}\n`);
  console.log(`${colors.yellow}📋 Test 1: Health Checks${colors.reset}\n`);

  // Test 1: Logo Generation Health
  await testEndpoint(
    'Logo Generation Health Check',
    `${BASE_URL}/api/ai/generate-logo`,
    'GET'
  );

  // Test 2: Parameter Suggestions Health
  await testEndpoint(
    'Parameter Suggestions Health Check',
    `${BASE_URL}/api/ai/suggest-params`,
    'GET'
  );

  // Test 3: Chat Assistant Health
  await testEndpoint(
    'Chat Assistant Health Check',
    `${BASE_URL}/api/ai/chat`,
    'GET'
  );

  console.log(`\n${colors.magenta}═══════════════════════════════════════${colors.reset}\n`);
  console.log(`${colors.yellow}🎨 Test 2: Logo Generation${colors.reset}\n`);

  // Test 4: Generate Logo
  const logoResult = await testEndpoint(
    'Generate Logo (Space Theme)',
    `${BASE_URL}/api/ai/generate-logo`,
    'POST',
    {
      name: 'TestCoin',
      theme: 'space',
      style: 'cartoon',
      additionalPrompt: 'Make it fun and colorful',
    }
  );

  if (logoResult.success) {
    console.log(`  ${colors.cyan}→${colors.reset} Image URL: ${logoResult.data.imageUrl?.substring(0, 50)}...`);
    console.log(`  ${colors.cyan}→${colors.reset} Prompt: ${logoResult.data.prompt?.substring(0, 60)}...`);
  }

  console.log(`\n${colors.magenta}═══════════════════════════════════════${colors.reset}\n`);
  console.log(`${colors.yellow}💡 Test 3: Parameter Suggestions${colors.reset}\n`);

  // Test 5: Get Parameter Suggestions
  const paramsResult = await testEndpoint(
    'Generate Parameter Suggestions',
    `${BASE_URL}/api/ai/suggest-params`,
    'POST',
    {
      name: 'TestCoin',
      theme: 'gaming',
      targetAudience: 'gamers and crypto enthusiasts',
      goals: 'build a strong community and enable governance',
    }
  );

  if (paramsResult.success) {
    const suggestions = paramsResult.data.suggestions;
    console.log(`  ${colors.cyan}→${colors.reset} Total Supply: ${suggestions.tokenomics?.totalSupply}`);
    console.log(`  ${colors.cyan}→${colors.reset} Base APY: ${suggestions.staking?.baseAPY}`);
    console.log(`  ${colors.cyan}→${colors.reset} Recommendations: ${suggestions.recommendations?.length} items`);
  }

  console.log(`\n${colors.magenta}═══════════════════════════════════════${colors.reset}\n`);
  console.log(`${colors.yellow}💬 Test 4: Chat Assistant${colors.reset}\n`);

  // Test 6: Chat - General Question
  const chatResult1 = await testEndpoint(
    'Chat - General Question',
    `${BASE_URL}/api/ai/chat`,
    'POST',
    {
      messages: [
        {
          role: 'user',
          content: 'What makes a good memecoin?',
        },
      ],
    }
  );

  if (chatResult1.success) {
    console.log(`  ${colors.cyan}→${colors.reset} Response: ${chatResult1.data.message?.substring(0, 100)}...`);
    console.log(`  ${colors.cyan}→${colors.reset} Tokens: ${chatResult1.data.usage?.totalTokens}`);
  }

  // Test 7: Chat - Context-Aware Question
  const chatResult2 = await testEndpoint(
    'Chat - Context-Aware Question',
    `${BASE_URL}/api/ai/chat`,
    'POST',
    {
      messages: [
        {
          role: 'user',
          content: 'I want to create a space-themed memecoin. What should I consider?',
        },
      ],
      context: {
        theme: 'space',
        name: 'MoonRocket',
      },
    }
  );

  if (chatResult2.success) {
    console.log(`  ${colors.cyan}→${colors.reset} Response: ${chatResult2.data.message?.substring(0, 100)}...`);
  }

  // Test 8: Chat - Multi-turn Conversation
  const chatResult3 = await testEndpoint(
    'Chat - Multi-turn Conversation',
    `${BASE_URL}/api/ai/chat`,
    'POST',
    {
      messages: [
        {
          role: 'user',
          content: 'What is staking?',
        },
        {
          role: 'assistant',
          content: 'Staking is when you lock up your tokens for a period of time to earn rewards...',
        },
        {
          role: 'user',
          content: 'What APY should I offer?',
        },
      ],
    }
  );

  if (chatResult3.success) {
    console.log(`  ${colors.cyan}→${colors.reset} Response: ${chatResult3.data.message?.substring(0, 100)}...`);
  }

  console.log(`\n${colors.magenta}═══════════════════════════════════════${colors.reset}\n`);
  console.log(`${colors.yellow}⚠️  Test 5: Error Handling${colors.reset}\n`);

  // Test 9: Missing Required Fields
  await testEndpoint(
    'Logo Generation - Missing Fields',
    `${BASE_URL}/api/ai/generate-logo`,
    'POST',
    {
      name: 'TestCoin',
      // Missing theme and style
    }
  );

  // Test 10: Invalid Chat Messages
  await testEndpoint(
    'Chat - Invalid Messages',
    `${BASE_URL}/api/ai/chat`,
    'POST',
    {
      messages: 'invalid',
    }
  );

  // Print Summary
  console.log(`\n${colors.magenta}═══════════════════════════════════════${colors.reset}\n`);
  console.log(`${colors.cyan}📊 Test Summary${colors.reset}\n`);
  console.log(`  Total Tests: ${results.passed + results.failed}`);
  console.log(`  ${colors.green}✓ Passed: ${results.passed}${colors.reset}`);
  console.log(`  ${colors.red}✗ Failed: ${results.failed}${colors.reset}`);
  
  if (results.failed === 0) {
    console.log(`\n  ${colors.green}🎉 All tests passed!${colors.reset}`);
  } else {
    console.log(`\n  ${colors.yellow}⚠️  Some tests failed. Check the output above.${colors.reset}`);
  }

  // Print detailed results
  console.log(`\n${colors.cyan}Detailed Results:${colors.reset}`);
  results.tests.forEach((test, index) => {
    const icon = test.status === 'passed' ? colors.green + '✓' : colors.red + '✗';
    const duration = test.duration ? ` (${test.duration}ms)` : '';
    console.log(`  ${icon} ${index + 1}. ${test.name}${duration}${colors.reset}`);
    if (test.error) {
      console.log(`     ${colors.red}Error: ${test.error}${colors.reset}`);
    }
  });

  console.log(`\n${colors.magenta}═══════════════════════════════════════${colors.reset}\n`);

  // Exit with appropriate code
  process.exit(results.failed > 0 ? 1 : 0);
}

// Check if server is running
async function checkServer() {
  try {
    await fetch(BASE_URL);
    return true;
  } catch (error) {
    console.log(`${colors.red}❌ Error: Dev server not running at ${BASE_URL}${colors.reset}\n`);
    console.log(`Please start the server first:`);
    console.log(`  cd frontend && npm run dev\n`);
    return false;
  }
}

// Main execution
(async () => {
  const serverRunning = await checkServer();
  if (serverRunning) {
    await runTests();
  } else {
    process.exit(1);
  }
})();
