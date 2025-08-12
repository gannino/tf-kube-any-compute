#!/bin/bash
set -e

echo "Running terraform-docs recursively on all modules..."

# Update root README.md
echo "Updating root README.md..."
terraform-docs markdown table --output-file README.md .

# Update all submodule README.md files
for dir in helm-*/; do
  if [ -d "$dir" ]; then
    echo "Updating $dir/README.md..."
    cd "$dir"
    terraform-docs markdown table --output-file README.md .
    cd ..
  fi
done

echo "✅ terraform-docs recursive update completed"
