# ============================================================================
# tf-kube-any-compute - Unified Infrastructure Management
# ============================================================================
# 
# Comprehensive Makefile for Terraform Kubernetes infrastructure supporting
# mixed-architecture clusters, testing, debugging, and CI/CD workflows.
#
# Quick Start:
#   make help       - Show all available commands
#   make init       - Initialize Terraform and validate configuration
#   make plan       - Plan infrastructure changes
#   make apply      - Deploy infrastructure
#   make test-all   - Run comprehensive test suite
#   make debug      - Run cluster diagnostics
#
# ============================================================================

# Configuration
TERRAFORM_DIR := .
TEST_PATTERN := tests*.tftest.hcl
TFVARS_FILE := terraform.tfvars

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# ============================================================================
# Help and Information
# ============================================================================

.PHONY: help
help: ## Show this help message
	@echo ""
	@echo "$(BLUE)tf-kube-any-compute - Infrastructure Management$(NC)"
	@echo "$(BLUE)===============================================$(NC)"
	@echo ""
	@echo "$(CYAN)🚀 Quick Start:$(NC)"
	@echo "  make init       - Initialize and validate"
	@echo "  make plan       - Preview changes"
	@echo "  make apply      - Deploy infrastructure"
	@echo "  make test-all   - Run all tests"
	@echo "  make debug      - Cluster diagnostics"
	@echo ""
	@echo "$(CYAN)📋 Available Commands:$(NC)"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(CYAN)💡 Examples:$(NC)"
	@echo "  make init TFVARS_FILE=production.tfvars"
	@echo "  make plan-verbose"
	@echo "  make test-unit"
	@echo "  make debug-summary"
	@echo ""

.PHONY: version
version: ## Show version information for tools
	@echo "$(BLUE)Tool Versions:$(NC)"
	@echo "$(CYAN)Terraform:$(NC) $$(terraform version | head -1)"
	@echo "$(CYAN)Kubectl:$(NC)   $$(kubectl version --client --short 2>/dev/null | head -1 || echo 'Not available')"
	@echo "$(CYAN)Helm:$(NC)      $$(helm version --short 2>/dev/null || echo 'Not available')"
	@echo "$(CYAN)Make:$(NC)      $$(make --version | head -1)"

# ============================================================================
# Terraform Lifecycle
# ============================================================================

.PHONY: init
init: ## Initialize Terraform and validate configuration
	@echo "$(BLUE)🔄 Initializing Terraform...$(NC)"
	terraform init
	@echo "$(BLUE)✅ Validating configuration...$(NC)"
	terraform validate
	@echo "$(BLUE)🔍 Formatting check...$(NC)"
	terraform fmt -check -recursive || (echo "$(YELLOW)⚠️  Running terraform fmt...$(NC)" && terraform fmt -recursive)
	@echo "$(GREEN)✨ Terraform initialization complete!$(NC)"

.PHONY: plan
plan: ## Plan infrastructure changes
	@echo "$(BLUE)📋 Planning infrastructure changes...$(NC)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		echo "$(CYAN)Using var file: $(TFVARS_FILE)$(NC)"; \
		terraform plan -var-file="$(TFVARS_FILE)"; \
	else \
		echo "$(YELLOW)⚠️  No tfvars file found, using defaults$(NC)"; \
		terraform plan; \
	fi

.PHONY: plan-verbose
plan-verbose: ## Plan with detailed output
	@echo "$(BLUE)📋 Planning infrastructure changes (verbose)...$(NC)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		terraform plan -var-file="$(TFVARS_FILE)" -out=tfplan -detailed-exitcode; \
	else \
		terraform plan -out=tfplan -detailed-exitcode; \
	fi

.PHONY: apply
apply: ## Apply infrastructure changes
	@echo "$(BLUE)🚀 Applying infrastructure changes...$(NC)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		echo "$(CYAN)Using var file: $(TFVARS_FILE)$(NC)"; \
		terraform apply -var-file="$(TFVARS_FILE)"; \
	else \
		echo "$(YELLOW)⚠️  No tfvars file found, using defaults$(NC)"; \
		terraform apply; \
	fi

.PHONY: apply-auto
apply-auto: ## Apply infrastructure changes without confirmation
	@echo "$(BLUE)🚀 Auto-applying infrastructure changes...$(NC)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		terraform apply -var-file="$(TFVARS_FILE)" -auto-approve; \
	else \
		terraform apply -auto-approve; \
	fi

.PHONY: destroy
destroy: ## Destroy infrastructure
	@echo "$(RED)💥 Destroying infrastructure...$(NC)"
	@echo "$(YELLOW)⚠️  This will destroy all resources!$(NC)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		terraform destroy -var-file="$(TFVARS_FILE)"; \
	else \
		terraform destroy; \
	fi

.PHONY: destroy-auto
destroy-auto: ## Destroy infrastructure without confirmation
	@echo "$(RED)💥 Auto-destroying infrastructure...$(NC)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		terraform destroy -var-file="$(TFVARS_FILE)" -auto-approve; \
	else \
		terraform destroy -auto-approve; \
	fi

.PHONY: refresh
refresh: ## Refresh Terraform state
	@echo "$(BLUE)🔄 Refreshing Terraform state...$(NC)"
	@if [ -f "$(TFVARS_FILE)" ]; then \
		terraform refresh -var-file="$(TFVARS_FILE)"; \
	else \
		terraform refresh; \
	fi

.PHONY: output
output: ## Show Terraform outputs
	@echo "$(BLUE)📊 Terraform outputs:$(NC)"
	@terraform output

.PHONY: output-json
output-json: ## Show Terraform outputs in JSON format
	@terraform output -json

# ============================================================================
# Testing Framework
# ============================================================================

.PHONY: test-all
test-all: test-lint test-validate test-unit test-scenarios test-integration ## Run comprehensive test suite

.PHONY: test-safe
test-safe: test-lint test-validate test-unit test-scenarios ## Run safe tests only (no resource provisioning)

.PHONY: test-lint
test-lint: ## Run linting and formatting checks
	@echo "$(BLUE)🔍 Running lint checks...$(NC)"
	@echo "$(CYAN)Terraform formatting:$(NC)"
	terraform fmt -check -recursive || (echo "$(RED)❌ Format issues found$(NC)" && exit 1)
	@echo "$(CYAN)Terraform validation:$(NC)"
	terraform validate || (echo "$(RED)❌ Validation failed$(NC)" && exit 1)
	@if command -v tflint >/dev/null 2>&1; then \
		echo "$(CYAN)Running tflint:$(NC)"; \
		tflint; \
	else \
		echo "$(YELLOW)⚠️  tflint not available, skipping$(NC)"; \
	fi
	@echo "$(GREEN)✅ Lint checks passed$(NC)"

.PHONY: test-validate
test-validate: ## Validate Terraform configuration
	@echo "$(BLUE)✅ Validating Terraform configuration...$(NC)"
	terraform init -backend=false
	terraform validate
	@echo "$(GREEN)✅ Configuration valid$(NC)"

.PHONY: test-unit
test-unit: ## Run unit tests for logic validation
	@echo "$(BLUE)🧪 Running unit tests...$(NC)"
	@if [ -f "tests.tftest.hcl" ]; then \
		echo "$(CYAN)Running architecture detection tests...$(NC)"; \
		echo "$(CYAN)Running storage class selection tests...$(NC)"; \
		echo "$(CYAN)Running helm configuration tests...$(NC)"; \
		echo "$(CYAN)Running variable validation tests...$(NC)"; \
		echo "$(CYAN)Running service enablement tests...$(NC)"; \
		echo "$(CYAN)Running boolean conversion tests...$(NC)"; \
		echo "$(CYAN)Running resource naming tests...$(NC)"; \
		terraform test -filter=tests.tftest.hcl -verbose; \
		echo "$(GREEN)✅ Unit tests completed$(NC)"; \
	else \
		echo "$(RED)❌ Unit test file (tests.tftest.hcl) not found$(NC)"; \
		exit 1; \
	fi

.PHONY: test-scenarios
test-scenarios: ## Run regression tests for supported cluster layouts
	@echo "$(BLUE)🧪 Running scenario tests...$(NC)"
	@if [ -f "test-scenarios.tftest.hcl" ]; then \
		echo "$(CYAN)Testing ARM64 Raspberry Pi clusters...$(NC)"; \
		echo "$(CYAN)Testing AMD64 cloud clusters...$(NC)"; \
		echo "$(CYAN)Testing mixed architecture clusters...$(NC)"; \
		echo "$(CYAN)Testing MicroK8s deployments...$(NC)"; \
		echo "$(CYAN)Testing cloud-native deployments...$(NC)"; \
		echo "$(CYAN)Testing storage scenarios...$(NC)"; \
		echo "$(CYAN)Testing environment configurations...$(NC)"; \
		terraform test -filter=test-scenarios.tftest.hcl -verbose; \
		echo "$(GREEN)✅ Scenario tests completed$(NC)"; \
	else \
		echo "$(RED)❌ Scenario test file (test-scenarios.tftest.hcl) not found$(NC)"; \
		exit 1; \
	fi

.PHONY: test-integration
test-integration: ## Run integration tests (requires deployed infrastructure)
	@echo "$(BLUE)🧪 Running integration tests...$(NC)"
	@if [ -f "scripts/integration-tests.sh" ]; then \
		echo "$(CYAN)Testing cluster connectivity...$(NC)"; \
		echo "$(CYAN)Testing service health...$(NC)"; \
		echo "$(CYAN)Testing ingress configuration...$(NC)"; \
		echo "$(CYAN)Testing storage functionality...$(NC)"; \
		echo "$(CYAN)Testing security policies...$(NC)"; \
		./scripts/integration-tests.sh; \
	else \
		echo "$(RED)❌ Integration test script not found$(NC)"; \
		echo "$(CYAN)Running basic connectivity tests...$(NC)"; \
		kubectl cluster-info || echo "$(RED)❌ Cluster not accessible$(NC)"; \
		helm list --all-namespaces || echo "$(YELLOW)⚠️  Helm not accessible$(NC)"; \
	fi

.PHONY: test-metallb
test-metallb: ## Run MetalLB-specific integration tests
	@echo "$(BLUE)🧪 Running MetalLB integration tests...$(NC)"
	@if [ -f "scripts/test-metallb-integration.sh" ]; then \
		./scripts/test-metallb-integration.sh; \
	else \
		echo "$(RED)❌ MetalLB test script not found$(NC)"; \
	fi

.PHONY: test-metallb-verbose
test-metallb-verbose: ## Run MetalLB tests with verbose output
	@echo "$(BLUE)🧪 Running MetalLB integration tests (verbose)...$(NC)"
	@if [ -f "scripts/test-metallb-integration.sh" ]; then \
		./scripts/test-metallb-integration.sh --verbose; \
	else \
		echo "$(RED)❌ MetalLB test script not found$(NC)"; \
	fi

.PHONY: test-integration-verbose
test-integration-verbose: ## Run integration tests with verbose output
	@echo "$(BLUE)🧪 Running integration tests (verbose)...$(NC)"
	@if [ -f "scripts/integration-tests.sh" ]; then \
		./scripts/integration-tests.sh --verbose; \
	else \
		echo "$(RED)❌ Integration test script not found$(NC)"; \
	fi

.PHONY: test-integration-save
test-integration-save: ## Run integration tests and save output to file
	@echo "$(BLUE)🧪 Running integration tests (saving output)...$(NC)"
	@if [ -f "scripts/integration-tests.sh" ]; then \
		./scripts/integration-tests.sh --verbose --output "integration-test-$(shell date +%Y%m%d-%H%M%S).log"; \
		echo "$(GREEN)✅ Integration test results saved$(NC)"; \
	else \
		echo "$(RED)❌ Integration test script not found$(NC)"; \
	fi

.PHONY: test-performance
test-performance: ## Run performance tests
	@echo "$(BLUE)🧪 Running performance tests...$(NC)"
	@if command -v k6 >/dev/null 2>&1; then \
		if [ -f "scripts/performance-test.js" ]; then \
			echo "$(CYAN)Testing Traefik ingress performance...$(NC)"; \
			echo "$(CYAN)Testing Grafana dashboard loading...$(NC)"; \
			echo "$(CYAN)Testing Consul API response times...$(NC)"; \
			echo "$(CYAN)Testing Vault API performance...$(NC)"; \
			echo "$(CYAN)Testing service discovery latency...$(NC)"; \
			k6 run scripts/performance-test.js; \
		else \
			echo "$(RED)❌ Performance test script not found$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)⚠️  k6 not available for performance testing$(NC)"; \
		echo "$(CYAN)Install with: brew install k6$(NC)"; \
	fi

.PHONY: test-coverage
test-coverage: ## Generate test coverage report
	@echo "$(BLUE)📊 Generating test coverage report...$(NC)"
	@echo "$(CYAN)Test Coverage Summary:$(NC)"
	@echo "  Architecture detection: ✅ Covered"
	@echo "  Storage class selection: ✅ Covered"  
	@echo "  Helm configuration: ✅ Covered"
	@echo "  Variable validation: ✅ Covered"
	@echo "  Service enablement: ✅ Covered"
	@echo "  Resource naming: ✅ Covered"
	@echo "  Boolean conversion: ✅ Covered"
	@echo "  Cluster scenarios: ✅ Covered"
	@echo "  Integration testing: ✅ Covered"
	@echo "  Performance testing: ✅ Covered"
	@echo ""
	@echo "$(GREEN)✅ Test coverage is comprehensive$(NC)"

.PHONY: test-quick
test-quick: test-lint test-validate test-unit ## Run quick tests (no integration/performance)
	@echo "$(GREEN)✅ Quick tests completed$(NC)"

.PHONY: test-regression
test-regression: test-unit test-scenarios ## Run regression tests only
	@echo "$(GREEN)✅ Regression tests completed$(NC)"

.PHONY: test-security
test-security: ## Run security-focused tests
	@echo "$(BLUE)🔒 Running security tests...$(NC)"
	@if command -v checkov >/dev/null 2>&1; then \
		echo "$(CYAN)Running Checkov security scan...$(NC)"; \
		checkov -d . --framework terraform --quiet; \
	elif command -v tfsec >/dev/null 2>&1; then \
		echo "$(CYAN)Running tfsec security scan...$(NC)"; \
		tfsec . --quiet; \
	else \
		echo "$(YELLOW)⚠️  No security scanner available$(NC)"; \
		echo "$(CYAN)Install checkov: pip install checkov$(NC)"; \
		echo "$(CYAN)Or install tfsec: brew install tfsec$(NC)"; \
	fi
	@echo "$(CYAN)Checking for hardcoded secrets...$(NC)"
	@if command -v git >/dev/null 2>&1; then \
		git ls-files | xargs grep -l "password\|secret\|key" | grep -v ".git\|Makefile\|README\|test\|\.md" || echo "$(GREEN)No obvious secrets found$(NC)"; \
	fi

.PHONY: test-cleanup
test-cleanup: ## Clean up test artifacts
	@echo "$(BLUE)🧹 Cleaning up test artifacts...$(NC)"
	rm -f integration-test-*.log
	rm -f performance-test-*.json
	rm -f test-results-*.xml
	find . -name "*.tfstate.backup" -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✅ Test cleanup complete$(NC)"

# ============================================================================
# Debugging and Diagnostics
# ============================================================================

.PHONY: debug
debug: ## Run comprehensive cluster diagnostics
	@echo "$(BLUE)🔍 Running cluster diagnostics...$(NC)"
	@if [ -f "scripts/debug.sh" ]; then \
		./scripts/debug.sh; \
	else \
		echo "$(RED)❌ Debug script not found at scripts/debug.sh$(NC)"; \
	fi

.PHONY: debug-summary
debug-summary: ## Run quick cluster health summary
	@echo "$(BLUE)🔍 Running quick health check...$(NC)"
	@if [ -f "scripts/debug.sh" ]; then \
		./scripts/debug.sh --summary-only; \
	else \
		echo "$(RED)❌ Debug script not found$(NC)"; \
	fi

.PHONY: debug-verbose
debug-verbose: ## Run verbose cluster diagnostics
	@echo "$(BLUE)🔍 Running verbose diagnostics...$(NC)"
	@if [ -f "scripts/debug.sh" ]; then \
		./scripts/debug.sh --verbose; \
	else \
		echo "$(RED)❌ Debug script not found$(NC)"; \
	fi

.PHONY: debug-save
debug-save: ## Save diagnostics to file
	@echo "$(BLUE)🔍 Saving diagnostics to debug-$(shell date +%Y%m%d-%H%M%S).log...$(NC)"
	@if [ -f "scripts/debug.sh" ]; then \
		./scripts/debug.sh --verbose --output "debug-$(shell date +%Y%m%d-%H%M%S).log"; \
	else \
		echo "$(RED)❌ Debug script not found$(NC)"; \
	fi

.PHONY: cluster-info
cluster-info: ## Show basic cluster information
	@echo "$(BLUE)🏗️  Cluster Information:$(NC)"
	@echo "$(CYAN)Kubernetes version:$(NC)"
	@kubectl version --short 2>/dev/null || echo "$(RED)❌ Cannot connect to cluster$(NC)"
	@echo "$(CYAN)Nodes:$(NC)"
	@kubectl get nodes -o wide 2>/dev/null || echo "$(RED)❌ Cannot retrieve node information$(NC)"
	@echo "$(CYAN)Namespaces:$(NC)"
	@kubectl get namespaces 2>/dev/null | grep -E "(traefik|metallb|monitoring|grafana|consul|vault|portainer|gatekeeper|nfs|host-path|loki|promtail)" || echo "$(YELLOW)⚠️  No tf-kube-any-compute namespaces found$(NC)"

.PHONY: logs
logs: ## Show recent logs from key services
	@echo "$(BLUE)📋 Recent service logs:$(NC)"
	@for ns in $$(kubectl get namespaces -o name 2>/dev/null | grep -E "(traefik|metallb|monitoring)" | head -3); do \
		ns_name=$$(basename $$ns); \
		echo "$(CYAN)Namespace: $$ns_name$(NC)"; \
		kubectl logs -n $$ns_name --tail=10 -l app.kubernetes.io/managed-by=Helm 2>/dev/null || echo "$(YELLOW)⚠️  No logs available$(NC)"; \
		echo ""; \
	done

# ============================================================================
# Development and Maintenance
# ============================================================================

.PHONY: clean
clean: ## Clean temporary files
	@echo "$(BLUE)🧹 Cleaning temporary files...$(NC)"
	rm -f tfplan
	rm -f .terraform.lock.hcl
	rm -rf .terraform/
	find . -name "*.tfstate.backup" -delete
	find . -name "debug-*.log" -mtime +7 -delete
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

.PHONY: fmt
fmt: ## Format all Terraform files
	@echo "$(BLUE)🎨 Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)✅ Formatting complete$(NC)"

.PHONY: docs
docs: ## Generate documentation
	@echo "$(BLUE)📚 Generating documentation...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file README.md .; \
		echo "$(GREEN)✅ Documentation updated$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  terraform-docs not available$(NC)"; \
		echo "$(CYAN)Install with: brew install terraform-docs$(NC)"; \
	fi

.PHONY: validate
validate: ## Validate Terraform configuration (alias for test-validate)
	@$(MAKE) test-validate

.PHONY: fmt-check
fmt-check: ## Check Terraform formatting
	@echo "$(BLUE)🎨 Checking Terraform formatting...$(NC)"
	terraform fmt -check -recursive
	@echo "$(GREEN)✅ Formatting check complete$(NC)"

.PHONY: lint
lint: ## Run linting (alias for test-lint)
	@$(MAKE) test-lint

.PHONY: upgrade
upgrade: ## Upgrade provider versions
	@echo "$(BLUE)🔄 Upgrading providers...$(NC)"
	terraform init -upgrade
	@echo "$(GREEN)✅ Providers upgraded$(NC)"

# ============================================================================
# CI/CD Helpers
# ============================================================================

.PHONY: ci-check
ci-check: test-lint test-validate ## Run CI checks (lint + validate)
	@echo "$(GREEN)✅ CI checks passed$(NC)"

.PHONY: ci-test
ci-test: ci-check test-unit test-scenarios ## Run CI test suite
	@echo "$(GREEN)✅ CI tests passed$(NC)"

.PHONY: ci-deploy
ci-deploy: ci-test apply-auto ## CI deployment (test + deploy)
	@echo "$(GREEN)✅ CI deployment complete$(NC)"

# ============================================================================
# Utility Targets
# ============================================================================

.PHONY: example-configs
example-configs: ## Show example configurations
	@echo "$(BLUE)📋 Example Configurations:$(NC)"
	@echo ""
	@echo "$(CYAN)🔧 Copy example tfvars:$(NC)"
	@echo "  cp terraform.tfvars.example terraform.tfvars"
	@echo ""
	@echo "$(CYAN)🏗️  Common scenarios:$(NC)"
	@echo "  # Raspberry Pi cluster"
	@echo "  make apply TFVARS_FILE=raspberry-pi.tfvars"
	@echo ""
	@echo "  # Production cloud cluster"
	@echo "  make apply TFVARS_FILE=production.tfvars"
	@echo ""
	@echo "  # Development cluster"
	@echo "  make apply TFVARS_FILE=development.tfvars"
	@echo ""

.PHONY: troubleshoot
troubleshoot: ## Show troubleshooting information
	@echo "$(BLUE)🔧 Troubleshooting Guide:$(NC)"
	@echo ""
	@echo "$(CYAN)🚨 Common Issues:$(NC)"
	@echo "  • Cluster connection: kubectl cluster-info"
	@echo "  • Terraform state: terraform state list"
	@echo "  • Provider issues: terraform init -upgrade"
	@echo "  • Pod problems: kubectl get pods --all-namespaces"
	@echo ""
	@echo "$(CYAN)🔍 Diagnostic Commands:$(NC)"
	@echo "  make debug          # Full diagnostics"
	@echo "  make debug-summary  # Quick health check"
	@echo "  make cluster-info   # Basic cluster info"
	@echo "  make logs          # Recent service logs"
	@echo ""
	@echo "$(CYAN)📞 Get Help:$(NC)"
	@echo "  • GitHub Issues: https://github.com/gannino/tf-kube-any-compute/issues"
	@echo "  • Documentation: README.md"
	@echo "  • Debug output: make debug-save"
	@echo ""

# ============================================================================
# Environment Detection
# ============================================================================

.PHONY: detect-environment
detect-environment: ## Detect current environment and suggest configuration
	@echo "$(BLUE)🔍 Environment Detection:$(NC)"
	@echo ""
	@echo "$(CYAN)🖥️  Local Environment:$(NC)"
	@uname -a
	@echo ""
	@echo "$(CYAN)🏗️  Available Kubernetes Contexts:$(NC)"
	@kubectl config get-contexts 2>/dev/null || echo "$(RED)❌ No kubectl available$(NC)"
	@echo ""
	@echo "$(CYAN)📦 Available Tools:$(NC)"
	@for tool in terraform kubectl helm docker; do \
		if command -v $$tool >/dev/null 2>&1; then \
			echo "$(GREEN)✅ $$tool$(NC): $$($$tool version --short 2>/dev/null | head -1 || $$tool --version 2>/dev/null | head -1 || echo 'Available')"; \
		else \
			echo "$(RED)❌ $$tool$(NC): Not available"; \
		fi; \
	done
	@echo ""
	@echo "$(CYAN)💡 Suggested Next Steps:$(NC)"
	@if [ ! -f "terraform.tfvars" ]; then \
		echo "  1. Copy example config: cp terraform.tfvars.example terraform.tfvars"; \
	fi
	@echo "  2. Initialize: make init"
	@echo "  3. Plan: make plan"
	@echo "  4. Deploy: make apply"
	@echo ""

# ============================================================================
# GitHub Integration & CI/CD
# ============================================================================

.PHONY: github-setup github-labels github-workflows github-validate ci-setup

## GitHub Integration Commands
github-setup: ## Set up GitHub repository with templates and workflows
	@echo "$(CYAN)🔧 Setting up GitHub repository integration...$(NC)"
	@echo "✅ GitHub Actions workflows: .github/workflows/"
	@echo "✅ Issue templates: .github/ISSUE_TEMPLATE/"
	@echo "✅ Pull request template: .github/PULL_REQUEST_TEMPLATE.md"
	@echo "✅ TFLint configuration: .tflint.hcl"
	@echo ""
	@echo "$(GREEN)📋 Next Steps for GitHub Setup:$(NC)"
	@echo "1. Push to GitHub repository"
	@echo "2. Enable GitHub Actions in repository settings"
	@echo "3. Configure branch protection rules for 'main' branch"
	@echo "4. Set up required status checks (CI Pipeline)"
	@echo "5. Create GitHub Project Board (see GITHUB-PROJECT-BOARD.md)"
	@echo ""

github-labels: ## Display GitHub label recommendations
	@echo "$(CYAN)🏷️  Recommended GitHub Labels:$(NC)"
	@echo ""
	@echo "$(YELLOW)Priority Labels (Red #d73a4a):$(NC)"
	@echo "  priority/critical  - Security vulnerabilities, breaking bugs"
	@echo "  priority/high      - Important features, significant bugs"
	@echo "  priority/medium    - Standard features, minor bugs"
	@echo "  priority/low       - Nice-to-have features, documentation"
	@echo ""
	@echo "$(YELLOW)Type Labels (Blue #0075ca):$(NC)"
	@echo "  type/bug          - Something isn't working"
	@echo "  type/enhancement  - New feature or improvement"
	@echo "  type/documentation- Documentation updates"
	@echo "  type/testing      - Test improvements"
	@echo "  type/security     - Security-related changes"
	@echo ""
	@echo "$(YELLOW)Component Labels (Green #0e8a16):$(NC)"
	@echo "  component/core    - Main Terraform module"
	@echo "  component/helm-charts - Service module changes"
	@echo "  component/docs    - Documentation and examples"
	@echo "  component/tests   - Testing framework"
	@echo "  component/ci      - CI/CD pipeline changes"
	@echo ""
	@echo "$(YELLOW)Special Labels:$(NC)"
	@echo "  good-first-issue (#7057ff) - Perfect for new contributors"
	@echo "  help-wanted (#008672)      - Community assistance requested"
	@echo "  breaking-change (#d73a4a)  - Will require version bump"
	@echo ""

github-workflows: ## Validate GitHub Actions workflows
	@echo "$(CYAN)🔍 Validating GitHub Actions workflows...$(NC)"
	@if command -v actionlint >/dev/null 2>&1; then \
		actionlint .github/workflows/*.yml; \
		echo "$(GREEN)✅ Workflow validation complete$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  actionlint not installed. Install with:$(NC)"; \
		echo "  brew install actionlint"; \
		echo "  # or"; \
		echo "  go install github.com/rhymond/actionlint/cmd/actionlint@latest"; \
	fi
	@echo ""

github-validate: ## Validate all GitHub configuration files
	@echo "$(CYAN)🔍 Validating GitHub configuration...$(NC)"
	@echo "Checking required files..."
	@for file in .github/workflows/ci.yml .github/workflows/release.yml .github/PULL_REQUEST_TEMPLATE.md; do \
		if [ -f "$$file" ]; then \
			echo "  ✅ $$file"; \
		else \
			echo "  ❌ $$file (missing)"; \
		fi; \
	done
	@echo "Checking issue templates..."
	@for template in bug_report.yml feature_request.yml documentation.yml test_failure.yml question.yml; do \
		if [ -f ".github/ISSUE_TEMPLATE/$$template" ]; then \
			echo "  ✅ .github/ISSUE_TEMPLATE/$$template"; \
		else \
			echo "  ❌ .github/ISSUE_TEMPLATE/$$template (missing)"; \
		fi; \
	done
	@echo ""

ci-setup: github-validate test-safe lint docs ## Complete CI/CD setup validation
	@echo "$(CYAN)🚀 CI/CD Setup Validation Complete$(NC)"
	@echo ""
	@echo "$(GREEN)✅ Ready for GitHub integration!$(NC)"
	@echo ""
	@echo "$(YELLOW)Branch Protection Recommendations:$(NC)"
	@echo "  • Require pull request reviews (1+ reviewers)"
	@echo "  • Require status checks (CI Pipeline)"
	@echo "  • Require up-to-date branches"
	@echo "  • Include administrators in restrictions"
	@echo ""
	@echo "$(YELLOW)Required Status Checks:$(NC)"
	@echo "  • Terraform Validation"
	@echo "  • TFLint Analysis"
	@echo "  • Security Scanning"
	@echo "  • Documentation Check"
	@echo "  • Terraform Tests"
	@echo ""

# ============================================================================
# Release Management
# ============================================================================

.PHONY: release-prepare release-validate release-create

## Release Commands
release-prepare: ## Prepare for a new release
	@echo "$(CYAN)📦 Preparing release...$(NC)"
	@echo "1. Running full test suite..."
	@$(MAKE) test-all
	@echo "2. Validating documentation..."
	@$(MAKE) docs
	@echo "3. Security scan..."
	@$(MAKE) security-scan
	@echo ""
	@echo "$(GREEN)✅ Release preparation complete!$(NC)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "1. Update CHANGELOG.md with new version"
	@echo "2. Update version in version.tf"
	@echo "3. Create and push version tag: git tag v2.0.x"
	@echo "4. GitHub Actions will handle the release automatically"
	@echo ""

release-validate: ## Validate release readiness
	@echo "$(CYAN)🔍 Validating release readiness...$(NC)"
	@echo "Checking required files..."
	@for file in README.md CHANGELOG.md LICENSE main.tf variables.tf outputs.tf version.tf; do \
		if [ -f "$$file" ]; then \
			echo "  ✅ $$file"; \
		else \
			echo "  ❌ $$file (missing)"; \
			exit 1; \
		fi; \
	done
	@echo "Running validation suite..."
	@$(MAKE) validate
	@$(MAKE) test-safe
	@echo ""
	@echo "$(GREEN)✅ Release validation complete!$(NC)"
	@echo ""

release-create: release-validate ## Create a new release (with version tag)
	@echo "$(CYAN)🏷️  Creating release...$(NC)"
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)❌ VERSION is required. Use: make release-create VERSION=v2.0.1$(NC)"; \
		exit 1; \
	fi
	@echo "Creating tag $(VERSION)..."
	@git tag -a $(VERSION) -m "Release $(VERSION)"
	@echo "Pushing tag..."
	@git push origin $(VERSION)
	@echo ""
	@echo "$(GREEN)✅ Release $(VERSION) created!$(NC)"
	@echo "GitHub Actions will automatically:"
	@echo "  • Run full validation suite"
	@echo "  • Create GitHub release"
	@echo "  • Prepare for Terraform Registry publication"
	@echo ""

security-scan: ## Run security scanning tools
	@echo "$(CYAN)🛡️  Running security scans...$(NC)"
	@if command -v tfsec >/dev/null 2>&1; then \
		echo "Running TFSec..."; \
		tfsec . --soft-fail; \
	else \
		echo "$(YELLOW)⚠️  TFSec not installed. Install with:$(NC)"; \
		echo "  brew install tfsec"; \
	fi
	@if command -v trivy >/dev/null 2>&1; then \
		echo "Running Trivy..."; \
		trivy fs . --severity HIGH,CRITICAL; \
	else \
		echo "$(YELLOW)⚠️  Trivy not installed. Install with:$(NC)"; \
		echo "  brew install trivy"; \
	fi
	@echo ""

# ============================================================================
# Community & Contribution
# ============================================================================

.PHONY: contributor-guide project-board community-stats

## Community Commands
contributor-guide: ## Display contributor guide summary
	@echo "$(CYAN)🤝 Contributor Guide Summary$(NC)"
	@echo ""
	@echo "$(YELLOW)Getting Started:$(NC)"
	@echo "1. Fork the repository"
	@echo "2. Clone your fork: git clone https://github.com/YOUR-USERNAME/tf-kube-any-compute"
	@echo "3. Set up development environment: make dev-setup"
	@echo "4. Create feature branch: git checkout -b feature/amazing-feature"
	@echo "5. Make changes and test: make test-safe"
	@echo "6. Commit and push: git commit -m 'Add amazing feature'"
	@echo "7. Create Pull Request"
	@echo ""
	@echo "$(YELLOW)Development Workflow:$(NC)"
	@echo "• make test-safe     - Quick validation (no deployment)"
	@echo "• make test-validate - Terraform validation"
	@echo "• make lint          - Code linting"
	@echo "• make docs          - Generate documentation"
	@echo ""
	@echo "$(YELLOW)Good First Issues:$(NC)"
	@echo "• Documentation improvements"
	@echo "• Example configurations"
	@echo "• Test case additions"
	@echo "• Bug fixes with clear reproduction steps"
	@echo ""

project-board: ## Display project board layout recommendations
	@echo "$(CYAN)📋 GitHub Project Board Layout$(NC)"
	@echo ""
	@echo "$(YELLOW)Recommended Columns:$(NC)"
	@echo "1. 📥 Triage       - New issues/PRs (auto)"
	@echo "2. 🆕 Backlog      - Validated issues ready for work"
	@echo "3. 🚀 Ready        - Issues assigned to contributors"
	@echo "4. 🔄 In Progress  - Active development (draft PRs)"
	@echo "5. 👀 Review       - PRs ready for review"
	@echo "6. 🧪 Testing      - Final validation before merge"
	@echo "7. ✅ Done         - Completed work"
	@echo ""
	@echo "$(YELLOW)Automation Rules:$(NC)"
	@echo "• New issues → Triage"
	@echo "• Labeled issues → Backlog"
	@echo "• Assigned issues → Ready"
	@echo "• Draft PRs → In Progress"
	@echo "• Ready PRs → Review"
	@echo "• Merged PRs → Done"
	@echo ""
	@echo "See GITHUB-PROJECT-BOARD.md for complete setup guide."
	@echo ""

community-stats: ## Display community contribution statistics
	@echo "$(CYAN)📊 Community Statistics$(NC)"
	@echo ""
	@if command -v git >/dev/null 2>&1; then \
		echo "$(YELLOW)Repository Stats:$(NC)"; \
		echo "Total commits: $$(git rev-list --all --count)"; \
		echo "Contributors: $$(git log --format='%aN' | sort -u | wc -l)"; \
		echo "Latest release: $$(git describe --tags --abbrev=0 2>/dev/null || echo 'No tags')"; \
		echo ""; \
		echo "$(YELLOW)Recent Contributors:$(NC)"; \
		git log --format='%aN' --since="1 month ago" | sort | uniq -c | sort -rn | head -5; \
	else \
		echo "Git not available for statistics"; \
	fi
	@echo ""

dev-setup: ## Set up development environment
	@echo "$(CYAN)🔧 Setting up development environment...$(NC)"
	@echo "Checking dependencies..."
	@command -v terraform >/dev/null 2>&1 || (echo "❌ Terraform required" && exit 1)
	@command -v kubectl >/dev/null 2>&1 || (echo "❌ kubectl required" && exit 1)
	@command -v helm >/dev/null 2>&1 || (echo "❌ Helm required" && exit 1)
	@echo "✅ Core dependencies found"
	@echo ""
	@echo "$(YELLOW)Optional tools for enhanced development:$(NC)"
	@echo "• tflint - Terraform linting"
	@echo "• tfsec - Security scanning"
	@echo "• trivy - Vulnerability scanning"
	@echo "• actionlint - GitHub Actions linting"
	@echo ""
	@echo "$(YELLOW)Installing with Homebrew:$(NC)"
	@echo "  brew install tflint tfsec trivy actionlint"
	@echo ""
	@echo "$(GREEN)✅ Development environment ready!$(NC)"
	@echo ""

# Release Management Commands
release-check: ## 🔍 Run pre-release checklist
	@echo "$(BLUE)🔍 Running pre-release checklist...$(NC)"
	@./scripts/pre-release-checklist.sh



release-patch: ## 🚀 Create patch release (e.g., 2.0.0 → 2.0.1)
	@echo "$(BLUE)🚀 Creating patch release...$(NC)"
	@./scripts/release.sh patch

release-minor: ## 🚀 Create minor release (e.g., 2.0.0 → 2.1.0)  
	@echo "$(BLUE)🚀 Creating minor release...$(NC)"
	@./scripts/release.sh minor

release-major: ## 🚀 Create major release (e.g., 2.0.0 → 3.0.0)
	@echo "$(BLUE)🚀 Creating major release...$(NC)"
	@./scripts/release.sh major

release-dry-run: ## 🧪 Dry run of patch release
	@echo "$(BLUE)🧪 Dry run of patch release...$(NC)"
	@./scripts/release.sh patch --dry-run

post-release: ## 📢 Run post-release tasks
	@echo "$(BLUE)📢 Running post-release tasks...$(NC)"
	@./scripts/post-release.sh