# Technology Stack: tf-kube-any-compute

## Core Technologies

### Infrastructure as Code
- **Terraform**: >= 1.0
  - Primary IaC tool for all deployments
  - Module-based architecture
  - State management with workspaces
  - Native testing framework (tftest.hcl)

### Kubernetes
- **Supported Distributions**:
  - K3s (default, lightweight)
  - MicroK8s (ARM64 optimized)
  - EKS (AWS managed)
  - GKE (Google managed)
  - AKS (Azure managed)
  - Standard Kubernetes (k8s)

### Package Management
- **Helm**: ~> 3.0
  - Chart-based service deployment
  - Values templating with .tpl files
  - Release lifecycle management

## Terraform Providers

### Required Providers
```hcl
kubernetes = {
  source  = "hashicorp/kubernetes"
  version = "~> 2.0"
}

helm = {
  source  = "hashicorp/helm"
  version = "~> 3.0"
}

kubectl = {
  source  = "gavinbunney/kubectl"
  version = "~> 1.0"
}

random = {
  source  = "hashicorp/random"
  version = "~> 3.0"
}
```

## Service Technologies

### Ingress & Networking
- **Traefik**: v3.x (latest)
  - Modern reverse proxy and load balancer
  - Automatic SSL with Let's Encrypt
  - Dynamic configuration
  - Middleware support (auth, rate limiting)
- **MetalLB**: Latest stable
  - Bare metal load balancer
  - Layer 2 and BGP modes

### Monitoring & Observability
- **Prometheus**: kube-prometheus-stack
  - Metrics collection and alerting
  - ServiceMonitor CRDs
  - AlertManager integration
- **Grafana**: Latest stable
  - Visualization dashboards
  - Pre-configured Kubernetes dashboards
  - Data source auto-configuration
- **Kube-State-Metrics**: Latest stable
  - Kubernetes object metrics
  - Deployment, Pod, Node metrics
- **Loki**: Latest stable (optional)
  - Log aggregation
  - Grafana integration
- **Promtail**: Latest stable (optional)
  - Log collection agent

### Storage
- **NFS CSI Driver**: Latest stable
  - Dynamic NFS provisioning
  - ReadWriteMany support
  - Configurable mount options
- **HostPath Provisioner**: Latest stable
  - Local storage provisioner
  - Development and testing

### Service Mesh & Security
- **Consul**: Latest stable (optional)
  - Service discovery
  - Service mesh capabilities
  - Key-value store
- **Vault**: Latest stable (optional)
  - Secrets management
  - Auto-unsealing support
  - Kubernetes authentication
- **Gatekeeper**: Latest stable (optional)
  - OPA-based policy engine
  - Admission control
  - Constraint templates

### Container Management
- **Portainer**: Latest stable
  - Web-based container management
  - Kubernetes dashboard
  - Multi-cluster support

### Automation & Workflow
- **Home Assistant**: Latest stable
  - Python-based home automation
  - 1000+ integrations
  - Web UI configuration
- **openHAB**: Latest stable
  - Java/OSGi runtime
  - 400+ device bindings
  - Rule engine
- **Homebridge**: Latest stable
  - Node.js-based HomeKit bridge
  - Plugin ecosystem
- **Node-RED**: Latest stable
  - Node.js visual programming
  - Flow-based development
  - NPM package integration
- **n8n**: Latest stable
  - Node.js workflow automation
  - 200+ integrations
  - Self-hosted alternative to Zapier

### Node Discovery
- **Node Feature Discovery**: Latest stable
  - Hardware feature detection
  - Node labeling
  - Storage detection (NVMe, SATA, USB)

## Development Tools

### Code Quality
- **TFLint**: Latest
  - Terraform linting
  - Optimized rules for fast pre-commit
  - Module validation
- **terraform-docs**: Latest
  - Automatic documentation generation
  - Markdown output
  - Variable and output documentation

### Testing
- **Terraform Test**: Native framework
  - Unit tests (tests.tftest.hcl)
  - Scenario tests (test-scenarios.tftest.hcl)
  - Architecture tests (tests-architecture.tftest.hcl)
- **Shell Scripts**: Bash
  - Integration testing
  - Performance testing (Node.js)
  - Security scanning

### CI/CD
- **GitHub Actions**: Workflow automation
  - Consolidated CI pipeline
  - Release automation
- **GitLab CI**: Alternative pipeline
  - Same test coverage
  - Optimized for GitLab

### Pre-commit Hooks
- **pre-commit framework**: Python-based
  - Terraform formatting (terraform fmt)
  - TFLint validation
  - terraform-docs generation
  - Secrets detection

## DNS Providers (SSL Automation)

### Supported Providers
- Hurricane Electric (default)
- Cloudflare
- AWS Route53
- DigitalOcean
- Gandi
- Namecheap
- GoDaddy
- OVH
- Linode
- Vultr
- Hetzner

### DNS Challenge Configuration
- ACME DNS-01 challenge
- Automatic certificate renewal
- Wildcard certificate support

## Authentication Methods

### Basic Authentication
- htpasswd format
- bcrypt password hashing
- Kubernetes Secret storage

### LDAP Integration
- **Supported Directories**:
  - JumpCloud
  - Active Directory
  - OpenLDAP
  - Generic LDAP servers
- **Methods**:
  - ForwardAuth (recommended)
  - Traefik Plugin

## Build System

### Makefile Targets
```makefile
# Initialization
make init                 # Terraform init

# Planning & Deployment
make plan                 # Terraform plan
make apply                # Terraform apply
make destroy              # Terraform destroy

# Testing
make test-quick           # Fast validation
make test-all             # Comprehensive tests
make test-safe            # Non-destructive tests
make test-lint            # Linting only
make test-validate        # Validation only
make test-unit            # Unit tests
make test-scenarios       # Scenario tests
make test-integration     # Integration tests
make test-performance     # Performance tests
make test-security        # Security scanning

# Linting
make lint                 # Optimized linting
make lint-full            # Comprehensive linting
```

## Configuration Management

### Variable Types
- **Primitive**: string, number, bool
- **Complex**: object, list, map
- **Optional**: All service configurations
- **Sensitive**: Passwords, tokens, secrets

### Configuration Files
- **terraform.tfvars**: User configuration
- **terraform.tfvars.example**: Template
- **examples/*.tfvars**: Use-case examples
- **test-configs/*.tfvars**: Test scenarios

## Version Management

### Semantic Versioning
- Major.Minor.Patch format
- Synchronized across modules
- Automated version updates

### Version Files
- `.github/versions.yml`: Central version registry
- `scripts/version-manager.sh`: Sync tool
- `scripts/sync-versions.sh`: Automation

## Runtime Requirements

### Local Development
```bash
terraform >= 1.0
kubectl >= 1.20
helm >= 3.0
make
bash >= 4.0
```

### Kubernetes Cluster
```bash
Kubernetes >= 1.20
CoreDNS (DNS resolution)
Metrics Server (optional, for HPA)
Storage provisioner (NFS or HostPath)
```

### Network Requirements
- Internet access (Helm charts, container images)
- DNS resolution
- Load balancer IP range (MetalLB)
- NFS server (if using NFS storage)

## Container Registries

### Default Registries
- Docker Hub (most images)
- Quay.io (some services)
- GitHub Container Registry (custom images)

### Architecture Support
- **amd64**: Full support
- **arm64**: Full support with architecture detection
- **Mixed clusters**: Automatic service placement

## Resource Requirements

### Minimum (MicroK8s Mode)
- CPU: 2 cores
- Memory: 4GB RAM
- Storage: 20GB

### Recommended (Full Stack)
- CPU: 4+ cores
- Memory: 8GB+ RAM
- Storage: 50GB+

### Production (High Availability)
- CPU: 8+ cores
- Memory: 16GB+ RAM
- Storage: 100GB+
- Multiple nodes
