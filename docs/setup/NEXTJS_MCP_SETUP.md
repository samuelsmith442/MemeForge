# Next.js MCP Server Setup

## Overview

The Next.js MCP (Model Context Protocol) server enables AI agents to access your application state, errors, logs, and metadata during development.

## Configuration

### 1. MCP Configuration File

The `.mcp.json` file at the project root configures all MCP servers:

```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools-mcp@latest"]
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "foundry": {
      "command": "npx",
      "args": ["-y", "@upstash/foundry-mcp"]
    }
  }
}
```

### 2. Next.js Configuration

The `frontend/next.config.js` includes:
- Image optimization for DALL·E and IPFS
- Webpack bundle optimization
- Code splitting configuration

## Available Tools

### Next.js MCP Tools

1. **get_errors** - Retrieve build errors, runtime errors, and type errors
2. **get_logs** - Access development server logs and console output
3. **get_page_metadata** - Get metadata about specific pages
4. **get_project_metadata** - Retrieve project structure and configuration
5. **get_server_action_by_id** - Look up Server Actions by ID

### Context7 MCP Tools

- **get-library-docs** - Fetch up-to-date documentation for libraries
- **resolve-library-id** - Resolve package names to Context7 IDs

### Foundry MCP Tools

- **anvil_start/stop/status** - Manage local Ethereum node
- **cast_balance/call/send** - Interact with smart contracts
- **forge_script** - Run deployment scripts
- **heimdall_*** - Analyze EVM bytecode

## Usage with AI Agents

### Starting Development

```bash
cd frontend
npm run dev
```

The MCP server will automatically start with the dev server.

### Agent Access

AI agents can now:
- ✅ Detect and diagnose errors in real-time
- ✅ Access application logs
- ✅ Understand project structure
- ✅ Debug Server Actions
- ✅ Get page routing information

### Example Agent Queries

**Error Detection:**
```
"What errors are currently in my Next.js app?"
```

**Project Understanding:**
```
"Show me the structure of my Next.js project"
```

**Page Analysis:**
```
"What components are used on the /create page?"
```

## Benefits

### For Development
- **Real-time Error Detection** - Agents can identify and fix errors immediately
- **Context-Aware Assistance** - Agents understand your project structure
- **Faster Debugging** - Direct access to logs and metadata
- **Smart Suggestions** - Based on actual application state

### For MemeForge
- **AI-Powered Debugging** - Agents can help fix issues in the wizard
- **Component Analysis** - Understand component dependencies
- **Performance Monitoring** - Track bundle sizes and optimization
- **Smart Contract Integration** - Debug blockchain interactions

## Troubleshooting

### MCP Server Not Connecting

1. **Check dev server is running:**
   ```bash
   npm run dev
   ```

2. **Verify .mcp.json exists:**
   ```bash
   cat .mcp.json
   ```

3. **Restart your IDE/Agent:**
   - Close and reopen your coding agent
   - Restart the Next.js dev server

### Tools Not Available

1. **Update next-devtools-mcp:**
   ```bash
   npx next-devtools-mcp@latest
   ```

2. **Check Next.js version:**
   ```bash
   npm list next
   ```
   - Should be 15.0.0 or higher

### Performance Issues

If MCP server causes lag:
- Reduce polling frequency in agent settings
- Disable unused MCP servers in `.mcp.json`
- Use selective tool access

## Best Practices

### 1. Development Workflow
- Keep dev server running during agent sessions
- Use MCP tools for debugging before manual inspection
- Let agents access errors first

### 2. Security
- MCP server only runs in development
- Never expose MCP endpoints in production
- Keep `.mcp.json` in version control

### 3. Performance
- Use lazy loading for heavy components
- Monitor bundle size with MCP tools
- Optimize based on metadata insights

## Integration with MemeForge

### Current Setup
- ✅ Next.js MCP configured
- ✅ Context7 for documentation
- ✅ Foundry for smart contracts
- ✅ All tools available to agents

### Workflow
1. Agent detects errors via `get_errors`
2. Agent analyzes structure via `get_project_metadata`
3. Agent suggests fixes based on context
4. Agent verifies fixes via logs

## Resources

- [Next.js MCP Documentation](https://nextjs.org/docs/app/guides/mcp)
- [next-devtools-mcp Repository](https://github.com/vercel/next-devtools-mcp)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## Version Info

- **Next.js:** 15.5.6
- **MCP Protocol:** Latest
- **next-devtools-mcp:** Latest (auto-updated)
