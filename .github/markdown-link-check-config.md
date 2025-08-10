# Markdown Link Check Configuration

This configuration file (`markdown-link-check-config.json`) handles common issues that occur when checking external links in CI environments:

## Common Issues Addressed

### 1. Network Connectivity Issues
- **terraform.io** and **hashicorp.com** sometimes have connection resets in CI
- **Solution**: Enhanced headers with proper User-Agent and retry logic

### 2. Rate Limiting
- **OpenAI** and other services may return 403 errors due to rate limiting
- **Solution**: Retry logic and fallback status codes

### 3. URL Redirects
- Some URLs have changed (e.g., `openai.com/gpt-4` → `openai.com/product/gpt-4`)
- **Solution**: Replacement patterns to handle URL changes

## Configuration Features

- **Timeout**: 30 seconds for external requests
- **Retries**: 3 attempts with 429 retry handling
- **Headers**: Realistic browser headers to avoid blocking
- **Status Codes**: Comprehensive list of acceptable response codes
- **Local URLs**: Ignored patterns for development/test environments

## CI Integration

The link check job is configured with `continue-on-error: true` to prevent external link issues from blocking the entire CI pipeline. This ensures:

1. **Fast Feedback**: Core functionality tests aren't delayed by external link issues
2. **Informational**: Link check results are reported but non-blocking
3. **Practical**: Avoids CI failures due to temporary external service issues

## Manual Testing

To test link checking locally:

```bash
# Install markdown-link-check
npm install -g markdown-link-check

# Check specific file
markdown-link-check README.md --config .github/markdown-link-check-config.json

# Check all markdown files
find . -name "*.md" -not -path "./node_modules/*" -exec markdown-link-check {} --config .github/markdown-link-check-config.json \;
```

## Maintenance

- Review failed links periodically and update URLs if needed
- Add new patterns to `ignorePatterns` for development URLs
- Update `replacementPatterns` when services change URLs
- Adjust timeout and retry settings based on CI performance
