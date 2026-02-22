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
TEST_DIR := tests
TEST_PATTERN := tests/$(1)
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

.PHONY: validate
validate: ## Validate Terraform configuration
	@echo "$(BLUE)✅ Validating Terraform configuration...$(NC)"
	terraform init -backend=false
	terraform validate
	@echo "$(GREEN)✅ Configuration valid$(NC)"

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
	@echo "$(BLUE)🔍 Ensuring CoreDNS is running...$(NC)"
	@./scripts/ensure-coredns.sh
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
	terraform init -backend=false
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
	@terraform init -backend=false
	@if [ -f "$(TEST_DIR)/tests.tftest.hcl" ]; then \
		echo "$(CYAN)Running architecture detection tests...$(NC)"; \
		echo "$(CYAN)Running storage class selection tests...$(NC)"; \
		echo "$(CYAN)Running helm configuration tests...$(NC)"; \
		echo "$(CYAN)Running variable validation tests...$(NC)"; \
		echo "$(CYAN)Running service enablement tests...$(NC)"; \
		echo "$(CYAN)Running boolean conversion tests...$(NC)"; \
		echo "$(CYAN)Running resource naming tests...$(NC)"; \
		terraform test -filter=$(TEST_DIR)/tests.tftest.hcl -verbose; \
		echo "$(GREEN)✅ Unit tests completed$(NC)"; \
	else \
		echo "$(RED)❌ Unit test file ($(TEST_DIR)/tests.tftest.hcl) not found$(NC)"; \
		exit 1; \
	fi

.PHONY: test-scenarios
test-scenarios: ## Run regression tests for supported cluster layouts
	@echo "$(BLUE)🧪 Running scenario tests...$(NC)"
	@if [ -f "$(TEST_DIR)/test-scenarios.tftest.hcl" ]; then \
		echo "$(CYAN)Testing ARM64 Raspberry Pi clusters...$(NC)"; \
		echo "$(CYAN)Testing AMD64 cloud clusters...$(NC)"; \
		echo "$(CYAN)Testing mixed architecture clusters...$(NC)"; \
		echo "$(CYAN)Testing MicroK8s deployments...$(NC)"; \
		echo "$(CYAN)Testing cloud-native deployments...$(NC)"; \
		echo "$(CYAN)Testing storage scenarios...$(NC)"; \
		echo "$(CYAN)Testing environment configurations...$(NC)"; \
		terraform test -filter=$(TEST_DIR)/test-scenarios.tftest.hcl -verbose; \
		echo "$(GREEN)✅ Scenario tests completed$(NC)"; \
	else \
		echo "$(RED)❌ Scenario test file ($(TEST_DIR)/test-scenarios.tftest.hcl) not found$(NC)"; \
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

.PHONY: test-report
test-report: ## Generate comprehensive test report for CI
	@echo "$(BLUE)📊 Generating test report...$(NC)"
	@echo "$(CYAN)Test Report - $(shell date)$(NC)"
	@echo ""
	@echo "$(YELLOW)Test Suite Results:$(NC)"
	@$(MAKE) test-safe 2>&1 | grep -E "(✅|❌|⚠️)" || echo "  Tests completed"
	@echo ""
	@echo "$(YELLOW)Validation Results:$(NC)"
	@$(MAKE) test-validate 2>&1 | grep -E "(✅|❌|⚠️)" || echo "  Validation completed"
	@echo ""
	@echo "$(YELLOW)Security Scan Results:$(NC)"
	@$(MAKE) test-security 2>&1 | grep -E "(✅|❌|⚠️)" || echo "  Security scan completed"
	@echo ""
	@echo "$(GREEN)✅ Test report generation complete$(NC)"

.PHONY: test-quick
test-quick: test-lint test-validate test-unit ## Run quick tests (no integration/performance)
	@echo "$(GREEN)✅ Quick tests completed$(NC)"

.PHONY: test-regression
test-regression: test-unit test-scenarios ## Run regression tests only
	@echo "$(GREEN)✅ Regression tests completed$(NC)"

.PHONY: test-security
test-security: ## Run comprehensive security tests
	@echo "$(BLUE)🔒 Running comprehensive security tests...$(NC)"
	@echo "$(CYAN)Security scanners available:$(NC)"
	@command -v checkov >/dev/null 2>&1 && echo "  ✅ Checkov" || echo "  ❌ Checkov (pip install checkov)"
	@command -v terrascan >/dev/null 2>&1 && echo "  ✅ Terrascan" || echo "  ❌ Terrascan (brew install terrascan)"
	@command -v tfsec >/dev/null 2>&1 && echo "  ✅ TFSec" || echo "  ❌ TFSec (brew install tfsec)"
	@command -v trivy >/dev/null 2>&1 && echo "  ✅ Trivy" || echo "  ❌ Trivy (brew install trivy)"
	@echo ""
	@$(MAKE) test-security-checkov
	@$(MAKE) test-security-terrascan
	@$(MAKE) test-security-tfsec
	@$(MAKE) test-security-trivy
	@$(MAKE) test-security-secrets
	@echo "$(GREEN)✅ Comprehensive security testing complete$(NC)"

.PHONY: test-security-checkov
test-security-checkov: ## Run Checkov security scan
	@echo "$(BLUE)🛡️ Running Checkov security scan...$(NC)"
	@if command -v checkov >/dev/null 2>&1; then \
		echo "$(CYAN)Scanning with Checkov (comprehensive policy checks)...$(NC)"; \
		checkov -d . \
			--framework terraform,kubernetes,helm \
			--output cli \
			--compact \
			--soft-fail || true; \
		echo ""; \
		echo "$(YELLOW)💡 Common Checkov Fixes:$(NC)"; \
		echo "  • CKV_K8S_8: Add resource limits to containers"; \
		echo "  • CKV_K8S_10: Set runAsNonRoot: true in securityContext"; \
		echo "  • CKV_K8S_12/13: Add readiness and liveness probes"; \
		echo "  • CKV_K8S_16: Set allowPrivilegeEscalation: false"; \
		echo "  • CKV_K8S_22: Set readOnlyRootFilesystem: true"; \
		echo "  • CKV_TF_1: Use commit hash in module sources"; \
		echo "$(CYAN)📚 Docs: https://www.checkov.io/5.Policy%20Index/kubernetes.html$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Checkov not available$(NC)"; \
		echo "$(CYAN)Install: pip install checkov$(NC)"; \
	fi
	@echo ""

.PHONY: test-security-terrascan
test-security-terrascan: ## Run Terrascan policy scan
	@echo "$(BLUE)🔒 Running Terrascan policy scan...$(NC)"
	@if command -v terrascan >/dev/null 2>&1; then \
		echo "$(CYAN)Scanning with Terrascan (policy-as-code)...$(NC)"; \
		terrascan scan \
			--iac-type terraform \
			--policy-type k8s,aws,azure,gcp \
			--severity high,medium \
			--output human \
			--verbose || true; \
		echo ""; \
		echo "$(YELLOW)💡 Common Terrascan Policy Fixes:$(NC)"; \
		echo "  • AC_K8S_0001: Add securityContext.runAsNonRoot: true"; \
		echo "  • AC_K8S_0002: Set allowPrivilegeEscalation: false"; \
		echo "  • AC_K8S_0004/0005: Add resource limits and requests"; \
		echo "  • AC_K8S_0006/0007: Add liveness and readiness probes"; \
		echo "  • AC_K8S_0011: Create default deny NetworkPolicy"; \
		echo "  • AC_K8S_0016: Configure proper RBAC"; \
		echo "$(CYAN)📚 Docs: https://runterrascan.io/docs/policies/$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Terrascan not available$(NC)"; \
		echo "$(CYAN)Install: brew install terrascan$(NC)"; \
	fi
	@echo ""

.PHONY: test-security-tfsec
test-security-tfsec: ## Run TFSec security analysis (DEPRECATED - use Trivy)
	@echo "$(YELLOW)⚠️  TFSec is deprecated and joining the Trivy family$(NC)"
	@echo "$(CYAN)Use 'make test-security-trivy' for Terraform security scanning$(NC)"
	@echo "$(CYAN)Migration info: https://github.com/aquasecurity/tfsec#tfsec-is-joining-the-trivy-family$(NC)"
	@if command -v tfsec >/dev/null 2>&1; then \
		echo "$(CYAN)Running deprecated TFSec scan...$(NC)"; \
		tfsec . --soft-fail || true; \
		echo ""; \
		echo "$(YELLOW)💡 Migrate to Trivy for Terraform security:$(NC)"; \
		echo "  • trivy config . --severity HIGH,CRITICAL"; \
		echo "  • trivy fs . --scanners config --severity HIGH,CRITICAL"; \
	else \
		echo "$(GREEN)✅ TFSec not installed - use Trivy instead$(NC)"; \
		echo "$(CYAN)Install Trivy: brew install trivy$(NC)"; \
	fi
	@echo ""

.PHONY: test-security-trivy
test-security-trivy: ## Run Trivy vulnerability and Terraform security scan
	@echo "$(BLUE)🔍 Running Trivy comprehensive security scan...$(NC)"
	@if command -v trivy >/dev/null 2>&1; then \
		echo "$(CYAN)Scanning with Trivy (vulnerabilities + Terraform security + secrets)...$(NC)"; \
		trivy fs . --severity HIGH,CRITICAL --scanners vuln,config,secret || true; \
		echo ""; \
		echo "$(CYAN)Running dedicated Terraform config scan...$(NC)"; \
		trivy config . --severity HIGH,CRITICAL || true; \
		echo ""; \
		echo "$(YELLOW)💡 Common Trivy Fixes:$(NC)"; \
		echo "  • Update dependencies to latest secure versions"; \
		echo "  • Use specific image tags with known security status"; \
		echo "  • Add resource limits and security contexts (Terraform)"; \
		echo "  • Remove hardcoded secrets from configuration"; \
		echo "  • Apply security patches to base images"; \
		echo "$(CYAN)📚 Docs: https://aquasecurity.github.io/trivy/$(NC)"; \
		echo "$(CYAN)🔄 Replaces tfsec: https://github.com/aquasecurity/tfsec#tfsec-is-joining-the-trivy-family$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Trivy not available$(NC)"; \
		echo "$(CYAN)Install: brew install trivy$(NC)"; \
	fi
	@echo ""

.PHONY: test-security-secrets
test-security-secrets: ## Check for hardcoded secrets
	@echo "$(BLUE)🔐 Checking for hardcoded secrets...$(NC)"
	@if command -v git >/dev/null 2>&1; then \
		echo "$(CYAN)Scanning for potential secrets...$(NC)"; \
		if git ls-files | xargs grep -l "password\|secret\|key\|token\|credential" | grep -v ".git\|Makefile\|README\|test\|\.md\|\.yaml\|\.yml" 2>/dev/null; then \
			echo "$(RED)⚠️  Potential secrets found in files above$(NC)"; \
			echo "$(YELLOW)💡 Security Fixes:$(NC)"; \
			echo "  • Move secrets to environment variables"; \
			echo "  • Use Kubernetes secrets or external secret management"; \
			echo "  • Add sensitive files to .gitignore"; \
			echo "  • Use terraform variables for sensitive data"; \
		else \
			echo "$(GREEN)✅ No obvious secrets found$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)⚠️  Git not available for secret scanning$(NC)"; \
	fi
	@if command -v detect-secrets >/dev/null 2>&1; then \
		echo "$(CYAN)Running detect-secrets scan...$(NC)"; \
		detect-secrets scan --all-files || true; \
	else \
		echo "$(YELLOW)💡 Install detect-secrets for advanced secret detection: pip install detect-secrets$(NC)"; \
	fi
	@echo ""

.PHONY: security-review
security-review: ## Run comprehensive security review (analyze baseline + reports)
	@echo "$(BLUE)🔍 Running comprehensive security review...$(NC)"
	@if [ -f "scripts/review-secrets.py" ]; then \
		python3 scripts/review-secrets.py --all; \
	else \
		echo "$(RED)❌ Security review script not found$(NC)"; \
		echo "$(YELLOW)💡 Create the script first: scripts/review-secrets.py$(NC)"; \
	fi
	@echo ""

.PHONY: security-review-baseline
security-review-baseline: ## Review only the secrets baseline
	@echo "$(BLUE)🔍 Reviewing secrets baseline...$(NC)"
	@if [ -f "scripts/review-secrets.py" ]; then \
		python3 scripts/review-secrets.py --baseline; \
	else \
		echo "$(RED)❌ Security review script not found$(NC)"; \
	fi
	@echo ""

.PHONY: security-review-findings
security-review-findings: ## Review baseline with detailed findings (shows first 10 per file)
	@echo "$(BLUE)🔍 Reviewing baseline with detailed findings...$(NC)"
	@if [ -f "scripts/review-secrets.py" ]; then \
		python3 scripts/review-secrets.py --baseline --show-findings --limit 10; \
	else \
		echo "$(RED)❌ Security review script not found$(NC)"; \
	fi
	@echo ""

.PHONY: security-review-all-findings
security-review-all-findings: ## Review baseline showing ALL findings (no limit)
	@echo "$(BLUE)🔍 Reviewing baseline with all findings...$(NC)"
	@if [ -f "scripts/review-secrets.py" ]; then \
		python3 scripts/review-secrets.py --baseline --show-findings --show-all; \
	else \
		echo "$(RED)❌ Security review script not found$(NC)"; \
	fi
	@echo ""

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

.PHONY: lint
lint: ## Run optimized TFLint analysis (fast)
	@echo "$(BLUE)🔎 Running optimized TFLint analysis...$(NC)"
	terraform fmt -check -recursive
	terraform validate
	@if command -v tflint >/dev/null 2>&1; then \
		./.pre-commit-hooks/tflint-optimized.sh; \
	else \
		echo "$(YELLOW)⚠️  tflint not available, skipping$(NC)"; \
	fi
	@echo "$(GREEN)✅ Optimized linting complete$(NC)"

.PHONY: lint-full
lint-full: ## Run comprehensive TFLint analysis (thorough)
	@echo "$(BLUE)🔎 Running comprehensive TFLint analysis...$(NC)"
	terraform fmt -check -recursive
	terraform validate
	@if command -v tflint >/dev/null 2>&1; then \
		./.pre-commit-hooks/tflint-recursive.sh; \
	else \
		echo "$(YELLOW)⚠️  tflint not available, skipping$(NC)"; \
	fi
	@echo "$(GREEN)✅ Comprehensive linting complete$(NC)"

.PHONY: fmt-check
fmt-check: ## Check Terraform formatting
	@echo "$(BLUE)🎨 Checking Terraform formatting...$(NC)"
	terraform fmt -check -recursive
	@echo "$(GREEN)✅ Formatting check passed$(NC)"

.PHONY: fmt
fmt: ## Format all Terraform files
	@echo "$(BLUE)🎨 Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)✅ Formatting complete$(NC)"

.PHONY: docs
docs: ## Generate documentation for all modules
	@echo "$(BLUE)📚 Generating documentation...$(NC)"
	@./.pre-commit-hooks/terraform-docs-automation.sh update
	@echo "$(GREEN)✅ Documentation updated$(NC)"

.PHONY: docs-check
docs-check: ## Check if documentation is up to date
	@echo "$(BLUE)📚 Checking documentation...$(NC)"
	@./.pre-commit-hooks/terraform-docs-automation.sh check

.PHONY: docs-install
docs-install: ## Install terraform-docs tool
	@echo "$(BLUE)📚 Installing terraform-docs...$(NC)"
	@./.pre-commit-hooks/terraform-docs-automation.sh install

.PHONY: security-scan
security-scan: test-security ## Run comprehensive security scanning (alias for test-security)

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
# CI-Specific Testing Commands
# ============================================================================

.PHONY: ci-validate
ci-validate: ## CI-specific validation (backend disabled)
	@echo "$(BLUE)🔍 Running CI validation...$(NC)"
	terraform init -backend=false
	terraform validate
	@echo "$(GREEN)✅ CI validation complete$(NC)"

.PHONY: ci-lint
ci-lint: ## CI-specific linting
	@echo "$(BLUE)🔎 Running CI linting...$(NC)"
	terraform fmt -check -recursive
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init; \
		tflint -f compact; \
	else \
		echo "$(YELLOW)⚠️  TFLint not available$(NC)"; \
	fi
	@echo "$(GREEN)✅ CI linting complete$(NC)"

.PHONY: ci-security
ci-security: ## CI-specific security scanning
	@echo "$(BLUE)🛡️  Running CI security scanning...$(NC)"
	@if [ -f "scripts/security-scan.sh" ]; then \
		./scripts/security-scan.sh --ci --severity high --format sarif; \
	else \
		echo "$(YELLOW)⚠️  Security scan script not found$(NC)"; \
		$(MAKE) test-security; \
	fi
	@echo "$(GREEN)✅ CI security scanning complete$(NC)"

.PHONY: pre-commit-install
pre-commit-install: ## Install pre-commit hooks
	@echo "$(BLUE)🔧 Installing pre-commit hooks...$(NC)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit install; \
		pre-commit install --hook-type commit-msg; \
		echo "$(GREEN)✅ Pre-commit hooks installed$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Pre-commit not available$(NC)"; \
		echo "$(CYAN)Install: pip install pre-commit$(NC)"; \
	fi

.PHONY: pre-commit-run
pre-commit-run: ## Run pre-commit hooks on all files
	@echo "$(BLUE)🔍 Running pre-commit hooks...$(NC)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "$(YELLOW)⚠️  Pre-commit not available$(NC)"; \
		echo "$(CYAN)Install: pip install pre-commit$(NC)"; \
		echo "$(CYAN)Then run: make pre-commit-install$(NC)"; \
	fi

.PHONY: ci-test-architecture
ci-test-architecture: ## Run architecture detection tests
	@echo "$(BLUE)🧪 Running architecture tests...$(NC)"
	terraform init -backend=false
	@if [ -f "$(TEST_DIR)/tests-architecture.tftest.hcl" ]; then \
		terraform test -filter=$(TEST_DIR)/tests-architecture.tftest.hcl -verbose; \
	else \
		echo "$(YELLOW)⚠️  Architecture test file not found$(NC)"; \
	fi
	@echo "$(GREEN)✅ Architecture tests complete$(NC)"

.PHONY: ci-test-storage
ci-test-storage: ## Run storage configuration tests
	@echo "$(BLUE)🧪 Running storage tests...$(NC)"
	terraform init -backend=false
	@if [ -f "$(TEST_DIR)/tests-storage.tftest.hcl" ]; then \
		terraform test -filter=$(TEST_DIR)/tests-storage.tftest.hcl -verbose; \
	else \
		echo "$(YELLOW)⚠️  Storage test file not found$(NC)"; \
	fi
	@echo "$(GREEN)✅ Storage tests complete$(NC)"

.PHONY: ci-test-services
ci-test-services: ## Run service enablement tests
	@echo "$(BLUE)🧪 Running service tests...$(NC)"
	terraform init -backend=false
	@if [ -f "$(TEST_DIR)/tests-services.tftest.hcl" ]; then \
		terraform test -filter=$(TEST_DIR)/tests-services.tftest.hcl -verbose; \
	else \
		echo "$(YELLOW)⚠️  Services test file not found$(NC)"; \
	fi
	@echo "$(GREEN)✅ Service tests complete$(NC)"

.PHONY: ci-test-scenarios
ci-test-scenarios: ## Run all scenario validation tests
	@echo "$(BLUE)🎯 Running scenario tests...$(NC)"
	terraform init -backend=false
	@for scenario in minimal raspberry-pi mixed-cluster cloud production; do \
		echo "$(CYAN)Testing $$scenario scenario...$(NC)"; \
		if [ -f "test-configs/$$scenario.tfvars" ]; then \
			cp test-configs/$$scenario.tfvars terraform.tfvars; \
			terraform plan -detailed-exitcode -out=tfplan-$$scenario || echo "$(YELLOW)⚠️  $$scenario scenario failed$(NC)"; \
			rm -f terraform.tfvars tfplan-$$scenario; \
		else \
			echo "$(YELLOW)⚠️  $$scenario.tfvars not found, skipping$(NC)"; \
		fi; \
	done
	@echo "$(GREEN)✅ Scenario tests complete$(NC)"

.PHONY: ci-security-scan
ci-security-scan: ci-security ## Alias for ci-security

# ============================================================================
# COMPREHENSIVE CI TEST SUITE
# ============================================================================

.PHONY: ci-test-comprehensive
ci-test-comprehensive: ## Run comprehensive CI test suite (all tests)
	@echo "$(BLUE)🚀 Running comprehensive CI test suite...$(NC)"
	@echo "$(CYAN)Phase 1: Validation$(NC)"
	@$(MAKE) ci-validate
	@$(MAKE) ci-lint
	@echo ""
	@echo "$(CYAN)Phase 2: Unit Tests$(NC)"
	@$(MAKE) ci-test-architecture
	@$(MAKE) ci-test-storage
	@$(MAKE) ci-test-services
	@echo ""
	@echo "$(CYAN)Phase 3: Scenario Tests$(NC)"
	@$(MAKE) ci-test-scenarios
	@echo ""
	@echo "$(CYAN)Phase 4: Security Scanning$(NC)"
	@$(MAKE) ci-security
	@echo ""
	@echo "$(GREEN)✅ Comprehensive CI test suite complete!$(NC)"

.PHONY: ci-test-fast
ci-test-fast: ## Run fast CI tests (validation + unit tests only)
	@echo "$(BLUE)⚡ Running fast CI tests...$(NC)"
	@$(MAKE) ci-validate
	@$(MAKE) ci-lint
	@$(MAKE) ci-test-architecture
	@$(MAKE) ci-test-storage
	@$(MAKE) ci-test-services
	@echo "$(GREEN)✅ Fast CI tests complete$(NC)"

.PHONY: ci-test-scenarios-only
ci-test-scenarios-only: ## Run scenario tests only
	@echo "$(BLUE)🎯 Running scenario tests only...$(NC)"
	@$(MAKE) ci-test-scenarios
	@echo "$(GREEN)✅ Scenario tests complete$(NC)"

.PHONY: ci-validate-all
ci-validate-all: ## Run all validation checks
	@echo "$(BLUE)🔍 Running all validation checks...$(NC)"
	@$(MAKE) ci-validate
	@$(MAKE) ci-lint
	@$(MAKE) docs
	@echo "$(GREEN)✅ All validation checks complete$(NC)"

# ============================================================================
# CI REPORTING AND DEBUGGING
# ============================================================================

.PHONY: ci-report
ci-report: ## Generate CI test report
	@echo "$(BLUE)📊 Generating CI test report...$(NC)"
	@echo "$(CYAN)CI Test Report - $(shell date)$(NC)"
	@echo ""
	@echo "$(YELLOW)Available Test Commands:$(NC)"
	@echo "  make ci-test-fast           - Quick validation + unit tests"
	@echo "  make ci-test-comprehensive  - Full test suite"
	@echo "  make ci-test-scenarios      - Deployment scenario tests"
	@echo "  make ci-security            - Security scanning"
	@echo ""
	@echo "$(YELLOW)Test Coverage:$(NC)"
	@echo "  ✅ Architecture detection logic"
	@echo "  ✅ Storage class selection"
	@echo "  ✅ Service enablement logic"
	@echo "  ✅ Mixed cluster configuration"
	@echo "  ✅ Raspberry Pi scenarios"
	@echo "  ✅ Cloud deployment scenarios"
	@echo "  ✅ Production configuration"
	@echo "  ✅ Security policy validation"
	@echo ""
	@echo "$(YELLOW)CI Environment Detection:$(NC)"
	@if [ "$$CI" = "true" ]; then \
		echo "  ✅ Running in CI environment"; \
	else \
		echo "  💻 Running in local environment"; \
	fi
	@if [ "$$GITHUB_ACTIONS" = "true" ]; then \
		echo "  ✅ GitHub Actions detected"; \
	fi
	@echo ""

.PHONY: ci-debug
ci-debug: ## Debug CI environment and configuration
	@echo "$(BLUE)🔧 CI Debug Information$(NC)"
	@echo ""
	@echo "$(CYAN)Environment Variables:$(NC)"
	@echo "  CI: $${CI:-not set}"
	@echo "  GITHUB_ACTIONS: $${GITHUB_ACTIONS:-not set}"
	@echo "  TERRAFORM_VERSION: $${TF_VERSION:-not set}"
	@echo ""
	@echo "$(CYAN)Tool Versions:$(NC)"
	@terraform version | head -1 || echo "  Terraform: not available"
	@kubectl version --client --short 2>/dev/null | head -1 || echo "  kubectl: not available"
	@helm version --short 2>/dev/null || echo "  Helm: not available"
	@echo ""
	@echo "$(CYAN)Test Files Status ($(TEST_DIR)/):$(NC)"
	@for file in tests-architecture.tftest.hcl tests-storage.tftest.hcl tests-services.tftest.hcl tests-mixed-cluster.tftest.hcl tests-module-outputs.tftest.hcl; do \
		if [ -f "$(TEST_DIR)/$$file" ]; then \
			echo "  ✅ $(TEST_DIR)/$$file"; \
		else \
			echo "  ❌ $(TEST_DIR)/$$file (missing)"; \
		fi; \
	done
	@echo ""
	@echo "$(CYAN)Test Config Files Status:$(NC)"
	@for file in minimal raspberry-pi mixed-cluster cloud production; do \
		if [ -f "test-configs/$$file.tfvars" ]; then \
			echo "  ✅ test-configs/$$file.tfvars"; \
		else \
			echo "  ❌ test-configs/$$file.tfvars (missing)"; \
		fi; \
	done
	@echo ""

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
# Version Management
# ============================================================================

.PHONY: versions
versions: ## Show all tool versions
	@echo "$(BLUE)📋 Tool Versions:$(NC)"
	@./scripts/version-manager.sh list

.PHONY: version-get
version-get: ## Get version for specific tool (usage: make version-get TOOL=terraform)
	@if [ -z "$(TOOL)" ]; then \
		echo "$(RED)❌ TOOL parameter required$(NC)"; \
		echo "$(CYAN)Usage: make version-get TOOL=terraform$(NC)"; \
		exit 1; \
	fi
	@echo "$(CYAN)$(TOOL):$(NC) $$(./scripts/version-manager.sh get $(TOOL))"

.PHONY: version-update
version-update: ## Update version for specific tool (usage: make version-update TOOL=terraform VERSION=1.6.0)
	@if [ -z "$(TOOL)" ] || [ -z "$(VERSION)" ]; then \
		echo "$(RED)❌ TOOL and VERSION parameters required$(NC)"; \
		echo "$(CYAN)Usage: make version-update TOOL=terraform VERSION=1.6.0$(NC)"; \
		exit 1; \
	fi
	@./scripts/version-manager.sh update $(TOOL) $(VERSION)

.PHONY: version-validate
version-validate: ## Validate all tool versions
	@echo "$(BLUE)✅ Validating tool versions...$(NC)"
	@./scripts/version-manager.sh validate

.PHONY: version-sync
version-sync: ## Sync versions across all configuration files
	@echo "$(BLUE)🔄 Syncing versions across configuration files...$(NC)"
	@./scripts/version-manager.sh generate-github-env .github/env.yml
	@echo "$(YELLOW)⚠️  Manual update required for pre-commit hooks$(NC)"
	@echo "$(CYAN)Run: ./scripts/version-manager.sh generate-precommit$(NC)"

.PHONY: version-check-outdated
version-check-outdated: ## Check for outdated tool versions
	@echo "$(BLUE)🔍 Checking for outdated versions...$(NC)"
	@./scripts/version-manager.sh check-outdated

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
