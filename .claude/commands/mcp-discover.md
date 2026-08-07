---
description: List all tools available from MCP servers
argument-hint: "[filter]"
allowed-tools:
  - Read
---

# MCP Tool Discovery

List every available tool from configured MCP servers.

## Steps

### Step 1: Read MCP configuration

Read `.mcp.json` to get all configured MCP servers.

### Step 2: Extract tool information

For each MCP server, extract:
- Server name
- Available tools (from known MCP schemas)
- Auto-approval status

### Step 3: Format output

Group by MCP server:

```
Available MCP Tools
===================

[server-name]
  [tool-name]: [description] [auto-approved: yes/no]
```

### Step 4: Filter (optional)

If user provides a filter string, only show matching tools.
