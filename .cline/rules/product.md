# Product Overview: tf-kube-any-compute

## Purpose
Universal Kubernetes infrastructure platform that provides comprehensive, cloud-agnostic Kubernetes deployments designed for tech enthusiasts, homelab builders, and learning environments. Enables rapid cluster deployment with production-grade services across any compute platform.

**Repository**: https://github.com/gannino/tf-kube-any-compute
**Mission**: Help maintain and enhance a Terraform module that enables homelab enthusiasts and cloud engineers to deploy Kubernetes services on Raspberry Pi clusters, home servers, cloud environments, and mixed architectures.

## Value Proposition
- **🚀 Rapid Deployment**: Spin up complete Kubernetes clusters in minutes on any distribution (K3s, MicroK8s, EKS, GKE, AKS)
- **🔧 Hands-on Learning**: Production-grade services for practical Kubernetes experience
- **📈 Incremental Scaling**: Add services based on architecture and needs
- **🏗️ Expertise Building**: Master Infrastructure as Code, monitoring, service mesh, and security
- **🌍 Platform Agnostic**: Works on Raspberry Pi clusters, home servers, cloud environments, edge devices, and learning labs

## Target Users
- **Homelab Enthusiasts**: Building personal Kubernetes infrastructure
- **DevOps Learners**: Gaining hands-on Kubernetes experience
- **Tech Experimenters**: Testing cloud-native technologies
- **Small Teams**: Deploying lightweight production environments
- **IoT/Automation Users**: Running home automation and workflow platforms

## Key Features

### Core Infrastructure Services
- **Traefik**: Modern ingress controller with automatic SSL via Let's Encrypt
- **MetalLB**: Load balancer for bare metal clusters
- **Storage Drivers**: NFS CSI + HostPath for flexible persistent storage
- **Node Feature Discovery**: Hardware detection and labeling with enhanced storage detection (NVMe, SATA, USB, high-capacity drives)

### Platform Services
- **Monitoring Stack**: Prometheus + Grafana + Kube-State-Metrics for complete observability
- **Metrics Server**: Kubernetes metrics API for `kubectl top` and HPA functionality
- **Secrets Management**: Vault + Consul for service discovery and secrets
- **Container Management**: Portainer web UI
- **Policy Engine**: Gatekeeper (optional)
- **Authentication**: Centralized Traefik middleware (Basic Auth + LDAP) with rate limiting

### Automation & Workflow Services
- **Home Assistant**: Open-source home automation (1000+ integrations)
- **openHAB**: Vendor-neutral enterprise-grade home automation
- **Homebridge**: Apple HomeKit bridge (3000+ plugins)
- **Node-RED**: Visual programming for IoT workflows
- **n8n**: Self-hosted workflow automation (Zapier/IFTTT alternative)

### Advanced Capabilities
- **Multi-Architecture Support**: ARM64/AMD64 with intelligent service placement
- **Mixed Cluster Management**: Automatic configuration for heterogeneous clusters
- **DNS Provider Integration**: 11+ DNS providers for SSL certificate automation
- **Authentication Methods**: Basic Auth, LDAP (JumpCloud, Active Directory, OpenLDAP)
- **Storage Flexibility**: NFS, HostPath, cloud storage with auto-detection
- **Resource Management**: MicroK8s mode for resource-constrained environments

## Use Cases

### Learning & Development
- Kubernetes fundamentals training
- Cloud-native architecture experimentation
- CI/CD pipeline development
- Service mesh exploration

### Home Automation
- Smart home device integration
- IoT workflow automation
- Apple HomeKit bridging
- Visual programming with Node-RED

### Homelab Infrastructure
- Personal cloud services
- Media server hosting
- Development environments
- Network monitoring

### Small Production Deployments
- Lightweight microservices
- Internal tools hosting
- Edge computing applications
- Development/staging environments

## Deployment Models

### Raspberry Pi / ARM64
- MicroK8s optimized configuration
- Resource-constrained mode
- HostPath storage
- ARM64-specific service placement

### K3s Clusters
- NFS storage integration
- MetalLB load balancing
- Full monitoring stack
- Mixed architecture support

### Cloud Providers (EKS/GKE/AKS)
- Cloud storage integration
- Native load balancers
- Scalable monitoring
- Enterprise features

### Edge Devices
- Lightweight footprint
- Local storage
- Minimal resource usage
- Device discovery support

## Technical Highlights
- **Infrastructure as Code**: 100% Terraform-based deployment
- **Helm Integration**: Kubernetes package management
- **Auto-Detection**: CPU architecture, storage classes, cluster topology
- **Two-Step Authentication**: CRD-safe deployment process
- **Comprehensive Testing**: Unit, integration, security, and performance tests
- **Extensive Documentation**: Guides, references, examples, and troubleshooting

## Service Categories

### Infrastructure (Required)
1. **Traefik** - Ingress controller with SSL/TLS
2. **MetalLB** - Bare metal load balancer
3. **Storage** - NFS CSI + HostPath drivers
4. **Node Feature Discovery** - Hardware detection

### Monitoring & Observability
1. **Prometheus** - Metrics collection and alerting
2. **Grafana** - Visualization dashboards
3. **Kube-State-Metrics** - Kubernetes object metrics
4. **Metrics Server** - HPA support

### Optional Services
- **Consul** - Service mesh and discovery
- **Vault** - Secrets management
- **Gatekeeper** - Policy enforcement
- **Loki/Promtail** - Log aggregation
- **Portainer** - Container management UI

### Automation Platforms
- **Home Assistant** - Home automation (Python)
- **openHAB** - Enterprise home automation (Java/OSGi)
- **Homebridge** - HomeKit bridge (Node.js)
- **Node-RED** - Visual workflow programming
- **n8n** - Workflow automation (Node.js)

## Key Differentiators

### 1. Architecture Awareness
- Automatic CPU architecture detection (ARM64/AMD64)
- Mixed cluster support with intelligent scheduling
- Architecture-specific resource optimization

### 2. Storage Flexibility
- Multiple storage backends (NFS, HostPath, cloud)
- Dynamic provisioning with auto-detection
- Performance-optimized storage classes

### 3. Developer Experience
- Comprehensive pre-commit hooks (~2-5 min vs ~50 min)
- Fast development cycle with smart TFLint
- Extensive examples and documentation

### 4. Production Ready
- Security best practices (RBAC, TLS, secrets management)
- Monitoring and observability out-of-the-box
- Comprehensive testing framework

### 5. Learning Oriented
- Progressive complexity (start simple, add gradually)
- Production patterns in homelab environment
- Hands-on Kubernetes experience

## Configuration Philosophy

### Default First
- Sensible defaults for common use cases
- Progressive disclosure of advanced options
- Zero-configuration for basic deployments

### Override Hierarchy
1. System defaults (hardcoded)
2. Service defaults (computed)
3. User variables (terraform.tfvars)
4. Service overrides (fine-grained control)
5. Auto-detection (runtime analysis)

### Two-Step Deployment
1. **Initial**: Core services without authentication (CRD-safe)
2. **Enable**: Authentication after CRDs installed

## Supported Platforms

### Kubernetes Distributions
- K3s (default, lightweight)
- MicroK8s (ARM64 optimized)
- EKS (AWS)
- GKE (Google Cloud)
- AKS (Azure)
- Standard Kubernetes

### Hardware Platforms
- Raspberry Pi (ARM64)
- Intel/AMD servers (AMD64)
- Mixed architecture clusters
- Edge devices
- Virtual machines

### Storage Backends
- NFS server (dynamic provisioning)
- HostPath (local storage)
- Cloud storage (EBS, GPD, Azure Disk)
- Custom storage classes

## Security Features

### Authentication
- Basic Auth (htpasswd format)
- LDAP integration (JumpCloud, AD, OpenLDAP)
- Rate limiting (brute force protection)
- IP whitelisting

### Network Security
- Automatic SSL/TLS (Let's Encrypt)
- DNS-01 challenge support
- 11+ DNS providers
- Certificate auto-renewal

### Access Control
- RBAC for all services
- Service accounts and roles
- Secret management with Vault
- Policy enforcement with Gatekeeper

## Testing Strategy

### Test Types
1. **Unit Tests** - Configuration logic validation
2. **Scenario Tests** - Real-world deployment scenarios
3. **Integration Tests** - Service health and connectivity
4. **Performance Tests** - Load testing with k6
5. **Security Tests** - Vulnerability scanning

### Test Coverage
- Architecture detection (ARM64/AMD64)
- Storage configuration (NFS, HostPath)
- Service enablement logic
- Resource limit application
- Mixed cluster scenarios
- Security policies

## Performance Optimization

### Resource Limits
- MicroK8s mode for constrained environments
- Architecture-specific defaults
- Configurable resource limits
- Priority and QoS classes

### Helm Timeouts
- Service-specific timeouts
- Configurable wait behavior
- Job completion tracking
- Cleanup on failure

### Storage Optimization
- Storage class templates (performance, reliable, low_latency)
- Mount options for NFS
- Reclaim policies
- Capacity planning

## Documentation Structure

### User Documentation
- README.md (project overview)
- docs/guides/ (detailed guides)
- docs/reference/ (technical references)
- examples/ (configuration examples)

### Developer Documentation
- CONTRIBUTING.md (contribution guidelines)
- docs/development/ (dev setup, testing)
- .amazonq/rules/ (AI assistant rules)
- .cline/rules/ (Cline AI rules)

### Module Documentation
- Each module has comprehensive README
- Auto-generated terraform-docs
- Usage examples
- Troubleshooting sections

## Version Management

### Semantic Versioning
- Major.Minor.Patch format
- Breaking changes documented
- Migration guides provided

### Version Synchronization
- Central version registry (.github/versions.yml)
- Automated sync scripts
- Provider version constraints

### Release Process
- Comprehensive testing
- CHANGELOG updates
- Release notes
- Git tagging

## Community & Support

### Contribution Areas
1. New service modules
2. Documentation improvements
3. Bug fixes and enhancements
4. Testing on different platforms
5. Community support

### Support Channels
- GitHub Issues (bug reports, feature requests)
- GitHub Discussions (questions, community)
- Wiki (community guides)
- Issues for troubleshooting

## Success Metrics

### User Success
- Successful deployments on first attempt
- Learning Kubernetes concepts
- Building homelab infrastructure
- Contributing to the project

### Technical Success
- Multi-architecture support
- Production-grade reliability
- Comprehensive test coverage
- Extensive documentation

## Future Roadmap

### Planned Features
- GitOps integration (ArgoCD)
- Backup automation (Velero)
- Advanced monitoring dashboards
- Service mesh (Consul Connect)
- Multi-cluster support
- Edge computing patterns
- Terraform Registry publication

### Enhancement Areas
- Performance optimization
- Security enhancements
- Monitoring improvements
- CI/CD integration
- More service modules
