# tf-kube-any-compute

## Universal Kubernetes Infrastructure for Any Compute Platform

[![LinkedIn][linkedin-shield]][linkedin-url]

## 🏠 **About This Project**

**tf-kube-any-compute** provides a **comprehensive, cloud-agnostic Kubernetes infrastructure** designed specifically for **tech enthusiasts and homelab builders** who want to:

- **🚀 Spin up clusters quickly** on any Kubernetes distribution (K3s, MicroK8s, EKS, GKE, AKS)
- **🔧 Learn Kubernetes** through hands-on experience with production-grade services
- **📈 Scale incrementally** by adding services based on their architecture and needs
- **🏗️ Build expertise** in Infrastructure as Code, monitoring, service mesh, and security

Perfect for **any compute platform**: **Raspberry Pi clusters**, **home servers**, **cloud environments**, **edge devices**, and **learning labs**.

## 🌟 **Project Origin**

This project represents the culmination of a **lifelong passion for technology** that began at age 14. While my friends were focused on playing games, I found myself fascinated by understanding and fixing computers - a curiosity that naturally evolved into a career in IT and eventually led to this comprehensive infrastructure platform.

### **🚀 The Early Spark**

**The Beginning**: At 14, technology wasn't just a hobby - it was a calling. While peers were gaming, I was deep in system configurations, troubleshooting hardware, and learning how computers actually worked. This early passion for understanding the "how" and "why" of technology became the foundation for everything that followed.

**The Natural Progression**: That teenage curiosity grew into professional expertise, leading to a career built on genuine passion for infrastructure and systems. The same drive that kept me up late fixing computers as a teenager now fuels the enterprise solutions I architect today.

### **🏡 The Personal Project Catalyst**

This project emerged from the same curiosity that drove me at 14 - wanting to understand and master new technologies in my personal environment:

- Testing different Kubernetes distributions (K3s, MicroK8s) on ARM64 hardware
- Exploring modern infrastructure patterns outside of work constraints
- Applying the problem-solving mindset that's driven my career from the beginning
- Bridging the gap between enterprise complexity and accessible learning environments

**The Core Motivation**: The same passion for fixing and understanding technology that started in my teenage years continues to drive exploration of cutting-edge infrastructure patterns.

### **🚀 From Enterprise Experience to Universal Solution**

Drawing from enterprise cloud architecture experience:

- **🔧 Modular Design**: Applied systematic Infrastructure-as-Code principles developed through enterprise experience
- **🏗️ Architecture Intelligence**: Implemented automatic platform detection learned from multi-cloud deployments
- **🧪 Enterprise Testing**: Brought production-grade testing patterns to homelab infrastructure
- **� Security First**: Applied the same security-hardened approaches required in financial services
- **🤖 AI-Enhanced Development**: Leveraged modern AI tools to accelerate and refine development

### **🌍 The Mission**

Having contributed to enterprise technologies throughout my career - from network infrastructure to cloud-native solutions - I believe in democratizing access to sophisticated infrastructure. This module represents that philosophy: making enterprise-grade patterns accessible to anyone with curiosity and a willingness to learn.

### **� The Technical Philosophy**

This project embodies lessons learned from **17 years of infrastructure evolution**:

- **🌐 Universal Patterns**: What works in enterprise clouds should work on edge devices
- **🎓 Knowledge Transfer**: Bridge the gap between traditional networking and cloud-native
- **🤝 Community Innovation**: Share enterprise-grade patterns with the broader community
- **🚀 Continuous Evolution**: Embrace new technologies while honoring proven foundations

What started as teenage curiosity about how computers work has evolved into a passion-driven contribution to democratizing access to production-grade Kubernetes environments. Every module reflects the same problem-solving enthusiasm that kept me up late fixing computers as a kid.

### 🎯 **Homelab Philosophy**

This infrastructure is built with the homelab mindset:

- **Start Simple**: Deploy core services first, add complexity gradually
- **Learn by Doing**: Each service teaches different Kubernetes concepts
- **Architecture Agnostic**: Works on ARM64 Raspberry Pis and AMD64 servers
- **Production Patterns**: Learn industry best practices in your homelab
- **Cost Conscious**: Optimized for resource-constrained environments

## 🛠️ **Services Deployed**

### **Core Infrastructure**

- **🌐 Traefik** - Modern ingress controller with automatic SSL
- **⚖️ MetalLB** - Load balancer for bare metal clusters
- **💾 Storage Drivers** - NFS CSI + HostPath for flexible storage
- **🔍 Node Feature Discovery** - Hardware detection and labeling

### **Platform Services**

- **📊 Prometheus + Grafana** - Complete monitoring and visualization stack
- **🔐 Vault + Consul** - Secrets management and service discovery with service mesh
- **🌐 Service Mesh** - Consul Connect integration with Traefik for advanced traffic management
- **🐳 Portainer** - Container management web UI
- **🛡️ Gatekeeper** - Policy engine (optional)

### **Built With**

- [Terraform](https://terraform.io) - Infrastructure as Code
- [Helm](https://helm.sh) - Kubernetes package manager
- [Kubernetes](https://kubernetes.io) - Container orchestration

## 🏗️ **Architecture Overview**

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

## 📈 **Current Status & Recent Enhancements**

### **✅ Task 5 Completed: Troubleshooting Automation**

- **🔧 Comprehensive Debug Scripts**: Enhanced troubleshooting framework with multiple diagnostic modes
- **📊 Main Debug Script**: Multi-mode diagnostics (`--quick`, `--full`, `--network`, `--storage`, `--service`)
- **🔐 Vault Health Check**: Specialized Vault diagnostics with authentication handling
- **🌐 Ingress Diagnostics**: Complete ingress and networking analysis with SSL certificate checking
- **🎯 Smart Output**: Color-coded status indicators with actionable troubleshooting recommendations

### **✅ Task 4 Completed: Enhanced Testing Framework**

- **🧪 Terraform Native Testing**: Comprehensive test suite using `terraform test` commands
- **🔬 Multi-Level Testing**: Unit tests, scenario tests, integration tests, and performance tests
- **📋 Make Commands**: Full test automation with `make test-*` commands
- **🎯 Test Coverage**: Architecture detection, storage classes, helm configs, service enablement

### **✅ Task 3 Completed: Security Hardening**

- **🔒 Infrastructure Stability**: Achieved 0 destroys (down from 4 destroys)
- **🛡️ Enhanced Security**: Removed `api.insecure=true` vulnerability from Traefik
- **⚙️ Service Override Framework**: 200+ configuration options implemented
- **📊 Resource Limits**: Enhanced with pod-level and PVC-level constraints

### **⚠️ Known Issues & TODO**

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

### **🎯 Next Phase: Complete Security Hardening**

1. **Resolve Gatekeeper CRD deployment**: Test server-side apply fix
2. **Enable comprehensive policies**:
   - Security context enforcement (runAsNonRoot, no privilege escalation)
   - Privileged container prevention
   - Resource limits enforcement
   - Storage size limits (10Gi max PVCs)
3. **Validate policy compliance**: Ensure existing workloads meet security standards

**Note**: Set `enable_gatekeeper = true` in `terraform.tfvars` when ready to deploy policy engine.

## 🚀 **Quick Start**

### **Prerequisites**

```bash
# Install required tools
terraform >= 1.0
kubectl
helm >= 3.0

# Verify cluster access
kubectl cluster-info
```

### **1. Clone and Configure**

```bash
git clone https://github.com/gannino/tf-kube-any-compute.git
cd tf-kube-any-compute

# Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

### **2. Deploy Infrastructure**

```bash
# Initialize Terraform
make init

# Create environment workspace
terraform workspace new homelab

# Review planned changes
make plan

# Deploy services
make apply
```

### **3. Access Your Services**

After deployment, access services at:

- **Traefik Dashboard**: `https://traefik.homelab.k3s.example.com`
- **Grafana**: `https://grafana.homelab.k3s.example.com`
- **Portainer**: `https://portainer.homelab.k3s.example.com`
- **Consul**: `https://consul.homelab.k3s.example.com`
- **Vault**: `https://vault.homelab.k3s.example.com`

## ⚙️ **Configuration**

For comprehensive configuration options, see [VARIABLES.md](VARIABLES.md) which covers:

- **Service Overrides**: Fine-tune every aspect of your deployment
- **Mixed Architecture Management**: ARM64/AMD64 cluster strategies
- **Storage Configuration**: NFS, HostPath, and storage class options
- **Password Management**: Auto-generation and custom overrides
- **DNS & SSL**: Hurricane Electric and Let's Encrypt setup
- **Architecture Detection**: Intelligent service placement

## 🎯 **Kubernetes Distribution Support**

### **🥧 Raspberry Pi / ARM64 (MicroK8s)**

```bash
# Install MicroK8s
snap install microk8s --classic

# Configure for ARM64
echo 'cpu_arch = "arm64"' >> terraform.tfvars
echo 'enable_microk8s_mode = true' >> terraform.tfvars
echo 'use_hostpath_storage = true' >> terraform.tfvars
```

### **☁️ K3s Clusters**

```bash
# Configure for K3s
echo 'use_nfs_storage = true' >> terraform.tfvars
echo 'nfs_server = "192.168.1.100"' >> terraform.tfvars
echo 'metallb_address_pool = "192.168.1.200-210"' >> terraform.tfvars
```

### **🌩️ Cloud Providers (EKS/GKE/AKS)**

```bash
# Use cloud storage and load balancers
echo 'use_nfs_storage = false' >> terraform.tfvars
echo 'use_hostpath_storage = false' >> terraform.tfvars
```

## 🏛️ **Opinionated Decisions & Defaults**

This infrastructure makes intelligent decisions to provide a **production-ready, secure, and maintainable** platform:

### **🔒 Security First**

- **SSL by Default**: Automatic HTTPS with Let's Encrypt wildcard certificates
- **DNS Challenge**: Hurricane Electric (dns.he.net) for wildcard certificate validation
- **Dynamic DNS**: HE.net tunnel broker support for homelab domains
- **Traefik Dashboard**: Enabled for operational visibility (`service_overrides.traefik.enable_dashboard = true`)
- **Custom Passwords**: Override auto-generated passwords for all services
- **Resource Limits**: Prevent resource exhaustion (`enable_resource_limits = true`)
- **Helm Security**: Webhooks disabled for compatibility (`default_helm_disable_webhooks = true`)

### **🏗️ Architecture Intelligence**

- **Auto-Detection**: Automatically detects ARM64/AMD64 architecture (`cpu_arch = ""`)
- **Mixed Clusters**: Intelligent service placement on heterogeneous nodes
- **Universal Support**: Works across K3s, MicroK8s, EKS, GKE, AKS

### **💾 Storage Strategy**

- **NFS Primary**: Shared storage for production workloads (`use_nfs_storage = true`)
- **HostPath Fallback**: Local storage for development (`use_hostpath_storage = true`)
- **Smart Selection**: `nfs-csi-safe` for critical data, `hostpath` for UI components

### **⚡ Performance & Reliability**

- **Conservative Timeouts**: 5-minute default with service-specific overrides
- **Balanced Resources**: 500m CPU / 512Mi memory limits for stability
- **Helm Best Practices**: Force updates, cleanup on failure, proper waiting

### **🚀 Service Philosophy**

- **Core Services**: Essential infrastructure enabled by default
- **Platform Services**: Complete experience with monitoring, secrets, service mesh
- **Optional Components**: Gatekeeper disabled by default to reduce complexity

## 🎛️ **Architecture Management & Mixed Cluster Strategy**

Comprehensive architecture detection and service placement for **hybrid homelabs** with mixed ARM64/AMD64 hardware.

### **🔍 Intelligent Architecture Detection**

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

### **📋 Architecture Selection Priority**

**For Application Services:**

1. **User Override** (`cpu_arch_override.service`)
2. **Most Common Worker Architecture** (where apps typically run)
3. **Most Common Overall Architecture** (fallback)
4. **AMD64 Default** (final fallback)

**For Cluster-Wide Services:**

1. **User Override** (`cpu_arch_override.service`)
2. **Control Plane Architecture** (infrastructure follows masters)
3. **Most Common Architecture** (fallback)

### **🎯 Service Placement Strategy**

**🌐 Cluster-Wide Services (Architecture-Agnostic):**

- `node_feature_discovery` - Hardware detection on all nodes
- `metallb` - Load balancer speakers on all nodes  
- `nfs_csi` - Storage driver on all nodes

**🚀 Application Services (Worker-Optimized):**

- `traefik`, `prometheus`, `consul`, `vault`, `grafana`, `portainer`
- Prefer worker node architecture for optimal placement

### **🏗️ Mixed Cluster Scenarios**

#### **Scenario 1: ARM64 Masters + AMD64 Workers**

```
Control Plane: 3x ARM64 Raspberry Pi
Workers: 2x AMD64 Mini PCs

Result:
- Applications → AMD64 workers (better performance)
- Cluster services → ARM64 masters (infrastructure consistency)
```

#### **Scenario 2: Homogeneous ARM64 Cluster**

```
All Nodes: ARM64 Raspberry Pi

Result:
- All services → ARM64
- Optimized resource limits for ARM64
```

#### **Scenario 3: Mixed Everything**

```
Masters: 1x ARM64, 1x AMD64
Workers: 2x ARM64, 3x AMD64

Result:
- Applications → AMD64 (most common worker arch)
- Cluster services → AMD64 (most common overall)
```

### **⚙️ Manual Architecture Overrides**

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

### **🔧 Architecture Debug Information**

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

### **🏠 Homelab Architecture Patterns**

#### **1. Raspberry Pi Control + x86 Workers**

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

#### **2. Homogeneous ARM64 Cluster**

```hcl
# All Raspberry Pi cluster
cpu_arch = "arm64"              # Explicit architecture
enable_microk8s_mode = true     # ARM64 optimizations
use_hostpath_storage = true     # Local storage for ARM64

# Resource limits for ARM64
default_cpu_limit = "500m"
default_memory_limit = "512Mi"
```

#### **3. Development/Learning Environment**

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

#### **4. Production Mixed Cluster**

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

## 🧠 **Configuration Management Philosophy**

The infrastructure uses a **centralized configuration approach** with intelligent defaults and override capabilities:

### **🎯 Configuration Hierarchy**

1. **Locals (locals.tf)** - Centralized logic and computed values
2. **Variables (variables.tf)** - User inputs and overrides
3. **Main (main.tf)** - Service deployments using local values
4. **Debug Outputs** - Visibility into computed configurations

### **🔄 Configuration Flow**

```
User Variables → Local Computations → Service Deployments
     ↓                    ↓                    ↓
 terraform.tfvars → locals.tf → main.tf
     ↓                    ↓                    ↓
 Overrides        → Smart Defaults → Consistent Application
```

### **📋 Configuration Categories**

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

### **🎛️ Override Pattern**

All configurations follow the same override pattern:

```hcl
service_config = coalesce(
  var.service_override.service,  # User override
  local.computed_default,        # Smart default
  "fallback_value"              # Safety fallback
)
```

## 📊 **Configuration Reference**

### **Default Values & Rationale**

| Variable | Default | Rationale |
|----------|---------|-----------|
| `domain_name` | `example.com` | Multi-environment domain strategy |
| `letsencrypt_email` | `admin@example.com` | Must be updated for production |
| `service_overrides.traefik.enable_dashboard` | `true` | Operational visibility by default |
| `cpu_arch` | `""` (auto-detect) | Universal cluster support |
| `use_nfs_storage` | `true` | Shared storage for production |
| `enable_resource_limits` | `true` | Prevent resource exhaustion |
| `metallb_address_pool` | `192.168.1.200-210` | Common homelab IP range |

### **Service Enablement Defaults**

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

### **Environment-Specific Domains**

```hcl
domain_name = {
  default = "example.com"
  homelab = "homelab.local"
  dev     = "dev.local"
  prod    = "example.com"
}
```

## 🔧 **Workspace Management**

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

### **Available Workspaces**

- `homelab` - Home laboratory environment
- `dev` - Development environment
- `staging` - Staging/QA environment
- `prod` - Production environment

## 📈 **Learning Path**

### **🎓 Beginner (Start Here)**

1. **Deploy Core Services**: Traefik + MetalLB
2. **Add Monitoring**: Prometheus + Grafana
3. **Container Management**: Portainer
4. **Learn kubectl**: Explore pods, services, ingresses

### **🎓 Intermediate**

1. **Service Discovery**: Deploy Consul
2. **Secrets Management**: Add Vault
3. **Storage Deep Dive**: Configure NFS + HostPath
4. **Architecture Optimization**: Mixed ARM64/AMD64 clusters

### **🎓 Advanced**

1. **Policy Enforcement**: Enable Gatekeeper
2. **Custom Dashboards**: Create Grafana dashboards
3. **Service Mesh**: Consul Connect with Traefik integration
4. **DNS Management**: Hurricane Electric dynamic DNS setup
5. **GitOps**: Integrate with ArgoCD

## 🛠️ **Troubleshooting**

### **🔧 Automated Troubleshooting Scripts**

The infrastructure includes comprehensive troubleshooting scripts for rapid diagnosis and issue resolution:

#### **📊 Main Diagnostic Script**

```bash
# Comprehensive infrastructure health check
./scripts/debug.sh

# Quick health check (essential services only)
./scripts/debug.sh --quick

# Full detailed analysis
./scripts/debug.sh --full

# Network-specific diagnostics
./scripts/debug.sh --network

# Storage-specific diagnostics
./scripts/debug.sh --storage

# Service-specific analysis
./scripts/debug.sh --service vault
```

#### **🔐 Vault-Specific Diagnostics**

```bash
# Comprehensive Vault health check
./scripts/check-vault.sh

# Example output:
# ✅ Vault service available, requires authentication (HTTP 401)
# ✅ Vault ingress responding with HTTP 307 (redirect to login)
# ✅ 5/6 Vault pods running, 1 pending
# 💡 Tip: HTTP 401/403 responses indicate service is working but needs auth
```

#### **🌐 Ingress & Networking Diagnostics**

```bash
# Complete ingress and connectivity analysis
./scripts/check-ingress.sh

# Test SSL certificates
./scripts/check-ingress.sh --test-ssl

# Example output:
# ✅ Traefik controller healthy (LoadBalancer IP: 192.168.1.200)
# ✅ 6/6 ingress resources configured correctly
# ✅ 4/6 services responding (2 require authentication)
# ✅ Vault, Prometheus responding but need authentication (HTTP 401)
# ✅ Grafana, Portainer accessible without additional auth
```

#### **🚀 Script Features**

**Comprehensive Analysis:**

- Pod status and resource usage
- Service endpoint validation
- Ingress configuration and connectivity
- Storage class and PVC status
- Network policy and DNS resolution
- SSL certificate validation

**Service-Specific Checks:**

- **Vault**: Pod status, service endpoints, ingress response, optional seal status
- **Traefik**: Controller health, LoadBalancer IP, dashboard access
- **Prometheus**: Stack components, storage, data retention
- **Grafana**: UI accessibility, dashboard availability
- **Consul**: Service discovery, cluster status

**Smart Output:**

- Color-coded status indicators (✅ success, ⚠️ warning, ❌ error)
- Actionable troubleshooting recommendations
- Verbose mode for detailed debugging
- Timestamp logging for issue tracking

#### **🔍 Common Issues Detected**

**Pod Issues:**

```bash
# Script output example:
⚠️  [WARN] Pod vault-1 in namespace prod-vault-stack is Pending
💡 [TIP] Check node resources: kubectl describe node
💡 [TIP] Check pod events: kubectl describe pod vault-1 -n prod-vault-stack
```

**Connectivity Issues:**

```bash
# Script output example:
⚠️  [WARN] consul.prod.k3s.example.com not responding on HTTP or HTTPS
💡 [TIP] Check service status: kubectl get svc -n prod-consul-stack
💡 [TIP] Check pod logs: kubectl logs -l app=consul -n prod-consul-stack
```

**Storage Issues:**

```bash
# Script output example:
❌ [ERROR] PVC consul-data-0 is Pending
💡 [TIP] Check storage class: kubectl describe storageclass nfs-csi-safe
💡 [TIP] Check NFS server connectivity
```

### **🎯 Helm/Terraform Integration Issues**

**Common Issue**: Terraform fails to apply Helm releases due to state inconsistencies, resource conflicts, or failed deployments.

**Best Practice Resolution**:

```bash
# 1. Identify the problematic Helm release
helm list --all-namespaces
kubectl get pods --all-namespaces | grep -E "(Error|CrashLoop|Pending)"

# 2. Uninstall the Helm release manually
helm uninstall <release-name> -n <namespace>

# 3. Clean up any remaining resources (if needed)
kubectl delete namespace <namespace> --ignore-not-found
kubectl delete pvc --all -n <namespace> --ignore-not-found

# 4. Re-apply with Terraform
terraform apply -target=module.<service-name>

# 5. Verify deployment
kubectl get pods -n <namespace>
helm status <release-name> -n <namespace>
```

**Example - Fixing Vault Deployment Issues**:

```bash
# Check current state
helm list -A | grep vault
kubectl get pods -n prod-vault-stack

# Remove problematic release
helm uninstall prod-vault -n prod-vault-stack

# Clean up persistent volumes (if needed)
kubectl get pvc -n prod-vault-stack
kubectl delete pvc data-prod-vault-0 data-prod-vault-1 -n prod-vault-stack

# Re-deploy with Terraform
terraform apply -target=module.vault[0]

# Verify the fix
kubectl get pods -n prod-vault-stack
kubectl logs vault-0 -n prod-vault-stack
```

**When to Use This Approach**:

- ✅ Terraform apply fails with Helm resource conflicts
- ✅ Helm release is in `FAILED` or `PENDING-UPGRADE` state
- ✅ Resources exist but Terraform shows drift
- ✅ After manual `kubectl` changes that conflict with Terraform state
- ✅ When upgrading between major chart versions

**Prevention Tips**:

- Use `terraform plan` before applying changes
- Avoid manual `helm upgrade` commands on Terraform-managed releases
- Set appropriate Helm timeout values in service overrides
- Use `helm_wait = true` for critical services

### **Architecture Issues**

```bash
# Check detected architecture
terraform output detected_architecture

# Verify node architectures
kubectl get nodes -o wide

# Check pod placement
kubectl get pods -o wide -A | grep <service-name>
```

### **Storage Problems**

```bash
# Check storage classes
kubectl get storageclass

# Verify PVC status
kubectl get pvc -A

# Debug storage issues
kubectl describe pvc <pvc-name> -n <namespace>
```

### **Service Access Issues**

```bash
# Check ingress status
kubectl get ingress -A

# Verify certificates
kubectl get certificates -A

# Test service connectivity
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>
```

### **Mixed Architecture Troubleshooting**

```bash
# Check if pods are pending due to architecture constraints
kubectl get pods -A | grep Pending

# Describe pending pods
kubectl describe pod <pending-pod> -n <namespace>

# Verify nodes by architecture
kubectl get nodes -l kubernetes.io/arch=arm64
kubectl get nodes -l kubernetes.io/arch=amd64
```

## 🎯 **Best Practices**

### **🏠 Homelab Optimization**

- **Start Small**: Deploy core services first, add complexity gradually
- **Monitor Resources**: Use Grafana to track CPU/memory usage
- **Backup Configs**: Version control your `terraform.tfvars`
- **Document Changes**: Keep notes on customizations

### **🔒 Security**

- **Change Default Passwords**: Update all service passwords
- **Use Real Domains**: Configure proper DNS for SSL certificates
- **Network Segmentation**: Consider network policies for isolation
- **Regular Updates**: Keep Helm charts and images updated

### **⚡ Performance**

- **Resource Limits**: Set appropriate CPU/memory limits
- **Storage Optimization**: Use NFS for shared data, HostPath for local
- **Architecture Placement**: Put heavy workloads on powerful nodes
- **Monitoring**: Watch for resource bottlenecks

## 🤝 **Contributing**

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on:

- Development setup and pre-commit hooks
- Code standards and testing
- Pull request process
- Architecture guidelines

## 🗺️ **Roadmap**

- [ ] **GitOps Integration** - ArgoCD for continuous deployment
- [ ] **Backup Automation** - Velero for disaster recovery
- [ ] **Advanced Monitoring** - Custom Grafana dashboards
- [ ] **Service Mesh** - Consul Connect service mesh integration
- [ ] **Multi-Cluster** - Cluster federation support
- [ ] **Edge Computing** - K3s edge deployment patterns
- [ ] **Terraform Registry** - Publish as official Terraform module

## 🧪 **Testing Framework & Quality Assurance**

### **🔬 Comprehensive Testing Strategy**

The infrastructure includes a robust testing framework using **Terraform native testing** for reliable validation:

**Test Types:**

- **Unit Tests** - Core logic validation (architecture detection, storage classes, helm configs)
- **Scenario Tests** - Deployment scenarios (ARM64, mixed clusters, storage configurations)
- **Integration Tests** - Live infrastructure validation (connectivity, health checks)
- **Performance Tests** - Service response times and resource usage
- **Security Tests** - Vulnerability scanning and policy validation

### **🚀 Make Commands for Testing**

#### **Quick Testing**

```bash
# Run quick validation tests
make test-quick              # Lint + validate + unit tests

# Run comprehensive test suite
make test-all               # All tests including integration

# Run safe tests only (no resource provisioning)
make test-safe              # Lint + validate + unit + scenarios
```

#### **Specific Test Types**

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

#### **Test Utilities**

```bash
# Test reporting
make test-coverage          # Generate test coverage report
make test-regression        # Run regression tests only

# Test management
make test-cleanup           # Clean up test artifacts
make ci-test               # CI/CD test pipeline
```

### **📋 Test Coverage Areas**

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

### **🎯 Example Test Output**

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

## 📋 **Complete Variable Reference**

### **🎯 Core Configuration Variables**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `base_domain` | string | `"local"` | Base domain name (e.g., 'example.com') |
| `platform_name` | string | `"k3s"` | Platform identifier (k3s, eks, gke, aks, microk8s) |
| `cpu_arch` | string | `""` | CPU architecture (`""` = auto-detect, `"amd64"`, `"arm64"`) |
| `auto_mixed_cluster_mode` | bool | `true` | Automatically configure services for mixed architecture clusters |

### **🏗️ Architecture Management Variables**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cpu_arch_override` | object | `{}` | Per-service CPU architecture overrides |
| `disable_arch_scheduling` | object | `{}` | Disable architecture-based scheduling for specific services |

### **🛠️ Service Enablement Variables**

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

### **💾 Storage Configuration Variables**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `use_nfs_storage` | bool | `false` | Use NFS storage as primary backend |
| `use_hostpath_storage` | bool | `true` | Use hostPath storage |
| `nfs_server_address` | string | `"192.168.1.100"` | NFS server IP address |
| `nfs_server_path` | string | `"/mnt/k8s-storage"` | NFS server path |
| `default_storage_class` | string | `""` | Default storage class (empty = auto-detect) |

### **🔒 Security & Access Variables**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `traefik_dashboard_password` | string | `""` | Traefik dashboard password (empty = auto-generate) |
| `grafana_admin_password` | string | `""` | Grafana admin password (empty = auto-generate) |
| `portainer_admin_password` | string | `""` | Portainer admin password (empty = auto-generate) |
| `le_email` | string | `""` | Let's Encrypt email for certificates |

### **⚙️ Performance & Resource Variables**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_resource_limits` | bool | `true` | Enable resource limits on all services |
| `default_cpu_limit` | string | `"500m"` | Default CPU limit per container |
| `default_memory_limit` | string | `"512Mi"` | Default memory limit per container |
| `default_helm_timeout` | number | `600` | Default Helm deployment timeout (seconds) |

### **🎛️ Service Override Variables**

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

### **📁 Configuration Scenarios**

#### **Scenario 1: Raspberry Pi Homelab**

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

#### **Scenario 2: Mixed Architecture Production**

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

#### **Scenario 3: Cloud Development**

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

## 🤝 **Contributing & Development Guide**

### **🚀 Recent Enhancements (v2.0)**

The infrastructure has been significantly enhanced with:

- **🎯 Enhanced Configuration System**: New `service_overrides` with 200+ configuration options
- **🏗️ Advanced Architecture Management**: Smart mixed-cluster support with `cpu_arch_override`
- **📦 Flexible Service Selection**: Granular service enablement with scenario-based examples
- **⚙️ Modern Domain Structure**: `{workspace}.{platform}.{base_domain}` format
- **📋 Comprehensive Testing**: Terraform native testing with make commands
- **🔧 Troubleshooting Automation**: Advanced diagnostic scripts with multiple modes

### **🏗️ Collaboration Prerequisites**

To effectively contribute to this project, you'll need a **minimum viable homelab setup** for testing and development:

#### **📋 Minimum Hardware Requirements**

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

#### **🖥️ Software Prerequisites**

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

#### **🚀 Raspberry Pi Cluster Setup**

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

#### **🔧 Development Environment Setup**

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

#### **🎯 Development Best Practices**

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

#### **💡 Tips for Pi Development**

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

### **🛠️ Development Workflow**

#### **1. Setting Up Development Environment**

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

#### **2. Making Changes**

```bash
# Format and validate
make fmt                        # Format Terraform files
make test-lint                  # Check formatting and validation

# Test changes
make test-unit                  # Test configuration logic
make test-scenarios             # Test deployment scenarios
```

#### **3. Testing Infrastructure Changes**

```bash
# Plan and apply
make plan                       # Review planned changes
make apply                      # Deploy to test environment

# Validate deployment
make debug                      # Run diagnostics
make test-integration           # Test live infrastructure
```

#### **4. Contributing Changes**

```bash
# Run full test suite
make test-all                   # Comprehensive testing

# Clean up
make test-cleanup               # Remove test artifacts
make clean                      # Clean temporary files
```

### **📝 Contribution Guidelines**

#### **Code Standards**

- **Terraform Formatting**: Use `make fmt` before committing
- **Variable Validation**: Add validation rules for new variables
- **Documentation**: Update README for new features
- **Testing**: Add tests for new functionality

#### **Testing Requirements**

- **Unit Tests**: Test configuration logic and validation
- **Scenario Tests**: Test different deployment configurations
- **Integration Tests**: Validate live infrastructure functionality
- **Security Tests**: Ensure security best practices

 ne#### **Pull Request Process**

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Test** your changes thoroughly (`make test-all`)
4. **Commit** your changes (`git commit -m 'Add amazing feature'`)
5. **Push** to the branch (`git push origin feature/amazing-feature`)
6. **Open** a Pull Request

### **🤖 AI-Assisted Development**

For contributors using AI assistants, we provide specialized prompts optimized for different models:

- **📁 [AI Contribution Prompts](prompts/)** - Model-specific prompts for GPT-4, Claude, and Gemini
- **🧠 [GPT-4 Prompt](prompts/GPT4-CONTRIBUTION-PROMPT.md)** - Structured development and analytical problem-solving
- **📘 [Claude Prompt](prompts/CLAUDE-CONTRIBUTION-PROMPT.md)** - Comprehensive analysis and systematic execution  
- **🎨 [Gemini Prompt](prompts/GEMINI-CONTRIBUTION-PROMPT.md)** - Creative innovation and community-driven development

These prompts ensure AI-assisted contributions maintain project quality and standards.

### **🔍 Debugging and Troubleshooting Development**

#### **Development Tools**

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

#### **Common Development Issues**

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

### **Community-Driven Development**

While the roadmap reflects the creator's vision, **this project is driven by community support and suggestions**. We encourage:

- **Feature requests** based on real homelab needs
- **Use case discussions** to prioritize development
- **Community feedback** to shape the project direction

### **Areas for Contribution**

- Additional Kubernetes distributions support
- New service integrations
- Performance optimizations
- Documentation improvements
- Troubleshooting guides

## 📄 **License**

Distributed under the Apache License 2.0. See `LICENSE` for more information.

## 📞 **Contact & Support**

**Giovanni Annino** - [Website](https://giovannino.net) - [GitHub](https://github.com/gannino) - <giovanni.annino@gmail.com>

**Project Link**: [https://github.com/gannino/tf-kube-any-compute](https://github.com/gannino/tf-kube-any-compute)

### **Community**

- **[Issues](https://github.com/gannino/tf-kube-any-compute/issues)**: Report bugs and request features
- **[Discussions](https://github.com/gannino/tf-kube-any-compute/discussions)**: Share your homelab setups and ask questions
- **[Wiki](https://github.com/gannino/tf-kube-any-compute/wiki)**: Community-contributed guides and tips

## 🙏 **Acknowledgments**

- **[Kubernetes Community](https://kubernetes.io)** - For the amazing orchestration platform
- **[Traefik](https://traefik.io)** - For the modern ingress controller
- **[HashiCorp](https://hashicorp.com)** - For Terraform and Vault
- **[Prometheus](https://prometheus.io)** - For monitoring excellence
- **[Grafana](https://grafana.com)** - For beautiful visualizations
- **[Civo](https://civo.com)** - For the cloud platform and K3s expertise
- **[Hurricane Electric](https://he.net)** - For DNS services and IPv6 tunnel broker
- **[GitHub Community](https://github.com/gannino/tf-kube-any-compute)** - For collaboration and knowledge sharing

### **🤖 AI Development Partners**

This project was significantly enhanced and accelerated through collaboration with cutting-edge AI tools:

- **[GitHub Copilot](https://github.com/features/copilot)** - For intelligent code completion and rapid development
- **[Amazon Q](https://aws.amazon.com/q/)** - For AWS and cloud infrastructure optimization guidance
- **[Anthropic Claude Sonnet 4](https://www.anthropic.com/claude)** - Primary AI partner for comprehensive analysis, refactoring, and documentation
- **[OpenAI GPT-4](https://openai.com/gpt-4)** - For structured problem-solving and technical documentation
- **[Google Gemini](https://gemini.google.com)** - For creative solutions and multi-perspective analysis

**Special Recognition**: **Claude Sonnet 4** served as the **primary AI development partner**, providing deep architectural analysis, comprehensive testing frameworks, quality assurance guidance, and extensive documentation enhancement that transformed this from a personal homelab tool into a production-ready, community-focused project.

*This project demonstrates the powerful synergy between human passion for technology and AI-assisted development, showing how modern tools can accelerate innovation while maintaining quality and community focus.*

---

## Happy Homelabbing! 🏠🚀

*What started as one engineer's quest to perfect their homelab has become a community-driven platform for Kubernetes excellence. Transform your homelab into a production-grade Kubernetes platform, accelerate your cloud-native learning journey, and join a passionate community of technology enthusiasts.*

**From homelab frustration to open-source innovation - powered by passion, enhanced by AI, and built for the community.** 🌟

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/gannino/

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_consul"></a> [consul](#module\_consul) | ./helm-consul | n/a |
| <a name="module_gatekeeper"></a> [gatekeeper](#module\_gatekeeper) | ./helm-gatekeeper | n/a |
| <a name="module_grafana"></a> [grafana](#module\_grafana) | ./helm-grafana | n/a |
| <a name="module_host_path"></a> [host\_path](#module\_host\_path) | ./helm-host-path | n/a |
| <a name="module_loki"></a> [loki](#module\_loki) | ./helm-loki | n/a |
| <a name="module_metallb"></a> [metallb](#module\_metallb) | ./helm-metallb | n/a |
| <a name="module_nfs_csi"></a> [nfs\_csi](#module\_nfs\_csi) | ./helm-nfs-csi | n/a |
| <a name="module_node-feature-discovery"></a> [node-feature-discovery](#module\_node-feature-discovery) | ./helm-node-feature-discovery | n/a |
| <a name="module_portainer"></a> [portainer](#module\_portainer) | ./helm-portainer | n/a |
| <a name="module_prometheus"></a> [prometheus](#module\_prometheus) | ./helm-prometheus-stack | n/a |
| <a name="module_prometheus_crds"></a> [prometheus\_crds](#module\_prometheus\_crds) | ./helm-prometheus-stack-crds | n/a |
| <a name="module_promtail"></a> [promtail](#module\_promtail) | ./helm-promtail | n/a |
| <a name="module_traefik"></a> [traefik](#module\_traefik) | ./helm-traefik | n/a |
| <a name="module_vault"></a> [vault](#module\_vault) | ./helm-vault | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_nodes.all_nodes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k3s_masters](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k3s_workers](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k8s_masters](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k8s_masters_legacy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.k8s_workers](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |
| [kubernetes_nodes.microk8s_masters](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/nodes) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_mixed_cluster_mode"></a> [auto\_mixed\_cluster\_mode](#input\_auto\_mixed\_cluster\_mode) | Automatically configure services for mixed architecture clusters | `bool` | `true` | no |
| <a name="input_base_domain"></a> [base\_domain](#input\_base\_domain) | Base domain name (e.g., 'example.com') | `string` | `"local"` | no |
| <a name="input_cert_resolver_override"></a> [cert\_resolver\_override](#input\_cert\_resolver\_override) | Override the default cert resolver for specific services | <pre>object({<br/>    traefik      = optional(string)<br/>    prometheus   = optional(string)<br/>    grafana      = optional(string)<br/>    alertmanager = optional(string)<br/>    consul       = optional(string)<br/>    vault        = optional(string)<br/>    portainer    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (leave empty for auto-detection) | `string` | `""` | no |
| <a name="input_cpu_arch_override"></a> [cpu\_arch\_override](#input\_cpu\_arch\_override) | Per-service CPU architecture overrides for mixed clusters | <pre>object({<br/>    traefik                = optional(string)<br/>    metallb                = optional(string)<br/>    nfs_csi                = optional(string)<br/>    host_path              = optional(string)<br/>    prometheus             = optional(string)<br/>    prometheus_crds        = optional(string)<br/>    grafana                = optional(string)<br/>    loki                   = optional(string)<br/>    promtail               = optional(string)<br/>    consul                 = optional(string)<br/>    vault                  = optional(string)<br/>    gatekeeper             = optional(string)<br/>    portainer              = optional(string)<br/>    node_feature_discovery = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_default_cpu_limit"></a> [default\_cpu\_limit](#input\_default\_cpu\_limit) | Default CPU limit for containers when resource limits are enabled | `string` | `"500m"` | no |
| <a name="input_default_helm_cleanup_on_fail"></a> [default\_helm\_cleanup\_on\_fail](#input\_default\_helm\_cleanup\_on\_fail) | Default value for Helm cleanup on fail | `bool` | `true` | no |
| <a name="input_default_helm_disable_webhooks"></a> [default\_helm\_disable\_webhooks](#input\_default\_helm\_disable\_webhooks) | Default value for Helm disable webhooks | `bool` | `true` | no |
| <a name="input_default_helm_force_update"></a> [default\_helm\_force\_update](#input\_default\_helm\_force\_update) | Default value for Helm force update | `bool` | `true` | no |
| <a name="input_default_helm_replace"></a> [default\_helm\_replace](#input\_default\_helm\_replace) | Default value for Helm replace | `bool` | `false` | no |
| <a name="input_default_helm_skip_crds"></a> [default\_helm\_skip\_crds](#input\_default\_helm\_skip\_crds) | Default value for Helm skip CRDs | `bool` | `false` | no |
| <a name="input_default_helm_timeout"></a> [default\_helm\_timeout](#input\_default\_helm\_timeout) | Default timeout for Helm deployments in seconds | `number` | `600` | no |
| <a name="input_default_helm_wait"></a> [default\_helm\_wait](#input\_default\_helm\_wait) | Default value for Helm wait | `bool` | `true` | no |
| <a name="input_default_helm_wait_for_jobs"></a> [default\_helm\_wait\_for\_jobs](#input\_default\_helm\_wait\_for\_jobs) | Default value for Helm wait for jobs | `bool` | `true` | no |
| <a name="input_default_memory_limit"></a> [default\_memory\_limit](#input\_default\_memory\_limit) | Default memory limit for containers when resource limits are enabled | `string` | `"512Mi"` | no |
| <a name="input_default_storage_class"></a> [default\_storage\_class](#input\_default\_storage\_class) | Default storage class to use when not specified (empty = auto-detection) | `string` | `""` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based scheduling for specific services (useful for development) | <pre>object({<br/>    traefik                = optional(bool, false)<br/>    metallb                = optional(bool, false)<br/>    nfs_csi                = optional(bool, false)<br/>    host_path              = optional(bool, false)<br/>    prometheus             = optional(bool, false)<br/>    prometheus_crds        = optional(bool, false)<br/>    grafana                = optional(bool, false)<br/>    loki                   = optional(bool, false)<br/>    promtail               = optional(bool, false)<br/>    consul                 = optional(bool, false)<br/>    vault                  = optional(bool, false)<br/>    gatekeeper             = optional(bool, false)<br/>    portainer              = optional(bool, false)<br/>    node_feature_discovery = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | DEPRECATED: Use base\_domain and platform\_name instead. Legacy domain name configuration | `string` | `null` | no |
| <a name="input_enable_consul"></a> [enable\_consul](#input\_enable\_consul) | Enable Consul service mesh (DEPRECATED: use services.consul) | `bool` | `null` | no |
| <a name="input_enable_debug_outputs"></a> [enable\_debug\_outputs](#input\_enable\_debug\_outputs) | Enable debug outputs for troubleshooting | `bool` | `false` | no |
| <a name="input_enable_gatekeeper"></a> [enable\_gatekeeper](#input\_enable\_gatekeeper) | Enable Gatekeeper policy engine (DEPRECATED: use services.gatekeeper) | `bool` | `false` | no |
| <a name="input_enable_grafana"></a> [enable\_grafana](#input\_enable\_grafana) | Enable standalone Grafana dashboard (DEPRECATED: use services.grafana) | `bool` | `null` | no |
| <a name="input_enable_grafana_persistence"></a> [enable\_grafana\_persistence](#input\_enable\_grafana\_persistence) | Enable persistent storage for Grafana (DEPRECATED: use service\_overrides.grafana.enable\_persistence) | `bool` | `null` | no |
| <a name="input_enable_host_path"></a> [enable\_host\_path](#input\_enable\_host\_path) | Enable host path CSI driver (DEPRECATED: use services.host\_path) | `bool` | `null` | no |
| <a name="input_enable_loki"></a> [enable\_loki](#input\_enable\_loki) | Enable Loki log aggregation (DEPRECATED: use services.loki) | `bool` | `null` | no |
| <a name="input_enable_metallb"></a> [enable\_metallb](#input\_enable\_metallb) | Enable MetalLB load balancer (DEPRECATED: use services.metallb) | `bool` | `null` | no |
| <a name="input_enable_microk8s_mode"></a> [enable\_microk8s\_mode](#input\_enable\_microk8s\_mode) | Enable MicroK8s mode | `bool` | `false` | no |
| <a name="input_enable_nfs_csi"></a> [enable\_nfs\_csi](#input\_enable\_nfs\_csi) | Enable NFS CSI driver (DEPRECATED: use services.nfs\_csi) | `bool` | `null` | no |
| <a name="input_enable_node_feature_discovery"></a> [enable\_node\_feature\_discovery](#input\_enable\_node\_feature\_discovery) | Enable Node Feature Discovery (DEPRECATED: use services.node\_feature\_discovery) | `bool` | `null` | no |
| <a name="input_enable_portainer"></a> [enable\_portainer](#input\_enable\_portainer) | Enable Portainer container management (DEPRECATED: use services.portainer) | `bool` | `null` | no |
| <a name="input_enable_prometheus"></a> [enable\_prometheus](#input\_enable\_prometheus) | Enable Prometheus monitoring stack (DEPRECATED: use services.prometheus) | `bool` | `null` | no |
| <a name="input_enable_prometheus_crds"></a> [enable\_prometheus\_crds](#input\_enable\_prometheus\_crds) | Enable Prometheus CRDs (DEPRECATED: use services.prometheus\_crds) | `bool` | `null` | no |
| <a name="input_enable_prometheus_ingress_route"></a> [enable\_prometheus\_ingress\_route](#input\_enable\_prometheus\_ingress\_route) | Enable Prometheus ingress route (DEPRECATED: use service\_overrides.prometheus.enable\_ingress) | `bool` | `null` | no |
| <a name="input_enable_promtail"></a> [enable\_promtail](#input\_enable\_promtail) | Enable Promtail log collection (DEPRECATED: use services.promtail) | `bool` | `null` | no |
| <a name="input_enable_resource_limits"></a> [enable\_resource\_limits](#input\_enable\_resource\_limits) | Enable resource limits for resource-constrained environments | `bool` | `true` | no |
| <a name="input_enable_traefik"></a> [enable\_traefik](#input\_enable\_traefik) | Enable Traefik ingress controller (DEPRECATED: use services.traefik) | `bool` | `null` | no |
| <a name="input_enable_vault"></a> [enable\_vault](#input\_enable\_vault) | Enable Vault secrets management (DEPRECATED: use services.vault) | `bool` | `null` | no |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | Custom password for Grafana admin (empty = auto-generate) | `string` | `""` | no |
| <a name="input_grafana_node_name"></a> [grafana\_node\_name](#input\_grafana\_node\_name) | Specific node name to run Grafana (DEPRECATED: use service\_overrides.grafana.node\_name) | `string` | `""` | no |
| <a name="input_helm_timeouts"></a> [helm\_timeouts](#input\_helm\_timeouts) | Custom timeout values for specific Helm deployments (advanced users only) | <pre>object({<br/>    traefik                = optional(number, 600) # 10 minutes - ingress controller needs time<br/>    metallb                = optional(number, 300) # 5 minutes - load balancer setup<br/>    nfs_csi                = optional(number, 300) # 5 minutes - storage driver setup<br/>    host_path              = optional(number, 180) # 3 minutes - storage driver<br/>    prometheus_stack       = optional(number, 900) # 15 minutes - complex monitoring stack<br/>    prometheus_stack_crds  = optional(number, 300) # 5 minutes - CRD installation<br/>    grafana                = optional(number, 600) # 10 minutes - dashboard setup + persistence<br/>    consul                 = optional(number, 600) # 10 minutes - service mesh setup<br/>    vault                  = optional(number, 600) # 10 minutes - secrets management setup<br/>    portainer              = optional(number, 300) # 5 minutes - container management UI<br/>    gatekeeper             = optional(number, 300) # 5 minutes - policy engine<br/>    node_feature_discovery = optional(number, 180) # 3 minutes - node labeling<br/>    loki                   = optional(number, 300) # 5 minutes - log aggregation setup<br/>    promtail               = optional(number, 180) # 3 minutes - log collection daemonset<br/>  })</pre> | `{}` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | Email address for Let's Encrypt certificate notifications | `string` | `""` | no |
| <a name="input_letsencrypt_email"></a> [letsencrypt\_email](#input\_letsencrypt\_email) | Email address for Let's Encrypt certificate notifications (DEPRECATED: use le\_email) | `string` | `""` | no |
| <a name="input_metallb_address_pool"></a> [metallb\_address\_pool](#input\_metallb\_address\_pool) | IP address range for MetalLB load balancer | `string` | `"192.168.1.200-192.168.1.210"` | no |
| <a name="input_monitoring_admin_password"></a> [monitoring\_admin\_password](#input\_monitoring\_admin\_password) | Custom password for monitoring services (Prometheus/AlertManager) admin (empty = auto-generate) | `string` | `""` | no |
| <a name="input_nfs_path"></a> [nfs\_path](#input\_nfs\_path) | NFS server path (DEPRECATED: use nfs\_server\_path) | `string` | `""` | no |
| <a name="input_nfs_server"></a> [nfs\_server](#input\_nfs\_server) | NFS server IP address (DEPRECATED: use nfs\_server\_address) | `string` | `""` | no |
| <a name="input_nfs_server_address"></a> [nfs\_server\_address](#input\_nfs\_server\_address) | NFS server IP address for persistent storage | `string` | `"192.168.1.100"` | no |
| <a name="input_nfs_server_path"></a> [nfs\_server\_path](#input\_nfs\_server\_path) | NFS server path for persistent storage | `string` | `"/mnt/k8s-storage"` | no |
| <a name="input_platform_name"></a> [platform\_name](#input\_platform\_name) | Platform identifier (e.g., 'k3s', 'eks', 'gke', 'aks', 'microk8s') | `string` | `"k3s"` | no |
| <a name="input_portainer_admin_password"></a> [portainer\_admin\_password](#input\_portainer\_admin\_password) | Custom password for Portainer admin (empty = auto-generate) | `string` | `""` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Service-specific configuration overrides for fine-grained control | <pre>object({<br/>    traefik = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_dashboard   = optional(bool)<br/>      dashboard_password = optional(string)<br/>      cert_resolver      = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    prometheus = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_ingress              = optional(bool)<br/>      enable_alertmanager_ingress = optional(bool)<br/>      retention_period            = optional(string)<br/>      monitoring_admin_password   = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    grafana = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_persistence = optional(bool)<br/>      node_name          = optional(string)<br/>      admin_user         = optional(string)<br/>      admin_password     = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    metallb = optional(object({<br/>      # Service-specific settings<br/>      address_pool = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    vault = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    consul = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    portainer = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      admin_password = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    loki = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    nfs_csi = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    host_path = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    node_feature_discovery = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    gatekeeper = optional(object({<br/>      # Gatekeeper-specific options<br/>      gatekeeper_version = optional(string)<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    prometheus_crds = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    promtail = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_services"></a> [services](#input\_services) | Service enablement configuration - choose your stack components | <pre>object({<br/>    # Core infrastructure services<br/>    traefik   = optional(bool, true)<br/>    metallb   = optional(bool, true)<br/>    nfs_csi   = optional(bool, true)<br/>    host_path = optional(bool, true)<br/><br/>    # Monitoring and observability stack<br/>    prometheus      = optional(bool, true)<br/>    prometheus_crds = optional(bool, true)<br/>    grafana         = optional(bool, true)<br/>    loki            = optional(bool, true)<br/>    promtail        = optional(bool, true)<br/><br/>    # Service mesh and security<br/>    consul     = optional(bool, true)<br/>    vault      = optional(bool, true)<br/>    gatekeeper = optional(bool, false)<br/><br/>    # Management and discovery<br/>    portainer              = optional(bool, true)<br/>    node_feature_discovery = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_storage_class_override"></a> [storage\_class\_override](#input\_storage\_class\_override) | Override the default storage class selection logic | <pre>object({<br/>    prometheus   = optional(string)<br/>    grafana      = optional(string)<br/>    loki         = optional(string)<br/>    alertmanager = optional(string)<br/>    consul       = optional(string)<br/>    vault        = optional(string)<br/>    traefik      = optional(string)<br/>    portainer    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Default certificate resolver for Traefik SSL certificates | `string` | `"wildcard"` | no |
| <a name="input_traefik_dashboard_password"></a> [traefik\_dashboard\_password](#input\_traefik\_dashboard\_password) | Custom password for Traefik dashboard (empty = auto-generate) | `string` | `""` | no |
| <a name="input_use_hostpath_storage"></a> [use\_hostpath\_storage](#input\_use\_hostpath\_storage) | Use hostPath storage (takes effect when use\_nfs\_storage is false) | `bool` | `true` | no |
| <a name="input_use_nfs_storage"></a> [use\_nfs\_storage](#input\_use\_nfs\_storage) | Use NFS storage as primary storage backend | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_applied_service_configs"></a> [applied\_service\_configs](#output\_applied\_service\_configs) | Applied service configurations showing override hierarchy results |
| <a name="output_cert_resolver_debug"></a> [cert\_resolver\_debug](#output\_cert\_resolver\_debug) | n/a |
| <a name="output_cluster_info"></a> [cluster\_info](#output\_cluster\_info) | Cluster information and configuration summary |
| <a name="output_cpu_arch_debug"></a> [cpu\_arch\_debug](#output\_cpu\_arch\_debug) | n/a |
| <a name="output_debug_storage_config"></a> [debug\_storage\_config](#output\_debug\_storage\_config) | n/a |
| <a name="output_detected_architecture"></a> [detected\_architecture](#output\_detected\_architecture) | Auto-detected CPU architecture and cluster analysis |
| <a name="output_enabled_services"></a> [enabled\_services](#output\_enabled\_services) | Summary of enabled services and their status |
| <a name="output_helm_debug"></a> [helm\_debug](#output\_helm\_debug) | n/a |
| <a name="output_mixed_cluster_strategy"></a> [mixed\_cluster\_strategy](#output\_mixed\_cluster\_strategy) | Strategy and recommendations for mixed architecture clusters |
| <a name="output_service_outputs"></a> [service\_outputs](#output\_service\_outputs) | Detailed outputs from all deployed services |
| <a name="output_service_urls"></a> [service\_urls](#output\_service\_urls) | Quick access URLs for deployed services |
| <a name="output_storage_configuration"></a> [storage\_configuration](#output\_storage\_configuration) | Storage configuration details and available storage classes |
| <a name="output_storage_debug"></a> [storage\_debug](#output\_storage\_debug) | n/a |
<!-- END_TF_DOCS -->
