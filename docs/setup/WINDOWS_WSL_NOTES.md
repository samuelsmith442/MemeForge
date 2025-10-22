# Windows/WSL Integration Notes

## 📁 File System Locations

### WSL (Linux) - Current Location
```
/home/ubuntuonwindows11/Cyfrin_Updraft/MemeForge/
```

**Contains:**
- Smart contracts (Foundry project)
- Tests
- Deployment scripts
- MCP configuration

### Windows - Starter Files Location
```
Windows: folders/nextjs-15-starter-tailwindcss-v4-main
```

**Contains:**
- Next.js 15 starter template
- Tailwind CSS v4 configuration
- TypeScript setup

---

## 🔄 Accessing Files Between Systems

### From WSL to Windows

```bash
# Windows drives are mounted at /mnt/
cd /mnt/c/Users/YourUsername/folders/nextjs-15-starter-tailwindcss-v4-main

# Or use Windows path
explorer.exe .
```

### From Windows to WSL

```powershell
# Access WSL filesystem from Windows
\\wsl$\Ubuntu\home\ubuntuonwindows11\Cyfrin_Updraft\MemeForge
```

---

## 🚀 Next Steps for Frontend Setup

### Option 1: Copy Starter to WSL (Recommended)

```bash
# Find the Windows folder
cd /mnt/c/Users/
find . -name "*nextjs-15-starter*" -type d 2>/dev/null

# Copy to WSL
cp -r /mnt/c/Users/YourUsername/folders/nextjs-15-starter-tailwindcss-v4-main ~/Cyfrin_Updraft/MemeForge/frontend-starter

# Then merge with our setup
cd ~/Cyfrin_Updraft/MemeForge
# Copy relevant files from frontend-starter to frontend/
```

### Option 2: Work from Windows

```bash
# Create frontend in Windows location
cd /mnt/c/Users/YourUsername/folders/nextjs-15-starter-tailwindcss-v4-main

# Install our dependencies
npm install openai ai @ai-sdk/openai wagmi viem

# Copy our files
cp ~/Cyfrin_Updraft/MemeForge/frontend/src/lib/openai.ts ./src/lib/
cp ~/Cyfrin_Updraft/MemeForge/frontend/src/types/*.ts ./src/types/
```

### Option 3: Use Symbolic Link

```bash
# Create symlink from WSL to Windows folder
ln -s /mnt/c/Users/YourUsername/folders/nextjs-15-starter-tailwindcss-v4-main ~/Cyfrin_Updraft/MemeForge/frontend-windows
```

---

## 📝 TODO: Locate and Copy Starter Files

### Steps to Complete:

1. **Find the exact Windows path:**
   ```bash
   # From WSL
   find /mnt/c/Users -name "*nextjs-15-starter*" -type d 2>/dev/null
   ```

2. **Copy to WSL:**
   ```bash
   # Replace with actual path
   cp -r /mnt/c/Users/[YourUsername]/folders/nextjs-15-starter-tailwindcss-v4-main \
         ~/Cyfrin_Updraft/MemeForge/frontend-starter
   ```

3. **Merge configurations:**
   - Copy Next.js config
   - Copy Tailwind config
   - Merge with our AI integration files
   - Install all dependencies

4. **Update paths in documentation**

---

## 🔧 Current Frontend Setup Status

### ✅ Created in WSL
- `frontend/` directory structure
- TypeScript types (`src/types/`)
- OpenAI client (`src/lib/openai.ts`)
- Configuration files
- Documentation

### 🔜 Need from Windows
- Next.js 15 starter files
- Tailwind CSS v4 configuration
- Base component structure
- App Router setup

---

## 💡 Recommended Approach

**Copy starter to WSL, then merge:**

1. Locate Windows folder path
2. Copy to WSL
3. Merge our AI integration files
4. Install dependencies
5. Test setup

This keeps everything in WSL for:
- Better performance
- Easier git integration
- Consistent development environment
- MCP server access

---

## 🎯 Action Items

- [ ] Find exact Windows path to nextjs-15-starter folder
- [ ] Copy starter files to WSL
- [ ] Merge with our frontend/ setup
- [ ] Install dependencies
- [ ] Test Next.js dev server
- [ ] Update documentation with actual paths

---

## 📚 Useful Commands

### Find files in Windows from WSL
```bash
# Search C drive
find /mnt/c -name "*nextjs*" -type d 2>/dev/null | grep starter

# Search all drives
find /mnt -name "*nextjs-15-starter*" -type d 2>/dev/null
```

### Copy large directories
```bash
# With progress
rsync -av --progress /mnt/c/source/ ~/destination/

# Or simple copy
cp -rv /mnt/c/source/ ~/destination/
```

### Check disk space
```bash
df -h
```

---

## 🔐 Permissions Note

Files copied from Windows to WSL may have different permissions:

```bash
# Fix permissions after copying
chmod -R u+rw ~/Cyfrin_Updraft/MemeForge/frontend-starter
```

---

**Note:** Update this file with actual paths once Windows folder is located.
