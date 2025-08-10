#!/bin/bash
# Run Terraform plan/tests in a dedicated CI workspace, mimicking CI environment
set -e

export TF_WORKSPACE=ci
export TF_VAR_ci_mode=true

# Initialize Terraform and select/create the CI workspace
echo "[test-ci] Initializing Terraform..."
terraform init -backend=false
terraform workspace select ci || terraform workspace new ci

# Run Terraform plan with detailed exit code (like CI)
echo "[test-ci] Running terraform plan..."
terraform plan -detailed-exitcode -out=tfplan

# Optionally, run other tests (lint, validate, etc.)
echo "[test-ci] Running terraform validate..."
terraform validate

echo "[test-ci] Running tflint..."
tflint --call-module-type=all

echo "[test-ci] CI test complete. Review output above."
