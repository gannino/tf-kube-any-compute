#!/bin/bash
set -e

echo "Running TFLint recursively on all modules..."

# Initialize TFLint
tflint --init

# Run TFLint on root
echo "Linting root directory..."
tflint -f compact

# Run TFLint on all submodules
for dir in helm-*/; do
  if [ -d "$dir" ]; then
    echo "Linting $dir"
    cd "$dir"
    tflint --init >/dev/null 2>&1
    tflint -f compact
    cd ..
  fi
done

echo "✅ TFLint recursive check completed"
