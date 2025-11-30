# Kubectl and Terraform Configuration Guide

## Overview

This guide explains how to configure kubectl for Terraform deployments and how tf-kube-any-compute selects the correct Kubernetes configuration based on Terraform workspaces.

## Kubectl Configuration Methods

### Method 1: Default Kubeconfig (Recommended)

```bash
# Ensure kubectl is configured
kubectl cluster-info

# Verify config location
echo $KUBECONFIG
# Should show: ~/.kube/config (if empty)

# Test access
kubectl get nodes
```

### Method 2: Custom Kubeconfig Path

```bash
# Set custom kubeconfig
export KUBECONFIG=/path/to/your/kubeconfig

# Make permanent
echo 'export KUBECONFIG=/path/to/your/kubeconfig' >> ~/.bashrc
source ~/.bashrc
```

### Method 3: Multiple Contexts

```bash
# List available contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# Verify current context
kubectl config current-context
```

## Terraform Provider Configuration

### Current Provider Setup

The Kubernetes provider in `provider.tf` uses intelligent kubeconfig detection:

```hcl
provider "kubernetes" {
  # Intelligent config path selection:
  # 1. CI mode: uses default kubeconfig or skips if not available
  # 2. Workspace-specific: ~/.kube/{workspace}-config
  # 3. Fallback: ~/.kube/config
  config_path = local.ci_mode ? null : (
    can(file("~/.kube/${lower(terraform.workspace)}-config")) ?
      "~/.kube/${lower(terraform.workspace)}-config" :
      "~/.kube/config"
  )
}

provider "helm" {
  kubernetes {
    # Uses same logic as kubernetes provider
    config_path = local.ci_mode ? null : (
      can(file("~/.kube/${lower(terraform.workspace)}-config")) ?
        "~/.kube/${lower(terraform.workspace)}-config" :
        "~/.kube/config"
    )
  }
}
```

### Workspace-Based Configuration

tf-kube-any-compute uses Terraform workspaces with intelligent kubeconfig selection:

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new prod
terraform workspace new staging
terraform workspace new homelab

# Switch workspace
terraform workspace select homelab

# Workspace affects:
# - State file isolation
# - Resource naming (prod-traefik-system, homelab-traefik-system)
# - Kubeconfig selection (~/.kube/prod-config, ~/.kube/homelab-config)
# - Domain generation (prod.k3s.example.com, homelab.k3s.example.com)
```

## Multi-Environment Setup

### Scenario 1: Workspace-Specific Kubeconfigs (Automatic)

```bash
# Structure your configs (matches workspace names)
~/.kube/
├── homelab-config      # Homelab cluster (workspace: homelab)
├── prod-config         # Production cluster (workspace: prod)
├── staging-config      # Staging cluster (workspace: staging)
└── config              # Default fallback

# Automatic selection - no KUBECONFIG needed
terraform workspace select homelab  # Uses ~/.kube/homelab-config
terraform apply

terraform workspace select prod      # Uses ~/.kube/prod-config
terraform apply
```

### Scenario 2: Single Kubeconfig with Multiple Contexts

```bash
# Configure contexts in single file
kubectl config set-context homelab --cluster=homelab --user=homelab-admin
kubectl config set-context prod --cluster=prod --user=prod-admin

# Switch context before Terraform operations
kubectl config use-context homelab
terraform workspace select homelab
terraform apply

kubectl config use-context prod
terraform workspace select prod
terraform apply
```

### Scenario 3: Automated Environment Switching

Create environment-specific scripts:

```bash
# scripts/deploy-homelab.sh
#!/bin/bash
export KUBECONFIG=~/.kube/config-homelab
terraform workspace select homelab
terraform apply -var-file=environments/homelab.tfvars

# scripts/deploy-prod.sh
#!/bin/bash
export KUBECONFIG=~/.kube/config-prod
terraform workspace select prod
terraform apply -var-file=environments/prod.tfvars
```

## Configuration Validation

### Pre-Deployment Checks

```bash
# Verify kubectl access
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Verify Terraform workspace
terraform workspace show

# Verify provider connectivity
terraform plan
```

### Troubleshooting Connection Issues

```bash
# Check kubeconfig
kubectl config view
kubectl config current-context

# Test provider access
terraform console
> data.kubernetes_nodes.all_nodes

# Debug provider issues
TF_LOG=DEBUG terraform plan
```

## Advanced Provider Configuration

### Custom Provider Configuration

If you need explicit provider configuration:

```hcl
# provider.tf
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "homelab"  # Explicit context
}

# Or use environment variables
provider "kubernetes" {
  config_path = var.kubeconfig_path
}
```

### How Automatic Selection Works

```hcl
# Built-in workspace mapping (from locals.tf)
locals {
  workspace = {
    "default" = "BUILD"
    "preprod" = "PREPROD"
    "prod"    = "PROD"
    "sit"     = "SIT"
    "qa"      = "QA"
    "uat"     = "UAT"
    "dev"     = "DEV"
    "homelab" = "homelab"  # Custom workspaces use lowercase
  }

  # Provider automatically tries:
  # 1. ~/.kube/{workspace}-config
  # 2. ~/.kube/config (fallback)
}
```

## Best Practices

### Security
- **Never commit kubeconfig files** to version control
- **Use service accounts** for CI/CD pipelines
- **Rotate credentials** regularly
- **Limit permissions** to minimum required

### Organization
- **One workspace per environment**
- **Consistent naming** (workspace = cluster context)
- **Environment-specific tfvars files**
- **Automated deployment scripts**

### Validation
- **Always verify context** before deployment
- **Test connectivity** with `kubectl get nodes`
- **Use `terraform plan`** to preview changes
- **Monitor resource creation** during apply

## Common Patterns

### Pattern 1: Homelab Setup (Automatic)
```bash
# Automatic kubeconfig selection
terraform workspace select homelab  # Uses ~/.kube/homelab-config
terraform apply -var-file=homelab.tfvars
# No kubectl config changes needed
```

### Pattern 2: Multi-Environment
```bash
# Environment-specific deployment
./scripts/deploy-to-env.sh homelab
./scripts/deploy-to-env.sh prod
```

### Pattern 3: CI/CD Pipeline
```bash
# Automated deployment
export KUBECONFIG=$WORKSPACE_KUBECONFIG
terraform workspace select $ENVIRONMENT
terraform apply -auto-approve -var-file=$ENVIRONMENT.tfvars
```

## Workspace Resource Naming

tf-kube-any-compute automatically prefixes resources with workspace name:

```hcl
# Workspace: prod
# Creates: prod-traefik-system namespace
# Creates: prod-traefik release
# Domain: prod.k3s.example.com

# Workspace: dev
# Creates: dev-traefik-system namespace
# Creates: dev-traefik release
# Domain: dev.k3s.example.com
```

**Supported Workspaces:**
- `prod` → `PROD` → `prod` (production)
- `dev` → `DEV` → `dev` (development)
- `qa` → `QA` → `qa` (quality assurance)
- `preprod` → `PREPROD` → `preprod` (pre-production)
- `sit` → `SIT` → `sit` (system integration testing)
- `uat` → `UAT` → `uat` (user acceptance testing)
- `fat` → `FAT` → `fat` (factory acceptance testing)
- `pentest` → `PENTEST` → `pentest` (penetration testing)
- `default` → `BUILD` → `build` (default/build)

This enables multiple deployments to the same cluster without conflicts.

## Quick Reference

### Essential Commands
```bash
# Check current setup
kubectl config current-context
terraform workspace show

# Switch environment
kubectl config use-context <context>
terraform workspace select <workspace>

# Deploy
terraform plan
terraform apply

# Cleanup
terraform destroy
```

### Environment Variables
```bash
export KUBECONFIG=/path/to/config    # Custom kubeconfig
export TF_WORKSPACE=homelab          # Default workspace
export TF_LOG=DEBUG                  # Debug provider issues
```

This configuration approach ensures clean separation between environments while maintaining simplicity for single-cluster deployments.
