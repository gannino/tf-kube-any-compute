#!/bin/bash
set -e

echo "Running TFLint recursively on all modules (full check)..."

# Initialize TFLint once globally
echo "Initializing TFLint plugins..."
tflint --init >/dev/null 2>&1

# Run TFLint recursively with all rules enabled
echo "Running TFLint recursively..."
tflint --recursive \
  -f compact \
  --ignore-module=helm-gatekeeper/policies \
  --ignore-module=helm-promtail/examples

echo "✅ TFLint full recursive check completed"
