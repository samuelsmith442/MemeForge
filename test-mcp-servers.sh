#!/bin/bash

echo "🔍 Testing MCP Server Prerequisites..."
echo ""

# Check Node.js
echo "1. Node.js:"
if command -v node &> /dev/null; then
    echo "   ✅ Node.js $(node --version)"
else
    echo "   ❌ Node.js not found"
fi

# Check npx
echo "2. npx:"
if command -v npx &> /dev/null; then
    echo "   ✅ npx $(npx --version)"
else
    echo "   ❌ npx not found"
fi

# Check Foundry
echo "3. Foundry:"
if command -v forge &> /dev/null; then
    echo "   ✅ forge $(forge --version | head -1)"
else
    echo "   ❌ forge not found"
fi

# Check Git
echo "4. Git:"
if command -v git &> /dev/null; then
    echo "   ✅ git $(git --version)"
else
    echo "   ❌ git not found"
fi

# Check GitHub CLI (optional)
echo "5. GitHub CLI (optional):"
if command -v gh &> /dev/null; then
    echo "   ✅ gh $(gh --version | head -1)"
else
    echo "   ⚠️  gh not found (optional)"
fi

echo ""
echo "📦 Testing MCP Server Packages..."
echo ""

# Test if MCP packages are available
echo "6. Foundry MCP Server:"
if npx -y @modelcontextprotocol/server-foundry --help &> /dev/null; then
    echo "   ✅ Available"
else
    echo "   ⚠️  Not installed (will install on first use)"
fi

echo "7. Filesystem MCP Server:"
if npx -y @modelcontextprotocol/server-filesystem --help &> /dev/null; then
    echo "   ✅ Available"
else
    echo "   ⚠️  Not installed (will install on first use)"
fi

echo ""
echo "🎯 MCP Configuration:"
echo ""

if [ -f ".mcp/config.json" ]; then
    echo "   ✅ MCP config file exists (.mcp/config.json)"
else
    echo "   ❌ MCP config file not found"
fi

echo ""
echo "📊 Summary:"
echo ""

# Count successes
SUCCESS=0
TOTAL=5

command -v node &> /dev/null && ((SUCCESS++))
command -v npx &> /dev/null && ((SUCCESS++))
command -v forge &> /dev/null && ((SUCCESS++))
command -v git &> /dev/null && ((SUCCESS++))
[ -f ".mcp/config.json" ] && ((SUCCESS++))

echo "   $SUCCESS/$TOTAL checks passed"
echo ""

if [ $SUCCESS -eq $TOTAL ]; then
    echo "✅ All MCP prerequisites are ready!"
    echo ""
    echo "Next steps:"
    echo "1. Configure MCP servers in your IDE"
    echo "2. Restart your IDE"
    echo "3. Test by asking AI to 'run forge test'"
else
    echo "⚠️  Some prerequisites are missing"
    echo ""
    echo "See MCP_SETUP.md for installation instructions"
fi

echo ""
