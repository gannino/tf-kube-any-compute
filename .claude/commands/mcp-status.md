---
description: Check health and configuration of MCP servers
argument-hint: ""
allowed-tools:
  - Read
  - Bash(jq:*, ls:*)
---

# MCP Status Check

Display configuration status of all MCP servers from `.mcp.json`.

## Steps

### Step 1: Read MCP configuration

Read `.mcp.json` to get all configured MCP servers.

### Step 2: Parse and display

For each MCP server, display:
- Server name
- Enabled/disabled status
- Command type
- Auto-approved tool count
- Timeout setting

### Step 3: Output format

```
MCP Servers Status
==================

[server-name]
  Status: enabled/disabled
  Command: [command]
  Auto-approved: N tools
  Timeout: Ns
```

### Step 4: Validation

Check if any paths reference non-existent directories and flag them.
