#!/bin/bash
set -e

# Get changed .tf files only
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.tf$' || true)

if [ -z "$CHANGED_FILES" ]; then
  echo "No .tf files changed, skipping TFLint"
  exit 0
fi

echo "Running TFLint on changed directories (optimized for speed)..."

# Get unique directories containing changed files
CHANGED_DIRS=$(echo "$CHANGED_FILES" | xargs dirname | sort -u)

# Initialize TFLint once globally (shared plugins cache)
echo "Initializing TFLint plugins globally..."
tflint --init >/dev/null 2>&1

# Only run on directories with .tflint.hcl AND changed files
for dir in $CHANGED_DIRS; do
  if [ -f "$dir/.tflint.hcl" ]; then
    echo "Checking: $dir"
    # Use --chdir with only critical rules enabled for speed
    if [ "$dir" = "." ]; then
      # Root directory - skip unused declarations (variables may be for future use)
      tflint --chdir="$dir" \
        -f compact \
        --enable-rule=terraform_deprecated_interpolation \
        --enable-rule=terraform_deprecated_index \
        --enable-rule=terraform_comment_syntax \
        --disable-rule=terraform_unused_declarations \
        --disable-rule=terraform_module_pinned_source \
        --disable-rule=terraform_standard_module_structure \
        --disable-rule=terraform_workspace_remote \
        --disable-rule=terraform_documented_outputs \
        --disable-rule=terraform_required_providers \
        --disable-rule=terraform_required_version \
        --disable-rule=terraform_naming_convention
    else
      # Module directories - enable unused declarations to catch real issues
      tflint --chdir="$dir" \
        -f compact \
        --enable-rule=terraform_unused_declarations \
        --enable-rule=terraform_deprecated_interpolation \
        --enable-rule=terraform_deprecated_index \
        --enable-rule=terraform_comment_syntax \
        --disable-rule=terraform_module_pinned_source \
        --disable-rule=terraform_standard_module_structure \
        --disable-rule=terraform_workspace_remote \
        --disable-rule=terraform_documented_outputs \
        --disable-rule=terraform_required_providers \
        --disable-rule=terraform_required_version \
        --disable-rule=terraform_naming_convention
    fi
  else
    echo "Skipping $dir (no .tflint.hcl)"
  fi
done

echo "✅ TFLint check completed (optimized: shared init + minimal rules)"
