#!/bin/bash

echo "🔧 Fixing OpenAI Organization ID issue..."
echo ""
echo "The error means your OPENAI_ORG_ID doesn't match your API key."
echo ""
echo "Options:"
echo "1. Remove OPENAI_ORG_ID (recommended for single org)"
echo "2. Update with correct org ID from: https://platform.openai.com/account/organization"
echo ""
read -p "Remove OPENAI_ORG_ID from .env.local? (Y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    # Comment out the OPENAI_ORG_ID line
    sed -i 's/^OPENAI_ORG_ID=/#OPENAI_ORG_ID=/' frontend/.env.local
    echo "✅ OPENAI_ORG_ID commented out"
    echo ""
    echo "Testing connection..."
    cd frontend && node test-api-keys.js
else
    echo ""
    echo "Please manually update OPENAI_ORG_ID in frontend/.env.local"
    echo "Get correct ID from: https://platform.openai.com/account/organization"
fi
