# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**tf-kube-any-compute** is a universal Kubernetes infrastructure platform built entirely in Terraform. It deploys **21+ production-grade services** (monitoring, security, automation, platform services) across any Kubernetes distribution (K3s, MicroK8s, EKS, GKE, AKS) and any CPU architecture (ARM64/AMD64, including mixed clusters).

**Key value proposition**: Platform-agnostic, architecture-aware, homelab-focused infrastructure with intelligent auto-detection and flexible configuration hierarchy.

**Recent additions** (2025-2026):

- **Redis** - Native Kubernetes deployment for caching and session storage
- **Authelia** - SSO/2FA with LDAP and OIDC integration
- **Headlamp** - Kubernetes dashboard with LDAP authentication
- **KubeVirt** - Virtual machine management (renamed from helm-kubevirt to kubevirt-operator)

## Common Development Commands

```bash
# Initialize and validate
make init                  # Terraform init + validate + format check
terraform workspace new <name>  # Create environment workspace

# Planning and deployment
make plan                  # Preview infrastructure changes
make apply                 # Deploy infrastructure

# Testing (non-destructive, fast feedback)
make test-safe             # Format, validate, lint only
make test-unit             # Terraform unit tests
make test-scenarios        # Real-world scenario tests

# Full testing suite
make test-all              # Comprehensive tests (includes integration/security/performance)

# Diagnostics and debugging
make debug                 # Comprehensive cluster diagnostics
./scripts/debug.sh         # Detailed cluster health check

# Linting and formatting
make lint                  # Optimized linting (~2-5 min)
make fmt                   # Format Terraform files
terraform fmt -recursive   # Format all .tf files
```

## High-Level Architecture

### Root Module Structure (4,476 lines total)

- **main.tf**: Module orchestration with `count` pattern for conditional service enablement
- **variables.tf**: All input variables (1,575 lines, alphabetically organized)
- **locals.tf**: Configuration computation engine - architecture detection, storage selection, override hierarchy (1,170 lines)
- **outputs.tf**: Service URLs, access information, debug outputs (677 lines)

### Service Module Pattern

Every service follows this consistent structure:

```
helm-{service}/
├── main.tf              # Helm release + core resources
├── variables.tf         # Module inputs with validation
├── outputs.tf           # Module outputs
├── locals.tf            # Local computations
├── version.tf           # Provider requirements
├── templates/           # Helm values templates (.yaml.tpl)
├── traefik-ingress.tf   # Ingress configuration (if applicable)
├── pvc.tf              # Persistent volume claims (if applicable)
├── limit_range.tf      # Resource limits (if applicable)
└── README.md           # Comprehensive documentation
```

**Deployment Patterns**:

1. **Helm Chart Deployment** (most services)
   - Uses `helm_release` resource
   - Template-based values via `.yaml.tpl` files
   - Chart version pinning for reproducibility

2. **Native Kubernetes Deployment** (Redis, some specialized services)
   - Uses `kubernetes_deployment`, `kubernetes_service`, `kubernetes_configmap`
   - Direct resource management without Helm abstraction
   - Simpler for stateless services or custom deployments

**When to use native Kubernetes vs Helm**:

- Use **Helm** for complex services with many dependencies (Prometheus, Grafana, Traefik)
- Use **native Kubernetes** for simpler services or when Helm chart doesn't exist (Redis)
- Documentation in module README should clearly indicate which pattern is used

### Critical Architectural Patterns

#### 1. Configuration Override Hierarchy (5-Level Priority System)
Configuration is applied in order, with later levels overriding earlier ones:
1. **System defaults** - Hardcoded base values
2. **Service defaults** - Per-service baseline settings
3. **User variables** - terraform.tfvars configuration
4. **Service overrides** - Fine-grained per-service control via `service_overrides` object
5. **Auto-detection** - Runtime cluster analysis (architecture, storage classes)

**Implication**: Always use the override hierarchy rather than bypassing it with custom logic.

#### 2. Two-Step Authentication Deployment
**Problem**: Traefik CRDs must exist before middleware resources can be created.

**Solution**:
- **Step 1**: Deploy core services with `middleware_overrides.enabled = false`
- **Step 2**: Change to `enabled = true` and reapply

**Code location**: `terraform.tfvars.example:138` shows this pattern with clear comments.

#### 3. CPU Architecture Auto-Detection
The system queries cluster nodes to detect architecture (ARM64/AMD64) and identifies mixed clusters automatically.

**Implementation**: `locals.tf` contains `data "kubernetes_nodes"` analysis that extracts `kubernetes.io/arch` labels.

**Mixed cluster handling**: When multiple architectures detected, automatically disables architecture-specific scheduling for cluster-wide services.

#### 4. DNS Provider = Certificate Resolver Name
**Architectural decision**: Certificate resolvers are named after DNS providers (e.g., "cloudflare", "route53", "hurricane") rather than generic names like "wildcard".

**Benefits**: Clear certificate resolver names, easy per-service override, no confusion about which DNS provider backs which resolver.

**Configuration**: `service_overrides.traefik.dns_providers` + `cert_resolvers` objects in terraform.tfvars.

#### 5. Storage Class Selection Logic
Storage is selected via priority chain:
1. User-specified `storage_class` override
2. NFS CSI if `use_nfs_storage = true`
3. HostPath if `use_hostpath_storage = true`
4. Auto-detected default storage class
5. "default" storage class as last resort

**Storage profiles**: NFS CSI supports 4 mount option templates: `default`, `performance`, `reliable`, `low_latency` (configured via `nfs_storage_class_config`).

#### 6. Module Count Pattern
Top-level module enablement uses `count` pattern:

```hcl
module "traefik" {
  count = local.services_enabled.traefik ? 1 : 0
}
```

**Implication**: When referencing module outputs, always use `[0]` index: `module.traefik[0].namespace`

#### 7. Module Reference Pattern for Service Discovery
Services can automatically discover and reference other services via module outputs:

```hcl
# Redis service exposes outputs
output "service_host" {
  description = "Redis service hostname for service discovery"
  value       = "${var.name}.${var.namespace}.svc.cluster.local"
}

# Authelia automatically references Redis
module "authelia" {
  redis_enabled          = true
  redis_module_reference = module.redis[0].service_host  # Automatic discovery
}
```

**Benefits**:
- No manual hostname configuration
- Consistent service naming across environments
- Works seamlessly with workspace-based deployments
- Eliminates hardcoding of service endpoints

**Services with module reference support**:
- Authelia → Redis (automatic session storage configuration)
- Headlamp → Authelia (OIDC authentication)
- Monitoring stack → Prometheus (metrics federation)

#### 8. Workspace-Aware Kubeconfig Detection
Services that require external kubectl access (like KubeVirt namespace cleanup) automatically detect kubeconfig files based on workspace prefix:

```hcl
# Matches main provider.tf logic
workspace_prefix  = "prod"   # Uses ~/.kube/prod-config
ci_mode         = false     # Uses KUBECONFIG environment variable
kubeconfig_path = ""        # Explicit path overrides auto-detection
```

**Implementation pattern**:
1. Check `kubeconfig_path` if explicitly provided
2. If `ci_mode = true`, use `KUBECONFIG` environment variable
3. Otherwise, construct path from `workspace_prefix`: `~/.kube/${workspace_prefix}-config`
4. Fallback to default kubeconfig: `~/.kube/config`

**Services using this pattern**: KubeVirt namespace cleanup, external health checks

### Service Categories and Dependencies

**Core Infrastructure** (typically required):

- **Node Feature Discovery** → Detects hardware and storage
- **Storage** (NFS CSI / HostPath) → Persistent volumes
- **MetalLB** → Load balancer for bare metal
- **Traefik** → Ingress controller with SSL

**Monitoring Stack**:

- **Prometheus CRDs** → Required before Prometheus Stack
- **Prometheus Stack** → Metrics collection (15 min timeout)
- **Grafana** → Visualization (depends on Prometheus)
- **Kube-State-Metrics** → Kubernetes object metrics
- **Metrics Server** → HPA support

**Platform Services** (optional):

- **Vault** + **Consul** → Secrets management and service mesh
- **Portainer** → Container management UI
- **Authelia** → SSO/2FA authentication (with LDAP, OIDC, Duo support)
- **Redis** → In-memory data store (caching, sessions, message queuing)
- **Gatekeeper** → OPA policy engine
- **Headlamp** → Kubernetes dashboard (with LDAP/OIDC integration)
- **KubeVirt** → Virtual machine management

**Automation Services** (optional):

- **Home Assistant** / **openHAB** / **Homebridge** / **Node-RED** / **n8n**

### Pre-commit Hooks Optimization

Full pre-commit runs ~2-5 minutes (down from ~50 minutes) due to:
- Smart TFLint with reduced rule set
- Parallel execution where possible
- Optimized check ordering

**Key hooks**: terraform fmt, terraform-docs (auto-generates module READMEs), tflint, terraform validate, checkov, terrascan, detect-secrets.

## Important Gotchas

1. **CRD Dependencies**: Services using CRDs (Prometheus, Gatekeeper, Traefik middleware) must depend on CRD deployment first. Use explicit `depends_on` or deploy CRDs as separate modules.

2. **Helm Timeouts**: Complex services need longer timeouts:
   - Simple services: 180s (3 min)
   - Monitoring stack: 900s (15 min)
   - Vault/Consul: 600s (10 min)
   - Configure via `helm_timeouts` object.

3. **Mixed Clusters**: Not all services work on all architectures. Use `auto_mixed_cluster_mode = true` to let system auto-configure, or use `cpu_arch_override` for per-service control.

4. **Secret Management**: Auto-generated passwords are created when variables are empty. Capture passwords from `terraform output` after first deployment.

5. **Workspace Naming**: Namespaces and releases are prefixed with workspace name: `{workspace}-{service}-system`. Use Terraform workspaces for environment isolation.

6. **Service Enablement**: Check `local.services_enabled.<service>` before referencing a module in main.tf.

7. **Authentication Order**: Deploy core services first, then enable middleware. The two-step deployment prevents CRD dependency failures.

8. **Storage Class Existence**: Always verify storage class exists before using it. The system auto-detects available storage classes.

9. **Module Output Access**: When using `count` pattern, module outputs are lists: `module.service[0].output_name`.

10. **DNS Provider Configuration**: DNS provider credentials in `service_overrides.traefik.dns_providers.<name>.config` - Hurricane Electric auto-generates config, others require API tokens.

## Configuration File Patterns

### Service Enablement (Modern Approach)
```hcl
services = {
  traefik     = true
  metallb     = true
  prometheus  = true
  grafana     = true
  consul      = false
  vault       = false
  authelia    = true
  kubevirt    = true
}
```

### Per-Service Overrides (Most Powerful)
```hcl
service_overrides = {
  traefik = {
    storage_class = "nfs-csi-safe"
    cpu_limit = "200m"
    enable_dashboard = true
    dns_providers = {
      primary = {
        name = "cloudflare"  # Creates "cloudflare" cert resolver
        config = {
          CF_DNS_API_TOKEN = "your_token"
        }
      }
    }
    cert_resolvers = {
      cloudflare = {
        challenge_type = "dns"
        dns_provider = "cloudflare"
      }
    }
  }
  prometheus = {
    storage_class = "hostpath"
    enable_ingress = true
  }
}
```

### Authentication Configuration
```hcl
middleware_overrides = {
  enabled = true  # Master switch - false for initial deployment
  all = {
    enable_rate_limit = true
    enable_ip_whitelist = true
  }
  traefik = {
    disable_auth = false  # Enable auth for dashboard
  }
  prometheus = {
    disable_auth = false  # Enable auth for Prometheus
  }
  grafana = {
    # Grafana has built-in auth, no middleware needed
  }
}
```

## Development Workflow

1. **Make changes** to module files
2. **Run `make test-safe`** for fast validation feedback (~2-5 min)
3. **Check pre-commit** with `make lint`
4. **Update documentation** - terraform-docs auto-generates via pre-commit hook
5. **Test on both architectures** if applicable (ARM64 and AMD64)
6. **Update CHANGELOG** for user-visible changes
7. **Use conventional commits**: `feat(scope): description`, `fix(scope): description`, etc.

## Testing Strategy

- **Unit tests** (`tests.tftest.hcl`): Architecture detection, storage selection, configuration merge logic
- **Scenario tests** (`test-scenarios.tftest.hcl`): ARM64 Pi deployment, AMD64 cloud, mixed clusters
- **Integration tests** (`scripts/integration-tests.sh`): Service health, ingress connectivity, authentication
- **Performance tests** (`scripts/performance-test.js`): Load testing with k6

## Module Integration Checklist

When adding new service modules:
1. Follow standard module structure (main.tf, variables.tf, outputs.tf, locals.tf, version.tf, templates/)
2. Add service enablement flag to `services` object in variables.tf
3. Add service to `locals.tf` for configuration merge logic
4. Add module instantiation in `main.tf` with `count` pattern
5. Add outputs to `outputs.tf`
6. Add helm timeout to `helm_timeouts` object if needed
7. Write unit tests in dedicated `tests-*.tftest.hcl` file
8. Create comprehensive module README
9. Add usage example to `examples/` directory

## Key Files Reference

### Core Configuration Files

- **terraform.tfvars.example** (38KB): Complete configuration template with inline comments
- **Makefile** (495 lines): All automation commands
- **locals.tf** (1,170 lines): Architecture detection, override hierarchy, storage logic
- **README.md** (27KB+): User-facing project overview

### Documentation Files

- **CONTRIBUTING.md** (19KB): Comprehensive contribution guidelines
- **CONTRIBUTOR-ROADMAP.md** (NEW): Strategic improvement roadmap and integration opportunities
- **CLAUDE.md** (this file): AI assistant guidance and architectural patterns
- **docs/development/ARCHITECTURE-DECISIONS.md** (NEW): Core principles, ADRs, and coding standards
- **CHANGELOG.md**: Version history and user-visible changes

### Documentation Structure

- **docs/guides/**: How-to guides (authentication, automation, security, testing)
- **docs/reference/**: Reference documentation (DNS providers, LDAP, variables, versions)
- **docs/development/**: Developer guides (contributing, service integration, quick start)
- **docs/prompts/**: AI assistant prompts for various LLMs (Claude, GPT-4, Gemini, etc.)
- **docs/archive/**: Historical documentation (deprecated features, old roadmaps)

### Module-Specific Files

- **redis/README.md**: Native Kubernetes deployment pattern (not Helm)
- **helm-authelia/README.md**: LDAP/OIDC integration with module reference pattern
- **helm-headlamp/README.md**: LDAP authentication guide and OIDC configuration
- **kubevirt-operator/README.md**: Renamed from helm-kubevirt, includes cleanup automation

### AI Assistant Configuration

- **.clinerules/**: AI assistant rules (product, structure, tech, guidelines, development)
- **.amazonq/rules/memory-bank/**: AI assistant rules (product, structure, tech, guidelines, contribution)

### Recent Documentation Audit (2026-02)

**Services Audited**: Redis, Authelia, Headlamp, KubeVirt

**Quality Scores**:
- Redis: Newly fixed (Helm → native Kubernetes documentation)
- Authelia: 95/100 (added redis_module_reference documentation)
- Headlamp: 92/100 (added OIDC Configuration table)
- KubeVirt: 92/100 (fixed source path, added missing variables)

**Common Issues Found**:

1. Documentation not matching implementation (Helm vs native Kubernetes)
2. Missing variable documentation (redis_module_reference, oidc_config)
3. Outdated module paths (kubevirt-operator renamed from helm-kubevirt)
4. Missing specialized configuration sections (OIDC, LDAP integration)

**Documentation Patterns**:

- Module READMEs auto-generated via terraform-docs (pre-commit hook)
- Specialized guides linked from main README for complex topics
- Configuration examples in terraform.tfvars.example with inline comments
- Implementation docs preserved separately when they add unique value

## Documentation Quality Standards

Based on the recent documentation audit (2026-02), all module READMEs should include:

### Essential Sections

1. **Features List**: Bullet points of key capabilities with emoji icons
2. **Usage Examples**: Both basic and advanced configuration examples
3. **Configuration Variables**: Complete table with types, defaults, and descriptions
4. **Architecture Support**: Clear indication of ARM64/AMD64/mixed cluster support
5. **Troubleshooting**: Common issues and solutions with diagnostic commands

### Specialized Sections (as needed)

1. **Integration Patterns**: Module reference examples for service discovery
2. **Authentication Guide**: LDAP, OIDC, or other auth mechanisms
3. **Storage Configuration**: PVC requirements, storage class recommendations
4. **Monitoring Setup**: ServiceMonitor configuration, Prometheus integration
5. **Namespace Cleanup**: Special cleanup procedures if needed

### Documentation Anti-Patterns to Avoid

1. **Implementation Mismatch**: Documentation describing Helm when code uses native Kubernetes
2. **Missing Variables**: Documented variables not matching variables.tf
3. **Outdated Paths**: References to renamed modules or moved files
4. **Incomplete Examples**: Examples that don't demonstrate key features
5. **Broken Links**: References to non-existent documentation or guides

### Quality Checklist

Before marking documentation as complete:

- [ ] All variables in variables.tf are documented in README
- [ ] Examples demonstrate all key features
- [ ] Architecture support clearly stated
- [ ] Service dependencies documented
- [ ] Troubleshooting section covers common issues
- [ ] Cross-references to specialized guides are valid
- [ ] terraform.tfvars.example includes service configuration
- [ ] Module outputs are documented with use cases

## Contributor Guidance

### Strategic Improvement Areas

The **[CONTRIBUTOR-ROADMAP.md](CONTRIBUTOR-ROADMAP.md)** document outlines high-impact improvement areas:

**Developer Experience & Automation**:

- Pre-commit hook optimization (parallel execution)
- Automated PR validation workflows
- Interactive setup scripts for new contributors
- Module validation tooling

**Service Ecosystem Expansion**:

- **Priority 1**: Falco (security), ArgoCD (GitOps), Thanos (long-term storage)
- **Priority 2**: Longhorn (storage), MinIO (object storage), PostgreSQL Operator

**Testing & Quality Assurance**:

- Module-specific test suites
- Performance baseline testing
- Upgrade path validation
- Chaos engineering scenarios

**Documentation & Knowledge Management**:

- Architecture Decision Records (ADRs)
- Service-specific troubleshooting guides
- Video tutorials for common scenarios
- Interactive documentation examples

### Contribution Pathways

**Beginner-Friendly** (Good First Issues):

- Add missing examples to module READMEs
- Create troubleshooting guides
- Improve inline code comments
- Add unit tests for untested logic

**Intermediate Contributions**:

- Add new services from roadmap
- Improve existing service modules
- Enhance architecture detection
- Implement GitOps patterns

**Advanced Contributions**:

- Multi-cluster management
- Advanced service mesh integration
- Edge computing optimizations
- Policy as code frameworks

### Quick Wins for New Contributors

1. **Documentation Improvements**: Add missing variable documentation, create troubleshooting guides
2. **Test Coverage**: Add unit tests for configuration logic, scenario tests for your deployment
3. **Tooling**: Create helpful Makefile targets, improve script error handling
4. **Examples**: Add configuration examples for different deployment scenarios

### Success Metrics

- Test coverage: >80% for new modules
- Documentation completeness: All sections filled
- Pre-commit runtime: <2 minutes for validation
- PR response time: <48 hours for initial review
- Security scans: Zero high/critical findings

## Recent Learnings & Patterns (2026)

### Documentation Audit Insights

From the comprehensive documentation audit (Redis, Authelia, Headlamp, KubeVirt):

**Common Issues Discovered**:

1. **Implementation-Documentation Mismatch**: Redis README described Helm deployment but code used native Kubernetes resources
   - **Fix**: Always verify README matches actual implementation pattern
   - **Pattern Check**: Look for `helm_release` vs `kubernetes_deployment` in main.tf

2. **Missing Module Reference Documentation**: Authelia supported automatic Redis discovery but wasn't documented
   - **Fix**: Document module output references for service integration patterns
   - **Pattern**: When Service B depends on Service A, document `module.service_a[0].output_name` usage

3. **Incomplete Variable Documentation**: OIDC configuration variables missing from main reference tables
   - **Fix**: Ensure all variables in variables.tf appear in README documentation
   - **Pattern**: Group related variables in subsections (e.g., "OIDC Configuration")

4. **Outdated Module Paths**: KubeVirt renamed but README still referenced old path
   - **Fix**: Update source paths and examples when modules are renamed
   - **Pattern**: Use `grep -r "old-module-name"` to find all references

### Module Integration Patterns

**When Adding Service Dependencies**:

1. **Module Reference Pattern** (preferred):

```hcl
module "service_b" {
  dependency_module_reference = module.service_a[0].output_name
}
```

1. **Manual Configuration Pattern** (fallback):

```hcl
module "service_b" {
  dependency_host = "service-a.namespace.svc.cluster.local"
}
```

**Document Both Patterns** in module README with clear preference and benefits.

### Native Kubernetes vs Helm Decision Tree

When creating new service modules, ask:

1. **Does a high-quality Helm chart exist?**
   - Yes → Use Helm (fewer resources to manage)
   - No → Consider native Kubernetes

2. **Is the service simple and stateless?**
   - Yes → Native Kubernetes acceptable
   - No → Use Helm for complex dependency management

3. **Do we need deep customization?**
   - Yes → Native Kubernetes may be simpler
   - No → Helm values templates sufficient

**Document the decision in the module README** with rationale.

### Workspace-Aware Configuration Pattern

For services that need external cluster access (health checks, cleanup scripts):

```hcl
variable "workspace_prefix" {
  description = "Workspace prefix for kubeconfig file selection"
  type        = string
  default     = ""
}

variable "ci_mode" {
  description = "Running in CI mode (kubeconfig handled externally)"
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "Explicit kubeconfig path (overrides automatic detection)"
  type        = string
  default     = ""
}
```

**Implementation**:

```hcl
locals {
  kubeconfig = var.kubeconfig_path != "" ? var.kubeconfig_path :
               var.ci_mode ? env("KUBECONFIG") :
               var.workspace_prefix != "" ? "~/.kube/${var.workspace_prefix}-config" :
               "~/.kube/config"
}
```

**Documentation Requirement**: Clearly explain this matches main provider.tf logic for consistency.

### Pre-commit Hook Optimization Patterns

Current runtime: ~2-5 minutes (down from ~50 minutes)

**Optimization Techniques Used**:

1. **TFLint Rule Reduction**: Only essential rules, focused on changed files
2. **Parallel Execution**: Independent hooks run simultaneously
3. **Smart Ordering**: Fast checks first (fmt, validate), slow checks last (security scanning)

**When Adding New Hooks**:

- Prefer fast checks (<30 seconds)
- Profile hook execution time before adding
- Consider making expensive hooks opt-in or CI-only
- Document runtime impact in pre-commit configuration

### Testing Strategy Evolution

**Current Test Coverage**:

- Unit tests: Architecture detection, configuration merge, storage selection
- Scenario tests: ARM64/AMD64/mixed clusters, MicroK8s/K3s/EKS
- Integration tests: Service health, connectivity, authentication
- Security scanning: Checkov, Terrascan, detect-secrets

**Gaps Identified**:

- Missing module-specific test suites (e.g., `tests-prometheus.tftest.hcl`)
- No performance baseline tests
- Limited upgrade path testing
- No chaos engineering scenarios

**Priority Additions**:

1. **Module-Specific Tests**: Each service should have dedicated test file
2. **Performance Baselines**: Establish resource usage per service
3. **Upgrade Validation**: Test service upgrades between major versions
4. **Failure Scenarios**: Pod failures, network partitions, storage issues

## Additional Resources

### For AI Assistants

When working with this codebase, reference:

1. **This file (CLAUDE.md)**: Architectural patterns and critical gotchas
2. **CONTRIBUTING.md**: Development workflow and testing requirements
3. **CONTRIBUTOR-ROADMAP.md**: Strategic priorities and improvement areas
4. **Module READMEs**: Service-specific documentation and examples
5. **terraform.tfvars.example**: Complete configuration reference

### For New Contributors

Start here:

1. **README.md**: Project overview and quick start
2. **CONTRIBUTOR-QUICK-START.md**: Fast path to contributions
3. **docs/development/SERVICE-INTEGRATION-TEMPLATE.md**: Module integration checklist
4. **CONTRIBUTOR-ROADMAP.md**: High-impact improvement opportunities

### For Maintainers

Key references:

1. **CHANGELOG.md**: Version history and release notes
2. **docs/archive/**: Historical context for deprecated features
3. **Security scans**: Review in `security-results/` directory
4. **Test results**: Check GitHub Actions or CI logs
