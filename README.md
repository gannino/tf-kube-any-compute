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
- **📊 Prometheus + Grafana** - Complete monitoring and visualization stack
- **🔐 Vault + Consul** - Secrets management and service discovery with service mesh
- **🐳 Portainer** - Container management web UI
- **🛡️ Gatekeeper** - Policy engine (optional)

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

### 2. Deploy Infrastructure

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

### 3. Access Your Services

After deployment, access services at:

- **Traefik Dashboard**: `https://traefik.homelab.k3s.example.com`
- **Grafana**: `https://grafana.homelab.k3s.example.com`
- **Portainer**: `https://portainer.homelab.k3s.example.com`
- **Consul**: `https://consul.homelab.k3s.example.com`
- **Vault**: `https://vault.homelab.k3s.example.com`

## ⚙️ Configuration

For comprehensive configuration options, see [VARIABLES.md](VARIABLES.md) which covers:

- **Service Overrides**: Fine-tune every aspect of your deployment
- **Mixed Architecture Management**: ARM64/AMD64 cluster strategies
- **Storage Configuration**: NFS, HostPath, and storage class options
- **Password Management**: Auto-generation and custom overrides
- **DNS & SSL**: Hurricane Electric and Let's Encrypt setup
- **Architecture Detection**: Intelligent service placement

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
3. **Storage Deep Dive**: Configure NFS + HostPath
4. **Architecture Optimization**: Mixed ARM64/AMD64 clusters

### Advanced
1. **Policy Enforcement**: Enable Gatekeeper
2. **Custom Dashboards**: Create Grafana dashboards
3. **Service Mesh**: Consul Connect with Traefik integration
4. **DNS Management**: Hurricane Electric dynamic DNS setup
5. **GitOps**: Integrate with ArgoCD

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on:

- Development setup and pre-commit hooks
- Code standards and testing
- Pull request process
- Architecture guidelines

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
- **[Discussions](https://github.com/gannino/tf-kube-any-compute/discussions)**: Share your homelab setups and ask questions
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

