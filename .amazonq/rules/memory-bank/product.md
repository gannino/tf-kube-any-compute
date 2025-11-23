# Product Overview - tf-kube-any-compute

## Purpose
Universal Kubernetes infrastructure deployment system designed for tech enthusiasts and homelab builders. Provides production-grade, cloud-agnostic Kubernetes infrastructure that works across any compute platform - from Raspberry Pi clusters to enterprise cloud environments.

## Value Proposition
- **Rapid Deployment**: Spin up complete Kubernetes clusters in minutes with 20+ pre-configured services
- **Learn by Doing**: Hands-on experience with production-grade infrastructure, monitoring, service mesh, and security
- **Incremental Scaling**: Add services based on needs - start simple, grow complex
- **Multi-Architecture**: Native support for ARM64 (Raspberry Pi) and AMD64 with intelligent mixed-cluster management
- **Zero Lock-in**: Cloud-agnostic design works on K3s, MicroK8s, EKS, GKE, AKS

## Key Features

### Core Infrastructure
- **Traefik Ingress**: Modern reverse proxy with automatic SSL via Let's Encrypt (11 DNS providers)
- **MetalLB**: Load balancer for bare metal clusters
- **Storage Flexibility**: NFS CSI + HostPath drivers with static/dynamic provisioning
- **Node Feature Discovery**: Automatic hardware detection and labeling

### Platform Services
- **Monitoring Stack**: Prometheus + Grafana + kube-state-metrics with pre-configured dashboards
- **Metrics Server**: Kubernetes metrics API for HPA and `kubectl top`
- **Service Mesh**: Consul for service discovery and mesh capabilities
- **Secrets Management**: HashiCorp Vault with auto-unsealing
- **Container Management**: Portainer web UI
- **Policy Engine**: Gatekeeper for OPA-based policies
- **Authentication**: Centralized Traefik middleware (Basic Auth + LDAP)

### Automation & Workflow
- **Home Assistant**: 1000+ smart home integrations
- **openHAB**: Vendor-neutral home automation (Java-based)
- **Homebridge**: Apple HomeKit bridge (3000+ plugins)
- **Node-RED**: Visual IoT programming with palette auto-installation
- **n8n**: Self-hosted workflow automation (Zapier/IFTTT alternative)

### Advanced Capabilities
- **Mixed Architecture**: Automatic detection and intelligent service placement across ARM64/AMD64 nodes
- **Two-Step Deployment**: CRD-aware deployment prevents dependency issues
- **Resource Management**: MicroK8s mode with optimized resource limits
- **SSL Automation**: Multi-provider DNS challenge with Hurricane Electric default
- **Static PVs**: Predictable NFS folder names for easy backup/restore

## Target Users

### Beginners
- Homelab enthusiasts learning Kubernetes
- Developers wanting local K8s environments
- Students studying cloud-native technologies

### Intermediate
- DevOps engineers building home infrastructure
- System administrators exploring service mesh
- IoT enthusiasts integrating automation platforms

### Advanced
- Platform engineers testing multi-arch deployments
- Security professionals implementing policy engines
- Infrastructure architects designing hybrid clouds

## Use Cases

### Learning Lab
Deploy complete monitoring stack to understand Prometheus, Grafana, and Kubernetes metrics collection. Experiment with service mesh, secrets management, and policy enforcement.

### Home Automation Hub
Run Home Assistant, openHAB, Homebridge, and Node-RED on Kubernetes with persistent storage, automatic SSL, and centralized authentication.

### Development Environment
Local Kubernetes cluster with Traefik ingress, Portainer management, and Grafana monitoring for application development and testing.

### Edge Computing
Deploy on Raspberry Pi clusters with ARM64-optimized configurations, resource limits, and mixed-architecture support for hybrid deployments.

### Production Homelab
Full-featured infrastructure with Vault secrets, Consul service mesh, Gatekeeper policies, and comprehensive monitoring for serious homelab projects.

## Competitive Advantages
- **Architecture Intelligence**: Automatic detection and mixed-cluster support (unique in homelab space)
- **Comprehensive Testing**: 600+ unit tests, scenario tests, integration tests, security scanning
- **Production-Ready**: Pre-commit hooks, CI/CD pipelines, security scanning, documentation automation
- **Community-Friendly**: Extensive documentation, contribution guides, example configurations
- **AI-Enhanced**: Developed with GitHub Copilot, Amazon Q, Claude, GPT-4, and Gemini
