# Project Structure: tf-kube-any-compute

## Directory Organization

### Root Level
```
/Users/gma/repo/tf-kube-any-compute/
├── main.tf                    # Main Terraform orchestration
├── variables.tf               # Input variable definitions
├── locals.tf                  # Local value computations
├── outputs.tf                 # Output definitions
├── versions.tf                # Provider version constraints
├── provider.tf                # Provider configurations
├── Makefile                   # Build and test automation
├── README.md                  # Project documentation
└── terraform.tfvars.example   # Configuration template
```

### Service Modules (helm-*)
Each service has a dedicated Terraform module following consistent structure:
- **helm-traefik/**: Ingress controller with SSL, DNS, middleware
- **helm-metallb/**: Load balancer for bare metal
- **helm-prometheus-stack/**: Monitoring with Grafana integration
- **helm-grafana/**: Standalone dashboard deployment
- **helm-vault/**: Secrets management with auto-unsealing
- **helm-consul/**: Service mesh and discovery
- **helm-portainer/**: Container management UI
- **helm-nfs-csi/**: NFS storage driver
- **helm-host-path/**: HostPath storage driver
- **helm-node-feature-discovery/**: Hardware detection
- **helm-kube-state-metrics/**: Kubernetes metrics exporter
- **helm-loki/**: Log aggregation
- **helm-promtail/**: Log collection
- **helm-gatekeeper/**: Policy enforcement
- **helm-node-red/**: IoT visual programming
- **n8n/**: Workflow automation (native Terraform)
- **home-assistant/**: Home automation platform
- **openhab/**: Enterprise home automation
- **homebridge/**: Apple HomeKit bridge

### Module Structure Pattern
```
helm-{service}/
├── main.tf                    # Helm release configuration
├── variables.tf               # Module inputs
├── outputs.tf                 # Module outputs
├── locals.tf                  # Local computations
├── version.tf                 # Provider requirements
├── values.yaml.tpl            # Helm values template
├── templates/                 # Additional templates
│   └── {service}-values.yaml.tpl
├── traefik-ingress.tf        # Ingress configuration (if applicable)
├── pvc.tf                    # Persistent volume claims (if applicable)
├── limit_range.tf            # Resource limits (if applicable)
└── README.md                 # Module documentation
```

### Documentation Structure
```
docs/
├── guides/                    # User guides
│   ├── AUTHENTICATION-GUIDE.md
│   ├── AUTOMATION-SERVICES-GUIDE.md
│   ├── MIDDLEWARE-GUIDE.md
│   ├── SECURITY-HARDENING.md
│   ├── SECURITY-TESTING-GUIDE.md
│   └── TESTING-GUIDE.md
├── reference/                 # Technical references
│   ├── VARIABLES.md
│   ├── DNS-PROVIDER-CERT-RESOLVERS.md
│   ├── LDAP-AUTHENTICATION-METHODS.md
│   └── VERSION-MANAGEMENT.md
├── development/               # Contributor documentation
│   ├── CONTRIBUTING.md
│   ├── CONTRIBUTOR-QUICK-START.md
│   └── SERVICE-INTEGRATION-TEMPLATE.md
└── archive/                   # Historical documentation
```

### Configuration Examples
```
examples/
├── quickstart-homelab.tfvars
├── quickstart-raspberry-pi.tfvars
├── quickstart-cloud.tfvars
├── quickstart-mixed-cluster.tfvars
├── quickstart-home-automation.tfvars
├── auth-ldap.tfvars
├── dns-cloudflare.tfvars
└── dns-route53.tfvars
```

### Testing Infrastructure
```
test-configs/                  # Test configurations
├── minimal.tfvars
├── production.tfvars
├── mixed-cluster.tfvars
└── middleware-test.tfvars

*.tftest.hcl                   # Terraform test files
├── tests.tftest.hcl          # Unit tests
├── tests-architecture.tftest.hcl
├── tests-storage.tftest.hcl
├── tests-services.tftest.hcl
├── tests-mixed-cluster.tftest.hcl
└── test-scenarios.tftest.hcl
```

### Automation Scripts
```
scripts/
├── debug.sh                   # Comprehensive diagnostics
├── check-ingress.sh          # Ingress/networking tests
├── check-vault.sh            # Vault health checks
├── integration-tests.sh      # Integration testing
├── performance-test.js       # Performance benchmarks
├── security-scan.sh          # Security scanning
├── test-automation-services.sh
├── test-middleware.sh
└── version-manager.sh        # Version synchronization
```

### CI/CD Configuration
```
.github/
├── workflows/
│   ├── ci-consolidated.yml   # Main CI pipeline
│   └── release-consolidated.yml
├── ISSUE_TEMPLATE/           # Issue templates
└── PULL_REQUEST_TEMPLATE.md

.gitlab-ci.yml                # GitLab CI configuration
```

### Development Tools
```
.pre-commit-hooks/            # Pre-commit automation
├── terraform-docs-automation.sh
├── tflint-optimized.sh
└── tflint-recursive.sh

.pre-commit-config.yaml       # Pre-commit configuration
.tflint.hcl                   # TFLint rules
.terraform-docs.yml           # Documentation generation
```

### AI Assistant Rules
```
.amazonq/
└── rules/
    └── memory-bank/
        ├── contribution.md
        ├── guidelines.md
        ├── product.md
        ├── structure.md
        └── tech.md

.cline/
└── rules/
    ├── guidelines.md
    ├── product.md
    ├── structure.md
    ├── tech.md
    └── development.md
```

## Architectural Patterns

### Module Composition
- **Root Module**: Orchestrates all service modules
- **Service Modules**: Self-contained Helm deployments
- **Shared Locals**: Architecture detection, storage logic
- **Output Aggregation**: Centralized service information

### Configuration Hierarchy
1. **System Defaults**: Base configuration values
2. **Service Defaults**: Per-service default settings
3. **User Variables**: terraform.tfvars overrides
4. **Service Overrides**: Fine-grained per-service control
5. **Auto-Detection**: Runtime cluster analysis

### Data Flow
```
User Input (tfvars)
    ↓
Variable Validation
    ↓
Architecture Detection (locals.tf)
    ↓
Storage Class Selection
    ↓
Service Configuration Merge
    ↓
Module Invocation
    ↓
Helm Deployment
    ↓
Output Aggregation
```

### Dependency Management
- **Storage First**: NFS/HostPath before services
- **CRDs Before Resources**: Prometheus CRDs before stack
- **Traefik Before Ingress**: Ingress controller before routes
- **Two-Step Auth**: Core services, then authentication

### Resource Organization
- **Namespaces**: Per-service isolation (prod-{service}-system)
- **Storage Classes**: Auto-detected or user-specified
- **Node Affinity**: Architecture-based scheduling
- **Resource Limits**: MicroK8s mode optimization

## Key Components

### Architecture Detection (locals.tf)
- Cluster node analysis
- CPU architecture detection
- Mixed cluster identification
- Storage class discovery

### Service Configuration (locals.tf)
- Override hierarchy resolution
- Default value application
- Helm timeout management
- Resource limit calculation

### Middleware System (helm-traefik/middleware/)
- Basic authentication
- LDAP integration
- Rate limiting
- IP whitelisting
- Default authentication with fallback

### Storage Management
- NFS CSI driver with mount options
- HostPath provisioner
- Storage class templates (default, performance, reliable, low_latency)
- Auto-detection logic

### Monitoring Integration
- ServiceMonitor resources
- Grafana dashboard provisioning
- Prometheus scrape configs
- Kube-state-metrics integration

## Naming Conventions

### Resources
- **Namespaces**: `{environment}-{service}-system` (e.g., prod-traefik-system)
- **Releases**: `{environment}-{service}` (e.g., prod-prometheus)
- **Storage Classes**: `{type}-{backend}` (e.g., nfs-csi, hostpath-storage)
- **Secrets**: `{service}-{purpose}` (e.g., traefik-dashboard-auth)

### Variables
- **Boolean Flags**: `enable_{feature}` or `use_{option}`
- **Overrides**: `{service}_override` or `{category}_override`
- **Configuration**: `{service}_config` or `{category}_config`
- **Defaults**: `default_{setting}` or `{category}_defaults`

### Modules
- **Helm Services**: `helm-{service}` (e.g., helm-traefik)
- **Native Services**: `{service}` (e.g., n8n, home-assistant)
- **Sub-modules**: `{parent}/{child}` (e.g., helm-traefik/middleware)

## File Organization Principles

### 1. Separation of Concerns
- **main.tf**: Core resource definitions
- **variables.tf**: Input configuration
- **outputs.tf**: Output values
- **locals.tf**: Computed values
- **templates/**: Reusable templates

### 2. Consistency Across Modules
- Same file structure for all service modules
- Consistent naming conventions
- Standardized variable patterns
- Uniform output format

### 3. Logical Grouping
- Related resources grouped together
- Clear separation between infrastructure and services
- Organized by function (networking, storage, monitoring)
- Hierarchical module structure

### 4. Scalability
- Modular design allows easy addition of new services
- Shared locals avoid duplication
- Template-based configuration
- Override system for customization

## Important Files Summary

### Root Configuration
- **main.tf**: Module orchestration and service integration
- **variables.tf**: All input variables (alphabetical)
- **locals.tf**: Architecture detection, configuration merge logic
- **outputs.tf**: Service information, URLs, debugging outputs
- **versions.tf**: Terraform and provider version constraints
- **provider.tf**: Kubernetes and Helm provider configuration

### Build Automation
- **Makefile**: All build, test, and deployment commands
- **setup-pre-commit.sh**: Pre-commit hooks installation
- **.tflint.hcl**: Terraform linting rules
- **.terraform-docs.yml**: Documentation generation config
- **.pre-commit-config.yaml**: Pre-commit hook definitions

### CI/CD
- **.github/workflows/ci-consolidated.yml**: GitHub Actions CI pipeline
- **.github/workflows/release-consolidated.yml**: Release automation
- **.gitlab-ci.yml**: GitLab CI configuration

### Testing
- **tests.tftest.hcl**: Core unit tests
- **test-scenarios.tftest.hcl**: Scenario-based tests
- **tests-architecture.tftest.hcl**: Architecture detection tests
- **tests-storage.tftest.hcl**: Storage configuration tests
- **tests-services.tftest.hcl**: Service enablement tests
- **tests-mixed-cluster.tftest.hcl**: Multi-architecture tests
- **scripts/integration-tests.sh**: Integration test suite
- **scripts/performance-test.js**: Load testing with k6

### Documentation
- **README.md**: Project overview and quick start
- **CONTRIBUTING.md**: Contribution guidelines
- **CHANGELOG.md**: Version history and changes
- **docs/guides/**: Detailed user guides
- **docs/reference/**: Technical references
- **docs/development/**: Contributor documentation

## Module Dependencies

### Core Infrastructure
```
Node Feature Discovery (NFD)
    ↓
Storage (NFS CSI / HostPath)
    ↓
MetalLB (Load Balancer)
    ↓
Traefik (Ingress Controller)
```

### Monitoring Stack
```
Prometheus CRDs
    ↓
Prometheus Stack
    ↓
Grafana
    ↓
Kube-State-Metrics
```

### Optional Services
- **Consul**: Requires storage
- **Vault**: Requires storage
- **Gatekeeper**: No dependencies
- **Portainer**: Requires storage
- **Automation Services**: Require storage, optional ingress

## Configuration Flow

### 1. User Configuration
```
terraform.tfvars
    ↓
Variable definitions (variables.tf)
```

### 2. Detection & Computation
```
locals.tf
    ├── Architecture detection
    ├── Storage class selection
    └── Configuration merge
```

### 3. Module Invocation
```
main.tf
    ├── Service enablement logic
    ├── Module configuration
    └── Dependency management
```

### 4. Resource Creation
```
Service modules
    ├── Namespace creation
    ├── Helm release deployment
    ├── Ingress configuration
    └── PVC creation
```

### 5. Output Generation
```
outputs.tf
    ├── Service information
    ├── Access URLs
    └── Debug outputs
```

## Testing Structure

### Unit Tests (tests.tftest.hcl)
- Architecture detection logic
- Storage class selection
- Configuration merge logic
- Variable validation

### Scenario Tests (test-scenarios.tftest.hcl)
- ARM64 Raspberry Pi deployment
- AMD64 cloud deployment
- Mixed architecture cluster
- MicroK8s mode
- Storage scenarios

### Integration Tests (scripts/integration-tests.sh)
- Service health checks
- Ingress connectivity
- Storage functionality
- Authentication verification

### Performance Tests (scripts/performance-test.js)
- Load testing with k6
- Response time measurement
- Resource utilization monitoring
- Scalability testing

## Development Workflow

### 1. Code Changes
```
Edit module files
    ↓
Run local tests
```

### 2. Pre-commit Validation
```
git add files
    ↓
pre-commit run
    ├── terraform fmt
    ├── terraform-docs
    ├── tflint
    ├── terraform validate
    └── security scans
```

### 3. Commit
```
git commit (with conventional commit message)
```

### 4. Push & CI
```
git push
    ↓
GitHub Actions CI
    ├── Run all tests
    ├── Security scanning
    ├── Documentation check
    └── Build verification
```

### 5. Review & Merge
```
Pull request review
    ↓
Merge to main
    ↓
Release automation
```

## Key Patterns to Remember

### 1. Override Hierarchy
Always follow: System defaults → Service defaults → User variables → Service overrides → Auto-detection

### 2. Conditional Resources
Use `count` for top-level resources, `dynamic` blocks for nested optional blocks

### 3. Secret Management
Always mark sensitive variables and outputs with `sensitive = true`

### 4. Architecture Awareness
Always consider ARM64 and AMD64, support mixed clusters

### 5. Resource Limits
Always include resource limits, optimize for MicroK8s mode

### 6. Documentation
Every module needs comprehensive README with examples

### 7. Testing
Write tests for all new features, including edge cases

### 8. Dependencies
Use explicit `depends_on` when ordering matters

### 9. Naming
Follow consistent naming conventions across all modules

### 10. Backward Compatibility
Support legacy variables with deprecation warnings when changing
