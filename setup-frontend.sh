#!/bin/bash

echo "🚀 MemeForge Frontend Setup"
echo ""

# Check if .env.local exists
if [ ! -f "frontend/.env.local" ]; then
    echo "❌ Error: frontend/.env.local not found"
    echo "Run: cp frontend/.env.example frontend/.env.local"
    echo "Then add your OPENAI_API_KEY"
    exit 1
fi

# Check if OPENAI_API_KEY is set
if ! grep -q "OPENAI_API_KEY=sk-" frontend/.env.local; then
    echo "⚠️  Warning: OPENAI_API_KEY not configured in frontend/.env.local"
    echo ""
    echo "Please add your OpenAI API key:"
    echo "1. Get key from: https://platform.openai.com/api-keys"
    echo "2. Edit frontend/.env.local"
    echo "3. Add: OPENAI_API_KEY=sk-your-key-here"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo "📦 Installing dependencies..."
cd frontend

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found"
    echo "Make sure you're in the MemeForge directory"
    exit 1
fi

# Install dependencies
npm install

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Dependencies installed successfully!"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Verify your .env.local has OPENAI_API_KEY"
    echo "2. Run: npm run dev"
    echo "3. Open: http://localhost:3000"
    echo ""
    echo "📝 To create your first API route:"
    echo "   See: docs/frontend/QUICK_START.md"
else
    echo ""
    echo "❌ Error installing dependencies"
    echo "Check the error messages above"
    exit 1
fi
