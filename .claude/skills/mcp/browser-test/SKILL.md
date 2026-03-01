---
description: Test web application using Playwright MCP
---

# Browser Testing

Test web applications using Playwright MCP server.

## Purpose

Automate browser testing workflows including navigation, interaction, screenshot capture, and console log analysis using the Playwright MCP server.

**Category**: Testing & QA

## Inputs

### Required
- **URL**: The web application URL to test

### Optional
- **Test actions**: List of actions to perform (click, fill, navigate)
- **Selectors**: CSS selectors for elements to interact with
- **Expected results**: What to verify after actions
- **Viewport size**: Browser viewport dimensions (default: 1280x720)

## System Context

Before starting:
- Read `memory.md` for test context and previous test results
- Check `.mcp.json` to verify playwright MCP is enabled
- Review any existing test plans or test data in the project

## Process

### Step 1: Initial Setup

- Navigate to URL: `playwright_navigate` to the target URL
- Set viewport size: `playwright_resize` to specified dimensions
- Take initial screenshot: `playwright_screenshot` as `baseline-[timestamp].png`

### Step 2: Execute Test Actions

For each test action:
- **Navigation**: `playwright_navigate` to new URL
- **Click**: `playwright_click` on element selector
- **Fill form**: `playwright_fill` input field with value
- **Hover**: `playwright_hover` over element
- **Wait**: Wait for page load or element visibility

### Step 3: Capture Results

- Take final screenshot: `playwright_screenshot` as `result-[timestamp].png`
- Capture console logs: `playwright_console_logs` filtering for errors
- Check network requests: `getNetworkLogs` for failed requests

### Step 4: Validation

- Compare screenshots if baseline exists
- Check for console errors or warnings
- Verify expected content is visible: `playwright_get_visible_text`
- Check page title: `browser_evaluate` to get `document.title`

### Step 5: Cleanup

- Close browser: `browser_close`
- Organize screenshots in output directory

## Output Format

```markdown
# Browser Test Results: [URL]

## Summary
- **Status**: [pass/fail/partial]
- **URL Tested**: [URL]
- **Timestamp**: [test execution time]
- **Actions Performed**: [count]

## Screenshots
- **Initial**: [baseline screenshot file]
- **Final**: [result screenshot file]
- **Differences**: [noted visual differences]

## Console Output
### Errors
[any console errors found]

### Warnings
[any console warnings found]

### Network Issues
[failed network requests]

## Test Actions Results
| Action | Target | Expected | Actual | Status |
|--------|--------|----------|---------|--------|
[action details] | [selector] | [expected result] | [actual result] | [pass/fail] |

## Recommendations
[issues found and suggested fixes]
```

## Quality Validation

- [ ] URL is accessible and valid
- [ ] Selectors are specific and accurate
- [ ] Test actions are logically ordered
- [ ] Expected results are clearly defined
- [ ] Screenshots are properly saved
- [ ] Console logs are reviewed for errors

## Common Issues

**Element Not Found:**
- Verify selector is correct
- Check if element is dynamically loaded
- Add explicit wait if needed

**Timeout Errors:**
- Increase timeout for slow-loading pages
- Check network connectivity
- Verify page is not hanging

**Console Errors:**
- Review JavaScript errors
- Check for missing resources (404s)
- Verify API endpoints are responding

## Best Practices

1. **Use specific selectors**: Prefer ID, class, or data attributes over generic selectors
2. **Wait for elements**: Add explicit waits for dynamically loaded content
3. **Capture console logs**: Always review for JavaScript errors
4. **Take screenshots**: Document visual state at key steps
5. **Test real scenarios**: Focus on user workflows, not just component testing
6. **Clean up resources**: Always close browser after testing
