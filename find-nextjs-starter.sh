#!/bin/bash

echo "🔍 Searching for Next.js 15 starter files..."
echo ""

# Search common Windows locations
SEARCH_PATHS=(
    "/mnt/c/Users"
    "/mnt/d"
    "/mnt/e"
)

FOUND=0

for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "Searching in $path..."
        RESULTS=$(find "$path" -name "*nextjs-15-starter*" -type d 2>/dev/null | head -5)
        
        if [ ! -z "$RESULTS" ]; then
            echo ""
            echo "✅ Found:"
            echo "$RESULTS"
            echo ""
            FOUND=1
        fi
    fi
done

if [ $FOUND -eq 0 ]; then
    echo ""
    echo "❌ Next.js starter not found in common locations"
    echo ""
    echo "💡 Try searching manually:"
    echo "   find /mnt/c -name '*nextjs*' -type d 2>/dev/null | grep starter"
    echo ""
    echo "Or specify the path directly:"
    echo "   ./copy-nextjs-starter.sh /mnt/c/path/to/starter"
else
    echo ""
    echo "📋 Next steps:"
    echo "1. Copy the path above"
    echo "2. Run: ./copy-nextjs-starter.sh <path>"
    echo ""
    echo "Example:"
    echo "   ./copy-nextjs-starter.sh /mnt/c/Users/YourName/folders/nextjs-15-starter-tailwindcss-v4-main"
fi

echo ""
