# Project Documentation

## 🌟 Project Origin & Philosophy

This project represents the culmination of a **lifelong passion for technology** that began at age 14. While my friends were focused on playing games, I found myself fascinated by understanding and fixing computers - a curiosity that naturally evolved into a career in IT and eventually led to this comprehensive infrastructure platform.

### 🚀 The Early Spark

**The Beginning**: At 14, technology wasn't just a hobby - it was a calling. While peers were gaming, I was deep in system configurations, troubleshooting hardware, and learning how computers actually worked. This early passion for understanding the "how" and "why" of technology became the foundation for everything that followed.

**The Natural Progression**: That teenage curiosity grew into professional expertise, leading to a career built on genuine passion for infrastructure and systems. The same drive that kept me up late fixing computers as a teenager now fuels the enterprise solutions I architect today.

### 🏡 The Personal Project Catalyst

This project emerged from the same curiosity that drove me at 14 - wanting to understand and master new technologies in my personal environment:

- Testing different Kubernetes distributions (K3s, MicroK8s) on ARM64 hardware
- Exploring modern infrastructure patterns outside of work constraints
- Applying the problem-solving mindset that's driven my career from the beginning
- Bridging the gap between enterprise complexity and accessible learning environments

**The Core Motivation**: The same passion for fixing and understanding technology that started in my teenage years continues to drive exploration of cutting-edge infrastructure patterns.

### 🚀 From Enterprise Experience to Universal Solution

Drawing from enterprise cloud architecture experience:

- **🔧 Modular Design**: Applied systematic Infrastructure-as-Code principles developed through enterprise experience
- **🏗️ Architecture Intelligence**: Implemented automatic platform detection learned from multi-cloud deployments
- **🧪 Enterprise Testing**: Brought production-grade testing patterns to homelab infrastructure
- **🔒 Security First**: Applied the same security-hardened approaches required in enterprise services
- **🤖 AI-Enhanced Development**: Leveraged modern AI tools to accelerate and refine development

### 🌍 The Mission

Having contributed to enterprise technologies throughout my career - from network infrastructure to cloud-native solutions - I believe in democratizing access to sophisticated infrastructure. This module represents that philosophy: making enterprise-grade patterns accessible to anyone with curiosity and a willingness to learn.

### 🎯 The Technical Philosophy

This project embodies lessons learned from **17 years of infrastructure evolution**:

- **🌐 Universal Patterns**: What works in enterprise clouds should work on edge devices
- **🎓 Knowledge Transfer**: Bridge the gap between traditional networking and cloud-native
- **🤝 Community Innovation**: Share enterprise-grade patterns with the broader community
- **🚀 Continuous Evolution**: Embrace new technologies while honoring proven foundations

What started as teenage curiosity about how computers work has evolved into a passion-driven contribution to democratizing access to production-grade Kubernetes environments. Every module reflects the same problem-solving enthusiasm that kept me up late fixing computers as a kid.

### 🎯 Homelab Philosophy

This infrastructure is built with the homelab mindset:

- **Start Simple**: Deploy core services first, add complexity gradually
- **Learn by Doing**: Each service teaches different Kubernetes concepts
- **Architecture Agnostic**: Works on ARM64 Raspberry Pis and AMD64 servers
- **Production Patterns**: Learn industry best practices in your homelab
- **Cost Conscious**: Optimized for resource-constrained environments

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Development   │    │   Staging/QA    │    │   Production    │
│   Environment   │    │   Environment   │    │   Environment   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Terraform      │
                    │  Workspaces     │
                    └─────────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                       │                        │
   ┌─────────┐            ┌─────────┐              ┌─────────┐
   │   K3s   │            │MicroK8s │              │  Cloud  │
   │Cluster  │            │ Cluster │              │   K8s   │
   └─────────┘            └─────────┘              └─────────┘
```

## 📈 Current Status & Recent Enhancements

### ✅ Task 5 Completed: Troubleshooting Automation

- **🔧 Comprehensive Debug Scripts**: Enhanced troubleshooting framework with multiple diagnostic modes
- **📊 Main Debug Script**: Multi-mode diagnostics (`--quick`, `--full`, `--network`, `--storage`, `--service`)
- **🔐 Vault Health Check**: Specialized Vault diagnostics with authentication handling
- **🌐 Ingress Diagnostics**: Complete ingress and networking analysis with SSL certificate checking
- **🎯 Smart Output**: Color-coded status indicators with actionable troubleshooting recommendations

### ✅ Task 4 Completed: Enhanced Testing Framework

- **🧪 Terraform Native Testing**: Comprehensive test suite using `terraform test` commands
- **🔬 Multi-Level Testing**: Unit tests, scenario tests, integration tests, and performance tests
- **📋 Make Commands**: Full test automation with `make test-*` commands
- **🎯 Test Coverage**: Architecture detection, storage classes, helm configs, service enablement

### ✅ Task 3 Completed: Security Hardening

- **🔒 Infrastructure Stability**: Achieved 0 destroys (down from 4 destroys)
- **🛡️ Enhanced Security**: Removed `api.insecure=true` vulnerability from Traefik
- **⚙️ Service Override Framework**: 200+ configuration options implemented
- **📊 Resource Limits**: Enhanced with pod-level and PVC-level constraints

### ⚠️ Known Issues & TODO

- **Traefik Dashboard**: Disabled by default due to Traefik CRD dependencies
  - **Issue**: Traefik IngressRoute CRD may not be available during initial deployment
  - **Workaround**: Enable `service_overrides.traefik.enable_dashboard = true` after first successful apply
  - **Status**: Dashboard ingress ready, requires two-phase deployment
  - **Access Impact**: Dashboard not accessible until enabled

- **Portainer Password**: Cannot set random password during deployment
  - **Issue**: Portainer requires manual password setup on first web interface access
  - **Workaround**: Access Portainer web UI immediately after deployment and set admin password
  - **Status**: Critical security configuration required on first run
  - **Security Impact**: 🔴 **HIGH** - Portainer accessible without password for 5 minutes, then locks itself until password is set

- **Monitoring Authentication**: Disabled by default due to Traefik CRD dependencies
  - **Issue**: Traefik Middleware CRD may not be available during initial deployment
  - **Workaround**: Enable `service_overrides.prometheus.enable_monitoring_auth = true` after first successful apply
  - **Status**: Authentication middleware ready, requires two-phase deployment
  - **Security Impact**: Monitoring services accessible without authentication until enabled

- **Gatekeeper Policy Engine**: Currently disabled due to Kubernetes provider inconsistency with CRD `preserveUnknownFields`
  - **Issue**: `kubernetes_manifest` provider errors during CRD deployment
  - **Workaround**: Server-side apply and lifecycle rules implemented but needs testing
  - **Status**: Gatekeeper module ready, will be enabled in dedicated security phase
  - **Security Impact**: Core infrastructure security maintained, policy enforcement deferred

### 🎯 Next Phase: Complete Security Hardening

1. **Resolve Gatekeeper CRD deployment**: Test server-side apply fix
2. **Enable comprehensive policies**:
   - Security context enforcement (runAsNonRoot, no privilege escalation)
   - Privileged container prevention
   - Resource limits enforcement
   - Storage size limits (10Gi max PVCs)
3. **Validate policy compliance**: Ensure existing workloads meet security standards

**Note**: Set `enable_gatekeeper = true` in `terraform.tfvars` when ready to deploy policy engine.

## 🎛️ Architecture Management & Mixed Cluster Strategy

Comprehensive architecture detection and service placement for **hybrid homelabs** with mixed ARM64/AMD64 hardware.

### 🔍 Intelligent Architecture Detection

The system performs multi-stage architecture detection:

```hcl
# Automatic mixed cluster detection and configuration
auto_mixed_cluster_mode = true  # Default: automatically configure for mixed clusters
cpu_arch = ""                   # Auto-detect from cluster (or specify: "amd64", "arm64")
```

**Detection Process:**

1. **Query Control Plane Nodes** - K8s, K3s, MicroK8s masters
2. **Query Worker Nodes** - Dedicated worker node detection
3. **Analyze All Nodes** - Complete cluster architecture mapping
4. **Calculate Statistics** - Architecture distribution and most common types

### 📋 Architecture Selection Priority

**For Application Services:**

1. **User Override** (`cpu_arch_override.service`)
2. **Most Common Worker Architecture** (where apps typically run)
3. **Most Common Overall Architecture** (fallback)
4. **AMD64 Default** (final fallback)

**For Cluster-Wide Services:**

1. **User Override** (`cpu_arch_override.service`)
2. **Control Plane Architecture** (infrastructure follows masters)
3. **Most Common Architecture** (fallback)

### 🎯 Service Placement Strategy

**🌐 Cluster-Wide Services (Architecture-Agnostic):**

- `node_feature_discovery` - Hardware detection on all nodes
- `metallb` - Load balancer speakers on all nodes
- `nfs_csi` - Storage driver on all nodes

**🚀 Application Services (Worker-Optimized):**

- `traefik`, `prometheus`, `consul`, `vault`, `grafana`, `portainer`
- Prefer worker node architecture for optimal placement

### 🏗️ Mixed Cluster Scenarios

#### Scenario 1: ARM64 Masters + AMD64 Workers

```
Control Plane: 3x ARM64 Raspberry Pi
Workers: 2x AMD64 Mini PCs

Result:
- Applications → AMD64 workers (better performance)
- Cluster services → ARM64 masters (infrastructure consistency)
```

#### Scenario 2: Homogeneous ARM64 Cluster

```
All Nodes: ARM64 Raspberry Pi

Result:
- All services → ARM64
- Optimized resource limits for ARM64
```

#### Scenario 3: Mixed Everything

```
Masters: 1x ARM64, 1x AMD64
Workers: 2x ARM64, 3x AMD64

Result:
- Applications → AMD64 (most common worker arch)
- Cluster services → AMD64 (most common overall)
```

### ⚙️ Manual Architecture Overrides

```hcl
# Performance-optimized mixed cluster
cpu_arch_override = {
  # High-performance services on AMD64
  traefik          = "amd64"    # Ingress performance
  prometheus_stack = "amd64"    # Resource-intensive monitoring
  consul           = "amd64"    # Service mesh performance
  vault            = "amd64"    # Security-critical workloads

  # Cost-effective services on ARM64
  portainer        = "arm64"    # Management UI
  grafana          = "arm64"    # Visualization
}

# Force cluster-wide deployment (ignore architecture)
disable_arch_scheduling = {
  node_feature_discovery = true  # Run on all nodes
  metallb                = true  # Load balancer everywhere
  nfs_csi                = true  # Storage on all nodes
}
```

### 🔧 Architecture Debug Information

```bash
# View detected architectures and service placement
terraform output cpu_arch_debug

# Example output:
{
  "detected_arch" = "amd64"
  "cluster_info" = {
    "is_mixed" = true
    "architectures" = ["arm64", "amd64"]
    "control_plane_arch" = "arm64"
    "most_common_arch" = "amd64"
    "most_common_worker_arch" = "amd64"
  }
  "service_architectures" = {
    "traefik" = "amd64"     # Application service → worker arch
    "metallb" = "arm64"     # Cluster service → control plane arch
  }
}
```

### 🏠 Homelab Architecture Patterns

#### 1. Raspberry Pi Control + x86 Workers

```hcl
# ARM64 Raspberry Pi masters + AMD64 Mini PC workers
cpu_arch = ""  # Auto-detect (will prefer AMD64 for apps)
auto_mixed_cluster_mode = true

# Optional: Force specific placement
cpu_arch_override = {
  # Heavy workloads on AMD64 workers
  prometheus_stack = "amd64"
  vault           = "amd64"
  consul          = "amd64"

  # UI services can run on ARM64 masters
  portainer       = "arm64"
  grafana         = "arm64"
}
```

#### 2. Homogeneous ARM64 Cluster

```hcl
# All Raspberry Pi cluster
cpu_arch = "arm64"              # Explicit architecture
enable_microk8s_mode = true     # ARM64 optimizations
use_hostpath_storage = true     # Local storage for ARM64

# Resource limits for ARM64
default_cpu_limit = "500m"
default_memory_limit = "512Mi"
```

#### 3. Development/Learning Environment

```hcl
# Flexible deployment - services can run anywhere
auto_mixed_cluster_mode = false  # Disable automatic constraints

disable_arch_scheduling = {
  traefik                = true  # Allow cross-architecture
  prometheus_stack       = true
  consul                 = true
  vault                  = true
  portainer             = true
  node_feature_discovery = true
}
```

#### 4. Production Mixed Cluster

```hcl
# Optimized for performance and reliability
cpu_arch = ""  # Auto-detect
auto_mixed_cluster_mode = true

# Strategic service placement
cpu_arch_override = {
  # Critical services on reliable AMD64
  traefik          = "amd64"
  prometheus_stack = "amd64"
  vault           = "amd64"

  # Monitoring/UI on efficient ARM64
  grafana         = "arm64"
  portainer       = "arm64"
}

# Ensure cluster services run everywhere
disable_arch_scheduling = {
  metallb                = true
  nfs_csi                = true
  node_feature_discovery = true
}
```

## 🧠 Configuration Management Philosophy

The infrastructure uses a **centralized configuration approach** with intelligent defaults and override capabilities:

### 🎯 Configuration Hierarchy

1. **Locals (locals.tf)** - Centralized logic and computed values
2. **Variables (variables.tf)** - User inputs and overrides
3. **Main (main.tf)** - Service deployments using local values
4. **Debug Outputs** - Visibility into computed configurations

### 🔄 Configuration Flow

```
User Variables → Local Computations → Service Deployments
     ↓                    ↓                    ↓
 terraform.tfvars → locals.tf → main.tf
     ↓                    ↓                    ↓
 Overrides        → Smart Defaults → Consistent Application
```

### 📋 Configuration Categories

**🏗️ Architecture Management:**

- `cpu_architectures` - Per-service architecture selection
- `final_disable_arch_scheduling` - Mixed cluster overrides
- Auto-detection with manual override capability

**🔐 Certificate Management:**

- `cert_resolvers` - Per-service SSL certificate resolver
- Conditional TLS configuration (wildcard vs HTTP challenge)
- Consistent across all ingress resources

**💾 Storage Management:**

- `storage_classes` - Intelligent storage class selection
- NFS primary, hostpath fallback strategy
- Per-service storage class overrides

**⚙️ Helm Management:**

- `helm_configs` - Centralized Helm deployment settings
- Timeout, retry, and cleanup configurations
- Service-specific overrides with global defaults

### 🎛️ Override Pattern

All configurations follow the same override pattern:

```hcl
service_config = coalesce(
  var.service_override.service,  # User override
  local.computed_default,        # Smart default
  "fallback_value"              # Safety fallback
)
```

## 📊 Configuration Reference

### Default Values & Rationale

| Variable | Default | Rationale |
|----------|---------|--------------|
| `domain_name` | `example.com` | Multi-environment domain strategy |
| `letsencrypt_email` | `admin@example.com` | Must be updated for production |
| `service_overrides.traefik.enable_dashboard` | `true` | Operational visibility by default |
| `cpu_arch` | `""` (auto-detect) | Universal cluster support |
| `use_nfs_storage` | `true` | Shared storage for production |
| `enable_resource_limits` | `true` | Prevent resource exhaustion |
| `metallb_address_pool` | `192.168.1.200-210` | Common homelab IP range |

### Service Enablement Defaults

| Service | Enabled | Purpose |
|---------|---------|---------|
| Traefik | ✅ | Essential ingress controller |
| MetalLB | ✅ | Load balancer for bare metal |
| Prometheus | ✅ | Monitoring and metrics |
| Grafana | ✅ | Visualization dashboards |
| Consul | ✅ | Service discovery |
| Vault | ✅ | Secrets management |
| Portainer | ✅ | Container management UI |
| Gatekeeper | ❌ | Policy engine (opt-in) |

### Environment-Specific Domains

```hcl
domain_name = {
  default = "example.com"
  homelab = "homelab.local"
  dev     = "dev.local"
  prod    = "example.com"
}
```

## 🔧 Workspace Management

Organize environments using Terraform workspaces:

```bash
# List available workspaces
terraform workspace list

# Create homelab environment
terraform workspace new homelab

# Switch to production
terraform workspace select prod

# Deploy to specific environment
terraform apply
```

### Available Workspaces

- `homelab` - Home laboratory environment
- `dev` - Development environment
- `staging` - Staging/QA environment
- `prod` - Production environment

## 🏛️ Opinionated Decisions & Defaults

This infrastructure makes intelligent decisions to provide a **production-ready, secure, and maintainable** platform:

### 🔒 Security First

- **SSL by Default**: Automatic HTTPS with Let's Encrypt wildcard certificates
- **DNS Challenge**: Hurricane Electric (dns.he.net) for wildcard certificate validation
- **Dynamic DNS**: HE.net tunnel broker support for homelab domains
- **Traefik Dashboard**: Enabled for operational visibility (`service_overrides.traefik.enable_dashboard = true`)
- **Custom Passwords**: Override auto-generated passwords for all services
- **Resource Limits**: Prevent resource exhaustion (`enable_resource_limits = true`)
- **Helm Security**: Webhooks disabled for compatibility (`default_helm_disable_webhooks = true`)

### 🏗️ Architecture Intelligence

- **Auto-Detection**: Automatically detects ARM64/AMD64 architecture (`cpu_arch = ""`)
- **Mixed Clusters**: Intelligent service placement on heterogeneous nodes
- **Universal Support**: Works across K3s, MicroK8s, EKS, GKE, AKS

### 💾 Storage Strategy

- **NFS Primary**: Shared storage for production workloads (`use_nfs_storage = true`)
- **HostPath Fallback**: Local storage for development (`use_hostpath_storage = true`)
- **Smart Selection**: `nfs-csi-safe` for critical data, `hostpath` for UI components

### ⚡ Performance & Reliability

- **Conservative Timeouts**: 5-minute default with service-specific overrides
- **Balanced Resources**: 500m CPU / 512Mi memory limits for stability
- **Helm Best Practices**: Force updates, cleanup on failure, proper waiting

### 🚀 Service Philosophy

- **Core Services**: Essential infrastructure enabled by default
- **Platform Services**: Complete experience with monitoring, secrets, service mesh
- **Optional Components**: Gatekeeper disabled by default to reduce complexity

## 🤝 Contributing & Development Guide

### 🚀 Recent Enhancements (v2.0)

The infrastructure has been significantly enhanced with:

- **🎯 Enhanced Configuration System**: New `service_overrides` with 200+ configuration options
- **🏗️ Advanced Architecture Management**: Smart mixed-cluster support with `cpu_arch_override`
- **📦 Flexible Service Selection**: Granular service enablement with scenario-based examples
- **⚙️ Modern Domain Structure**: `{workspace}.{platform}.{base_domain}` format
- **📋 Comprehensive Testing**: Terraform native testing with make commands
- **🔧 Troubleshooting Automation**: Advanced diagnostic scripts with multiple modes

### 🏗️ Collaboration Prerequisites

To effectively contribute to this project, you'll need a **minimum viable homelab setup** for testing and development:

#### 📋 Minimum Hardware Requirements

**Raspberry Pi Cluster Setup:**

- **2x Raspberry Pi 4** (minimum)
- **16GB RAM per Pi** (8GB minimum, 16GB recommended)
- **64GB+ MicroSD Cards** (Class 10, A2 rating recommended)
- **Reliable Power Supply** (Official Pi adapters recommended)
- **Gigabit Network Switch** (for cluster networking)
- **Ethernet Cables** (for stable connectivity)

**Alternative Setups:**

- **2x Intel NUCs or Mini PCs** (AMD64 architecture)
- **Mixed setup**: 1x Raspberry Pi + 1x x86 machine (for testing mixed architectures)
- **Virtual machines** on a powerful host (minimum 32GB RAM total)

#### 🖥️ Software Prerequisites

**Base Operating System:**

```bash
# Ubuntu Server 22.04 LTS (recommended)
# Download from: https://ubuntu.com/download/raspberry-pi
# Flash with Raspberry Pi Imager or balenaEtcher
```

**Required Tools on Development Machine:**

```bash
# Package managers (macOS)
brew install terraform kubectl helm

# Package managers (Ubuntu/Debian)
sudo apt update
sudo apt install -y terraform kubectl helm

# Verify installations
terraform version    # >= 1.0
kubectl version      # >= 1.21
helm version         # >= 3.0
```

#### 🚀 Raspberry Pi Cluster Setup

**1. Initial Pi Configuration**

```bash
# Enable SSH and configure each Pi
sudo systemctl enable ssh
sudo systemctl start ssh

# Update system
sudo apt update && sudo apt upgrade -y

# Set up unique hostnames
sudo hostnamectl set-hostname homelab-01  # Pi 1
sudo hostnamectl set-hostname homelab-02  # Pi 2

# Configure static IPs (optional but recommended)
sudo nano /etc/netplan/50-cloud-init.yaml
```

**Example netplan configuration:**

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: [192.168.1.101/24]  # Pi 1: .101, Pi 2: .102
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

**2. MicroK8s Installation**

```bash
# Install MicroK8s on each Pi
sudo snap install microk8s --classic --channel=1.28

# Add user to microk8s group
sudo usermod -a -G microk8s $USER
newgrp microk8s

# Enable required addons
microk8s enable dns storage

# On the first Pi (master), get join token
microk8s add-node

# On the second Pi, join the cluster
microk8s join <ip>:<port>/<token>

# Verify cluster status
microk8s kubectl get nodes
```

**3. Configure kubectl Access**

```bash
# Export kubeconfig from master Pi
microk8s config > ~/.kube/homelab-config

# On your development machine, copy the config
scp pi@192.168.1.101:~/.kube/homelab-config ~/.kube/homelab-config

# Test connectivity
kubectl --kubeconfig ~/.kube/homelab-config get nodes
```

#### 🔧 Development Environment Setup

**1. Clone and Configure Repository**

```bash
# Clone the repository
git clone https://github.com/gannino/tf-kube-any-compute.git
cd tf-kube-any-compute

# Create development branch
git checkout -b feature/your-feature-name

# Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars
```

**2. Configure for Raspberry Pi Development**

```bash
# Edit terraform.tfvars for Pi cluster
cat > terraform.tfvars << EOF
# Raspberry Pi Configuration
base_domain = "local"
platform_name = "microk8s"
cpu_arch = "arm64"

# Resource-conscious settings
use_nfs_storage = false
use_hostpath_storage = true
enable_resource_limits = true
default_cpu_limit = "200m"
default_memory_limit = "256Mi"

# Enable core services only for development
services = {
  traefik = true
  metallb = true
  host_path = true
  prometheus = true
  grafana = true
  consul = false     # Disable resource-intensive services
  vault = false      # during initial development
  loki = false
  gatekeeper = false
  portainer = true
  node_feature_discovery = true
}

# MetalLB configuration for Pi network
metallb_address_pool = "192.168.1.200-192.168.1.210"
EOF
```

**3. Initialize and Test**

```bash
# Initialize Terraform
make init

# Create development workspace
terraform workspace new dev

# Test configuration
make test-safe

# Plan deployment
make plan

# Deploy to Pi cluster
make apply
```

#### 🎯 Development Best Practices

**Testing Workflow:**

```bash
# Always test before committing
make test-safe                    # Safe tests (no deployment)
make debug                        # Check cluster health
make test-integration             # Test live infrastructure

# Clean up between tests
terraform destroy -auto-approve   # Clean deployment
make test-cleanup                 # Clean artifacts
```

**Resource Management:**

- Start with minimal services to avoid resource exhaustion
- Use `make debug` to monitor resource usage
- Scale up services gradually as you add capacity
- Monitor Pi temperatures during intensive operations

**Contribution Workflow:**

```bash
# Create feature branch
git checkout -b feature/your-improvement

# Make changes and test thoroughly
make test-all

# Commit with descriptive messages
git commit -m "feat: add improved error handling for ARM64 clusters"

# Push and create PR
git push origin feature/your-improvement
# Open PR on GitHub
```

#### 💡 Tips for Pi Development

**Performance Optimization:**

- Use faster MicroSD cards (SanDisk Extreme, Samsung EVO Select)
- Consider USB 3.0 SSDs for better I/O performance
- Monitor temperatures: `vcgencmd measure_temp`
- Use heat sinks and fans for sustained workloads

**Troubleshooting Common Pi Issues:**

```bash
# Check MicroK8s status
microk8s inspect

# View system resources
htop
df -h
free -h

# Monitor cluster health
kubectl top nodes
kubectl top pods --all-namespaces
```

**Backup and Recovery:**

```bash
# Backup MicroK8s cluster
microk8s kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Export important configs
cp ~/.kube/homelab-config ~/backup/
cp terraform.tfvars ~/backup/
```

### 🛠️ Development Workflow

#### 1. Setting Up Development Environment

```bash
# Clone repository
git clone https://github.com/gannino/tf-kube-any-compute.git
cd tf-kube-any-compute

# Install development dependencies
make version                    # Check tool versions
make detect-environment         # Analyze current environment

# Initialize and validate
make init                       # Initialize Terraform
make test-safe                  # Run safe tests
```

#### 2. Making Changes

```bash
# Format and validate
make fmt                        # Format Terraform files
make test-lint                  # Check formatting and validation

# Test changes
make test-unit                  # Test configuration logic
make test-scenarios             # Test deployment scenarios
```

#### 3. Testing Infrastructure Changes

```bash
# Plan and apply
make plan                       # Review planned changes
make apply                      # Deploy to test environment

# Validate deployment
make debug                      # Run diagnostics
make test-integration           # Test live infrastructure
```

#### 4. Contributing Changes

```bash
# Run full test suite
make test-all                   # Comprehensive testing

# Clean up
make test-cleanup               # Remove test artifacts
make clean                      # Clean temporary files
```

### 📝 Contribution Guidelines

#### Code Standards

- **Terraform Formatting**: Use `make fmt` before committing
- **Variable Validation**: Add validation rules for new variables
- **Documentation**: Update README for new features
- **Testing**: Add tests for new functionality

#### Testing Requirements

- **Unit Tests**: Test configuration logic and validation
- **Scenario Tests**: Test different deployment configurations
- **Integration Tests**: Validate live infrastructure functionality
- **Security Tests**: Ensure security best practices

#### Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Test** your changes thoroughly (`make test-all`)
4. **Commit** your changes (`git commit -m 'Add amazing feature'`)
5. **Push** to the branch (`git push origin feature/amazing-feature`)
6. **Open** a Pull Request

### 🤖 AI-Assisted Development

For contributors using AI assistants, we provide specialized prompts optimized for different models:

- **📁 [AI Contribution Prompts](prompts/)** - Model-specific prompts for GPT-4, Claude, and Gemini
- **🧠 [GPT-4 Prompt](prompts/GPT4-CONTRIBUTION-PROMPT.md)** - Structured development and analytical problem-solving
- **📘 [Claude Prompt](prompts/CLAUDE-CONTRIBUTION-PROMPT.md)** - Comprehensive analysis and systematic execution
- **🎨 [Gemini Prompt](prompts/GEMINI-CONTRIBUTION-PROMPT.md)** - Creative innovation and community-driven development

These prompts ensure AI-assisted contributions maintain project quality and standards.

### 🔍 Debugging and Troubleshooting Development

#### Development Tools

```bash
# Infrastructure debugging
make debug                      # Comprehensive diagnostics
make debug-summary              # Quick health check
make cluster-info               # Basic cluster information
make logs                       # Recent service logs

# Terraform debugging
terraform console               # Interactive Terraform console
terraform state list           # List resources in state
terraform state show <resource> # Show resource details
```

#### Common Development Issues

**Terraform State Issues:**

```bash
# Refresh state
make refresh                    # Refresh Terraform state
terraform state pull           # Check state file

# Fix state inconsistencies
terraform import <resource> <id>
terraform state rm <resource>
```

**Testing Issues:**

```bash
# Reset test environment
make test-cleanup               # Clean test artifacts
make clean                      # Remove temporary files
terraform workspace select default
```

**Service Deployment Issues:**

```bash
# Debug specific services
make debug --service vault      # Service-specific diagnostics
kubectl logs -l app=<service>   # Service logs
kubectl describe pod <pod-name> # Pod details
```

### Community-Driven Development

While the roadmap reflects the creator's vision, **this project is driven by community support and suggestions**. We encourage:

- **Feature requests** based on real homelab needs
- **Use case discussions** to prioritize development
- **Community feedback** to shape the project direction

### Areas for Contribution

- Additional Kubernetes distributions support
- New service integrations
- Performance optimizations
- Documentation improvements
- Troubleshooting guides

## 🧪 Testing Framework & Quality Assurance

### 🔬 Comprehensive Testing Strategy

The infrastructure includes a robust testing framework using **Terraform native testing** for reliable validation:

**Test Types:**

- **Unit Tests** - Core logic validation (architecture detection, storage classes, helm configs)
- **Scenario Tests** - Deployment scenarios (ARM64, mixed clusters, storage configurations)
- **Integration Tests** - Live infrastructure validation (connectivity, health checks)
- **Performance Tests** - Service response times and resource usage
- **Security Tests** - Vulnerability scanning and policy validation

### 🚀 Make Commands for Testing

#### Quick Testing

```bash
# Run quick validation tests
make test-quick              # Lint + validate + unit tests

# Run comprehensive test suite
make test-all               # All tests including integration

# Run safe tests only (no resource provisioning)
make test-safe              # Lint + validate + unit + scenarios
```

#### Specific Test Types

```bash
# Core validation
make test-lint              # Terraform formatting and linting
make test-validate          # Terraform configuration validation

# Logic testing
make test-unit              # Architecture detection, storage, helm logic
make test-scenarios         # ARM64, mixed clusters, configuration scenarios

# Live testing (requires deployed infrastructure)
make test-integration       # Service health, connectivity, functionality
make test-performance       # Load testing and response times
make test-security          # Security scanning and policy validation
```

#### Test Utilities

```bash
# Test reporting
make test-coverage          # Generate test coverage report
make test-regression        # Run regression tests only

# Test management
make test-cleanup           # Clean up test artifacts
make ci-test               # CI/CD test pipeline
```

### 📋 Test Coverage Areas

**Unit Test Coverage:**

- ✅ Architecture detection and selection logic
- ✅ Storage class configuration and fallbacks
- ✅ Certificate resolver mapping
- ✅ Helm configuration inheritance and overrides
- ✅ Service enablement boolean logic
- ✅ Resource naming conventions
- ✅ Mixed cluster configuration

**Scenario Test Coverage:**

- ✅ ARM64 Raspberry Pi clusters
- ✅ AMD64 cloud and homelab clusters
- ✅ Mixed architecture deployments
- ✅ MicroK8s vs K3s configurations
- ✅ NFS vs hostpath storage scenarios
- ✅ Environment-specific configurations

**Integration Test Coverage:**

- ✅ Cluster connectivity and kubectl access
- ✅ Service health and pod status validation
- ✅ Ingress configuration and SSL certificates
- ✅ Storage functionality and PVC creation
- ✅ Service discovery and networking

### 🎯 Example Test Output

```bash
$ make test-unit
🧪 Running unit tests...
✅ test_architecture_detection
✅ test_storage_class_selection
✅ test_cert_resolver_defaults
✅ test_helm_config_defaults
✅ test_mixed_cluster_overrides
✅ All unit tests passed!

$ make test-scenarios
🧪 Running scenario tests...
✅ ARM64 Raspberry Pi scenario
✅ Mixed architecture scenario
✅ Cloud deployment scenario
✅ Storage configuration scenarios
✅ All scenario tests passed!
```

## 📋 Complete Variable Reference

### 🎯 Core Configuration Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `base_domain` | string | `"local"` | Base domain name (e.g., 'example.com') |
| `platform_name` | string | `"k3s"` | Platform identifier (k3s, eks, gke, aks, microk8s) |
| `cpu_arch` | string | `""` | CPU architecture (`""` = auto-detect, `"amd64"`, `"arm64"`) |
| `auto_mixed_cluster_mode` | bool | `true` | Automatically configure services for mixed architecture clusters |

### 🏗️ Architecture Management Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cpu_arch_override` | object | `{}` | Per-service CPU architecture overrides |
| `disable_arch_scheduling` | object | `{}` | Disable architecture-based scheduling for specific services |

### 🛠️ Service Enablement Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `services.traefik` | bool | `true` | Enable Traefik ingress controller |
| `services.metallb` | bool | `true` | Enable MetalLB load balancer |
| `services.nfs_csi` | bool | `true` | Enable NFS CSI storage driver |
| `services.host_path` | bool | `true` | Enable HostPath storage driver |
| `services.prometheus` | bool | `true` | Enable Prometheus monitoring |
| `services.prometheus_crds` | bool | `true` | Enable Prometheus CRDs |
| `services.grafana` | bool | `true` | Enable Grafana dashboards |
| `services.loki` | bool | `true` | Enable Loki log aggregation |
| `services.promtail` | bool | `true` | Enable Promtail log collection |
| `services.consul` | bool | `true` | Enable Consul service discovery |
| `services.vault` | bool | `true` | Enable Vault secrets management |
| `services.gatekeeper` | bool | `false` | Enable Gatekeeper policy engine |
| `services.portainer` | bool | `true` | Enable Portainer management UI |
| `services.node_feature_discovery` | bool | `true` | Enable Node Feature Discovery |

### 💾 Storage Configuration Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `use_nfs_storage` | bool | `false` | Use NFS storage as primary backend |
| `use_hostpath_storage` | bool | `true` | Use hostPath storage |
| `nfs_server_address` | string | `"192.168.1.100"` | NFS server IP address |
| `nfs_server_path` | string | `"/mnt/k8s-storage"` | NFS server path |
| `default_storage_class` | string | `""` | Default storage class (empty = auto-detect) |

### 🔒 Security & Access Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `traefik_dashboard_password` | string | `""` | Traefik dashboard password (empty = auto-generate) |
| `grafana_admin_password` | string | `""` | Grafana admin password (empty = auto-generate) |
| `portainer_admin_password` | string | `""` | Portainer admin password (empty = auto-generate) |
| `le_email` | string | `""` | Let's Encrypt email for certificates |

### ⚙️ Performance & Resource Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_resource_limits` | bool | `true` | Enable resource limits on all services |
| `default_cpu_limit` | string | `"500m"` | Default CPU limit per container |
| `default_memory_limit` | string | `"512Mi"` | Default memory limit per container |
| `default_helm_timeout` | number | `600` | Default Helm deployment timeout (seconds) |

### 🎛️ Service Override Variables

The `service_overrides` variable provides fine-grained control over individual services:

| Service | Available Overrides |
|---------|-------------------|
| `traefik` | cpu_arch, chart_version, storage_class, storage_size, enable_dashboard, dashboard_password, cert_resolver, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `prometheus` | cpu_arch, chart_version, storage_class, storage_size, enable_ingress, retention_period, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `grafana` | cpu_arch, chart_version, storage_class, storage_size, enable_persistence, node_name, admin_user, admin_password, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `metallb` | address_pool, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `vault` | storage_class, storage_size, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `consul` | storage_class, storage_size, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `portainer` | storage_class, storage_size, admin_password, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |
| `loki` | storage_class, storage_size, cpu_limit, memory_limit, cpu_request, memory_request, helm_* |

### 📁 Configuration Scenarios

#### Scenario 1: Raspberry Pi Homelab

```hcl
base_domain = "local"
platform_name = "k3s"
cpu_arch = "arm64"
use_nfs_storage = false
use_hostpath_storage = true

services = {
  traefik = true
  metallb = true
  host_path = true
  prometheus = true
  grafana = true
  loki = false      # Disable resource-intensive services
  consul = false
  vault = false
  portainer = true
}
```

#### Scenario 2: Mixed Architecture Production

```hcl
base_domain = "example.com"
platform_name = "k3s"
cpu_arch = ""                     # Auto-detect
auto_mixed_cluster_mode = true
use_nfs_storage = true
le_email = "admin@example.com"

cpu_arch_override = {
  traefik = "amd64"              # Performance critical
  prometheus = "amd64"           # Resource intensive
  grafana = "arm64"              # UI services
  portainer = "arm64"
}

# All services enabled for production
services = {
  traefik = true
  metallb = true
  nfs_csi = true
  prometheus = true
  grafana = true
  loki = true
  consul = true
  vault = true
  portainer = true
}
```

#### Scenario 3: Cloud Development

```hcl
base_domain = "dev.example.com"
platform_name = "eks"
cpu_arch = ""
use_nfs_storage = false           # Use cloud storage
le_email = "dev-team@example.com"

services = {
  traefik = true
  metallb = false                 # Use cloud load balancer
  prometheus = true
  grafana = true
  loki = true
  consul = true
  vault = true
  gatekeeper = false              # Disable policies in dev
  portainer = true
}
```
