#!/bin/bash
set -e

echo "Checking terraform-docs on all modules..."
HAS_CHANGES=false

# Check root README.md
echo "Checking root README.md..."
cp README.md README.md.backup 2>/dev/null || touch README.md.backup
terraform-docs markdown table --output-file README.md --output-mode inject .
if ! diff -q README.md README.md.backup >/dev/null 2>&1; then
  echo "❌ Root README.md was out of date - updated"
  HAS_CHANGES=true
  rm README.md.backup
else
  mv README.md.backup README.md
fi

# Check all submodule README.md files
for dir in helm-*/; do
  if [ -d "$dir" ]; then
    echo "Checking $dir/README.md..."
    cd "$dir"
    cp README.md README.md.backup 2>/dev/null || touch README.md.backup
    terraform-docs markdown table --output-file README.md --output-mode inject .
    if ! diff -q README.md README.md.backup >/dev/null 2>&1; then
      echo "❌ $dir/README.md was out of date - updated"
      HAS_CHANGES=true
      rm README.md.backup
    else
      mv README.md.backup README.md
    fi
    cd ..
  fi
done

if [ "$HAS_CHANGES" = "true" ]; then
  echo "❌ Some README.md files were updated. Please stage and commit the changes."
  exit 1
fi

echo "✅ All README.md files are up to date"
