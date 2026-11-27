#!/usr/bin/env bash
# render-test.sh — Playwright-based render test for a Claudify Weekly issue.
#
# Usage:
#   bash Creatives/claudify/newsletter/render-test.sh <issue-number>
#
# Captures full-page screenshots at 4 viewports (320, 414, 768, 1024 px wide)
# of issues/<NNN>-rendered.html. Saves to issues/screenshots/<NNN>/.
#
# Used by the stylist agent during /newsletter render-test [N].

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <issue-number>" >&2
  exit 2
fi

ISSUE_NUM="$1"
# Zero-pad to 3 digits if needed
PADDED=$(printf "%03d" "$ISSUE_NUM" 2>/dev/null || echo "$ISSUE_NUM")

# Resolve script directory + project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEWSLETTER_DIR="$SCRIPT_DIR"

RENDERED_HTML="$NEWSLETTER_DIR/issues/$PADDED-rendered.html"
SCREENSHOT_DIR="$NEWSLETTER_DIR/issues/screenshots/$PADDED"

if [[ ! -f "$RENDERED_HTML" ]]; then
  echo "ERROR: rendered HTML not found at $RENDERED_HTML" >&2
  echo "Run /newsletter build $ISSUE_NUM first." >&2
  exit 3
fi

mkdir -p "$SCREENSHOT_DIR"

# Resolve to file:// URL
FILE_URL="file://$RENDERED_HTML"

echo "Rendering Issue $PADDED at 4 viewports..."

# 320 (iPhone SE)
echo "  320x568 (iPhone SE)..."
npx --yes playwright screenshot \
  --viewport-size=320,568 \
  --full-page \
  "$FILE_URL" \
  "$SCREENSHOT_DIR/320.png" \
  2>&1 | grep -v "Warning" || true

# 414 (iPhone 11 Pro Max)
echo "  414x896 (iPhone 11)..."
npx --yes playwright screenshot \
  --viewport-size=414,896 \
  --full-page \
  "$FILE_URL" \
  "$SCREENSHOT_DIR/414.png" \
  2>&1 | grep -v "Warning" || true

# 768 (iPad portrait)
echo "  768x1024 (iPad)..."
npx --yes playwright screenshot \
  --viewport-size=768,1024 \
  --full-page \
  "$FILE_URL" \
  "$SCREENSHOT_DIR/768.png" \
  2>&1 | grep -v "Warning" || true

# 1024 (small desktop / large tablet)
echo "  1024x768 (desktop)..."
npx --yes playwright screenshot \
  --viewport-size=1024,768 \
  --full-page \
  "$FILE_URL" \
  "$SCREENSHOT_DIR/1024.png" \
  2>&1 | grep -v "Warning" || true

echo ""
echo "Screenshots saved to: $SCREENSHOT_DIR"
ls -la "$SCREENSHOT_DIR" | grep "\.png" | awk '{print "  " $NF " (" $5 " bytes)"}'

# Quick height heuristic for the 320px viewport.
# Use python for image dimension inspection (Pillow optional, fallback to file metadata).
HEIGHT_320=$(python3 -c "
from PIL import Image
try:
    img = Image.open('$SCREENSHOT_DIR/320.png')
    print(img.height)
except Exception as e:
    print(0)
" 2>/dev/null || echo "0")

# Branch threshold on god-tier-gift presence (parallels BUDGETS.md two-profile model
# and stylist agent's V2 check). Without god-tier: 5000px. With god-tier: 9000px.
ISSUE_SOURCE="$NEWSLETTER_DIR/issues/$PADDED.md"
HEIGHT_THRESHOLD=5000
if [[ -f "$ISSUE_SOURCE" ]] && grep -q "^## GOD_PROMPT_BODY" "$ISSUE_SOURCE"; then
  # Check the section is non-empty (has content after the header)
  GOD_TIER_LEN=$(awk '/^## GOD_PROMPT_BODY$/,/^## [A-Z_]+$/' "$ISSUE_SOURCE" | grep -v "^## " | grep -v "^$" | wc -l)
  if [[ "$GOD_TIER_LEN" -gt "0" ]]; then
    HEIGHT_THRESHOLD=9000
    echo "Profile: WITH god-tier gift (threshold ${HEIGHT_THRESHOLD}px)"
  fi
fi

if [[ "$HEIGHT_320" -gt "$HEIGHT_THRESHOLD" ]]; then
  echo ""
  echo "WARNING: 320px viewport height is ${HEIGHT_320}px (over ${HEIGHT_THRESHOLD}px threshold)."
  echo "  Issue may be too long for mobile readers. Review BUDGETS.md visual two-profile rules."
fi

echo ""
echo "Render test complete for Issue $PADDED."
