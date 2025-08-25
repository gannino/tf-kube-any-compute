# tf-kube-any-compute

## Universal Kubernetes Infrastructure for Any Compute Platform

[![LinkedIn][linkedin-shield]][linkedin-url]

**tf-kube-any-compute** provides a **comprehensive, cloud-agnostic Kubernetes infrastructure** designed for **tech enthusiasts and homelab builders** who want to:

- **🚀 Spin up clusters quickly** on any Kubernetes distribution (K3s, MicroK8s, EKS, GKE, AKS)
- **🔧 Learn Kubernetes** through hands-on experience with production-grade services
- **📈 Scale incrementally** by adding services based on their architecture and needs
- **🏗️ Build expertise** in Infrastructure as Code, monitoring, service mesh, and security

Perfect for **any compute platform**: **Raspberry Pi clusters**, **home servers**, **cloud environments**, **edge devices**, and **learning labs**.

## 🛠️ Services Deployed

### Core Infrastructure
- **🌐 Traefik** - Modern ingress controller with automatic SSL
- **⚖️ MetalLB** - Load balancer for bare metal clusters
- **💾 Storage Drivers** - NFS CSI + HostPath for flexible storage
- **🔍 Node Feature Discovery** - Hardware detection and labeling

### Platform Services
- **📊 Prometheus + Grafana + Kube-State-Metrics** - Complete monitoring and visualization stack with Kubernetes metrics
- **🔐 Vault + Consul** - Secrets management and service discovery with service mesh
- **🐳 Portainer** - Container management web UI
- **🛡️ Gatekeeper** - Policy engine (optional)
- **🔒 Traefik Middleware** - Centralized authentication (Basic Auth + LDAP) with rate limiting

### Automation & Workflow Services
- **🏠 Home Assistant** - Open-source home automation platform with 1000+ integrations
- **🏢 openHAB** - Vendor-neutral home automation with enterprise-grade Java runtime
- **🔴 Node-RED** - Visual programming tool for IoT and automation workflows
- **⚡ n8n** - Workflow automation platform (self-hosted Zapier/IFTTT alternative)

### Built With
- [Terraform](https://terraform.io) - Infrastructure as Code
- [Helm](https://helm.sh) - Kubernetes package manager
- [Kubernetes](https://kubernetes.io) - Container orchestration

## 🚀 Quick Start

### Prerequisites

```bash
# Install required tools
terraform >= 1.0
kubectl
helm >= 3.0

# Verify cluster access
kubectl cluster-info
```

### 1. Clone and Configure

```bash
git clone https://github.com/gannino/tf-kube-any-compute.git
cd tf-kube-any-compute

# Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

### 2. Deploy Infrastructure (Two-Step Process)

**Step 1: Initial Deployment**
```bash
# Initialize Terraform
make init

# Create environment workspace
terraform workspace new homelab

# Review planned changes
make plan

# Deploy core services (without authentication)
make apply
```

**Step 2: Enable Authentication (After CRDs are ready)**
```bash
# Edit terraform.tfvars and change enabled = false to enabled = true
vi terraform.tfvars

# Find this line and change it:
# enabled = false  # CHANGE TO TRUE after first deployment
# to:
# enabled = true

# Apply authentication configuration
make apply
```

> 🔐 **Two-Step Deployment**: The first deployment installs core services without authentication to avoid CRD dependency issues. After Traefik CRDs are installed, simply change `middleware_overrides.enabled = false` to `middleware_overrides.enabled = true` in your `terraform.tfvars` to enable basic authentication for monitoring services.

### 3. Access Your Services

After deployment, access services at:

- **Traefik Dashboard**: `https://traefik.homelab.k3s.example.com`
- **Grafana**: `https://grafana.homelab.k3s.example.com`
- **Portainer**: `https://portainer.homelab.k3s.example.com`
- **Consul**: `https://consul.homelab.k3s.example.com`
- **Vault**: `https://vault.homelab.k3s.example.com`
- **Home Assistant**: `https://home-assistant.homelab.k3s.example.com`
- **openHAB**: `https://openhab.homelab.k3s.example.com`
- **Node-RED**: `https://node-red.homelab.k3s.example.com`
- **n8n**: `https://n8n.homelab.k3s.example.com`

> 🔒 **SSL Certificates**: All services automatically get SSL certificates via Let's Encrypt using your configured DNS provider

## 📊 Enhanced Monitoring & Dashboards

**tf-kube-any-compute** provides comprehensive Kubernetes monitoring out-of-the-box with curated Grafana dashboards:

### 📈 **Pre-configured Dashboards**
- **Cluster Overview** - Complete cluster health and resource utilization
- **Node Monitoring** - Detailed node metrics with ARM64/AMD64 support
- **Workload Analysis** - Pods, Deployments, StatefulSets, DaemonSets
- **Storage Monitoring** - Persistent Volumes and storage classes
- **Network Insights** - Services, Ingress, and networking metrics
- **Infrastructure Stack** - Prometheus, Grafana, Traefik monitoring
- **Homelab Specific** - Raspberry Pi and ARM64 optimized dashboards

### 🔍 **Kubernetes Metrics Collection**
- **kube-state-metrics** - Comprehensive Kubernetes object metrics
- **Node Exporter** - System and hardware metrics
- **Prometheus Operator** - Advanced monitoring capabilities
- **ServiceMonitor** - Automatic service discovery

### 📁 **Organized Dashboard Structure**
- **Overview** - Main cluster dashboards
- **Kubernetes** - Kubernetes-specific monitoring
- **Infrastructure** - Monitoring stack and applications

All dashboards are automatically imported and organized for the best out-of-the-box experience.

## ⚙️ Configuration

For comprehensive configuration options, see:

- **[AUTHENTICATION-GUIDE.md](AUTHENTICATION-GUIDE.md)** - Complete authentication setup guide
- **[VARIABLES.md](VARIABLES.md)** - All configuration options including:
  - Service Overrides: Fine-tune every aspect of your deployment
  - Mixed Architecture Management: ARM64/AMD64 cluster strategies
  - Storage Configuration: NFS, HostPath, and storage class options
  - Password Management: Auto-generation and custom overrides
  - DNS & SSL: Multi-provider DNS and Let's Encrypt setup
  - Architecture Detection: Intelligent service placement

## 🔒 Authentication & Security

### Centralized Authentication

**tf-kube-any-compute** provides centralized authentication through Traefik middleware with support for multiple authentication methods:

- **🔑 Basic Authentication** - Secure username/password authentication (default)
- **🏢 LDAP Integration** - Enterprise directory integration (JumpCloud, Active Directory, OpenLDAP)
- **🛡️ Rate Limiting** - Protection against brute force attacks
- **🔄 Priority System** - Automatic fallback from LDAP to Basic Auth

#### Two-Step Authentication Setup

**Step 1: Initial Deployment (No Authentication)**
```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Deploy core services first
terraform apply
```

**Step 2: Enable Authentication**
```bash
# Edit terraform.tfvars and change enabled flag
vi terraform.tfvars

# Change this line:
# enabled = false  # CHANGE TO TRUE after first deployment
# to:
# enabled = true

# Apply authentication
terraform apply
```

#### Advanced Authentication Examples

**Basic Authentication (Recommended for most users)**
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      basic_auth = {
        enabled         = true
        username        = "admin"
        static_password = ""  # Auto-generated secure password
        realm           = "Monitoring Services"
      }
    }
  }
}
```

**LDAP Authentication (JumpCloud)**
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled   = true
        method    = "forwardauth"  # or "plugin"
        url       = "ldap://ldap.jumpcloud.com"
        base_dn   = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
        attribute = "uid"
      }
    }
  }
}
```

**LDAP Authentication (Active Directory)**
```hcl
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled       = true
        method        = "forwardauth"
        url           = "ldap://ad.company.com"
        base_dn       = "dc=company,dc=com"
        bind_dn       = "cn=service,dc=company,dc=com"
        bind_password = "service-password"
        search_filter = "(sAMAccountName={username})"
      }
    }
  }
}
```

**Protected Services:**
- Traefik Dashboard, Prometheus, AlertManager

**Services with Built-in Auth:**
- Grafana, Portainer, Vault, Consul (use native authentication)

## 🔐 SSL Certificate Management

**tf-kube-any-compute** provides flexible SSL certificate management with support for multiple DNS providers and automatic Let's Encrypt integration.

### Supported DNS Providers

- **🌀 Hurricane Electric** (default) - Auto-configured dynamic DNS
- **☁️ Cloudflare** - Global CDN and DNS
- **🚀 AWS Route53** - Enterprise cloud DNS
- **🌊 DigitalOcean** - Developer-friendly DNS
- **🔧 Gandi** - Domain registrar DNS
- **📛 Namecheap** - Affordable domain DNS
- **🏆 GoDaddy** - Popular domain provider
- **🇫🇷 OVH** - European cloud provider
- **🔗 Linode** - Developer cloud platform
- **⚡ Vultr** - High-performance cloud
- **🇩🇪 Hetzner** - European hosting provider

### Quick SSL Setup

#### Hurricane Electric (Default - Zero Configuration)
```bash
# No configuration needed - works out of the box
echo 'le_email = "admin@example.com"' >> terraform.tfvars
```

#### Cloudflare DNS
```bash
# Add to terraform.tfvars
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "cloudflare"
        config = {
          CF_DNS_API_TOKEN = "your-cloudflare-dns-token"
        }
      }
    }
  }
}
```

#### AWS Route53
```bash
# Add to terraform.tfvars
service_overrides = {
  traefik = {
    dns_providers = {
      primary = {
        name = "route53"
        config = {
          AWS_ACCESS_KEY_ID = "your-access-key"
          AWS_SECRET_ACCESS_KEY = "your-secret-key"
          AWS_REGION = "us-east-1"
        }
      }
    }
  }
}
```

### Certificate Resolver Names

Certificate resolvers are now named after DNS providers for clarity:
- `hurricane` - Hurricane Electric DNS challenge
- `cloudflare` - Cloudflare DNS challenge
- `route53` - AWS Route53 DNS challenge
- `default` - HTTP challenge (no DNS required)

### Migration from Legacy Configuration

If you're upgrading from a previous version:

```bash
# OLD (deprecated)
traefik_cert_resolver = "wildcard"

# NEW (automatic based on DNS provider)
# Certificate resolver automatically uses DNS provider name
service_overrides = {
  traefik = {
    dns_providers = {
      primary = { name = "hurricane" }
    }
  }
}
```

## 🎯 Kubernetes Distribution Support

### Raspberry Pi / ARM64 (MicroK8s)

```bash
# Install MicroK8s
snap install microk8s --classic

# Configure for ARM64
echo 'cpu_arch = "arm64"' >> terraform.tfvars
echo 'enable_microk8s_mode = true' >> terraform.tfvars
echo 'use_hostpath_storage = true' >> terraform.tfvars
```

### K3s Clusters

```bash
# Configure for K3s
echo 'use_nfs_storage = true' >> terraform.tfvars
echo 'nfs_server = "192.168.1.100"' >> terraform.tfvars
echo 'metallb_address_pool = "192.168.1.200-210"' >> terraform.tfvars
```

### Cloud Providers (EKS/GKE/AKS)

```bash
# Use cloud storage and load balancers
echo 'use_nfs_storage = false' >> terraform.tfvars
echo 'use_hostpath_storage = false' >> terraform.tfvars
```

### Automation & Workflow Services

```bash
# Enable automation services
services = {
  home_assistant = true  # Open-source home automation platform
  openhab        = true  # Enterprise-grade home automation
  node_red       = true  # Visual programming for IoT
  n8n            = true  # Workflow automation platform
}

# Configure Node-RED with custom palette packages
service_overrides = {
  node_red = {
    cpu_arch           = "arm64"  # For Raspberry Pi
    storage_class      = "nfs-csi"
    persistent_disk_size = "2Gi"
    enable_persistence = true

    # Custom palette packages (npm packages + git repositories)
    palette_packages = [
      "node-red-contrib-home-assistant-websocket",
      "node-red-dashboard",
      "node-red-contrib-influxdb",
      "node-red-contrib-mqtt-broker",
      "node-red-node-pi-gpio",
      "node-red-contrib-modbus",
      # Git repositories supported
      "https://github.com/user/custom-node-red-nodes.git",
      "git+https://github.com/user/private-nodes.git"
    ]
  }
}
```

#### Node-RED Palette Installation

**tf-kube-any-compute** automatically installs Node-RED palette packages through a separate Kubernetes Job:

- **📦 Package Support**: Both npm registry packages and git repositories
- **🔄 Non-blocking**: Installation runs separately from Node-RED deployment
- **🎯 Smart Detection**: Automatically handles npm vs git package installation
- **📊 Progress Tracking**: Detailed logging with timestamps and status
- **🔄 Update Handling**: Checks for updates on existing packages
- **💾 Persistent**: Uses ReadWriteMany PVC for concurrent access

**Supported Package Formats:**
```bash
# NPM registry packages
"node-red-dashboard"
"node-red-contrib-home-assistant-websocket"

# GitHub repositories
"https://github.com/user/repo.git"
"git+https://github.com/user/repo.git"
"git+ssh://git@github.com/user/repo.git"
```

**Installation Process:**
1. Node-RED deploys immediately (no waiting)
2. Separate job installs packages in background
3. Restart Node-RED pod to load new packages: `kubectl rollout restart deployment/prod-node-red -n prod-node-red-system`

> ✅ **n8n Status**: Now available with native Terraform implementation! Provides enterprise-grade security, resource management, and full feature parity without Helm dependencies.

## 🛠️ Troubleshooting

### Automated Troubleshooting Scripts

```bash
# Comprehensive infrastructure health check
./scripts/debug.sh

# Quick health check (essential services only)
./scripts/debug.sh --quick

# Network-specific diagnostics
./scripts/debug.sh --network

# Storage-specific diagnostics
./scripts/debug.sh --storage

# Service-specific analysis
./scripts/debug.sh --service vault
```

### Vault-Specific Diagnostics

```bash
# Comprehensive Vault health check
./scripts/check-vault.sh
```

### Ingress & Networking Diagnostics

```bash
# Complete ingress and connectivity analysis
./scripts/check-ingress.sh

# Test SSL certificates
./scripts/check-ingress.sh --test-ssl
```

## 🧪 Testing Framework

### Make Commands for Testing

```bash
# Run quick validation tests
make test-quick              # Lint + validate + unit tests

# Run comprehensive test suite
make test-all               # All tests including integration

# Run safe tests only (no resource provisioning)
make test-safe              # Lint + validate + unit + scenarios
```

### Specific Test Types

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

## 📈 Learning Path

### Beginner (Start Here)
1. **Deploy Core Services**: Traefik + MetalLB
2. **Add Monitoring**: Prometheus + Grafana
3. **Container Management**: Portainer
4. **Learn kubectl**: Explore pods, services, ingresses

### Intermediate
1. **Service Discovery**: Deploy Consul
2. **Secrets Management**: Add Vault
3. **Enhanced Monitoring**: Explore comprehensive Kubernetes dashboards
4. **Storage Deep Dive**: Configure NFS + HostPath
5. **Architecture Optimization**: Mixed ARM64/AMD64 clusters

### Advanced
1. **Policy Enforcement**: Enable Gatekeeper
2. **Custom Dashboards**: Create Grafana dashboards
3. **Service Mesh**: Consul Connect with Traefik integration
4. **DNS Management**: Hurricane Electric dynamic DNS setup
5. **Automation Workflows**: Deploy Node-RED and n8n for IoT and workflow automation
6. **GitOps**: Integrate with ArgoCD

## 🤝 Contributing

We welcome contributions! Our community-friendly guides make it easy to get started:

### Quick Start for Contributors
- **[Contributor Quick Start](CONTRIBUTOR-QUICK-START.md)** - Get up and running in minutes
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Comprehensive contribution guidelines
- **[Testing Guide](TESTING-GUIDE.md)** - Complete testing documentation

### What We Cover
- **Development Setup** - Pre-commit hooks, tools, environment
- **Code Standards** - Terraform best practices, documentation
- **Testing Framework** - Unit tests, scenarios, integration, security
- **Pull Request Process** - Review process and requirements
- **Architecture Guidelines** - Multi-arch support, resource management

### ⚡ Performance Optimized Development

We've optimized the development experience for contributor productivity:

- **Fast Pre-commit**: ~2-5 minutes (was ~50 minutes)
- **Smart TFLint**: Only checks changed files with essential rules
- **Full Validation**: Available via `make lint-full` when needed
- **CI/CD Consistency**: Same optimized rules in GitLab CI

```bash
# Fast development cycle
git commit          # ~2-5 minutes (optimized)
make lint-full      # ~15-20 minutes (thorough, optional)
```

## 🗺️ Roadmap

- [ ] **GitOps Integration** - ArgoCD for continuous deployment
- [ ] **Backup Automation** - Velero for disaster recovery
- [ ] **Advanced Monitoring** - Custom Grafana dashboards
- [ ] **Service Mesh** - Consul Connect service mesh integration
- [ ] **Multi-Cluster** - Cluster federation support
- [ ] **Edge Computing** - K3s edge deployment patterns
- [ ] **Terraform Registry** - Publish as official Terraform module

## 📄 License

Distributed under the Apache License 2.0. See `LICENSE` for more information.

## 📞 Contact & Support

**Giovanni Annino** - [Website](https://giovannino.net) - [GitHub](https://github.com/gannino) - <giovanni.annino@gmail.com>

**Project Link**: [https://github.com/gannino/tf-kube-any-compute](https://github.com/gannino/tf-kube-any-compute)

### Community

- **[Issues](https://github.com/gannino/tf-kube-any-compute/issues)**: Report bugs and request features
- **[Discussions](https://github.com/gannino/tf-kube-any-compute/issues)**: Share your homelab setups and ask questions
- **[Wiki](https://github.com/gannino/tf-kube-any-compute/wiki)**: Community-contributed guides and tips

## 🙏 Acknowledgments

- **[Kubernetes Community](https://kubernetes.io)** - For the amazing orchestration platform
- **[Traefik](https://traefik.io)** - For the modern ingress controller
- **[HashiCorp](https://hashicorp.com)** - For Terraform and Vault
- **[Prometheus](https://prometheus.io)** - For monitoring excellence
- **[Grafana](https://grafana.com)** - For beautiful visualizations

### AI Development Partners

This project was significantly enhanced through collaboration with cutting-edge AI tools:

- **[GitHub Copilot](https://github.com/features/copilot)** - For intelligent code completion
- **[Amazon Q](https://aws.amazon.com/q/)** - For AWS and cloud infrastructure guidance
- **[Anthropic Claude](https://www.anthropic.com/claude)** - Primary AI partner for analysis and documentation
- **[OpenAI GPT-4](https://openai.com/gpt-4)** - For structured problem-solving
- **[Google Gemini](https://gemini.google.com)** - For creative solutions

---

## Happy Homelabbing! 🏠🚀

*Transform your homelab into a production-grade Kubernetes platform and accelerate your cloud-native learning journey.*

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
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

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
| <a name="module_home_assistant"></a> [home\_assistant](#module\_home\_assistant) | ./helm-home-assistant | n/a |
| <a name="module_host_path"></a> [host\_path](#module\_host\_path) | ./helm-host-path | n/a |
| <a name="module_kube_state_metrics"></a> [kube\_state\_metrics](#module\_kube\_state\_metrics) | ./helm-kube-state-metrics | n/a |
| <a name="module_loki"></a> [loki](#module\_loki) | ./helm-loki | n/a |
| <a name="module_metallb"></a> [metallb](#module\_metallb) | ./helm-metallb | n/a |
| <a name="module_n8n"></a> [n8n](#module\_n8n) | ./n8n | n/a |
| <a name="module_nfs_csi"></a> [nfs\_csi](#module\_nfs\_csi) | ./helm-nfs-csi | n/a |
| <a name="module_node_feature_discovery"></a> [node\_feature\_discovery](#module\_node\_feature\_discovery) | ./helm-node-feature-discovery | n/a |
| <a name="module_node_red"></a> [node\_red](#module\_node\_red) | ./helm-node-red | n/a |
| <a name="module_openhab"></a> [openhab](#module\_openhab) | ./helm-openhab | n/a |
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
| <a name="input_auth_override"></a> [auth\_override](#input\_auth\_override) | Override authentication method for specific services (DEPRECATED: use middleware\_overrides) | <pre>object({<br/>    alertmanager = optional(string)<br/>    consul       = optional(string)<br/>    grafana      = optional(string)<br/>    portainer    = optional(string)<br/>    prometheus   = optional(string)<br/>    traefik      = optional(string)<br/>    vault        = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_auto_mixed_cluster_mode"></a> [auto\_mixed\_cluster\_mode](#input\_auto\_mixed\_cluster\_mode) | Automatically configure services for mixed architecture clusters | `bool` | `true` | no |
| <a name="input_base_domain"></a> [base\_domain](#input\_base\_domain) | Base domain name (e.g., 'example.com') | `string` | `"local"` | no |
| <a name="input_cert_resolver_override"></a> [cert\_resolver\_override](#input\_cert\_resolver\_override) | Override the default cert resolver for specific services | <pre>object({<br/>    alertmanager = optional(string)<br/>    consul       = optional(string)<br/>    grafana      = optional(string)<br/>    portainer    = optional(string)<br/>    prometheus   = optional(string)<br/>    traefik      = optional(string)<br/>    vault        = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (leave empty for auto-detection) | `string` | `""` | no |
| <a name="input_cpu_arch_override"></a> [cpu\_arch\_override](#input\_cpu\_arch\_override) | Per-service CPU architecture overrides for mixed clusters | <pre>object({<br/>    consul                 = optional(string)<br/>    gatekeeper             = optional(string)<br/>    grafana                = optional(string)<br/>    home_assistant         = optional(string)<br/>    host_path              = optional(string)<br/>    loki                   = optional(string)<br/>    metallb                = optional(string)<br/>    n8n                    = optional(string)<br/>    nfs_csi                = optional(string)<br/>    node_feature_discovery = optional(string)<br/>    node_red               = optional(string)<br/>    openhab                = optional(string)<br/>    portainer              = optional(string)<br/>    prometheus             = optional(string)<br/>    prometheus_crds        = optional(string)<br/>    promtail               = optional(string)<br/>    traefik                = optional(string)<br/>    vault                  = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_default_cpu_limit"></a> [default\_cpu\_limit](#input\_default\_cpu\_limit) | Default CPU limit for containers when resource limits are enabled | `string` | `"200m"` | no |
| <a name="input_default_helm_cleanup_on_fail"></a> [default\_helm\_cleanup\_on\_fail](#input\_default\_helm\_cleanup\_on\_fail) | Default value for Helm cleanup on fail | `bool` | `true` | no |
| <a name="input_default_helm_disable_webhooks"></a> [default\_helm\_disable\_webhooks](#input\_default\_helm\_disable\_webhooks) | Default value for Helm disable webhooks | `bool` | `true` | no |
| <a name="input_default_helm_force_update"></a> [default\_helm\_force\_update](#input\_default\_helm\_force\_update) | Default value for Helm force update | `bool` | `true` | no |
| <a name="input_default_helm_replace"></a> [default\_helm\_replace](#input\_default\_helm\_replace) | Default value for Helm replace | `bool` | `false` | no |
| <a name="input_default_helm_skip_crds"></a> [default\_helm\_skip\_crds](#input\_default\_helm\_skip\_crds) | Default value for Helm skip CRDs | `bool` | `false` | no |
| <a name="input_default_helm_timeout"></a> [default\_helm\_timeout](#input\_default\_helm\_timeout) | Default timeout for Helm deployments in seconds | `number` | `600` | no |
| <a name="input_default_helm_wait"></a> [default\_helm\_wait](#input\_default\_helm\_wait) | Default value for Helm wait | `bool` | `true` | no |
| <a name="input_default_helm_wait_for_jobs"></a> [default\_helm\_wait\_for\_jobs](#input\_default\_helm\_wait\_for\_jobs) | Default value for Helm wait for jobs | `bool` | `true` | no |
| <a name="input_default_memory_limit"></a> [default\_memory\_limit](#input\_default\_memory\_limit) | Default memory limit for containers when resource limits are enabled | `string` | `"256Mi"` | no |
| <a name="input_default_storage_class"></a> [default\_storage\_class](#input\_default\_storage\_class) | Default storage class to use when not specified (empty = auto-detection) | `string` | `""` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based scheduling for specific services (useful for development) | <pre>object({<br/>    consul                 = optional(bool, false)<br/>    gatekeeper             = optional(bool, false)<br/>    grafana                = optional(bool, false)<br/>    home_assistant         = optional(bool, false)<br/>    host_path              = optional(bool, false)<br/>    kube_state_metrics     = optional(bool, false)<br/>    loki                   = optional(bool, false)<br/>    metallb                = optional(bool, false)<br/>    n8n                    = optional(bool, false)<br/>    nfs_csi                = optional(bool, false)<br/>    node_feature_discovery = optional(bool, false)<br/>    node_red               = optional(bool, false)<br/>    openhab                = optional(bool, false)<br/>    portainer              = optional(bool, false)<br/>    prometheus             = optional(bool, false)<br/>    prometheus_crds        = optional(bool, false)<br/>    promtail               = optional(bool, false)<br/>    traefik                = optional(bool, false)<br/>    vault                  = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | DEPRECATED: Use base\_domain and platform\_name instead. Legacy domain name configuration | `string` | `null` | no |
| <a name="input_enable_consul"></a> [enable\_consul](#input\_enable\_consul) | Enable Consul service mesh (DEPRECATED: use services.consul) | `bool` | `null` | no |
| <a name="input_enable_debug_outputs"></a> [enable\_debug\_outputs](#input\_enable\_debug\_outputs) | Enable debug outputs for troubleshooting | `bool` | `false` | no |
| <a name="input_enable_gatekeeper"></a> [enable\_gatekeeper](#input\_enable\_gatekeeper) | Enable Gatekeeper policy engine (DEPRECATED: use services.gatekeeper) | `bool` | `false` | no |
| <a name="input_enable_grafana"></a> [enable\_grafana](#input\_enable\_grafana) | Enable standalone Grafana dashboard (DEPRECATED: use services.grafana) | `bool` | `null` | no |
| <a name="input_enable_grafana_persistence"></a> [enable\_grafana\_persistence](#input\_enable\_grafana\_persistence) | Enable persistent storage for Grafana (DEPRECATED: use service\_overrides.grafana.enable\_persistence) | `bool` | `null` | no |
| <a name="input_enable_host_path"></a> [enable\_host\_path](#input\_enable\_host\_path) | Enable host path CSI driver (DEPRECATED: use services.host\_path) | `bool` | `null` | no |
| <a name="input_enable_kube_state_metrics"></a> [enable\_kube\_state\_metrics](#input\_enable\_kube\_state\_metrics) | Enable kube-state-metrics for Kubernetes metrics (DEPRECATED: use services.kube\_state\_metrics) | `bool` | `null` | no |
| <a name="input_enable_loki"></a> [enable\_loki](#input\_enable\_loki) | Enable Loki log aggregation (DEPRECATED: use services.loki) | `bool` | `null` | no |
| <a name="input_enable_metallb"></a> [enable\_metallb](#input\_enable\_metallb) | Enable MetalLB load balancer (DEPRECATED: use services.metallb) | `bool` | `null` | no |
| <a name="input_enable_microk8s_mode"></a> [enable\_microk8s\_mode](#input\_enable\_microk8s\_mode) | Enable MicroK8s mode with smaller resource footprint | `bool` | `true` | no |
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
| <a name="input_helm_timeouts"></a> [helm\_timeouts](#input\_helm\_timeouts) | Custom timeout values for specific Helm deployments (advanced users only) | <pre>object({<br/>    consul                 = optional(number, 600) # 10 minutes - service mesh setup<br/>    gatekeeper             = optional(number, 300) # 5 minutes - policy engine<br/>    grafana                = optional(number, 600) # 10 minutes - dashboard setup + persistence<br/>    host_path              = optional(number, 180) # 3 minutes - storage driver<br/>    loki                   = optional(number, 300) # 5 minutes - log aggregation setup<br/>    metallb                = optional(number, 300) # 5 minutes - load balancer setup<br/>    nfs_csi                = optional(number, 300) # 5 minutes - storage driver setup<br/>    node_feature_discovery = optional(number, 180) # 3 minutes - node labeling<br/>    portainer              = optional(number, 300) # 5 minutes - container management UI<br/>    prometheus_stack       = optional(number, 900) # 15 minutes - complex monitoring stack<br/>    prometheus_stack_crds  = optional(number, 300) # 5 minutes - CRD installation<br/>    promtail               = optional(number, 180) # 3 minutes - log collection daemonset<br/>    traefik                = optional(number, 600) # 10 minutes - ingress controller needs time<br/>    vault                  = optional(number, 600) # 10 minutes - secrets management setup<br/>  })</pre> | `{}` | no |
| <a name="input_le_email"></a> [le\_email](#input\_le\_email) | Email address for Let's Encrypt certificate notifications | `string` | `""` | no |
| <a name="input_letsencrypt_email"></a> [letsencrypt\_email](#input\_letsencrypt\_email) | Email address for Let's Encrypt certificate notifications (DEPRECATED: use le\_email) | `string` | `""` | no |
| <a name="input_metallb_address_pool"></a> [metallb\_address\_pool](#input\_metallb\_address\_pool) | IP address range for MetalLB load balancer | `string` | `"192.168.1.200-192.168.1.210"` | no |
| <a name="input_middleware_overrides"></a> [middleware\_overrides](#input\_middleware\_overrides) | Per-service middleware selection - choose which middlewares to apply to each service | <pre>object({<br/>    # Master enable/disable switch for all middleware functionality<br/>    enabled = optional(bool, false)<br/><br/>    # Global middleware settings (applied to all services unless overridden)<br/>    all = optional(object({<br/>      enable_rate_limit   = optional(bool, false)<br/>      enable_ip_whitelist = optional(bool, false)<br/>      custom_middlewares  = optional(list(string), [])<br/>    }), {})<br/><br/>    # Per-service middleware overrides<br/>    alertmanager = optional(object({<br/>      disable_auth        = optional(bool, false)<br/>      enable_rate_limit   = optional(bool)<br/>      enable_ip_whitelist = optional(bool)<br/>      custom_middlewares  = optional(list(string), [])<br/>    }), {})<br/><br/>    consul = optional(object({<br/>      enable_rate_limit   = optional(bool)<br/>      enable_ip_whitelist = optional(bool)<br/>      custom_middlewares  = optional(list(string), [])<br/>    }), {})<br/><br/>    grafana = optional(object({<br/>      enable_rate_limit   = optional(bool)<br/>      enable_ip_whitelist = optional(bool)<br/>      custom_middlewares  = optional(list(string), [])<br/>    }), {})<br/><br/>    portainer = optional(object({<br/>      enable_rate_limit   = optional(bool)<br/>      enable_ip_whitelist = optional(bool)<br/>      custom_middlewares  = optional(list(string), [])<br/>    }), {})<br/><br/>    prometheus = optional(object({<br/>      disable_auth        = optional(bool, false)<br/>      enable_rate_limit   = optional(bool)<br/>      enable_ip_whitelist = optional(bool)<br/>      custom_middlewares  = optional(list(string), [])<br/>    }), {})<br/><br/>    traefik = optional(object({<br/>      disable_auth        = optional(bool, false) # Disable auth for unprotected service<br/>      enable_rate_limit   = optional(bool)        # Override global setting<br/>      enable_ip_whitelist = optional(bool)        # Override global setting<br/>      custom_middlewares  = optional(list(string), [])<br/>    }), {})<br/><br/>    vault = optional(object({<br/>      enable_rate_limit   = optional(bool)<br/>      enable_ip_whitelist = optional(bool)<br/>      custom_middlewares  = optional(list(string), [])<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_monitoring_admin_password"></a> [monitoring\_admin\_password](#input\_monitoring\_admin\_password) | Custom password for monitoring services (Prometheus/AlertManager) admin (empty = auto-generate) | `string` | `""` | no |
| <a name="input_nfs_path"></a> [nfs\_path](#input\_nfs\_path) | NFS server path (DEPRECATED: use nfs\_server\_path) | `string` | `""` | no |
| <a name="input_nfs_server"></a> [nfs\_server](#input\_nfs\_server) | NFS server IP address (DEPRECATED: use nfs\_server\_address) | `string` | `""` | no |
| <a name="input_nfs_server_address"></a> [nfs\_server\_address](#input\_nfs\_server\_address) | NFS server IP address or hostname for persistent storage | `string` | `"192.168.1.100"` | no |
| <a name="input_nfs_server_path"></a> [nfs\_server\_path](#input\_nfs\_server\_path) | NFS server path for persistent storage | `string` | `"/mnt/k8s-storage"` | no |
| <a name="input_platform_name"></a> [platform\_name](#input\_platform\_name) | Platform identifier (e.g., 'k3s', 'eks', 'gke', 'aks', 'microk8s') | `string` | `"k3s"` | no |
| <a name="input_portainer_admin_password"></a> [portainer\_admin\_password](#input\_portainer\_admin\_password) | Custom password for Portainer admin (empty = auto-generate) | `string` | `""` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Service-specific configuration overrides for fine-grained control | <pre>object({<br/>    consul = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/>      cert_resolver = optional(string)<br/><br/>      # HA configuration<br/>      server_replicas = optional(number)<br/>      client_replicas = optional(number)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    gatekeeper = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    grafana = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/>      cert_resolver = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_persistence = optional(bool)<br/>      node_name          = optional(string)<br/>      admin_user         = optional(string)<br/>      admin_password     = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    host_path = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    kube_state_metrics = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    loki = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    metallb = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/><br/>      # Service-specific settings<br/>      address_pool = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    nfs_csi = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/><br/>      # Service-specific settings<br/>      nfs_server_address = optional(string)<br/>      nfs_server_path    = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    node_feature_discovery = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    portainer = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/>      cert_resolver = optional(string)<br/><br/>      # Service-specific settings<br/>      admin_password = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    prometheus = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/>      cert_resolver = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_ingress              = optional(bool)<br/>      enable_alertmanager_ingress = optional(bool)<br/>      retention_period            = optional(string)<br/>      monitoring_admin_password   = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    prometheus_crds = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    promtail = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    traefik = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_dashboard   = optional(bool)<br/>      dashboard_password = optional(string)<br/>      cert_resolver      = optional(string)<br/><br/>      # Middleware configuration - streamlined structure<br/>      middleware_config = optional(object({<br/>        # Basic Authentication<br/>        basic_auth = optional(object({<br/>          enabled         = optional(bool, false)<br/>          secret_name     = optional(string, "")<br/>          realm           = optional(string, "Authentication Required")<br/>          static_password = optional(string, "")<br/>          username        = optional(string, "admin")<br/>          }), {<br/>          enabled         = false<br/>          secret_name     = ""<br/>          realm           = "Authentication Required"<br/>          static_password = ""<br/>          username        = "admin"<br/>        })<br/><br/>        # LDAP Authentication<br/>        ldap_auth = optional(object({<br/>          enabled       = optional(bool, false)<br/>          method        = optional(string, "forwardauth") # "plugin" or "forwardauth"<br/>          log_level     = optional(string, "INFO")<br/>          url           = optional(string, "")<br/>          port          = optional(number, 389)<br/>          base_dn       = optional(string, "")<br/>          attribute     = optional(string, "uid")<br/>          bind_dn       = optional(string, "")<br/>          bind_password = optional(string, "")<br/>          search_filter = optional(string, "")<br/>          }), {<br/>          enabled       = false<br/>          method        = "forwardauth"<br/>          log_level     = "INFO"<br/>          url           = ""<br/>          port          = 389<br/>          base_dn       = ""<br/>          attribute     = "uid"<br/>          bind_dn       = ""<br/>          bind_password = ""<br/>          search_filter = ""<br/>        })<br/><br/>        # Rate Limiting<br/>        rate_limit = optional(object({<br/>          enabled = optional(bool, false)<br/>          average = optional(number, 100)<br/>          burst   = optional(number, 200)<br/>          }), {<br/>          enabled = false<br/>          average = 100<br/>          burst   = 200<br/>        })<br/><br/>        # IP Whitelist<br/>        ip_whitelist = optional(object({<br/>          enabled       = optional(bool, false)<br/>          source_ranges = optional(list(string), ["127.0.0.1/32"])<br/>          }), {<br/>          enabled       = false<br/>          source_ranges = ["127.0.0.1/32"]<br/>        })<br/><br/>        # Default Authentication (priority: LDAP > Basic)<br/>        default_auth = optional(object({<br/>          enabled       = optional(bool, false)<br/>          ldap_override = optional(bool, false) # Set to true to use LDAP instead of basic<br/>          basic_config = optional(object({<br/>            secret_name     = optional(string, "")<br/>            realm           = optional(string, "Authentication Required")<br/>            static_password = optional(string, "")<br/>            username        = optional(string, "admin")<br/>            }), {<br/>            secret_name     = ""<br/>            realm           = "Authentication Required"<br/>            static_password = ""<br/>            username        = "admin"<br/>          })<br/>          ldap_config = optional(object({<br/>            method        = optional(string, "forwardauth") # "plugin" or "forwardauth"<br/>            log_level     = optional(string, "INFO")<br/>            url           = optional(string, "")<br/>            port          = optional(number, 389)<br/>            base_dn       = optional(string, "")<br/>            attribute     = optional(string, "uid")<br/>            bind_dn       = optional(string, "")<br/>            bind_password = optional(string, "")<br/>            search_filter = optional(string, "")<br/>            }), {<br/>            method        = "forwardauth"<br/>            log_level     = "INFO"<br/>            url           = ""<br/>            port          = 389<br/>            base_dn       = ""<br/>            attribute     = "uid"<br/>            bind_dn       = ""<br/>            bind_password = ""<br/>            search_filter = ""<br/>          })<br/>          }), {<br/>          enabled       = false<br/>          ldap_override = false<br/>          basic_config = {<br/>            secret_name     = ""<br/>            realm           = "Authentication Required"<br/>            static_password = ""<br/>            username        = "admin"<br/>          }<br/>          ldap_config = {<br/>            log_level     = "INFO"<br/>            url           = ""<br/>            port          = 389<br/>            base_dn       = ""<br/>            attribute     = "uid"<br/>            bind_dn       = ""<br/>            bind_password = ""<br/>            search_filter = ""<br/>          }<br/>        })<br/>        }), {<br/>        basic_auth = {<br/>          enabled         = false<br/>          secret_name     = ""<br/>          realm           = "Authentication Required"<br/>          static_password = ""<br/>          username        = "admin"<br/>        }<br/>        ldap_auth = {<br/>          enabled       = false<br/>          method        = "forwardauth"<br/>          log_level     = "INFO"<br/>          url           = ""<br/>          port          = 389<br/>          base_dn       = ""<br/>          attribute     = "uid"<br/>          bind_dn       = ""<br/>          bind_password = ""<br/>          search_filter = ""<br/>        }<br/>        rate_limit = {<br/>          enabled = false<br/>          average = 100<br/>          burst   = 200<br/>        }<br/>        ip_whitelist = {<br/>          enabled       = false<br/>          source_ranges = ["127.0.0.1/32"]<br/>        }<br/>        default_auth = {<br/>          enabled       = false<br/>          ldap_override = false<br/>          basic_config = {<br/>            secret_name     = ""<br/>            realm           = "Authentication Required"<br/>            static_password = ""<br/>            username        = "admin"<br/>          }<br/>          ldap_config = {<br/>            method        = "forwardauth"<br/>            log_level     = "INFO"<br/>            url           = ""<br/>            port          = 389<br/>            base_dn       = ""<br/>            attribute     = "uid"<br/>            bind_dn       = ""<br/>            bind_password = ""<br/>            search_filter = ""<br/>          }<br/>        }<br/>      })<br/><br/>      # Dashboard middleware - use centralized middleware names<br/>      dashboard_middleware = optional(list(string), [])<br/><br/>      # DNS provider configuration<br/>      dns_providers = optional(object({<br/>        primary = optional(object({<br/>          name   = string<br/>          config = optional(map(string), {})<br/>        }))<br/>        additional = optional(list(object({<br/>          name   = string<br/>          config = map(string)<br/>        })), [])<br/>      }))<br/><br/>      dns_challenge_config = optional(object({<br/>        resolvers                 = optional(list(string))<br/>        delay_before_check        = optional(string)<br/>        disable_propagation_check = optional(bool)<br/>        polling_interval          = optional(string)<br/>        propagation_timeout       = optional(string)<br/>        sequence_interval         = optional(string)<br/>        http_timeout              = optional(string)<br/>      }))<br/><br/>      cert_resolvers = optional(object({<br/>        default = optional(object({<br/>          challenge_type = optional(string)<br/>          dns_provider   = optional(string)<br/>        }))<br/>        wildcard = optional(object({<br/>          challenge_type = optional(string)<br/>          dns_provider   = optional(string)<br/>        }))<br/>        custom = optional(map(object({<br/>          challenge_type = string<br/>          dns_provider   = optional(string)<br/>        })), {})<br/>      }))<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    vault = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/>      cert_resolver = optional(string)<br/><br/>      # HA configuration<br/>      ha_replicas = optional(number)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    node_red = optional(object({<br/>      # Core configuration<br/>      cpu_arch             = optional(string)<br/>      chart_version        = optional(string)<br/>      storage_class        = optional(string)<br/>      persistent_disk_size = optional(string)<br/>      cert_resolver        = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_persistence = optional(bool)<br/>      palette_packages   = optional(list(string))<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    n8n = optional(object({<br/>      # Core configuration<br/>      cpu_arch             = optional(string)<br/>      chart_version        = optional(string)<br/>      storage_class        = optional(string)<br/>      persistent_disk_size = optional(string)<br/>      cert_resolver        = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_persistence = optional(bool)<br/>      enable_database    = optional(bool)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    home_assistant = optional(object({<br/>      # Core configuration<br/>      cpu_arch             = optional(string)<br/>      chart_version        = optional(string)<br/>      storage_class        = optional(string)<br/>      persistent_disk_size = optional(string)<br/>      cert_resolver        = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_persistence  = optional(bool)<br/>      enable_privileged   = optional(bool)<br/>      enable_host_network = optional(bool)<br/>      enable_ingress      = optional(bool)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    openhab = optional(object({<br/>      # Core configuration<br/>      cpu_arch             = optional(string)<br/>      chart_version        = optional(string)<br/>      storage_class        = optional(string)<br/>      persistent_disk_size = optional(string)<br/>      addons_disk_size     = optional(string)<br/>      conf_disk_size       = optional(string)<br/>      cert_resolver        = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_persistence   = optional(bool)<br/>      enable_privileged    = optional(bool)<br/>      enable_host_network  = optional(bool)<br/>      enable_karaf_console = optional(bool)<br/>      enable_ingress       = optional(bool)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_services"></a> [services](#input\_services) | Service enablement configuration - choose your stack components | <pre>object({<br/>    # Core infrastructure services<br/>    consul                 = optional(bool, false) # Disabled by default - complex setup<br/>    gatekeeper             = optional(bool, false)<br/>    grafana                = optional(bool, true)<br/>    home_assistant         = optional(bool, false) # Open-source home automation platform<br/>    host_path              = optional(bool, true)<br/>    kube_state_metrics     = optional(bool, true)  # Kubernetes metrics for Prometheus<br/>    loki                   = optional(bool, false) # Disabled by default - resource intensive<br/>    metallb                = optional(bool, true)<br/>    n8n                    = optional(bool, false) # Workflow automation platform<br/>    nfs_csi                = optional(bool, false) # Disabled by default - requires NFS server<br/>    node_feature_discovery = optional(bool, true)<br/>    node_red               = optional(bool, false) # Visual programming for IoT and automation<br/>    openhab                = optional(bool, false) # Vendor-neutral home automation platform<br/>    portainer              = optional(bool, true)<br/>    prometheus             = optional(bool, true)<br/>    prometheus_crds        = optional(bool, true)<br/>    promtail               = optional(bool, false) # Disabled by default - typically used with Loki, but can operate independently as a log shipper<br/>    traefik                = optional(bool, true)<br/>    vault                  = optional(bool, false) # Disabled by default - requires manual unsealing<br/>  })</pre> | `{}` | no |
| <a name="input_storage_class_override"></a> [storage\_class\_override](#input\_storage\_class\_override) | Override storage class for services (DEPRECATED: use service\_overrides.{service}.storage\_class) | <pre>object({<br/>    alertmanager = optional(string)<br/>    consul       = optional(string)<br/>    grafana      = optional(string)<br/>    loki         = optional(string)<br/>    portainer    = optional(string)<br/>    prometheus   = optional(string)<br/>    traefik      = optional(string)<br/>    vault        = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_system_defaults"></a> [system\_defaults](#input\_system\_defaults) | System-wide default values for consistent configuration | <pre>object({<br/>    # Network defaults<br/>    nfs_server_address   = optional(string, "192.168.1.100")<br/>    nfs_server_path      = optional(string, "/mnt/k8s-storage")<br/>    metallb_address_pool = optional(string, "192.168.1.200-192.168.1.210")<br/><br/>    # Resource defaults<br/>    cpu_limit_default      = optional(string, "200m")<br/>    memory_limit_default   = optional(string, "256Mi")<br/>    cpu_request_default    = optional(string, "100m")<br/>    memory_request_default = optional(string, "128Mi")<br/><br/>    # Resource defaults for high-performance services<br/>    cpu_limit_high      = optional(string, "1000m")<br/>    memory_limit_high   = optional(string, "2Gi")<br/>    cpu_request_high    = optional(string, "500m")<br/>    memory_request_high = optional(string, "1Gi")<br/><br/>    # Resource defaults for lightweight services<br/>    cpu_limit_light      = optional(string, "100m")<br/>    memory_limit_light   = optional(string, "64Mi")<br/>    cpu_request_light    = optional(string, "25m")<br/>    memory_request_light = optional(string, "32Mi")<br/><br/>    # Storage size defaults<br/>    storage_size_small  = optional(string, "1Gi")<br/>    storage_size_medium = optional(string, "2Gi")<br/>    storage_size_large  = optional(string, "4Gi")<br/>    storage_size_xlarge = optional(string, "8Gi")<br/><br/>    # MicroK8s optimized defaults<br/>    microk8s_cpu_limit      = optional(string, "200m")<br/>    microk8s_memory_limit   = optional(string, "256Mi")<br/>    microk8s_storage_small  = optional(string, "1Gi")<br/>    microk8s_storage_medium = optional(string, "2Gi")<br/>    microk8s_storage_large  = optional(string, "4Gi")<br/><br/>    # Helm timeout defaults<br/>    helm_timeout_short  = optional(number, 180)<br/>    helm_timeout_medium = optional(number, 300)<br/>    helm_timeout_long   = optional(number, 600)<br/>    helm_timeout_xllong = optional(number, 900)<br/><br/>    # Authentication defaults<br/>    ldap_port_default  = optional(number, 389)<br/>    rate_limit_average = optional(number, 100)<br/>    rate_limit_burst   = optional(number, 200)<br/><br/>    # Service replica defaults<br/>    ha_replicas_default = optional(number, 2)<br/>    ha_replicas_high    = optional(number, 3)<br/>  })</pre> | `{}` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Default certificate resolver for Traefik SSL certificates | `string` | `"wildcard"` | no |
| <a name="input_use_hostpath_storage"></a> [use\_hostpath\_storage](#input\_use\_hostpath\_storage) | Use hostPath storage (takes effect when use\_nfs\_storage is false) | `bool` | `true` | no |
| <a name="input_use_nfs_storage"></a> [use\_nfs\_storage](#input\_use\_nfs\_storage) | Use NFS storage as primary storage backend | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_applied_service_configs"></a> [applied\_service\_configs](#output\_applied\_service\_configs) | Applied service configurations showing override hierarchy results |
| <a name="output_cert_resolver_debug"></a> [cert\_resolver\_debug](#output\_cert\_resolver\_debug) | Certificate resolver debugging information |
| <a name="output_cluster_info"></a> [cluster\_info](#output\_cluster\_info) | Cluster information and configuration summary |
| <a name="output_cpu_arch_debug"></a> [cpu\_arch\_debug](#output\_cpu\_arch\_debug) | CPU architecture debugging information |
| <a name="output_detected_architecture"></a> [detected\_architecture](#output\_detected\_architecture) | Auto-detected CPU architecture and cluster analysis |
| <a name="output_enabled_services"></a> [enabled\_services](#output\_enabled\_services) | Summary of enabled services and their status |
| <a name="output_helm_debug"></a> [helm\_debug](#output\_helm\_debug) | Helm configuration debugging information |
| <a name="output_middleware_debug"></a> [middleware\_debug](#output\_middleware\_debug) | Middleware configuration debugging information |
| <a name="output_mixed_cluster_strategy"></a> [mixed\_cluster\_strategy](#output\_mixed\_cluster\_strategy) | Strategy and recommendations for mixed architecture clusters |
| <a name="output_service_outputs"></a> [service\_outputs](#output\_service\_outputs) | Detailed outputs from all deployed services with full module information for debugging |
| <a name="output_service_urls"></a> [service\_urls](#output\_service\_urls) | Quick access URLs for deployed services |
| <a name="output_storage_configuration"></a> [storage\_configuration](#output\_storage\_configuration) | Storage configuration details and available storage classes |
| <a name="output_storage_debug"></a> [storage\_debug](#output\_storage\_debug) | Storage debugging information |
| <a name="output_system_configuration"></a> [system\_configuration](#output\_system\_configuration) | System defaults and configuration hierarchy |

<!-- END_TF_DOCS -->

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
| <a name="input_default_cpu_limit"></a> [default\_cpu\_limit](#input\_default\_cpu\_limit) | Default CPU limit for containers when resource limits are enabled | `string` | `"200m"` | no |
| <a name="input_default_helm_cleanup_on_fail"></a> [default\_helm\_cleanup\_on\_fail](#input\_default\_helm\_cleanup\_on\_fail) | Default value for Helm cleanup on fail | `bool` | `true` | no |
| <a name="input_default_helm_disable_webhooks"></a> [default\_helm\_disable\_webhooks](#input\_default\_helm\_disable\_webhooks) | Default value for Helm disable webhooks | `bool` | `true` | no |
| <a name="input_default_helm_force_update"></a> [default\_helm\_force\_update](#input\_default\_helm\_force\_update) | Default value for Helm force update | `bool` | `true` | no |
| <a name="input_default_helm_replace"></a> [default\_helm\_replace](#input\_default\_helm\_replace) | Default value for Helm replace | `bool` | `false` | no |
| <a name="input_default_helm_skip_crds"></a> [default\_helm\_skip\_crds](#input\_default\_helm\_skip\_crds) | Default value for Helm skip CRDs | `bool` | `false` | no |
| <a name="input_default_helm_timeout"></a> [default\_helm\_timeout](#input\_default\_helm\_timeout) | Default timeout for Helm deployments in seconds | `number` | `600` | no |
| <a name="input_default_helm_wait"></a> [default\_helm\_wait](#input\_default\_helm\_wait) | Default value for Helm wait | `bool` | `true` | no |
| <a name="input_default_helm_wait_for_jobs"></a> [default\_helm\_wait\_for\_jobs](#input\_default\_helm\_wait\_for\_jobs) | Default value for Helm wait for jobs | `bool` | `true` | no |
| <a name="input_default_memory_limit"></a> [default\_memory\_limit](#input\_default\_memory\_limit) | Default memory limit for containers when resource limits are enabled | `string` | `"256Mi"` | no |
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
| <a name="input_enable_microk8s_mode"></a> [enable\_microk8s\_mode](#input\_enable\_microk8s\_mode) | Enable MicroK8s mode with smaller resource footprint | `bool` | `true` | no |
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
| <a name="input_nfs_server_address"></a> [nfs\_server\_address](#input\_nfs\_server\_address) | NFS server IP address or hostname for persistent storage | `string` | `"192.168.1.100"` | no |
| <a name="input_nfs_server_path"></a> [nfs\_server\_path](#input\_nfs\_server\_path) | NFS server path for persistent storage | `string` | `"/mnt/k8s-storage"` | no |
| <a name="input_platform_name"></a> [platform\_name](#input\_platform\_name) | Platform identifier (e.g., 'k3s', 'eks', 'gke', 'aks', 'microk8s') | `string` | `"k3s"` | no |
| <a name="input_portainer_admin_password"></a> [portainer\_admin\_password](#input\_portainer\_admin\_password) | Custom password for Portainer admin (empty = auto-generate) | `string` | `""` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Service-specific configuration overrides for fine-grained control | <pre>object({<br/>    traefik = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_dashboard   = optional(bool)<br/>      dashboard_password = optional(string)<br/>      cert_resolver      = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    prometheus = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_ingress              = optional(bool)<br/>      enable_alertmanager_ingress = optional(bool)<br/>      retention_period            = optional(string)<br/>      monitoring_admin_password   = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    grafana = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      enable_persistence = optional(bool)<br/>      node_name          = optional(string)<br/>      admin_user         = optional(string)<br/>      admin_password     = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    metallb = optional(object({<br/>      # Service-specific settings<br/>      address_pool = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    vault = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    consul = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    portainer = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Service-specific settings<br/>      admin_password = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    loki = optional(object({<br/>      # Core configuration<br/>      cpu_arch      = optional(string)<br/>      chart_version = optional(string)<br/>      storage_class = optional(string)<br/>      storage_size  = optional(string)<br/><br/>      # Resource limits<br/>      cpu_limit      = optional(string)<br/>      memory_limit   = optional(string)<br/>      cpu_request    = optional(string)<br/>      memory_request = optional(string)<br/><br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    nfs_csi = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    host_path = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    node_feature_discovery = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    gatekeeper = optional(object({<br/>      # Gatekeeper-specific options<br/>      gatekeeper_version = optional(string)<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    prometheus_crds = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/><br/>    promtail = optional(object({<br/>      # Helm deployment options<br/>      helm_timeout          = optional(number)<br/>      helm_wait             = optional(bool)<br/>      helm_wait_for_jobs    = optional(bool)<br/>      helm_disable_webhooks = optional(bool)<br/>      helm_skip_crds        = optional(bool)<br/>      helm_replace          = optional(bool)<br/>      helm_force_update     = optional(bool)<br/>      helm_cleanup_on_fail  = optional(bool)<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_services"></a> [services](#input\_services) | Service enablement configuration - choose your stack components | <pre>object({<br/>    # Core infrastructure services<br/>    traefik   = optional(bool, true)<br/>    metallb   = optional(bool, true)<br/>    nfs_csi   = optional(bool, false) # Disabled by default - requires NFS server<br/>    host_path = optional(bool, true)<br/><br/>    # Monitoring and observability stack<br/>    prometheus      = optional(bool, true)<br/>    prometheus_crds = optional(bool, true)<br/>    grafana         = optional(bool, true)<br/>    loki            = optional(bool, false) # Disabled by default - resource intensive<br/>    promtail        = optional(bool, false) # Disabled by default - typically used with Loki, but can operate independently as a log shipper<br/><br/>    # Service mesh and security<br/>    consul     = optional(bool, false) # Disabled by default - complex setup<br/>    vault      = optional(bool, false) # Disabled by default - requires manual unsealing<br/>    gatekeeper = optional(bool, false)<br/><br/>    # Management and discovery<br/>    portainer              = optional(bool, true)<br/>    node_feature_discovery = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_storage_class_override"></a> [storage\_class\_override](#input\_storage\_class\_override) | Override the default storage class selection logic | <pre>object({<br/>    prometheus   = optional(string)<br/>    grafana      = optional(string)<br/>    loki         = optional(string)<br/>    alertmanager = optional(string)<br/>    consul       = optional(string)<br/>    vault        = optional(string)<br/>    traefik      = optional(string)<br/>    portainer    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_traefik_cert_resolver"></a> [traefik\_cert\_resolver](#input\_traefik\_cert\_resolver) | Default certificate resolver for Traefik SSL certificates | `string` | `"wildcard"` | no |
| <a name="input_traefik_dashboard_password"></a> [traefik\_dashboard\_password](#input\_traefik\_dashboard\_password) | Custom password for Traefik dashboard (empty = auto-generate) | `string` | `""` | no |
| <a name="input_use_hostpath_storage"></a> [use\_hostpath\_storage](#input\_use\_hostpath\_storage) | Use hostPath storage (takes effect when use\_nfs\_storage is false) | `bool` | `true` | no |
| <a name="input_use_nfs_storage"></a> [use\_nfs\_storage](#input\_use\_nfs\_storage) | Use NFS storage as primary storage backend | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_applied_service_configs"></a> [applied\_service\_configs](#output\_applied\_service\_configs) | Applied service configurations showing override hierarchy results |
| <a name="output_cert_resolver_debug"></a> [cert\_resolver\_debug](#output\_cert\_resolver\_debug) | Certificate resolver debugging information |
| <a name="output_cluster_info"></a> [cluster\_info](#output\_cluster\_info) | Cluster information and configuration summary |
| <a name="output_cpu_arch_debug"></a> [cpu\_arch\_debug](#output\_cpu\_arch\_debug) | CPU architecture debugging information |
| <a name="output_debug_storage_config"></a> [debug\_storage\_config](#output\_debug\_storage\_config) | Debug information for storage configuration |
| <a name="output_detected_architecture"></a> [detected\_architecture](#output\_detected\_architecture) | Auto-detected CPU architecture and cluster analysis |
| <a name="output_enabled_services"></a> [enabled\_services](#output\_enabled\_services) | Summary of enabled services and their status |
| <a name="output_helm_debug"></a> [helm\_debug](#output\_helm\_debug) | Helm configuration debugging information |
| <a name="output_mixed_cluster_strategy"></a> [mixed\_cluster\_strategy](#output\_mixed\_cluster\_strategy) | Strategy and recommendations for mixed architecture clusters |
| <a name="output_service_outputs"></a> [service\_outputs](#output\_service\_outputs) | Detailed outputs from all deployed services |
| <a name="output_service_urls"></a> [service\_urls](#output\_service\_urls) | Quick access URLs for deployed services |
| <a name="output_storage_configuration"></a> [storage\_configuration](#output\_storage\_configuration) | Storage configuration details and available storage classes |
| <a name="output_storage_debug"></a> [storage\_debug](#output\_storage\_debug) | Storage debugging information |
