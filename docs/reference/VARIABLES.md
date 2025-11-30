# 🔧 Variable Reference Guide

## ⚙️ **Enhanced Configuration System**

### **🎯 Modern Domain Structure**

Infrastructure uses a structured domain format: `{workspace}.{platform}.{base_domain}`

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
    enable_dashboard = true             # Enable web UI
    cert_resolver    = "wildcard"       # SSL certificates

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

## 🔐 **Middleware Authentication System**

### **🛡️ Centralized Authentication**

Traefik middleware provides centralized authentication for all services with support for multiple authentication methods:

```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      # Basic Authentication (always enabled as fallback)
      basic_auth = {
        enabled         = true                    # Always enabled
        secret_name     = "monitoring-basic-auth" # Kubernetes secret name
        realm           = "Monitoring Services"   # Authentication realm
        static_password = ""                      # Empty = auto-generate
        username        = "admin"                 # Default username
      }

      # LDAP Authentication (preferred when enabled)
      ldap_auth = {
        enabled       = false                     # Enable for LDAP auth
        log_level     = "INFO"                    # Plugin log level
        url           = "ldap://ldap.example.com" # LDAP server URL
        port          = 389                       # LDAP port
        base_dn       = "ou=Users,dc=example,dc=com" # Search base DN
        attribute     = "uid"                     # Username attribute
        bind_dn       = ""                        # Optional: service account DN
        bind_password = ""                        # Optional: service account password
        search_filter = ""                        # Optional: custom search filter
      }

      # Rate Limiting (protect against abuse)
      rate_limit = {
        enabled = true    # Enable rate limiting
        average = 100     # Requests per second
        burst   = 200     # Burst capacity
      }
    }
  }
}
```

### **🔄 Authentication Priority System**

The system uses a priority-based authentication selection similar to storage classes:

1. **LDAP Authentication** (preferred when enabled)
2. **Basic Authentication** (fallback, always available)

**Automatic Selection:**
- When `ldap_auth.enabled = true` → Uses LDAP middleware
- When `ldap_auth.enabled = false` → Uses basic auth middleware
- Per-service overrides available via `auth_override`

### **🎯 Service Authentication Coverage**

**Protected Services:**
- **Traefik Dashboard** - Ingress controller management
- **Prometheus** - Metrics and monitoring data
- **AlertManager** - Alert management interface

**Excluded Services (Built-in Auth):**
- **Grafana** - Has native authentication system
- **Portainer** - Has native authentication system
- **Vault** - Has native authentication system
- **Consul** - Has native authentication system

### **🔧 LDAP Configuration Examples**

#### **JumpCloud LDAP**
```hcl
ldap_auth = {
  enabled   = true
  url       = "ldap://ldap.jumpcloud.com"
  port      = 389
  base_dn   = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
  attribute = "uid"
}
```

#### **Active Directory**
```hcl
ldap_auth = {
  enabled       = true
  url           = "ldap://dc.example.com"
  port          = 389
  base_dn       = "ou=Users,dc=example,dc=com"
  attribute     = "sAMAccountName"
  bind_dn       = "cn=service,ou=ServiceAccounts,dc=example,dc=com"
  bind_password = "service-account-password"
}
```

#### **OpenLDAP**
```hcl
ldap_auth = {
  enabled       = true
  url           = "ldap://openldap.example.com"
  port          = 389
  base_dn       = "ou=people,dc=example,dc=com"
  attribute     = "cn"
  search_filter = "(&(objectClass=person)(memberOf=cn=k8s-users,ou=groups,dc=example,dc=com))"
}
```

### **🔐 Per-Service Authentication Overrides**

```hcl
# Override authentication method for specific services
auth_override = {
  traefik      = "basic"  # Force basic auth for Traefik dashboard
  prometheus   = "ldap"   # Force LDAP for Prometheus (if enabled)
  alertmanager = "basic"  # Force basic auth for AlertManager
}
```

### **🛠️ Middleware Management**

**Automatic Middleware Creation:**
- `{name_prefix}-basic-auth` - Basic authentication middleware
- `{name_prefix}-ldap-auth` - LDAP authentication middleware (when enabled)
- `{name_prefix}-rate-limit` - Rate limiting middleware

**Middleware References:**
- Format: `{namespace}-{middleware-name}@kubernetescrd`
- Example: `traefik-prod-traefik-basic-auth@kubernetescrd`

### **🔍 Troubleshooting Authentication**

```bash
# Check middleware resources
kubectl get middleware -n traefik

# View LDAP plugin logs (when enabled)
kubectl logs -n traefik deployment/prod-traefik -f

# Test authentication
curl -u admin:password https://prometheus.homelab.k3s.example.com

# View generated passwords
terraform output -json | jq '.auth_credentials.value'
```

### **🔒 Security Best Practices**

- **Use HTTPS Only** - All authentication over encrypted connections
- **Strong Passwords** - Auto-generated passwords are cryptographically secure
- **Rate Limiting** - Prevents brute force attacks
- **LDAP over TLS** - Use `ldaps://` for encrypted LDAP connections
- **Service Account** - Use dedicated LDAP service account with minimal permissions
- **Regular Rotation** - Rotate service account passwords regularly

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
