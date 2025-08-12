#!/bin/bash
set -e

echo "Checking terraform-docs on all modules..."

# Check root README.md
echo "Checking root README.md..."
cp README.md README.md.backup
terraform-docs markdown table --output-file README.md .
if ! diff -q README.md README.md.backup >/dev/null 2>&1; then
  echo "❌ Root README.md is not up to date - updating it"
  rm README.md.backup
else
  mv README.md.backup README.md
fi

# Check all submodule README.md files
for dir in helm-*/; do
  if [ -d "$dir" ]; then
    echo "Checking $dir/README.md..."
    cd "$dir"
    if [ -f README.md ]; then
      cp README.md README.md.backup
    fi
    terraform-docs markdown table --output-file README.md .
    if [ -f README.md.backup ] && ! diff -q README.md README.md.backup >/dev/null 2>&1; then
      echo "❌ $dir/README.md is not up to date - updating it"
      rm README.md.backup
    elif [ -f README.md.backup ]; then
      mv README.md.backup README.md
    fi
    cd ..
  fi
done

echo "✅ terraform-docs check completed"
