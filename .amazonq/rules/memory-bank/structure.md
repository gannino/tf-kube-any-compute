# Project Structure - tf-kube-any-compute

## Directory Organization

### Root Level - Core Terraform
```
/
├── main.tf              # Service orchestration and module instantiation
├── locals.tf            # Configuration logic, override hierarchy, architecture detection
├── variables.tf         # Input definitions (200+ variables)
├── outputs.tf           # Output definitions with debug information
├── provider.tf          # Kubernetes, Helm, kubectl provider configuration
├── versions.tf          # Terraform and provider version constraints
├── coredns-hpa.tf       # CoreDNS autoscaling to prevent DNS outages
└── terraform.tfvars     # User configuration (gitignored)
```

### Helm Modules - Service Deployments (20+ modules)
```
/helm-{service}/
├── main.tf              # Helm release configuration
├── variables.tf         # Module input variables
├── outputs.tf           # Module outputs
├── locals.tf            # Module-specific logic
├── version.tf           # Provider versions
├── limit_range.tf       # Resource limits for namespace
├── static-pv.tf         # Static persistent volumes (optional)
├── traefik-ingress.tf   # Ingress route configuration (optional)
└── templates/           # Helm values templates
    └── {service}-values.yaml.tpl
```

**Key Modules:**
- `helm-traefik/` - Ingress controller with middleware system
- `helm-prometheus-stack/` - Monitoring with Grafana integration
- `helm-consul/` - Service mesh and discovery
- `helm-vault/` - Secrets management with auto-unsealing
- `helm-metallb/` - Load balancer for bare metal
- `helm-nfs-csi/` - NFS storage driver
- `helm-grafana/` - Standalone dashboards
- `home-assistant/`, `openhab/`, `homebridge/` - Home automation
- `helm-node-red/` - IoT automation with palette installer
- `n8n/` - Workflow automation

### Testing Framework
```
/
├── tests.tftest.hcl                    # Unit tests (architecture, storage, helm)
├── test-scenarios.tftest.hcl           # Scenario tests (ARM64, cloud, mixed)
├── tests-architecture.tftest.hcl       # Architecture detection tests
├── tests-storage.tftest.hcl            # Storage configuration tests
├── tests-services.tftest.hcl           # Service enablement tests
├── tests-mixed-cluster.tftest.hcl      # Mixed architecture tests
├── tests-automation-services.tftest.hcl # Automation services tests
└── test-configs/                       # Test configuration files
    ├── minimal.tfvars
    ├── raspberry-pi.tfvars
    ├── mixed-cluster.tfvars
    ├── cloud.tfvars
    └── production.tfvars
```

### Scripts - Automation & Diagnostics (30+ scripts)
```
/scripts/
├── debug.sh                        # Comprehensive cluster diagnostics
├── ensure-coredns.sh               # DNS health verification
├── check-vault.sh                  # Vault-specific diagnostics
├── check-ingress.sh                # Ingress and networking analysis
├── integration-tests.sh            # Live infrastructure testing
├── performance-test.js             # k6 performance testing
├── security-scan.sh                # Multi-tool security scanning
├── test-automation-services.sh     # Automation services validation
├── version-manager.sh              # Version synchronization
├── release.sh                      # Release automation
└── pre-release-checklist.sh        # Release validation
```

### Documentation
```
/
├── README.md                           # Main documentation
├── VARIABLES.md                        # Configuration reference
├── AUTHENTICATION-GUIDE.md             # Auth setup guide
├── AUTOMATION-SERVICES-FIXES.md        # Troubleshooting guide
├── CONTRIBUTING.md                     # Contribution guidelines
├── CONTRIBUTOR-QUICK-START.md          # Quick start for contributors
├── TESTING-GUIDE.md                    # Testing documentation
├── SECURITY-HARDENING.md               # Security best practices
├── CHANGELOG.md                        # Version history
└── docs/                               # Additional documentation
    ├── MIDDLEWARE-GUIDE.md
    ├── NFS-STORAGE-OPTIONS.md
    └── VERSION-UPDATES.md
```

### CI/CD & Development
```
/.github/
├── workflows/
│   ├── ci-consolidated.yml         # Main CI pipeline
│   └── release-consolidated.yml    # Release automation
├── ISSUE_TEMPLATE/                 # Issue templates
│   ├── bug_report.yml
│   ├── feature_request.yml
│   ├── documentation.yml
│   └── test_failure.yml
└── PULL_REQUEST_TEMPLATE.md        # PR template

/.pre-commit-hooks/
├── tflint-optimized.sh             # Fast TFLint (changed files)
├── tflint-recursive.sh             # Full TFLint (all files)
├── terraform-docs-automation.sh    # Auto-generate docs
└── terraform-docs-recursive.sh     # Recursive doc generation
```

## Core Components

### Configuration Hierarchy (locals.tf)
1. **CI Mode Detection**: Automatic CI environment detection
2. **Architecture Detection**: Control plane → most common → default (amd64)
3. **Override Hierarchy**: service_overrides → cpu_arch_override → global cpu_arch
4. **Storage Selection**: NFS CSI → HostPath → cloud provider
5. **Middleware Configuration**: Basic Auth → LDAP → rate limiting → IP whitelist
6. **Helm Configuration**: Service-specific → global defaults

### Service Orchestration (main.tf)
- Conditional module instantiation based on `services` variable
- Dependency management (CRDs before services)
- Resource limits based on `enable_microk8s_mode`
- Architecture-aware node selection
- Storage class assignment

### Module Pattern
All Helm modules follow consistent structure:
1. **Namespace creation** with labels
2. **LimitRange** for resource constraints
3. **Static PV** creation (optional, NFS only)
4. **Helm release** with templated values
5. **Traefik IngressRoute** (optional)
6. **ServiceMonitor** for Prometheus (optional)

## Architectural Patterns

### Mixed Architecture Support
- Automatic node architecture detection via Kubernetes labels
- Per-service architecture override capability
- Intelligent scheduling with `nodeSelector` and `affinity`
- Fallback to most common architecture in cluster

### Two-Step Deployment
1. **Initial**: Deploy core services without authentication (CRD installation)
2. **Second**: Enable middleware authentication after CRDs ready

### Storage Abstraction
- **Dynamic NFS**: CSI driver with automatic PVC provisioning
- **Static NFS**: Pre-created PVs with predictable names
- **HostPath**: Local node storage for single-node clusters
- **Cloud**: Native storage classes (EBS, GCE PD, Azure Disk)

### Authentication System
- **Centralized Middleware**: Traefik middleware for all services
- **Priority System**: LDAP → Basic Auth fallback
- **Per-Service Override**: Disable auth for specific services
- **Rate Limiting**: Configurable per-service protection

## Key Relationships

### Dependencies
```
prometheus_crds → prometheus → grafana
traefik → middleware → ingress routes
nfs_csi → static_pvs → services with persistence
node_feature_discovery → architecture detection
```

### Data Flow
```
User Config (tfvars)
  → locals.tf (override hierarchy)
  → main.tf (module instantiation)
  → helm modules (service deployment)
  → Kubernetes cluster
```

### Testing Layers
```
Unit Tests (logic validation)
  → Scenario Tests (configuration validation)
  → Integration Tests (live cluster)
  → Security Tests (vulnerability scanning)
```
