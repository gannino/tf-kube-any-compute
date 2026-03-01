---
description: Look up library documentation using Context7 MCP
---

# Documentation Lookup

Look up library and package documentation using Context7 MCP.

## Purpose

Quickly access up-to-date documentation for any npm package, library, or framework using the Context7 MCP server. Eliminates the need to switch context to a browser to look up API documentation.

**Category**: Development & Research

## Inputs

### Required
- **Package name**: The npm package name (e.g., `react`, `@anthropic-ai/sdk`, `next`)

### Optional
- **Specific topic**: What aspect to look up (e.g., `useState hook`, `authentication`, `API reference`)
- **Version**: Specific package version (default: latest)
- **Code examples needed**: Whether to include code examples in results

## System Context

Before starting:
- Read `memory.md` for current project context and previously looked up packages
- Check `knowledge-base.md` for any relevant learned rules about packages
- Check `.mcp.json` to verify context7 MCP is enabled

## Process

### Step 1: Formulate Query

Construct the documentation query:
- Base: Package documentation overview
- With topic: Specific feature or API documentation
- With version: Documentation for specific version

### Step 2: Query Context7 MCP

Use the context7 MCP server to query documentation:
- Package: The npm package name
- Query: The specific topic or general overview
- Format preference: Markdown preferred for code examples

### Step 3: Extract Key Information

From the documentation response, extract:
- Package overview and purpose
- Key features and capabilities
- Installation instructions
- Common usage patterns
- API signatures for requested topics
- Code examples
- Best practices and gotchas

### Step 4: Format Results

Organize the information into a readable format:
- Include relevant code examples
- Highlight important notes or warnings
- Link to official documentation if available
- Summarize key points

### Step 5: Context Integration

If relevant to current project:
- Compare with project's installed version
- Note any version differences
- Suggest applicable patterns or migrations

## Output Format

```markdown
# Documentation: [Package Name]

## Overview
[brief description of the package and its purpose]

## Installation
```bash
[npm install command]
```

## Key Features
[list of main features and capabilities]

## [Specific Topic Documentation]
[detailed information about the requested topic]

## Code Examples
```javascript
[relevant code examples from the docs]
```

## Important Notes
[key warnings, gotchas, or best practices]

## Further Reading
[links to official documentation or related topics]
```

## Quality Validation

- [ ] Package name is valid and exists on npm
- [ ] Query is specific enough to return relevant results
- [ ] Code examples are complete and runnable
- [ ] Version information is included if relevant
- [ ] Security notes are highlighted if present

## Common Use Cases

**Framework Documentation:**
- React: `useState`, `useEffect`, component patterns
- Next.js: App router, server components, middleware
- Vue: Composition API, reactivity system
- Express: Routing, middleware, error handling

**Library Documentation:**
- Testing: Jest, Vitest, Playwright
- State: Zustand, Redux, Jotai
- UI: Tailwind, Chakra, shadcn/ui
- Utilities: Lodash, date-fns, zod

**API Documentation:**
- Anthropic SDK: Message streaming, tool use
- Database: Prisma, Drizzle, Mongoose
- Auth: NextAuth, Lucia, Clerk

## Tips

1. **Be specific**: "How do I use useEffect for data fetching?" is better than "React hooks"
2. **Include context**: "Next.js 14 app router authentication with NextAuth" is better than "authentication"
3. **Request examples**: Always ask for code examples when available
4. **Check versions**: Note the documentation version vs your installed version
5. **Cross-reference**: If multiple packages are involved, look up each one
