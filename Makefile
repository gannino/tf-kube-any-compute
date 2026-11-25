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

# Bootstrap TFVARS files (can be overridden via .env or command line)
BOOTSTRAP_TFVARS_ON_PREM := terraform.bootstrap.on-prem.tfvars.example
BOOTSTRAP_TFVARS_ON_CLOUD := terraform.bootstrap.cloud.tfvars.example
# Load environment variables from .env file if it exists
#   Run: set -a; . .env; set +a  (to export variables to subprocesses)

# MicroK8s Database Lock Prevention
# Detect if using MicroK8s and adjust Terraform parallelism to prevent database locks
# Terraform default parallelism is 10 (too aggressive for MicroK8s SQLite/etcd backend)
MICROK8S_MODE := $(shell grep -q "enable_microk8s_mode = true" $(TFVARS_FILE) 2>/dev/null && echo "true" || echo "false")

# Set appropriate parallelism based on Kubernetes distribution
ifeq ($(MICROK8S_MODE),true)
    PARALLELISM ?= 2
    $(info ✅ MicroK8s detected: using parallelism=$(PARALLELISM) to prevent database locks)
else
    PARALLELISM ?= 10
    $(info ✅ Standard deployment: using parallelism=$(PARALLELISM) (Terraform default))
endif

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
.PHONY: bootstrap
bootstrap: ## Stage 1: minimal core (NFD, Longhorn, host-path, MetalLB, Traefik, metrics, CRDs) - run before full apply
	@echo "$(BLUE)🧱 Bootstrap stage: minimal core only (parallelism=1)$(NC)"
	@echo "$(CYAN)Use $(BOOTSTRAP_TFVARS_ON_PREM) or copy from example$(NC)"
	@./scripts/ensure-coredns.sh
	@if [ -f "$(BOOTSTRAP_TFVARS_ON_PREM)" ]; then 		terraform apply -var-file=$(BOOTSTRAP_TFVARS_ON_PREM) -parallelism=1; 	else 		echo "$(YELLOW)⚠️  $(BOOTSTRAP_TFVARS_ON_PREM) not found. Copy $(BOOTSTRAP_TFVARS_ON_PREM) or $(BOOTSTRAP_TFVARS_ON_CLOUD) to $(BOOTSTRAP_TFVARS_ON_PREM) and edit it.$(NC)"; 		exit 1; 	fi
.PHONY: bootstrap-auto
bootstrap-auto: ## Stage 1 without confirmation (same as bootstrap, -auto-approve)
	@echo "$(BLUE)🧱 Bootstrap stage: minimal core only (auto-approve, parallelism=1)$(NC)"
	@echo "$(CYAN)Use $(BOOTSTRAP_TFVARS_ON_PREM)$(NC)"
	@./scripts/ensure-coredns.sh
	@if [ -f "$(BOOTSTRAP_TFVARS_ON_PREM)" ]; then 		terraform apply -var-file=$(BOOTSTRAP_TFVARS_ON_PREM) -auto-approve -parallelism=1; 	else 		echo "$(YELLOW)⚠️  $(BOOTSTRAP_TFVARS_ON_PREM) not found, creating from $(BOOTSTRAP_TFVARS_ON_PREM)...$(NC)"; 		cp $(BOOTSTRAP_TFVARS_ON_PREM).example $(BOOTSTRAP_TFVARS_ON_PREM); 		echo "$(YELLOW)Please edit $(BOOTSTRAP_TFVARS_ON_PREM) with your cluster settings and re-run$(NC)"; 		exit 1; 	fi
.PHONY: bootstrap-on-prem
bootstrap-on-prem: ## Stage 1: on-prem cluster (ARM64, hostpath, hurricane DNS)
	@echo "$(BLUE)🧱 Bootstrap: on-prem cluster (parallelism=1)$(NC)"
	$(call switch_workspace,on-prem)
	@./scripts/ensure-coredns.sh
	terraform apply -var-file=$(BOOTSTRAP_TFVARS_ON_PREM) -parallelism=1

.PHONY: bootstrap-auto-on-prem
bootstrap-auto-on-prem: ## Stage 1: on-prem cluster (auto-approve, parallelism=1)
	@echo "$(BLUE)🧱 Bootstrap: on-prem cluster (auto-approve, parallelism=1)$(NC)"
	$(call switch_workspace,on-prem)
	@./scripts/ensure-coredns.sh
	terraform apply -var-file=$(BOOTSTRAP_TFVARS_ON_PREM) -auto-approve -parallelism=1

.PHONY: bootstrap-on-cloud
bootstrap-on-cloud: ## Stage 1: cloud cluster (AMD64, nfs-csi, hurricane DNS)
	@echo "$(BLUE)🧱 Bootstrap: cloud cluster (parallelism=1)$(NC)"
	$(call switch_workspace,on-cloud)
	@./scripts/ensure-coredns.sh
	terraform apply -var-file=$(BOOTSTRAP_TFVARS_ON_CLOUD) -parallelism=1

.PHONY: bootstrap-auto-on-cloud
bootstrap-auto-on-cloud: ## Stage 1: cloud cluster (auto-approve, parallelism=1)
	@echo "$(BLUE)🧱 Bootstrap: cloud cluster (auto-approve, parallelism=1)$(NC)"
	$(call switch_workspace,on-cloud)
	@./scripts/ensure-coredns.sh
	terraform apply -var-file=$(BOOTSTRAP_TFVARS_ON_CLOUD) -auto-approve -parallelism=1

.PHONY: bootstrap-on-prem
bootstrap-on-prem: ## Stage 1: on-prem cluster (ARM64, hostpath, hurricane DNS)
	@echo "$(BLUE)🧱 Bootstrap: on-prem cluster (parallelism=1)$(NC)"
	$(call switch_workspace,on-prem)
	@./scripts/ensure-coredns.sh
	terraform apply -var-file=$(BOOTSTRAP_TFVARS_ON_PREM) -parallelism=1

		terraform apply -var-file=$(BOOTSTRAP_TFVARS_ON_PREM) -auto-approve -parallelism=1; \
	else \
		echo "$(YELLOW)⚠️  $(BOOTSTRAP_TFVARS_ON_PREM) not found, creating from $(BOOTSTRAP_TFVARS_ON_PREM)...$(NC)"; \
		cp $(BOOTSTRAP_TFVARS_ON_PREM) $(BOOTSTRAP_TFVARS_ON_PREM); \
		echo "$(YELLOW)Please edit $(BOOTSTRAP_TFVARS_ON_PREM) with your cluster settings and re-run$(NC)"; \
		exit 1; \
	fi
