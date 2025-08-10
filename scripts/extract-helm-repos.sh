#!/bin/bash

# extract-helm-repos.sh
# Dynamically extracts all Helm repository URLs from Terraform modules
# This ensures the setup script always has the most current repository list

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🔍 Extracting Helm repository information from Terraform modules...${NC}"

# Function to extract repositories from a directory
extract_repos_from_dir() {
    local dir="$1"
    local module_name="$(basename "$dir")"

    if [[ ! -d "$dir" ]]; then
        return 0
    fi

    echo -e "${YELLOW}📂 Checking module: $module_name${NC}"

    # Look for repository URLs in .tf files
    find "$dir" -name "*.tf" -type f | while read -r tf_file; do
        # Extract repository URLs using various patterns
        grep -E '(repository\s*=|helm_repository)' "$tf_file" 2>/dev/null | \
        grep -E 'https?://[^"]+' | \
        sed -E 's/.*"(https?:\/\/[^"]+)".*/\1/' | \
        sort -u | while read -r repo_url; do
            if [[ -n "$repo_url" && "$repo_url" =~ ^https?:// ]]; then
                # Try to determine repository name from URL
                local repo_name
                if [[ "$repo_url" =~ charts\.bitnami\.com ]]; then
                    repo_name="bitnami"
                elif [[ "$repo_url" =~ prometheus-community\.github\.io ]]; then
                    repo_name="prometheus-community"
                elif [[ "$repo_url" =~ grafana\.github\.io ]]; then
                    repo_name="grafana"
                elif [[ "$repo_url" =~ traefik\.github\.io ]]; then
                    repo_name="traefik"
                elif [[ "$repo_url" =~ metallb\.github\.io ]]; then
                    repo_name="metallb"
                elif [[ "$repo_url" =~ kubernetes-sigs\.github\.io ]]; then
                    repo_name="nfs-csi"
                elif [[ "$repo_url" =~ kubernetes\.github\.io ]]; then
                    repo_name="kubernetes"
                elif [[ "$repo_url" =~ hashicorp\.github\.io ]]; then
                    repo_name="hashicorp"
                elif [[ "$repo_url" =~ open-policy-agent\.github\.io ]]; then
                    repo_name="gatekeeper"
                else
                    # Extract name from URL path
                    repo_name=$(echo "$repo_url" | sed -E 's|https?:\/\/([^/]+).*|\1|' | sed 's/\./-/g')
                fi

                echo -e "${GREEN}  ✓ Found: $repo_name -> $repo_url${NC}"
                echo "$repo_name|$repo_url"
            fi
        done
    done
}

# Create temporary file for collecting repositories
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

echo -e "${BLUE}📋 Scanning all Helm modules...${NC}"

# Extract from main directory
extract_repos_from_dir "$PROJECT_ROOT" >> "$temp_file"

# Extract from all helm-* subdirectories
find "$PROJECT_ROOT" -type d -name "helm-*" | while read -r helm_dir; do
    extract_repos_from_dir "$helm_dir" >> "$temp_file"
done

# Remove duplicates and sort
if [[ -s "$temp_file" ]]; then
    echo -e "\n${GREEN}📊 Summary of discovered repositories:${NC}"
    sort -u "$temp_file" | while IFS='|' read -r name url; do
        echo -e "${GREEN}  • $name${NC}: $url"
    done

    echo -e "\n${BLUE}📝 Generating repository array for setup script...${NC}"
    echo "# Auto-generated repository list from Terraform modules"
    echo "declare -A HELM_REPOSITORIES=("
    sort -u "$temp_file" | while IFS='|' read -r name url; do
        echo "    [\"$name\"]=\"$url\""
    done
    echo ")"
else
    echo -e "${YELLOW}⚠️  No Helm repositories found in Terraform modules${NC}"
fi

echo -e "\n${GREEN}✅ Repository extraction complete!${NC}"
