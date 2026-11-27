---
description: Analyze local documentation using filesystem MCP
---

# Local Documentation Analysis

Analyze and index local project documentation using the filesystem MCP server.

## Purpose

Systematically discover, catalog, and analyze documentation within a project using the filesystem MCP. Provides structured access to project-specific documentation without needing external search tools.

**Category**: Development & Research

## Inputs

### Required
- **Project path**: Root directory to analyze (default: current working directory)

### Optional
- **Documentation type**: Type of docs to focus on (README, API, guides, tutorials, architecture)
- **Output format**: Summary, detailed index, or full analysis
- **Specific file**: Analyze a specific documentation file

## System Context

Before starting:
- Read `memory.md` for current project context
- Check `.mcp.json` to verify filesystem MCP is enabled
- Review any existing documentation indices in the project

## Process

### Step 1: Discover Documentation Files

Use filesystem MCP to search for documentation:
- `search_files` for common doc patterns: `**/*.md`, `**/README*`, `**/docs/**`
- `directory_tree` to visualize documentation structure
- `list_directory` to examine documentation directories

Common documentation locations:
- Root level: README.md, CONTRIBUTING.md, CHANGELOG.md
- docs/ directory: guides, tutorials, API reference
- src/ directories: inline documentation, code comments
- .claude/: project-specific Claude instructions

### Step 2: Categorize Documentation

Group discovered files by type:
- **Getting Started**: README, INSTALL, SETUP, QUICKSTART
- **Architecture**: ARCHITECTURE, DESIGN, docs/architecture/
- **API Reference**: api/, docs/api/, swagger/openapi files
- **Guides**: docs/guides/, tutorials/, how-to/
- **Contributing**: CONTRIBUTING, DEVELOPMENT, HACKING
- **Changelog**: CHANGELOG, HISTORY, RELEASES
- **Reference**: docs/reference/, glossary/, faq/

### Step 3: Analyze Content

For each documentation file:
- `read_text_file` to extract content
- Identify main sections and headers
- Extract key topics covered
- Note cross-references between documents
- Identify outdated or incomplete sections

### Step 4: Build Documentation Index

Create a structured index:
- File path and title
- Brief description of content
- Key topics covered
- Related documents
- Last modified date (from file metadata)

### Step 5: Generate Summary

Compile analysis results:
- Total documentation files found
- Documentation coverage by category
- Gaps or missing documentation
- Outdated or orphaned files
- Recommendations for improvements

## Output Format

```markdown
# Documentation Analysis: [Project Name]

## Summary
- **Total Files**: [number of documentation files]
- **Coverage**: [assessment of documentation completeness]
- **Last Updated**: [most recent documentation change]
- **Gaps**: [missing documentation areas]

## Documentation Structure

### Getting Started
- [README.md](path/to/README.md) — Project overview and quick start
- [INSTALL.md](path/to/INSTALL.md) — Installation instructions

### Architecture
- [ARCHITECTURE.md](path/to/ARCHITECTURE.md) — System design overview
- [docs/architecture/](path/to/docs/architecture/) — Detailed architecture docs

### API Reference
- [docs/api/](path/to/docs/api/) — API documentation
- [openapi.yaml](path/to/openapi.yaml) — OpenAPI specification

## Detailed Index

| File | Category | Topics | Status |
|------|----------|---------|--------|
| [README.md](path) | Overview | installation, usage | Complete |
| [ARCHITECTURE.md](path) | Architecture | design, components | Needs update |

## Content Analysis

### Coverage by Category
- **Getting Started**: [X/Y files] — [complete/incomplete]
- **Architecture**: [X/Y files] — [complete/incomplete]
- **API Reference**: [X/Y files] — [complete/incomplete]
- **Guides**: [X/Y files] — [complete/incomplete]

### Identified Gaps
- [Missing documentation areas]
- [Incomplete sections]
- [Outdated information]

### Cross-References
- [Related documents that should link to each other]
- [Orphaned pages not linked from anywhere]

## Recommendations
1. [Specific improvement suggestions]
2. [Files to create or update]
3. [Structural improvements]
```

## Quality Validation

- [ ] All documentation files have been discovered
- [ ] Files are correctly categorized
- [ ] Content summaries are accurate
- [ ] Cross-references are identified
- [ ] Gaps and recommendations are specific

## Common Documentation Patterns

### README Structure
A good README should include:
- Project title and brief description
- Installation instructions
- Quick start example
- Key features
- Links to full documentation
- Contributing guidelines
- License information

### Architecture Documentation
Should cover:
- High-level system overview
- Key components and their relationships
- Data flow diagrams
- Technology choices and rationale
- Deployment architecture
- Security considerations

### API Documentation
Should include:
- Endpoint descriptions
- Request/response formats
- Authentication details
- Error codes and handling
- Rate limiting
- Code examples

## Tips

1. **Start with README**: It's usually the most comprehensive overview
2. **Follow the links**: Documentation often references other docs
3. **Check dates**: Look at file modification timestamps to identify stale docs
4. **Search for keywords**: Use `grep` or `search_files` to find specific topics
5. **Review examples**: Code examples are often the most accurate documentation
6. **Check for tests**: Test files can serve as usage documentation
7. **Look for comments**: Inline code comments often explain implementation details
8. **Verify links**: Check if cross-references actually point to existing files

## Integration with Other Skills

This skill works well with:
- **doc-lookup**: For external library documentation
- **onboarding-sherpa**: For rapid codebase understanding
- **archaeologist**: For understanding why code exists
