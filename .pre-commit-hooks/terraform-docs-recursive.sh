#!/bin/bash
# Terraform Docs Pre-commit Hook
# This script is a wrapper around the main terraform-docs automation

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the main terraform-docs automation in check mode
"${SCRIPT_DIR}/terraform-docs-automation.sh" check
