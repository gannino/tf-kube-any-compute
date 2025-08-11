#!/bin/bash
set -e

echo "🔧 Setting up pre-commit hooks..."

# Install pre-commit if not already installed
if ! command -v pre-commit &> /dev/null; then
    echo "Installing pre-commit..."
    pip install pre-commit
fi

# Install the git hook scripts
pre-commit install

# Run against all files to test
echo "🧪 Running pre-commit against all files..."
pre-commit run --all-files

echo "✅ Pre-commit hooks installed successfully!"
echo ""
echo "📋 Usage:"
echo "  - Hooks will run automatically on git commit"
echo "  - Run manually: pre-commit run --all-files"
echo "  - Update hooks: pre-commit autoupdate"
