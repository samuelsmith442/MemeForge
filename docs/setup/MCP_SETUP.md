# MCP (Model Context Protocol) Server Setup

## 🎯 What are MCP Servers?

MCP servers provide AI assistants with access to external tools and data sources. For MemeForge, we can use:

1. **Foundry MCP** - Smart contract development tools
2. **Filesystem MCP** - Project file access
3. **Git MCP** - Repository operations
4. **GitHub MCP** - GitHub API access

---

## 📁 Configuration File

Created: `.mcp/config.json`

This file configures all MCP servers for the project.

---

## 🚀 Available MCP Servers

### 1. Foundry MCP Server
**Purpose:** Smart contract development tools
- Compile contracts
- Run tests
- Deploy contracts
- Interact with blockchain

**Command:**
```bash
npx -y @modelcontextprotocol/server-foundry
```

### 2. Filesystem MCP Server
**Purpose:** File system access
- Read project files
- Write files
- List directories
- Search files

**Command:**
```bash
npx -y @modelcontextprotocol/server-filesystem /path/to/project
```

### 3. Git MCP Server
**Purpose:** Git operations
- Commit changes
- Create branches
- View history
- Manage remotes

**Command:**
```bash
npx -y @modelcontextprotocol/server-git
```

### 4. GitHub MCP Server
**Purpose:** GitHub API access
- Create issues
- Manage PRs
- View repositories
- Update releases

**Command:**
```bash
npx -y @modelcontextprotocol/server-github
```

---

## 🔧 Setup Instructions

### For Windsurf/Cascade

1. **Check if MCP is enabled:**
   - Open Windsurf settings
   - Look for "MCP" or "Model Context Protocol"
   - Enable if disabled

2. **Configure MCP servers:**
   - Copy `.mcp/config.json` to Windsurf config directory
   - Or manually add servers in Windsurf settings

3. **Restart Windsurf**

### For VS Code with Claude Dev

1. **Install Claude Dev extension**

2. **Configure MCP servers:**
   ```bash
   # Edit settings
   code ~/.vscode-server/data/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
   ```

3. **Add server configurations:**
   Copy contents from `.mcp/config.json`

4. **Restart VS Code**

---

## 🧪 Testing MCP Servers

### Test Foundry MCP
```bash
# Check if forge is accessible
forge --version

# Test compilation
forge build

# Test tests
forge test
```

### Test Filesystem MCP
```bash
# List files
ls -la

# Read a file
cat README.md
```

### Test Git MCP
```bash
# Check git status
git status

# View log
git log --oneline -5
```

### Test GitHub MCP
```bash
# Check GitHub CLI
gh --version

# View repo info
gh repo view
```

---

## 🔐 Environment Variables

Some MCP servers require environment variables:

### GitHub Token
```bash
export GITHUB_TOKEN=ghp_your_token_here
```

### OpenAI API Key (for AI features)
```bash
export OPENAI_API_KEY=sk-your-key-here
```

Add to `.env` or `.bashrc`:
```bash
echo 'export GITHUB_TOKEN=ghp_your_token' >> ~/.bashrc
echo 'export OPENAI_API_KEY=sk-your-key' >> ~/.bashrc
source ~/.bashrc
```

---

## 📊 MCP Server Status

### Check if MCP servers are running:

```bash
# Check for running npx processes
ps aux | grep npx

# Check for MCP-related processes
ps aux | grep mcp
```

### Manually start a server:

```bash
# Start Foundry MCP
npx -y @modelcontextprotocol/server-foundry

# Start Filesystem MCP
npx -y @modelcontextprotocol/server-filesystem $(pwd)

# Start Git MCP
npx -y @modelcontextprotocol/server-git

# Start GitHub MCP
npx -y @modelcontextprotocol/server-github
```

---

## 🐛 Troubleshooting

### MCP servers not working?

1. **Check Node.js version:**
   ```bash
   node --version  # Should be 18+
   ```

2. **Check npx:**
   ```bash
   npx --version
   ```

3. **Clear npx cache:**
   ```bash
   npx clear-npx-cache
   ```

4. **Reinstall MCP servers:**
   ```bash
   npm install -g @modelcontextprotocol/server-foundry
   npm install -g @modelcontextprotocol/server-filesystem
   npm install -g @modelcontextprotocol/server-git
   npm install -g @modelcontextprotocol/server-github
   ```

### Permission issues?

```bash
# Fix npm permissions
sudo chown -R $USER ~/.npm
sudo chown -R $USER /usr/local/lib/node_modules
```

### Foundry MCP not finding forge?

```bash
# Add Foundry to PATH
echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 📚 MCP Resources

- [MCP Documentation](https://modelcontextprotocol.io/)
- [MCP GitHub](https://github.com/modelcontextprotocol)
- [Foundry MCP](https://github.com/modelcontextprotocol/servers/tree/main/src/foundry)
- [Filesystem MCP](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem)

---

## 🎯 MCP Servers for MemeForge

### Recommended Setup

For optimal development experience with MemeForge:

1. ✅ **Foundry MCP** - Essential for smart contract work
2. ✅ **Filesystem MCP** - Useful for file operations
3. ✅ **Git MCP** - Helpful for version control
4. ⚠️ **GitHub MCP** - Optional, requires GitHub token

### Minimal Setup

If you just want to get started:

1. ✅ **Foundry MCP** - For smart contract development
2. ✅ **Filesystem MCP** - For file access

---

## 🔄 Auto-start MCP Servers

### Create a startup script:

```bash
cat > start-mcp-servers.sh << 'EOF'
#!/bin/bash

# Start Foundry MCP
npx -y @modelcontextprotocol/server-foundry &

# Start Filesystem MCP
npx -y @modelcontextprotocol/server-filesystem $(pwd) &

# Start Git MCP
npx -y @modelcontextprotocol/server-git &

echo "MCP servers started"
EOF

chmod +x start-mcp-servers.sh
```

### Run on startup:

```bash
# Add to .bashrc
echo './start-mcp-servers.sh' >> ~/.bashrc
```

---

## ✅ Verification

### Check if MCP servers are accessible:

1. **Ask AI assistant to:**
   - "Run forge test"
   - "List files in src/"
   - "Show git status"
   - "Create a new branch"

2. **If commands work, MCP is configured correctly!**

---

## 📝 Notes

- MCP servers run in the background
- They communicate with AI assistants via stdio
- Each server provides specific capabilities
- Servers are automatically started when needed

---

**MCP servers enhance AI assistant capabilities for smart contract development!** 🚀
