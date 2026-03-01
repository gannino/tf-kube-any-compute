# Memory

## Project

**tf-kube-any-compute** - Universal Kubernetes infrastructure platform

- Deploys 21+ production-grade services across any K8s distribution (K3s, MicroK8s, EKS, GKE, AKS)
- Multi-architecture support (ARM64/AMD64) with auto-detection
- Core files: main.tf (1,229 lines), variables.tf (1,791 lines), locals.tf (1,396 lines), outputs.tf (677 lines)

## User Goals & Workflow

- **Goals**: Active Development, Maintenance & Stability, Learning & Exploration, Production Operations
- **Workflow**: Feature-Driven, Bug-Fix Focus, Exploratory, Ops-Driven
- **Focus Areas**: Service Integration, Testing & Validation, Documentation, Debugging & Troubleshooting
- **Tools**: GitHub Actions, Homelab Tools (Proxmox, Ansible, Raspberry Pi clusters)

## Core Architectural Patterns (8 Critical Patterns)

### 1. Configuration Override Hierarchy (5-Level Priority)

1. System defaults (hardcoded)
2. Service defaults (per-service baseline)
3. User variables (terraform.tfvars)
4. Service overrides (fine-grained control)
5. Auto-detection (runtime cluster analysis)

### 2. Module Count Pattern

```hcl
module "traefik" {
  count = local.services_enabled.traefik ? 1 : 0
}
```

**Implication**: Module outputs are lists, always use `[0]` index: `module.traefik[0].namespace`

### 3. Two-Step Authentication Deployment

- **Step 1**: Deploy core services with `middleware_overrides.enabled = false`
- **Step 2**: Change to `enabled = true` and reapply
- **Reason**: Traefik CRDs must exist before middleware resources

### 4. CPU Architecture Auto-Detection

- Queries cluster nodes for `kubernetes.io/arch` labels
- Handles mixed clusters automatically
- Distribution detection: k3s, microk8s, standard k8s
- Fallback: amd64 in CI mode

### 5. DNS Provider = Certificate Resolver Name

- Resolvers named after DNS providers: "cloudflare", "route53", "hurricane"
- Clear naming, easy per-service override
- Config: `service_overrides.traefik.dns_providers`

### 6. Storage Class Selection Logic

Priority chain:

1. User-specified `storage_class` override
2. NFS CSI if `use_nfs_storage = true`
3. HostPath if `use_hostpath_storage = true`
4. Auto-detected default storage class
5. "default" storage class

### 7. Module Reference Pattern for Service Discovery

```hcl
# Redis service exposes outputs
output "service_host" {
  value = "${var.name}.${var.namespace}.svc.cluster.local"
}

# Authelia auto-discovers Redis
module "authelia" {
  redis_module_reference = module.redis[0].service_host
}
```

### 8. Workspace-Aware Kubeconfig Detection

```hcl
kubeconfig = var.kubeconfig_path != "" ? var.kubeconfig_path :
             var.ci_mode ? env("KUBECONFIG") :
             var.workspace_prefix != "" ? "~/.kube/${workspace_prefix}-config" :
             "~/.kube/config"
```

## Service Categories

**Core Infrastructure**: Traefik, MetalLB, NFS CSI, HostPath, Node Feature Discovery

**Storage**: Longhorn, Rook Ceph (block/object/file storage)

**Monitoring**: Prometheus CRDs, Prometheus Stack, Grafana, Loki, Promtail, Kube-State-Metrics, Metrics Server

**Platform**: Vault, Consul, Portainer, Gatekeeper, Authelia, Redis, Headlamp

**Virtualization**: KubeVirt

**Automation**: Home Assistant, openHAB, Homebridge, Node-RED, n8n

## Deployment Patterns

**Helm Chart** (most services): `helm_release` with template values

**Native Kubernetes** (Redis, n8n): Direct `kubernetes_deployment`, `kubernetes_service`

## Current Work

- **Branch**: `feature/add-rook-storage`
- **Recent**: Adding Rook Ceph distributed storage with CSI integration
- **Status**: Implementation phase, reviewing architecture

## Key File Locations

- **locals.tf**: Configuration computation engine (1,396 lines) - architecture detection, storage selection, override hierarchy
- **main.tf**: Module orchestration with count pattern
- **outputs.tf**: Service URLs, access info, debug outputs
- **terraform.tfvars.example**: Complete configuration template (38KB)

## Quick Commands

```bash
make init          # Terraform init + validate + format
make plan          # Preview changes
make apply         # Deploy
make test-safe     # Fast validation (~2-5 min)
make test-all      # Comprehensive tests
make debug         # Cluster diagnostics
```

## Important Gotchas

1. **CRD Dependencies**: Services using CRDs must depend on CRD deployment first
2. **Helm Timeouts**: Simple 180s, Monitoring 900s, Vault/Consul 600s
3. **Mixed Clusters**: Auto-configure with `auto_mixed_cluster_mode = true`
4. **Secret Management**: Auto-generated passwords when variables empty
5. **Workspace Naming**: `{workspace}-{service}-system` format
6. **Storage Classes**: Always verify exists before using

## Now

- Rook Ceph deployment: Fixed template interpolation, cleanup jobs recreation. Cluster coming up on ARM64 (Raspberry Pi). Waiting for mon/OSD pods.

## Open Threads

- Rook Ceph dashboard accessibility (502 Bad Gateway) - waiting for cluster to stabilize
- OSD creation with dynamic node discovery (directory-based storage)

## Recent Decisions

- Use complete template files instead of partial interpolation for complex YAML
- Remove `ttl_seconds_after_finished` from Jobs to prevent Terraform recreation loops
- Dynamic node discovery via `data.kubernetes_nodes` instead of hardcoded names

## Blockers

- Mon pods pending (scheduler anti-affinity issue on raspberrypi3)

## Documentation Structure

### Guides (`docs/guides/`)

- **AUTHENTICATION-GUIDE.md** - Basic Auth, LDAP setup (2-step deployment process)
- **AUTOMATION-SERVICES-GUIDE.md** - Home Assistant, openHAB, Homebridge, Node-RED, n8n
- **AUTOMATION-SERVICES-FIXES.md** - Troubleshooting automation services
- **MIDDLEWARE-GUIDE.md** - Traefik middleware configuration
- **SECURITY-HARDENING.md** - Security best practices
- **TESTING-GUIDE.md** - Comprehensive testing framework

### Reference (`docs/reference/`)

- **VARIABLES.md** - Complete variable documentation
- **DNS-PROVIDER-CERT-RESOLVERS.md** - SSL certificate management
- **LDAP-AUTHENTICATION-METHODS.md** - LDAP integration (JumpCloud, AD, OpenLDAP)
- **VERSION-MANAGEMENT.md** - Version management system

### Development (`docs/development/`)

- **CONTRIBUTING.md** - How to contribute
- **CONTRIBUTOR-QUICK-START.md** - Quick start for contributors
- **SERVICE-INTEGRATION-TEMPLATE.md** - Template for adding new services
- **ARCHITECTURE-DECISIONS.md** - Core principles, ADRs, coding standards
- **TERRAFORM-DOCS-AUTOMATION.md** - Documentation automation (pre-commit hook)

### Archive (`docs/archive/`)

- Breaking changes, deprecated features, historical roadmaps

### AI Prompts (`docs/prompts/`)

- LLM-specific prompts for contribution, CI/CD creation, module development
- Supports: Claude, GPT-4, Gemini, DeepSeek, Ollama

## Key Architecture Decisions

### No Hardcoding Principle

**Never hardcode values in .tf files** - Use terraform.tfvars for explicit values, locals.tf for smart selection

**Pattern**:

```hcl
# variables.tf - No default, just definition
variable "helm_timeout" {
  description = "Helm deployment timeout in seconds"
  type        = number
}

# terraform.tfvars - Environment-specific
helm_timeout = 600

# locals.tf - Smart selection with override hierarchy
locals {
  helm_timeouts = {
    prometheus = coalesce(
      try(var.service_overrides.prometheus.helm_timeout, null),
      var.helm_timeout,
      900  # Fallback
    )
  }
}
```

### Service Integration Standards

### Service Integration Standards

1. Follow standard module structure (main.tf, variables.tf, outputs.tf, locals.tf, version.tf, templates/)
2. Add service enablement flag to `services` object
3. Add service to `locals.tf` for configuration merge logic
4. Add module in `main.tf` with `count` pattern
5. Add outputs to `outputs.tf`
6. Add helm timeout to `helm_timeouts` object
7. Write unit tests in `tests-*.tftest.hcl`
8. Create comprehensive module README
9. Add usage example to `terraform.tfvars.example`
