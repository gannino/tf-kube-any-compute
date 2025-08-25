# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### 🏠 Added - Home Automation Services

#### **New Terraform Modules**
- **🏠 Home Assistant Module** (`helm-home-assistant/`): Complete open-source home automation platform
  - ARM64/AMD64 architecture support with intelligent placement
  - Persistent storage with configurable size (default 5Gi)
  - Privileged mode support for USB device access
  - Host networking for device discovery
  - Traefik ingress with automatic SSL certificates
  - Resource optimization for Raspberry Pi deployments

- **🏢 openHAB Module** (`helm-openhab/`): Enterprise-grade home automation platform
  - Java-based runtime optimized for ARM64 and AMD64
  - Multi-volume persistent storage (data/addons/conf)
  - Karaf console support for advanced configuration
  - Enhanced resource allocation (2Gi RAM default)
  - Device access and host networking capabilities
  - Production-ready security configurations

#### **Service Integration**
- **Extended Service Configuration**: Added `home_assistant` and `openhab` to main services object
- **Architecture Override Support**: Per-service CPU architecture selection
- **Storage Class Management**: Intelligent storage class selection for automation services
- **Resource Optimization**: Architecture-aware resource limits and requests
- **Helm Configuration**: Complete Helm deployment options for both services

#### **Documentation Updates**
- **README.md**: Updated automation services section with comprehensive examples
- **terraform.tfvars.example**: Added configuration examples for both services
- **Module Documentation**: Auto-generated terraform-docs for both modules
- **Architecture Guide**: Updated mixed-cluster strategies for automation workloads

#### **Configuration Examples**
```hcl
# Enable home automation services
services = {
  home_assistant = true  # Open-source platform
  openhab        = true  # Enterprise platform
}

# Advanced configuration
service_overrides = {
  home_assistant = {
    cpu_arch             = "arm64"
    storage_class        = "nfs-csi"
    persistent_disk_size = "10Gi"
    enable_privileged    = true
    enable_host_network  = true
  }
  
  openhab = {
    cpu_arch             = "amd64"
    storage_class        = "nfs-csi"
    persistent_disk_size = "15Gi"
    addons_disk_size     = "3Gi"
    conf_disk_size       = "2Gi"
    enable_karaf_console = true
  }
}
```

### 🔧 Technical Implementation
- **Terraform Module Pattern**: Both modules follow established project conventions
- **Helm Template System**: Comprehensive values.yaml.tpl templates
- **PVC Management**: Intelligent persistent volume claim handling
- **Ingress Integration**: Seamless Traefik ingress configuration
- **Resource Management**: Architecture-aware resource allocation
- **Security Context**: Proper security contexts with privileged mode support

### 🧪 Testing Coverage
- **Unit Tests**: Architecture detection and service enablement logic
- **Scenario Tests**: ARM64, AMD64, and mixed-cluster deployment scenarios
- **Integration Tests**: Service health and connectivity validation
- **Documentation Tests**: Terraform-docs automation and validation

## [2.0.0] - 2025-08-09

### 🎉 Major Release - Complete Infrastructure Overhaul

This major release represents a complete evolution of tf-kube-any-compute from a basic Kubernetes deployment tool to a comprehensive, production-grade infrastructure platform.

### 🚀 Added

#### **Enhanced Configuration System**
- **Service Override Framework**: 200+ configuration options for fine-grained service control
- **Modern Domain Structure**: `{workspace}.{platform}.{base_domain}` format
- **Flexible Service Selection**: Granular service enablement with scenario-based examples
- **Auto-generated Passwords**: Secure password management for all services

#### **Advanced Architecture Management**
- **Intelligent Architecture Detection**: Multi-stage detection for ARM64/AMD64/mixed clusters
- **Smart Mixed-Cluster Support**: Automatic service placement optimization
- **Per-Service Architecture Overrides**: Strategic placement for performance optimization
- **Architecture Debug Information**: Comprehensive cluster analysis outputs

#### **Comprehensive Testing Framework**
- **Terraform Native Testing**: Full test suite using `terraform test` commands
- **Multi-Level Testing**: Unit, scenario, integration, and performance tests
- **Make Command Automation**: 15+ specialized test commands (`make test-*`)
- **Test Coverage**: Architecture detection, storage classes, Helm configs, service enablement
- **CI/CD Integration**: Automated testing pipeline with proper error handling

#### **Troubleshooting Automation**
- **Advanced Debug Scripts**: Multi-mode diagnostic framework
- **Main Debug Script**: Supports `--quick`, `--full`, `--network`, `--storage`, `--service` modes
- **Vault Health Check**: Specialized Vault diagnostics with authentication handling
- **Ingress Diagnostics**: Complete networking analysis with SSL certificate checking
- **Smart Output**: Color-coded status with actionable troubleshooting recommendations

#### **Complete Documentation Overhaul**
- **Comprehensive README**: Full coverage of all environments and use cases
- **Variable Reference**: Complete table for all 50+ configuration variables
- **Architecture Strategy**: Updated service placement rules and mixed-cluster management
- **Configuration Scenarios**: 3 comprehensive deployment examples (Pi, Mixed, Cloud)
- **Collaboration Prerequisites**: Hardware requirements and setup guide for contributors
- **Helm/Terraform Troubleshooting**: Best practices for common integration issues

#### **Service Portfolio Expansion**
- **Core Infrastructure**: Traefik, MetalLB, Storage (NFS-CSI, HostPath)
- **Monitoring Stack**: Prometheus, Grafana, Loki, Promtail with ARM64 optimization
- **Security & Service Mesh**: Consul, Vault with production-ready configurations
- **Management Tools**: Portainer, Node Feature Discovery
- **Policy Engine**: Gatekeeper (optional, with CRD handling improvements)

### 🛡️ Security Enhancements

#### **Infrastructure Hardening**
- **Traefik Security**: Removed `api.insecure=true` vulnerability
- **Resource Limits**: Enhanced pod-level and PVC-level constraints
- **Auto-generated Passwords**: Secure 12-16 character passwords for all services
- **Certificate Management**: Improved Let's Encrypt integration with wildcard support

#### **Deployment Stability**
- **Zero Destroys**: Achieved 0 destroys (down from 4 destroys in previous versions)
- **Proper Lifecycle Management**: Enhanced Helm deployment handling
- **Dependency Management**: Improved service startup order and dependencies

### 🔧 Technical Improvements

#### **Code Quality**
- **Variable Validation**: Comprehensive validation rules for all inputs
- **Error Handling**: Improved error messages and recovery procedures
- **Resource Tagging**: Consistent labeling and organization
- **Performance Optimization**: Resource-conscious defaults for different architectures

#### **Storage Strategy**
- **Intelligent Storage Selection**: Automatic storage class selection based on environment
- **NFS-CSI Primary**: Shared storage for production workloads
- **HostPath Fallback**: Local storage for development and testing
- **Storage Class Override**: Per-service storage class customization

#### **Helm Integration**
- **Chart Version Management**: Pinnable chart versions with intelligent defaults
- **Timeout Handling**: Service-specific timeout configurations
- **Wait Conditions**: Proper readiness waiting with job completion support
- **Webhook Management**: Configurable webhook handling for compatibility

### 🏗️ Platform Support

#### **Kubernetes Distributions**
- **MicroK8s**: Optimized configurations for ARM64 Raspberry Pi clusters
- **K3s**: Full feature support with mixed-architecture capabilities
- **Cloud Providers**: Enhanced support for EKS, GKE, AKS
- **Standard Kubernetes**: Compatible with vanilla Kubernetes installations

#### **Architecture Support**
- **ARM64**: Optimized for Raspberry Pi 4 with 16GB+ RAM
- **AMD64**: Full feature support for traditional x86_64 systems
- **Mixed Clusters**: Intelligent service placement across architectures
- **Cloud Environments**: Seamless integration with cloud-native services

### 📋 Configuration Examples

#### **Raspberry Pi Homelab**
```hcl
base_domain = "local"
platform_name = "microk8s"
cpu_arch = "arm64"
use_hostpath_storage = true

services = {
  traefik = true
  metallb = true
  prometheus = true
  grafana = true
  portainer = true
  # Resource-conscious selection
  consul = false
  vault = false
  loki = false
}
```

#### **Mixed Architecture Production**
```hcl
base_domain = "company.com"
cpu_arch = ""
auto_mixed_cluster_mode = true

cpu_arch_override = {
  traefik = "amd64"      # Performance critical
  prometheus = "amd64"   # Resource intensive
  grafana = "arm64"      # UI on efficient ARM64
}
```

### 🔄 Changed

#### **Breaking Changes**
- **Variable Structure**: Migrated from individual service enables to unified `services` object
- **Domain Configuration**: Changed from `domain_name` to `base_domain` + `platform_name`
- **Storage Configuration**: Unified storage backend selection with `use_nfs_storage`/`use_hostpath_storage`

#### **Configuration Migration**
```hcl
# OLD (v1.x)
enable_traefik = true
enable_prometheus = true
domain_name = ".local"

# NEW (v2.0)
services = {
  traefik = true
  prometheus = true
}
base_domain = "local"
platform_name = "k3s"
```

#### **Deprecated Features**
- Individual service enable variables (use `services` object)
- Legacy domain configuration (use `base_domain` + `platform_name`)
- Manual password configuration (use auto-generated with overrides)

### 🐛 Fixed

#### **Deployment Issues**
- **Helm State Conflicts**: Improved handling of failed deployments
- **Resource Cleanup**: Better cleanup on deployment failures
- **Dependency Resolution**: Fixed service startup order issues
- **Architecture Scheduling**: Resolved pod placement issues on mixed clusters

#### **Security Vulnerabilities**
- **Traefik Insecure API**: Removed insecure API exposure
- **Default Passwords**: Replaced weak defaults with strong auto-generated passwords
- **Resource Limits**: Added comprehensive resource constraints

#### **Documentation Issues**
- **Missing Examples**: Added comprehensive configuration scenarios
- **Outdated Instructions**: Updated all setup and deployment instructions
- **Architecture Guidance**: Clarified mixed-cluster deployment strategies

### 📦 Dependencies

#### **Provider Versions**
- **Terraform**: >= 0.14
- **Kubernetes Provider**: ~> 2.0
- **Helm Provider**: ~> 3.0
- **kubectl Provider**: ~> 1.0

#### **Kubernetes Requirements**
- **Kubernetes**: >= 1.21
- **Helm**: >= 3.0
- **kubectl**: >= 1.21

### 🎯 Migration Guide

#### **From v1.x to v2.0**

1. **Update Variable Configuration**
   ```bash
   # Backup existing configuration
   cp terraform.tfvars terraform.tfvars.v1.backup

   # Copy new example configuration
   cp terraform.tfvars.example terraform.tfvars

   # Migrate your settings to new structure
   ```

2. **Service Enablement Migration**
   ```hcl
   # Replace individual enables with services object
   services = {
     traefik = var.enable_traefik
     prometheus = var.enable_prometheus
     # ... etc
   }
   ```

3. **Test New Configuration**
   ```bash
   make test-safe    # Validate configuration
   make plan         # Review changes
   make apply        # Deploy updated infrastructure
   ```

### 🚀 Terraform Registry Readiness

#### **Registry Standards Compliance**
- ✅ Standard module layout with proper file organization
- ✅ Comprehensive variable documentation with types and validation
- ✅ Complete examples covering multiple deployment scenarios
- ✅ Proper output values for module integration
- ✅ Apache License 2.0 for enterprise compatibility

#### **Quality Assurance**
- ✅ Terraform validation passes without errors
- ✅ Comprehensive test suite with 90%+ coverage
- ✅ Security scanning and best practices compliance
- ✅ Documentation completeness and accuracy
- ✅ Version tagging and semantic versioning

### 🤝 Contributors

Special thanks to the homelab community for feedback and testing across various hardware configurations.

### 🔗 Links

- **Documentation**: [README.md](./README.md)
- **Examples**: [terraform.tfvars.example](./terraform.tfvars.example)
- **Testing**: [Makefile](./Makefile)
- **License**: [LICENSE](./LICENSE)

---

## [1.0.0] - 2024-12-01

### Initial Release
- Basic Terraform module for Kubernetes infrastructure
- Support for Traefik, Prometheus, Grafana
- ARM64 and AMD64 architecture support
- MicroK8s and K3s compatibility

### Added
- Core service modules for essential Kubernetes services
- Basic architecture detection
- Helm chart deployments
- Initial documentation

### Notes
- This was the foundational release
- Limited configuration options
- Single-architecture focus
- Basic service portfolio

---

**Note**: Version 2.0.0 represents a complete rewrite and major enhancement of the project. Users upgrading from v1.x should follow the migration guide carefully.
