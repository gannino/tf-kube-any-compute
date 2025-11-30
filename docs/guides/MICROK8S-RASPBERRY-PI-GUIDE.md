# MicroK8s on Raspberry Pi - Complete Setup Guide

## Overview

This guide provides step-by-step instructions for setting up MicroK8s on Raspberry Pi devices for use with **tf-kube-any-compute**. It covers everything from initial OS setup to cluster configuration and NFS client installation.

## Prerequisites

### Hardware Requirements
- **Raspberry Pi 4** (8GB RAM recommended, 4GB minimum)
- **MicroSD Card** - Class 10, 32GB minimum (64GB+ recommended)
- **Network Connection** - Ethernet preferred for stability
- **Power Supply** - Official Raspberry Pi 4 power supply (5.1V/3A)

### Software Requirements
- **Raspberry Pi OS** (64-bit, Lite or Desktop)
- **SSH Access** enabled
- **Internet Connection** for package downloads

## Step 1: Raspberry Pi OS Setup

### 1.1 Flash Raspberry Pi OS

```bash
# Download Raspberry Pi Imager
# https://www.raspberrypi.org/software/

# Flash 64-bit Raspberry Pi OS to SD card
# Enable SSH and configure WiFi/Ethernet during imaging
```

### 1.2 Initial System Configuration

```bash
# SSH into your Raspberry Pi
ssh pi@<raspberry-pi-ip>

# Update system packages
sudo apt update && sudo apt upgrade -y

# Configure system settings
sudo raspi-config
# - Enable SSH (if not already enabled)
# - Expand filesystem
# - Set timezone
# - Configure memory split (GPU: 16MB minimum)
# - Enable container features in Advanced Options

# Reboot to apply changes
sudo reboot
```

### 1.3 System Optimization for Kubernetes

```bash
# Enable cgroup memory and cpu
sudo nano /boot/firmware/cmdline.txt
# Add to the end of the line (single line):
# cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory

# Alternative location for older Pi OS versions:
sudo nano /boot/cmdline.txt

# Configure memory settings
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

# Disable swap (required for Kubernetes)
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo update-rc.d dphys-swapfile remove
sudo systemctl disable dphys-swapfile

# Reboot to apply cgroup changes
sudo reboot
```

## Step 2: Install Required Packages

### 2.1 Install NFS Client (Critical for tf-kube-any-compute)

```bash
# Install NFS client packages
sudo apt update
sudo apt install -y nfs-common

# Verify NFS client installation
showmount --version
mount.nfs --version

# Test NFS connectivity (replace with your NFS server)
showmount -e <your-nfs-server-ip>
# Example: showmount -e 192.168.1.100
```

### 2.2 Install Container Runtime Dependencies

```bash
# Install essential packages
sudo apt install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# Install iptables and configure for legacy mode
sudo apt install -y iptables
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```

## Step 3: Install MicroK8s

### 3.1 Install MicroK8s via Snap

```bash
# Install snapd if not present
sudo apt install -y snapd

# Install MicroK8s (stable channel)
sudo snap install microk8s --classic

# Add user to microk8s group
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube

# Apply group changes
newgrp microk8s

# Verify installation
microk8s status --wait-ready
```

### 3.2 Configure MicroK8s

```bash
# Enable essential addons
microk8s enable dns

# Optional: Enable additional addons
microk8s enable storage # if using tf-kube-anycompute this is not required
microk8s enable ingress # if using tf-kube-anycompute this is not required
microk8s enable metrics-server # if using tf-kube-anycompute this is not required

# Check status
microk8s status

# Configure kubectl alias
echo 'alias kubectl="microk8s kubectl"' >> ~/.bashrc
source ~/.bashrc

# Or install standalone kubectl
sudo snap install kubectl --classic
microk8s config > ~/.kube/config
```

## Step 4: Multi-Node Cluster Setup (Optional, but suggested to deploy all the services in tf-kube-anycompute)

### 4.1 Create Cluster on Primary Node

```bash
# On the primary Raspberry Pi
microk8s add-node
# This will output a join command like:
# microk8s join 192.168.1.100:25000/92b2db237428470dc4fcfc4eb9b90055/2c0cb3284b05
```

### 4.2 Join Additional Nodes

```bash
# On each additional Raspberry Pi
# Run the join command from the primary node
microk8s join <primary-node-ip>:25000/<token>

# Verify cluster status from primary node
microk8s kubectl get nodes
```

## Step 5: Configure for tf-kube-any-compute

### 5.1 Create Kubeconfig for External Access

```bash
# Generate kubeconfig for external tools
microk8s config > ~/.kube/config

# Make it accessible for terraform/kubectl
chmod 600 ~/.kube/config

# Test external kubectl access
kubectl cluster-info
kubectl get nodes
```

### 5.2 Configure NFS Storage (if using NFS)

```bash
# Test NFS mount capability
sudo mkdir -p /mnt/nfs-test
sudo mount -t nfs <nfs-server-ip>:<nfs-path> /mnt/nfs-test
# Example: sudo mount -t nfs 192.168.169.101:/DockerVols/k8s /mnt/nfs-test

# If successful, unmount
sudo umount /mnt/nfs-test
sudo rmdir /mnt/nfs-test

# If mount fails, check NFS server configuration
```

### 5.3 Verify Architecture Detection

```bash
# Check node architecture labels
kubectl get nodes -o wide
kubectl get nodes --show-labels | grep kubernetes.io/arch

# Should show: kubernetes.io/arch=arm64
```

## Step 6: Deploy tf-kube-any-compute

### 6.1 Optimal Configuration for Raspberry Pi

Create `terraform.tfvars` with Raspberry Pi optimizations:

```hcl
# MicroK8s Raspberry Pi Configuration
enable_microk8s_mode = true
cpu_arch = "arm64"

# Resource optimization for Pi
enable_resource_limits = true
default_cpu_limit = "500m"
default_memory_limit = "512Mi"

# Storage configuration
use_hostpath_storage = true
use_nfs_storage = true  # Only if NFS server is properly configured

# NFS configuration (if using NFS)
nfs_server_address = "192.168.1.100"  # Your NFS server IP
nfs_server_path = "/path/to/nfs/share"

# Service selection for Pi
services = {
  traefik                = true
  metallb                = true
  host_path              = true
  nfs_csi                = true   # Only if NFS is working
  prometheus             = true
  prometheus_crds        = true
  grafana                = true
  kube_state_metrics     = true
  portainer              = true
  node_feature_discovery = true

  # Optional services (resource intensive)
  consul     = false  # Enable if you have 8GB+ RAM
  vault      = false  # Enable if you have 8GB+ RAM
  loki       = false  # Enable if you have 8GB+ RAM
  promtail   = false  # Enable if you have 8GB+ RAM
}

# Service overrides for Pi optimization
service_overrides = {
  traefik = {
    cpu_limit = "200m"
    memory_limit = "128Mi"
    storage_class = "hostpath"
  }

  prometheus = {
    cpu_limit = "300m"
    memory_limit = "512Mi"
    storage_class = "hostpath"
  }

  grafana = {
    cpu_limit = "200m"
    memory_limit = "256Mi"
    storage_class = "hostpath"
  }
}
```

### 6.2 Deploy Infrastructure

```bash
# Clone tf-kube-any-compute
git clone https://github.com/gannino/tf-kube-any-compute.git
cd tf-kube-any-compute

# Initialize Terraform
make init

# Create workspace
terraform workspace new raspberry-pi

# Deploy (two-step process)
make plan
make apply

# After first deployment, enable authentication
# Edit terraform.tfvars: middleware_overrides.enabled = true
make apply
```

## Step 7: Troubleshooting

### 7.1 Common Issues

**MicroK8s not starting:**
```bash
# Check status
microk8s status

# Reset if needed
microk8s reset
sudo snap remove microk8s
sudo snap install microk8s --classic
```

**NFS mount failures:**
```bash
# Check NFS client
sudo systemctl status rpc-statd
sudo systemctl start rpc-statd

# Test NFS connectivity
showmount -e <nfs-server-ip>
sudo mount -t nfs -v <nfs-server>:<path> /mnt/test
```

**Memory issues:**
```bash
# Check memory usage
free -h
kubectl top nodes
kubectl top pods --all-namespaces

# Reduce resource limits in terraform.tfvars
```

### 7.2 Performance Optimization

```bash
# Monitor resource usage
watch kubectl top nodes
watch kubectl top pods --all-namespaces

# Check for resource constraints
kubectl describe nodes
kubectl get events --sort-by='.lastTimestamp'

# Optimize swap (if re-enabled)
echo 'vm.swappiness=1' | sudo tee -a /etc/sysctl.conf
```

### 7.3 Network Troubleshooting

```bash
# Check MicroK8s networking
microk8s kubectl get pods -n kube-system

# Test DNS resolution
microk8s kubectl run test-pod --image=busybox --rm -it -- nslookup kubernetes.default

# Check ingress
microk8s kubectl get ingress --all-namespaces
```

## Step 8: Monitoring and Maintenance

### 8.1 Health Checks

```bash
# Regular health check script
#!/bin/bash
echo "=== MicroK8s Status ==="
microk8s status

echo "=== Node Status ==="
kubectl get nodes -o wide

echo "=== Pod Status ==="
kubectl get pods --all-namespaces | grep -v Running

echo "=== Resource Usage ==="
kubectl top nodes
```

### 8.2 Updates and Maintenance

```bash
# Update MicroK8s
sudo snap refresh microk8s

# Update system packages
sudo apt update && sudo apt upgrade -y

# Clean up unused resources
microk8s kubectl delete pods --field-selector=status.phase=Succeeded --all-namespaces
docker system prune -f
```

## Step 9: Advanced Configuration

### 9.1 GPU Support (if available)

```bash
# Enable GPU addon (for Pi with GPU)
microk8s enable gpu

# Verify GPU detection
kubectl describe nodes | grep -i gpu
```

### 9.2 Custom Storage Classes

```bash
# Create custom storage class for Pi
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: pi-fast-storage
provisioner: microk8s.io/hostpath
parameters:
  pvDir: /var/snap/microk8s/common/default-storage
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF
```

### 9.3 Resource Quotas

```bash
# Create resource quota for namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: pi-quota
  namespace: default
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
EOF
```

## Best Practices for Raspberry Pi Kubernetes

### Resource Management
- **Start Small**: Begin with core services only
- **Monitor Resources**: Use `kubectl top` regularly
- **Set Limits**: Always configure resource limits
- **Use HostPath**: For single-node setups, HostPath is more efficient than NFS

### Storage Strategy
- **HostPath First**: Use HostPath for local storage needs
- **NFS for Shared**: Only use NFS when you need shared storage across nodes
- **SSD Recommended**: Use USB 3.0 SSD for better I/O performance

### Network Optimization
- **Ethernet Preferred**: Use wired connection for stability
- **Local Registry**: Consider local container registry for faster pulls
- **Resource Limits**: Prevent network-intensive pods from overwhelming Pi

### Security Considerations
- **Regular Updates**: Keep Pi OS and MicroK8s updated
- **Firewall Rules**: Configure iptables for cluster security
- **SSH Keys**: Use SSH keys instead of passwords
- **Resource Isolation**: Use namespaces and resource quotas

## Conclusion

This guide provides a complete setup for running MicroK8s on Raspberry Pi with tf-kube-any-compute. The key points are:

1. **NFS Client Installation** is critical for NFS storage functionality
2. **Resource Limits** are essential for stable operation on Pi hardware
3. **Two-Step Deployment** prevents CRD dependency issues
4. **Monitoring** helps identify resource constraints early

For additional help, refer to:
- [tf-kube-any-compute Documentation](../README.md)
- [MicroK8s Documentation](https://microk8s.io/docs)
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
