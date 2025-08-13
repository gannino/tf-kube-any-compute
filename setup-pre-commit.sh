#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up pre-commit hooks...${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check Python availability
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${RED}❌ Error: Python is required but not installed${NC}"
    echo -e "${CYAN}Install Python 3.8+ and try again${NC}"
    exit 1
fi

# Install pre-commit if not already installed
if ! command -v pre-commit &> /dev/null; then
    echo -e "${YELLOW}Installing pre-commit...${NC}"

    # Try different installation methods
    if command -v pip3 &> /dev/null; then
        pip3 install --user pre-commit
    elif command -v pip &> /dev/null; then
        pip install --user pre-commit
    elif command -v brew &> /dev/null; then
        echo -e "${CYAN}Using Homebrew to install pre-commit...${NC}"
        brew install pre-commit
    else
        echo -e "${RED}❌ Error: Could not install pre-commit${NC}"
        echo -e "${CYAN}Please install pre-commit manually:${NC}"
        echo "  pip install pre-commit"
        echo "  # or"
        echo "  brew install pre-commit"
        exit 1
    fi

    # Verify installation
    if ! command -v pre-commit &> /dev/null; then
        echo -e "${RED}❌ Error: pre-commit installation failed${NC}"
        echo -e "${CYAN}You may need to add ~/.local/bin to your PATH${NC}"
        echo "  export PATH=\$HOME/.local/bin:\$PATH"
        exit 1
    fi
else
    echo -e "${GREEN}✅ pre-commit already installed${NC}"
fi

# Show pre-commit version
echo -e "${CYAN}Pre-commit version: $(pre-commit --version)${NC}"
echo ""

# Install the git hook scripts
echo -e "${BLUE}Installing git hooks...${NC}"
pre-commit install
pre-commit install --hook-type commit-msg

# Update hooks to latest versions
echo -e "${BLUE}Updating hooks to latest versions...${NC}"
pre-commit autoupdate

# Run against all files to test
echo ""
echo -e "${BLUE}🧪 Running pre-commit against all files...${NC}"
echo -e "${YELLOW}This may take a few minutes on first run...${NC}"

if pre-commit run --all-files; then
    echo ""
    echo -e "${GREEN}✅ Pre-commit hooks installed and tested successfully!${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️  Some pre-commit checks failed${NC}"
    echo -e "${CYAN}This is normal on first setup. The hooks will fix issues automatically.${NC}"
    echo -e "${CYAN}Run 'git add .' and 'git commit' to see the fixes applied.${NC}"
fi

echo ""
echo -e "${BLUE}📋 Usage:${NC}"
echo "  - Hooks will run automatically on git commit"
echo "  - Run manually: pre-commit run --all-files"
echo "  - Update hooks: pre-commit autoupdate"
echo "  - Skip hooks temporarily: git commit --no-verify"
echo ""
echo -e "${BLUE}🔧 Available Make commands:${NC}"
echo "  - make pre-commit-install  # Install hooks"
echo "  - make pre-commit-run      # Run all hooks"
echo "  - make test-safe          # Run safe tests"
echo "  - make test-lint          # Run linting only"
echo ""
echo -e "${GREEN}🎉 Setup complete! You're ready to contribute!${NC}"
