# Multi-Cluster Deployment Guide

## Overview

`tf-kube-any-compute` supports deploying the same Terraform codebase to **multiple Kubernetes clusters** (e.g., on-prem homelab and cloud) using **Terraform workspaces**. Each workspace maintains its own state, allowing independent lifecycle management per cluster.

This guide covers:
1. **Why split clusters?** - Architectural reasoning
2. **Bootstrap strategy** - Two-stage deployment for smaller clusters
3. **Workspace-based setup** - Step-by-step configuration
4. **Cluster-specific configuration** - Different settings per cluster
5. **Workflow examples** - Day-to-day operations

---

## Why Split Clusters?

Splitting infrastructure across multiple clusters is common for homelabs and production environments. Here are the common reasons:

| Reason | On-Prem Cluster | Cloud Cluster |
|--------|-----------------|---------------|
| **Cost** | Uses existing hardware (Raspberry Pi, old servers) | Pay-as-you-go, no hardware investment |
| **Latency** | Local access for IoT devices, home automation | Global distribution, closer to users |
| **Data Sovereignty** | Sensitive data stays on-prem | Less sensitive data in cloud |
| **Reliability** | Single point of failure (power, internet) | High availability, multi-zone |
| **Learning** | Hands-on hardware experience | Cloud-native patterns, managed services |
| **Hybrid** | Keep critical services local | Burst non-critical workloads to cloud |

### Common Patterns

| Pattern | On-Prem | Cloud |
|---------|---------|-------|
| **Primary/Secondary** | Primary production, backup | Disaster recovery, burst |
| **Split by Service** | Core infra, databases | Frontend, web apps |
| **Split by Environment** | Development, staging | Production |
| **Split by Data Sensitivity** | PII, financial data | Public websites, blogs |

---

## Bootstrap Strategy for Smaller Clusters

For smaller clusters (e.g., single Raspberry Pi, small VPS), deploying all services at once can cause resource exhaustion. The **bootstrap strategy** deploys in two stages:

### Stage 1: Bootstrap (Minimal Core)

Deploys only the essential services needed for the cluster to function:

| Service | On-Prem | Cloud | Reason |
|---------|---------|-------|--------|
| Traefik | ✅ | ✅ | Ingress controller - required for all traffic |
| MetalLB | ✅ | ❌ | Load balancer for bare metal (cloud has its own LB) |
| HostPath | ✅ | ❌ | Local storage (cloud uses NFS/cloud storage) |
| Longhorn | ✅ | ❌ | Distributed block storage (cloud uses managed storage) |
| NFS CSI | ❌ | ✅ | Shared storage for cloud |
| metrics_server | ✅ | ✅ | Required for HPA |
| prometheus_crds | ✅ | ✅ | CRDs needed before Prometheus |

**Why bootstrap first?**
- CRDs must exist before Prometheus can be deployed
- Storage classes must exist before PVCs can be created
- Smaller resource footprint = faster initial deployment
- Easier to debug issues in isolation

### Stage 2: Full Apply

After bootstrap completes, deploy all remaining services:

- Prometheus, Grafana, Loki, Promtail (monitoring)
- Consul, Vault (service mesh, secrets)
- Authelia, Redis (authentication, caching)
- Home Assistant, openHAB, Homebridge, Node-RED, n8n (automation)
- And any other enabled services

---

## Workspace-Based Cluster Selection

Terraform workspaces provide **isolated state** per cluster. Each workspace has its own `terraform.tfstate`, so changes to one cluster never affect another.

### Workspace Naming Convention

| Workspace | Cluster Type | Example Use |
|-----------|-------------|-------------|
| `on-prem` | Raspberry Pi homelab | Local services, hostpath storage |
| `on-cloud` | AWS/GCP/AKS VPS | Cloud load balancer, NFS storage |
| `prod` | Production cluster | Production workloads |
| `dev` | Development cluster | Testing new services |
| `default` | Default cluster | General purpose |

### Workspace Commands

```bash
# List all workspaces
terraform workspace list

# Create a new workspace (one-time setup)
terraform workspace new on-prem
terraform workspace new on-cloud

# Switch between workspaces
terraform workspace select on-prem
terraform workspace select on-cloud

# Show current workspace
terraform workspace show
```

---

## Cluster-Specific Configuration

Each cluster uses its own `terraform.tfvars.<cluster>` file (gitignored for secrets). Example:

### `terraform.on-prem.tfvars` (Raspberry Pi Homelab)

```hcl
# Cluster selection
cluster_name = "on-prem"

# DNS Provider - Hurricane Electric (default, free)
dns_providers = {
  primary = {
    name   = "hurricane"
    config = {
      HE_TOKENS = "prod.k3s.annino.cloud:YOUR_HE_TOKEN"
    }
  }
  additional = []
}

# Services enabled for this cluster
services = {
  # Core infrastructure (essential)
  traefik   = true
  metallb   = true    # Load balancer for bare metal
  host_path = true    # Local storage
  longhorn  = true    # Distributed block storage (optional for HA)

  # Lightweight monitoring
  prometheus        = true
  prometheus_crds   = true
  grafana           = true
  kube_state_metrics = true
  metrics_server    = true

  # Home automation (optional)
  home_assistant = false
  node_red       = false
  n8n            = false

  # Optional services (disable for low resources)
  loki      = false
  promtail  = false
  consul    = false
  vault     = false
  gatekeeper = false
  redis     = false

  # Management
  portainer             = true
  node_feature_discovery = true
  authelia            = false
}

# Root domain for DNS challenges
domain_name = "k3s.annino.cloud"

# CPU Architecture (auto-detect for ARM64 on Pi)
cpu_arch = ""  # Auto-detect

# Default storage class
default_storage_class = "hostpath"

# Helm Configuration
default_helm_atomic            = false
default_helm_cleanup_on_fail  = true
default_helm_disable_webhooks = true
default_helm_force_update     = true
default_helm_timeout          = 600
default_helm_wait             = true
default_helm_wait_for_jobs    = true

# Storage defaults (override per-service)
default_storage_class = "hostpath"

# Disable architecture scheduling (development/testing)
disable_arch_scheduling = {
  # Example: Allow services to run on any architecture
  # traefik = true
  # prometheus = true
}
```

### `terraform.on-cloud.tfvars` (Cloud VPS)

```hcl
# Cluster selection
cluster_name = "on-cloud"

# DNS Provider - Hurricane Electric (works on cloud too)
dns_providers = {
  primary = {
    name   = "hurricane"
    config = {
      HE_TOKENS = "prod.k3s.annino.cloud:YOUR_HE_TOKEN"
    }
  }
  additional = []
}

# Services enabled for cloud cluster
services = {
  # Core infrastructure
  traefik   = true   # Ingress controller
  metallb   = false  # Cloud provides its own load balancer
  host_path = false  # Cloud has persistent storage
  longhorn  = false  # Cloud provides storage (EBS, PD, etc.)

  # Minimal monitoring
  prometheus        = false  # Enable after bootstrap
  prometheus_crds   = true   # CRDs needed first
  grafana           = false  # Enable after bootstrap
  kube_state_metrics = false
  metrics_server    = true   # Required for HPA

  # No automation services in bootstrap
  home_assistant  = false
  openhab         = false
  homebridge      = false
  node_red        = false
  n8n             = false

  # No optional services
  loki      = false
  promtail  = false
  consul    = false
  vault     = false
  gatekeeper= false
  redis     = false

  # Management
  portainer           = false
  headlamp            = false
  node_feature_discovery = false
  authelia            = false
}

# Domain configuration
domain_name = "k3s.annino.cloud"

# CPU Architecture (auto-detect)
cpu_arch = ""  # Auto-detect (likely amd64 on cloud)

# Default storage class
default_storage_class = "nfs-csi"

# Helm Configuration
default_helm_atomic            = false
default_helm_cleanup_on_fail  = true
default_helm_disable_webhooks = true
default_helm_force_update     = true
default_helm_timeout          = 600
default_helm_wait             = true
default_helm_wait_for_jobs    = true

# Storage defaults (override per-service)
default_storage_class = "nfs-csi"

# Disable architecture scheduling (development/testing)
disable_arch_scheduling = {
  # Example: Allow services to run on any architecture
  # traefik = true
  # prometheus = true
}
```

### Creating Cluster-Specific tfvars

```bash
# Copy the example to create your cluster config
cp terraform.tfvars.example terraform.on-prem.tfvars
cp terraform.tfvars.example terraform.on-cloud.tfvars

# Edit each file for your cluster's settings
vi terraform.on-prem.tfvars
vi terraform.on-cloud.tfvars
```

> ⚠️ **Important**: All `terraform.tfvars.*` files are **gitignored** and contain secrets. Never commit them. Only the `*.tfvars.example` files are committed to git.

---

## Multi-Cluster Makefile Targets

The Makefile provides workspace-aware targets for each cluster:

### Bootstrap (Stage 1 - Minimal Core)

```bash
# On-prem cluster (ARM64, hostpath, hurricane DNS)
make bootstrap-on-prem
make bootstrap-auto-on-prem      # Auto-approve

# Cloud cluster (AMD64, nfs-csi, hurricane DNS)
make bootstrap-on-cloud
make bootstrap-auto-on-cloud     # Auto-approve
```

### Full Apply (Stage 2 - All Services)

```bash
# On-prem cluster
make apply-on-prem
make apply-auto-on-prem          # Auto-approve

# Cloud cluster
make apply-on-cloud
make apply-auto-on-cloud         # Auto-approve
```

### Destroy

```bash
# Destroy on-prem cluster
make destroy-on-prem
make destroy-auto-on-prem        # Auto-approve

# Destroy cloud cluster
make destroy-on-cloud
make destroy-auto-on-cloud       # Auto-approve
```

### Workflow Example

```bash
# Day 1: Bootstrap both clusters
make bootstrap-on-prem
make bootstrap-on-cloud

# Day 2: Deploy full stacks
make apply-on-prem
make apply-on-cloud

# Day 3: Update one cluster only
make apply-on-prem   # Only updates on-prem
```

---

## Workspace Workflow Example

Here's a complete example of deploying to both clusters:

```bash
# ============================================
# DAY 1: Initial Cluster Setup
# ============================================

# Create workspaces (one-time setup)
terraform workspace new on-prem
terraform workspace new on-cloud

# Verify workspaces
terraform workspace list
#   default
>   on-prem
    on-cloud

# ============================================
# DAY 2: Bootstrap Both Clusters
# ============================================

# Bootstrap on-prem (ARM64 Pi cluster)
make bootstrap-on-prem

# Bootstrap cloud cluster
make bootstrap-on-cloud

# Verify both clusters are ready
terraform workspace select on-prem
kubectl get nodes
terraform workspace select on-cloud
kubectl get nodes

# ============================================
# DAY 3: Deploy Full Stacks
# ============================================

# Full deploy to on-prem
make apply-on-prem

# Full deploy to cloud
make apply-on-cloud

# Verify both clusters
terraform workspace select on-prem
kubectl get pods -A
terraform workspace select on-cloud
kubectl get pods -A

# ============================================
# DAY 4: Update One Cluster Only
# ============================================

# Update only on-prem (e.g., add Home Assistant)
echo 'services = { home_assistant = true }' >> terraform.on-prem.tfvars
make apply-on-prem

# Cloud cluster unchanged
```

---

## Configuration Differences by Cluster

| Setting | On-Prem (Raspberry Pi) | Cloud (VPS) |
|---------|------------------------|-------------|
| CPU Architecture | ARM64 | AMD64 |
| Storage Class | hostpath / Longhorn | nfs-csi / cloud storage |
| MetalLB | Enabled (bare metal) | Disabled (cloud LB) |
| DNS Provider | Hurricane Electric | Hurricane Electric (or Cloudflare) |
| Services | Home automation, monitoring | Web apps, APIs |
| Resource Limits | Conservative (Pi constraints) | Generous (cloud resources) |

---

## Troubleshooting Multi-Cluster

### Wrong Workspace

If you apply to the wrong cluster:

```bash
# Check current workspace
terraform workspace show

# Switch to correct workspace
terraform workspace select on-prem

# Re-apply
make apply-on-prem
```

### State Conflicts

If state files get out of sync:

```bash
# Refresh state from remote cluster
terraform workspace select on-prem
terraform refresh

# Or re-apply to reconcile
make apply-on-prem
```

### Missing kubeconfig

If you get "kubeconfig not found" errors:

```bash
# Check kubeconfig exists
ls -la ~/.kube/

# Create kubeconfig for the cluster
kubectl config view --flatten > ~/.kube/on-prem-config

# Verify access
kubectl --kubeconfig ~/.kube/on-prem-config cluster-info
```

---

## Related Documentation

- [Configuration Variables](docs/reference/VARIABLES.md) - All configuration options
- [Authentication Guide](docs/guides/AUTHENTICATION-GUIDE.md) - LDAP, OIDC, Basic Auth setup
- [Testing Guide](docs/guides/TESTING-GUIDE.md) - Testing multi-cluster deployments
- [Service Integration Template](docs/development/SERVICE-INTEGRATION-TEMPLATE.md) - Adding new services
- [Architecture Decisions](docs/development/ARCHITECTURE-DECISIONS.md) - Core principles and ADRs

---

## Quick Reference

```bash
# Cluster management
terraform workspace list           # List all workspaces
terraform workspace new <name>     # Create new workspace
terraform workspace select <name>  # Switch workspace
terraform workspace show           # Show current workspace

# Bootstrap (Stage 1)
make bootstrap-on-prem
make bootstrap-on-cloud

# Full deploy (Stage 2)
make apply-on-prem
make apply-on-cloud

# Auto-approve variants
make bootstrap-auto-on-prem
make apply-auto-on-cloud

# Destroy
make destroy-on-prem
make destroy-on-cloud
```

---

## Support

- **Issues**: [GitHub Issues](https://github.com/gannino/tf-kube-any-compute/issues)
- **Discussions**: [GitHub Discussions](https://github.com/gannino/tf-kube-any-compute/issues)
- **Author**: Giovanni Annino - [@gannino](https://github.com/gannino)
