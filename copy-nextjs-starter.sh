#!/bin/bash

if [ -z "$1" ]; then
    echo "❌ Error: No path provided"
    echo ""
    echo "Usage: ./copy-nextjs-starter.sh <path-to-starter>"
    echo ""
    echo "Example:"
    echo "   ./copy-nextjs-starter.sh /mnt/c/Users/YourName/folders/nextjs-15-starter-tailwindcss-v4-main"
    echo ""
    echo "💡 Run ./find-nextjs-starter.sh to locate the folder"
    exit 1
fi

SOURCE_PATH="$1"
DEST_PATH="./frontend-starter"

echo "📁 Copying Next.js starter files..."
echo ""
echo "From: $SOURCE_PATH"
echo "To:   $DEST_PATH"
echo ""

# Check if source exists
if [ ! -d "$SOURCE_PATH" ]; then
    echo "❌ Error: Source directory not found: $SOURCE_PATH"
    exit 1
fi

# Check if destination exists
if [ -d "$DEST_PATH" ]; then
    echo "⚠️  Warning: Destination already exists: $DEST_PATH"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    rm -rf "$DEST_PATH"
fi

# Copy files
echo "Copying files..."
cp -r "$SOURCE_PATH" "$DEST_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Files copied successfully!"
    echo ""
    echo "📊 Contents:"
    ls -la "$DEST_PATH" | head -15
    echo ""
    echo "📝 Next steps:"
    echo "1. Review copied files: cd $DEST_PATH"
    echo "2. Merge with our setup: ./merge-frontend-files.sh"
    echo "3. Install dependencies: cd frontend && npm install"
else
    echo ""
    echo "❌ Error copying files"
    exit 1
fi

echo ""
