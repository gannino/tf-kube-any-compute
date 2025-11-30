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
- **Node Feature Discovery**: Hardware detection and labeling with enhanced storage detection

### Platform Services
- **Monitoring Stack**: Prometheus + Grafana + Kube-State-Metrics for complete observability
- **Metrics Server**: Kubernetes metrics API for `kubectl top` and HPA
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
