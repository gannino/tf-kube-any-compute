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
- **� Security First**: Applied the same security-hardened approaches required in enterprise businesses
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

- [Terraform](https://www.terraform.io) - Infrastructure as Code
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

### **✅ Latest Enhancement: Advanced MetalLB Module**

- **🌐 BGP Support**: Full BGP mode with peer configuration and FRR support
- **🔧 Multi-Pool Management**: Support for multiple IP address pools with auto-assignment control
- **📊 Monitoring Integration**: Built-in Prometheus metrics and ServiceMonitor support
- **🏗️ High Availability**: Configurable controller and speaker replicas for production deployments
- **⚙️ Advanced Configuration**: Enhanced Helm values with logging levels, load balancer classes, and resource optimization

### **⚠️ Known Issues & TODO**

- **MetalLB Version Issue**: Using v0.13.10 instead of latest v0.14.8
  - **Issue**: MetalLB v0.14.8 fails to assign LoadBalancer IPs to services
  - **Symptoms**: Traefik LoadBalancer service remains in `<pending>` state
  - **Workaround**: Downgraded to stable v0.13.10 which works reliably
  - **Status**: Monitoring MetalLB releases for fix in future versions
  - **Impact**: No feature loss, v0.13.10 includes all required L2/BGP functionality

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
terraform >= 1.12.2
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

## ⚙️ **Enhanced Configuration System**

### **🎯 Modern Domain Structure**
Infrastructure now uses a structured domain format: `{workspace}.{platform}.{base_domain}`

```hcl
# Examples:
# prod.k3s.example.com (production)
# dev.microk8s.local (development)
# homelab.k3s.homelab.local (homelab)

base_domain   = "example.com"  # Your domain
platform_name = "k3s"          # Kubernetes distribution
# Workspace is automatically: prod, dev, staging, etc.
```

### **🔧 Comprehensive Service Overrides**
Fine-tune every aspect of your deployment with the enhanced `service_overrides` system:

```hcl
service_overrides = {
  traefik = {
    # Architecture and infrastructure
    cpu_arch         = "amd64"          # Force architecture
    chart_version    = "26.0.0"         # Pin chart version
    storage_class    = "nfs-csi-safe"   # Override storage
    storage_size     = "2Gi"            # Certificate storage
    
    # Service configuration
    enable_dashboard         = true     # Enable web UI
    cert_resolver            = "wildcard" # SSL certificates
    load_balancer_class      = "metallb" # Load balancer class
    enable_load_balancer_class = true   # Enable LB class annotation
    
    # Port configuration
    http_port      = 80                 # HTTP entrypoint
    https_port     = 443                # HTTPS entrypoint
    dashboard_port = 8080               # Dashboard port
    metrics_port   = 9100               # Prometheus metrics
    
    # Resource optimization
    cpu_limit        = "500m"           # Prevent resource issues
    memory_limit     = "512Mi"
    
    # Deployment control
    helm_timeout     = 600              # Extended timeout
    helm_wait        = true             # Wait for readiness
  }
  
  prometheus = {
    # Performance tuning for monitoring
    cpu_arch         = "amd64"          # Prefer AMD64 for performance
    storage_size     = "20Gi"           # Large metrics storage
    retention_period = "30d"            # Extended data retention
    
    # High-performance resources
    cpu_limit        = "2000m"
    memory_limit     = "4Gi"
    
    # Robust deployment
    helm_timeout     = 900              # 15 minutes for complex stack
    helm_wait        = true
    helm_wait_for_jobs = true
  }
  
  grafana = {
    # UI optimization
    storage_class      = "hostpath"     # SQLite compatibility
    enable_persistence = true          # Save dashboards
    node_name         = "homelab-01"   # Pin to specific node
    
    # Lightweight resources
    cpu_limit         = "300m"
    memory_limit      = "256Mi"
  }
}
```

### **🏗️ Mixed Architecture Management**
Intelligent service placement for ARM64/AMD64 mixed clusters:

```hcl
# Automatic mixed cluster handling
auto_mixed_cluster_mode = true

# Strategic architecture placement
cpu_arch_override = {
  # Performance-critical on AMD64
  traefik          = "amd64"
  prometheus       = "amd64"
  vault           = "amd64"
  
  # UI services on efficient ARM64
  grafana         = "arm64"
  portainer       = "arm64"
}

# Disable architecture constraints (development)
disable_arch_scheduling = {
  traefik    = true  # Allow cross-architecture deployment
  grafana    = true  # Flexible placement
}
```

### **⚖️ Advanced MetalLB Configuration**
Enhanced load balancer with BGP support, multi-pool management, and LoadBalancerClass support:

```hcl
# Basic L2 Mode (Default)
service_overrides = {
  metallb = {
    address_pool                 = "192.168.1.200-192.168.1.210"
    enable_prometheus_metrics    = true
    controller_replica_count     = 1
    speaker_replica_count        = 3  # Match node count
    load_balancer_class          = "metallb"
    enable_load_balancer_class   = true
    address_pool_name            = "default-pool"
  }
}

# Advanced BGP Mode
service_overrides = {
  metallb = {
    # Enable BGP routing
    enable_bgp = true
    enable_frr = true  # Advanced BGP features
    
    # BGP peer configuration
    bgp_peers = [
      {
        peer_address = "10.0.0.1"
        peer_asn     = 65001
        my_asn       = 65000
      }
    ]
    
    # Multiple IP pools
    additional_ip_pools = [
      {
        name        = "production-pool"
        addresses   = ["10.0.1.100-10.0.1.110"]
        auto_assign = false  # Manual assignment
      },
      {
        name        = "development-pool"
        addresses   = ["10.0.2.100-10.0.2.110"]
        auto_assign = true   # Automatic assignment
      }
    ]
    
    # High availability
    controller_replica_count = 3
    speaker_replica_count = 5
    
    # Monitoring and logging
    enable_prometheus_metrics = true
    service_monitor_enabled = true
    log_level = "info"
    
    # LoadBalancerClass configuration
    load_balancer_class = "metallb"
    enable_load_balancer_class = true
    address_pool_name = "production-pool"
  }
}
```

### **📦 Service Stack Selection**
Choose your infrastructure components with granular control:

```hcl
# Raspberry Pi Optimized
services = {
  traefik    = true   # Essential ingress
  metallb    = true   # Load balancing
  host_path  = true   # Local storage
  nfs_csi    = false  # Disable if no NFS
  
  # Core monitoring only
  prometheus = true
  grafana   = true
  
  # Disable resource-intensive services
  loki      = false
  consul    = false
  vault     = false
}

# Production Full Stack
services = {
  # Complete infrastructure
  traefik = true
  metallb = true
  nfs_csi = true
  
  # Full monitoring stack
  prometheus = true
  grafana   = true
  loki      = true   # Log aggregation
  promtail  = true   # Log collection
  
  # Service mesh and security
  consul    = true   # Service discovery
  vault     = true   # Secrets management
  
  # Management
  portainer = true
}
```

### **🔧 MetalLB Features**

| Feature | L2 Mode | BGP Mode | Description |
|---------|---------|----------|--------------|
| **Basic Load Balancing** | ✅ | ✅ | Layer 2/3 load balancing |
| **IP Pool Management** | ✅ | ✅ | Multiple IP address pools |
| **High Availability** | ✅ | ✅ | Multiple controller/speaker replicas |
| **BGP Routing** | ❌ | ✅ | Advanced routing with BGP peers |
| **FRR Integration** | ❌ | ✅ | Free Range Routing for complex scenarios |
| **Prometheus Metrics** | ✅ | ✅ | Built-in monitoring support |
| **ServiceMonitor** | ✅ | ✅ | Prometheus Operator integration |
| **Auto-Assignment** | ✅ | ✅ | Automatic IP allocation control |
| **LoadBalancerClass** | ✅ | ✅ | Kubernetes LoadBalancerClass support |

### **⚖️ LoadBalancerClass Configuration**

Modern Kubernetes LoadBalancerClass support for advanced load balancer selection:

```hcl
# Enable LoadBalancerClass for both MetalLB and Traefik
service_overrides = {
  metallb = {
    load_balancer_class        = "metallb"      # LoadBalancerClass name
    enable_load_balancer_class = false          # Enable LoadBalancerClass resource
    address_pool_name          = "default-pool" # Associated IP pool
  }
  
  traefik = {
    load_balancer_class        = "metallb"      # Use MetalLB class
    enable_load_balancer_class = false          # Enable class annotation
  }
}
```

**LoadBalancerClass Benefits:**
- **Service Selection**: Services can specify which load balancer to use
- **Multi-Provider**: Support multiple load balancer implementations
- **Resource Isolation**: Separate IP pools and configurations per class
- **Cloud Integration**: Seamless integration with cloud provider load balancers

**Usage Examples:**
```yaml
# Service using specific LoadBalancerClass
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  loadBalancerClass: metallb  # Use MetalLB specifically
  ports:
  - port: 80
    targetPort: 8080
```

### **🔧 Load Balancer Integration**

**Traefik + MetalLB Integration:**
- Traefik automatically uses MetalLB LoadBalancerClass when configured
- Consistent load balancer behavior across all ingress traffic
- Automatic IP assignment from MetalLB address pools
- Support for both L2 and BGP modes

**Configuration Hierarchy:**
1. **Service Override**: `service_overrides.traefik.load_balancer_class`
2. **Global Default**: `"metallb"` (automatic)
3. **Default**: `enable_load_balancer_class = false` (opt-in)

**Behavior Notes:**
- **Default (`false`)**: No `loadBalancerClass` field in service spec, MetalLB assigns IP as default provider
- **Enabled (`true`)**: Explicit `loadBalancerClass: metallb` field in service spec for multi-provider environments
- **IP Assignment**: Works in both cases when MetalLB is the only/default LoadBalancer implementation

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

## 💾 **Storage Configuration**

### **Storage Classes Available**

#### **NFS-Based (Primary)**
- **`nfs-csi-safe`** - Default, optimized for reliability
- **`nfs-csi-fast`** - High-performance for I/O intensive apps
- **`nfs-csi`** - Standard NFS storage

#### **Local (Fallback)**
- **`hostpath`** - Local node storage

### **Application Storage Assignments**
```hcl
storage_class_override = {
  grafana      = "hostpath"        # UI data works well locally
  prometheus   = "nfs-csi-safe"    # Long-term metrics persistence
  alertmanager = "nfs-csi-safe"    # Alert state persistence
  consul       = "nfs-csi-safe"    # Service registry data
  vault        = "nfs-csi-safe"    # Critical secrets storage
  traefik      = "nfs-csi-fast"    # SSL certificates fast access
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

## 🔑 **Password Management**

Secure password handling with auto-generation and custom override capabilities.

### **🔐 Auto-Generated Passwords**

By default, all services use secure auto-generated passwords:
- **Traefik Dashboard**: 12-character alphanumeric
- **Grafana Admin**: 12-character alphanumeric  
- **Portainer Admin**: 16-character alphanumeric

### **🔧 Custom Password Override**

```hcl
# Set custom passwords in terraform.tfvars
traefik_dashboard_password = "your-secure-traefik-password"
grafana_admin_password     = "your-secure-grafana-password"
portainer_admin_password   = "your-secure-portainer-password"
```

### **🔍 Retrieving Passwords**

```bash
# View passwords from enabled modules
terraform output -json | jq '.enabled_modules.value.modules.traefik.outputs.dashboard_password'
terraform output -json | jq '.enabled_modules.value.modules.grafana.outputs.admin_password'
terraform output -json | jq '.enabled_modules.value.modules.portainer.outputs.admin_password'

# Or view all module outputs
terraform output enabled_modules
```

### **🔒 Security Best Practices**

- **Use Strong Passwords**: Minimum 12 characters with mixed case, numbers, symbols
- **Rotate Regularly**: Change passwords periodically
- **Store Securely**: Use password managers or secure vaults
- **Environment Variables**: Set via `TF_VAR_*` for CI/CD pipelines

```bash
# Set via environment variables (recommended for automation)
export TF_VAR_traefik_dashboard_password="secure-password"
export TF_VAR_grafana_admin_password="secure-password"
export TF_VAR_portainer_admin_password="secure-password"
```

## 🌐 **DNS & SSL Configuration**

### **Hurricane Electric DNS Setup**

For homelab environments with dynamic IPs, configure Hurricane Electric for DNS challenge:

```bash
# Set up HE.net credentials in terraform.tfvars
letsencrypt_email = "your-email@domain.com"
traefik_cert_resolver = "wildcard"

# Configure DNS provider credentials (secure method)
export HE_USERNAME="your-he-username"
export HE_PASSWORD="your-he-password"
```

### **Dynamic DNS with HE.net**

```bash
# Enable HE.net tunnel broker for IPv6 and dynamic DNS
# Configure your domain's DNS records:
# *.homelab.yourdomain.com CNAME homelab.yourdomain.com
# homelab.yourdomain.com A <your-dynamic-ip>
```

### **Service Mesh Configuration**

```hcl
# Enable Consul Connect service mesh
enable_consul = true

# Traefik will automatically integrate with Consul for:
# - Service discovery
# - Load balancing
# - Circuit breaking
# - Distributed tracing
```

**Consul Connect Strategy:**
- **Automatic Service Registration**: Services auto-register with Consul
- **Mutual TLS**: Encrypted service-to-service communication
- **Traffic Management**: Intelligent routing and load balancing
- **Integrated Configuration**: Service mesh configuration within existing modules

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

## 🗺️ **Roadmap**

- [ ] **GitOps Integration** - ArgoCD for continuous deployment
- [ ] **Backup Automation** - Velero for disaster recovery
- [ ] **Advanced Monitoring** - Custom Grafana dashboards
- [ ] **Service Mesh** - Consul Connect service mesh integration
- [ ] **Multi-Cluster** - Cluster federation support
- [ ] **Edge Computing** - K3s edge deployment patterns
- [ ] **Terraform Registry** - Publish as official Terraform module

## 🔧 **Version Management & CI/CD**

### **📋 Centralized Version Management**

The project uses a centralized version management system for consistent tool versions across all environments:

**Version Configuration:**
- **Central Config**: `.github/versions.yml` - Single source of truth for all tool versions
- **Current Terraform**: `1.12.2` - Latest stable version with enhanced features
- **TFLint**: `v0.47.0` - Latest linting rules and security checks
- **GitHub Actions**: Standardized action versions across all workflows

**Update Script:**
```bash
# Update all versions at once
./scripts/update-versions.sh 1.12.2 v0.47.0

# Or use current defaults
./scripts/update-versions.sh
```

**Benefits:**
- **Consistency**: Same versions across development, CI/CD, and production
- **Easy Updates**: Single command updates all workflows
- **Version Tracking**: Clear visibility of tool versions in use
- **CI/CD Integration**: Automated version management in pipelines

### **🚀 GitHub Actions Workflows**

**CI Pipeline (`.github/workflows/ci.yml`):**
- **Terraform Validation**: Format checking, initialization, and validation
- **TFLint Analysis**: Security and best practices scanning
- **Documentation Check**: Terraform-docs validation
- **Security Scanning**: Trivy vulnerability assessment
- **Multi-Scenario Testing**: ARM64, mixed clusters, cloud deployments
- **Makefile Testing**: Validation of all make commands

**Test Pipeline (`.github/workflows/test.yml`):**
- **Unit Tests**: Configuration logic validation
- **Regression Tests**: Ensure no breaking changes
- **Integration Tests**: Live infrastructure validation

**Release Pipeline (`.github/workflows/release.yml`):**
- **Pre-Release Validation**: Comprehensive testing before release
- **Security Audit**: Enhanced security scanning for releases
- **Compatibility Testing**: Multi-version Terraform compatibility
- **Documentation Completeness**: Terraform Registry requirements
- **Automated Release**: GitHub release creation with changelog

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
terraform version    # >= 1.12.2
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
- **[Wiki](https://github.com/gannino/tf-kube-any-compute/wiki)**: Community-contributed guides and tips

## 🙏 **Acknowledgments**

- **[Kubernetes Community](https://kubernetes.io)** - For the amazing orchestration platform
- **[Traefik](https://traefik.io)** - For the modern ingress controller
- **[HashiCorp](https://www.hashicorp.com)** - For Terraform and Vault
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
- **[OpenAI GPT-4](https://openai.com/product/gpt-4)** - For structured problem-solving and technical documentation
- **[Google Gemini](https://gemini.google.com)** - For creative solutions and multi-perspective analysis

**Special Recognition**: **Claude Sonnet 4** served as the **primary AI development partner**, providing deep architectural analysis, comprehensive testing frameworks, quality assurance guidance, and extensive documentation enhancement that transformed this from a personal homelab tool into a production-ready, community-focused project.

*This project demonstrates the powerful synergy between human passion for technology and AI-assisted development, showing how modern tools can accelerate innovation while maintaining quality and community focus.*

---

## Happy Homelabbing! 🏠🚀

*What started as one engineer's quest to perfect their homelab has become a community-driven platform for Kubernetes excellence. Transform your homelab into a production-grade Kubernetes platform, accelerate your cloud-native learning journey, and join a passionate community of technology enthusiasts.*

**From homelab frustration to open-source innovation - powered by passion, enhanced by AI, and built for the community.** 🌟

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/gannino/
