# NFS CSI Helm Module

This Terraform module deploys the NFS Subdir External Provisioner for dynamic provisioning of Kubernetes persistent volumes using NFS storage.

## Features

- **📁 Dynamic Volume Provisioning**: Automatically create PVs from NFS exports
- **🔄 Multiple Storage Classes**: Standard, fast, and safe performance tiers
- **🏗️ Architecture Support**: ARM64 and AMD64 compatibility
- **⚙️ Flexible Configuration**: Customizable mount options and parameters
- **📊 Volume Management**: Automatic cleanup and archiving options
- **🔒 Security**: Configurable access modes and permissions
- **⚡ Performance Tuning**: Optimized mount options for different use cases
- **🎯 Kubernetes Native**: Full integration with Kubernetes storage APIs

## Features by Storage Class

### Standard (`nfs-csi`)
- **Balanced Performance**: Good balance of speed and reliability
- **NFS v4**: Modern NFS protocol with better security
- **Conservative Timeouts**: Stable for network variations
- **Retain Policy**: Volumes preserved when PVC deleted

### Fast (`nfs-csi-fast`)
- **High Performance**: Optimized for speed over safety
- **Large Block Sizes**: 1MB read/write for throughput
- **Async Writes**: Better performance, less data safety
- **Auto-Cleanup**: Volumes deleted with PVC

### Safe (`nfs-csi-safe`)
- **Data Safety**: Optimized for reliability over speed
- **Sync Writes**: Guaranteed data consistency
- **Extended Timeouts**: Better handling of network issues
- **Retain Policy**: Maximum data protection

## Usage

### Basic Usage

```hcl
module "nfs_csi" {
  source = "./helm-nfs-csi"
  
  nfs_server = "192.168.1.100"
  nfs_path   = "/exports/k8s"
  
  set_as_default_storage_class = true
}
```

### Advanced Configuration

```hcl
module "nfs_csi" {
  source = "./helm-nfs-csi"
  
  namespace     = "nfs-storage"
  chart_version = "4.0.17"
  
  # NFS Configuration
  nfs_server = "192.168.1.100"
  nfs_path   = "/exports/kubernetes"
  
  # Storage Classes
  set_as_default_storage_class = true
  create_fast_storage_class    = true
  create_safe_storage_class    = true
  
  # Architecture
  cpu_arch                = "amd64"
  disable_arch_scheduling = false
  
  # Resource Limits
  cpu_limit      = "200m"
  memory_limit   = "128Mi"
  cpu_request    = "50m"
  memory_request = "64Mi"
  
  # Helm Configuration
  helm_timeout = 600
  helm_wait    = true
}
```

### Production HA Setup

```hcl
module "nfs_csi" {
  source = "./helm-nfs-csi"
  
  # High Availability NFS Setup
  nfs_server = "nfs-cluster.example.com"
  nfs_path   = "/exports/prod-k8s"
  
  # Enable all storage classes for flexibility
  create_fast_storage_class = true
  create_safe_storage_class = true
  
  # Production resource limits
  cpu_limit      = "500m"
  memory_limit   = "256Mi"
  cpu_request    = "100m"
  memory_request = "128Mi"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14 |
| helm | >= 3.0 |
| kubernetes | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| helm | >= 3.0 |
| kubernetes | >= 2.0 |

## Resources

| Name | Type |
|------|------|
| kubernetes_namespace.this | resource |
| kubernetes_storage_class.this | resource |
| kubernetes_storage_class.nfs_fast | resource |
| kubernetes_storage_class.nfs_safe | resource |
| helm_release.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Namespace for NFS CSI | `string` | `"nfs-csi-stack"` | no |
| name | Helm release name | `string` | `"nfs-csi"` | no |
| chart_name | Helm chart name | `string` | `"nfs-subdir-external-provisioner"` | no |
| chart_repo | Helm repository | `string` | `"https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"` | no |
| chart_version | Helm chart version | `string` | `"4.0.17"` | no |
| nfs_server | NFS server IP or hostname | `string` | n/a | yes |
| nfs_path | NFS export path | `string` | n/a | yes |
| set_as_default_storage_class | Set as default storage class | `bool` | `true` | no |
| create_fast_storage_class | Create fast performance storage class | `bool` | `false` | no |
| create_safe_storage_class | Create safe performance storage class | `bool` | `true` | no |
| let_helm_create_storage_class | Let Helm create storage class | `bool` | `false` | no |
| cpu_arch | CPU architecture constraint | `string` | `"arm64"` | no |
| disable_arch_scheduling | Disable architecture scheduling | `bool` | `true` | no |
| cpu_limit | CPU limit for provisioner | `string` | `"100m"` | no |
| memory_limit | Memory limit for provisioner | `string` | `"64Mi"` | no |
| cpu_request | CPU request for provisioner | `string` | `"25m"` | no |
| memory_request | Memory request for provisioner | `string` | `"32Mi"` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | NFS CSI namespace |
| storage_classes | Available storage classes |

## Storage Classes Created

### Default Storage Class (`nfs-csi`)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: cluster.local/nfs-subdir-external-provisioner
parameters:
  server: <NFS_SERVER>
  share: <NFS_PATH>
  archiveOnDelete: "true"
mountOptions:
  - vers=4
  - rsize=131072
  - wsize=131072
  - hard
  - noatime
  - nodiratime
  - timeo=600
  - retrans=2
volumeBindingMode: Immediate
reclaimPolicy: Retain
allowVolumeExpansion: true
```

### Fast Storage Class (`nfs-csi-fast`)

Optimized for performance:

```yaml
mountOptions:
  - vers=4.1
  - rsize=1048576    # 1MB for maximum throughput
  - wsize=1048576
  - hard
  - noatime
  - nodiratime
  - async            # Async writes for speed
  - timeo=150        # Shorter timeout
  - retrans=3
reclaimPolicy: Delete  # Auto-cleanup
```

### Safe Storage Class (`nfs-csi-safe`)

Optimized for data safety:

```yaml
mountOptions:
  - vers=4.1
  - rsize=65536      # Smaller chunks for stability
  - wsize=65536
  - hard
  - sync             # Synchronous writes
  - timeo=900        # Longer timeout
  - retrans=5        # More retries
reclaimPolicy: Retain  # Maximum data protection
```

## NFS Server Setup

### Prerequisites

Your NFS server must be properly configured:

```bash
# Install NFS server (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y nfs-kernel-server

# Install NFS server (RHEL/CentOS)
sudo yum install -y nfs-utils
sudo systemctl enable --now nfs-server
```

### Configure NFS Exports

```bash
# Edit /etc/exports
sudo nano /etc/exports

# Add export (replace with your network)
/exports/k8s 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)

# Apply changes
sudo exportfs -ra
sudo systemctl restart nfs-server
```

### Firewall Configuration

```bash
# UFW (Ubuntu)
sudo ufw allow from 192.168.1.0/24 to any port 111
sudo ufw allow from 192.168.1.0/24 to any port 2049

# Firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --permanent --add-service=rpc-bind
sudo firewall-cmd --reload

# iptables
sudo iptables -A INPUT -p tcp --dport 111 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2049 -j ACCEPT
```

## Usage Examples

### Basic Persistent Volume Claim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nfs-csi
  resources:
    requests:
      storage: 10Gi
```

### High-Performance Storage

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nfs-csi-fast  # Use fast storage class
  resources:
    requests:
      storage: 50Gi
```

### Shared Storage (ReadWriteMany)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-storage
spec:
  accessModes:
    - ReadWriteMany  # Multiple pods can mount
  storageClassName: nfs-csi-safe
  resources:
    requests:
      storage: 100Gi
```

### Pod Using NFS Storage

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-nfs
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: my-app-storage
```

## Architecture Support

### ARM64 (Raspberry Pi)

```hcl
module "nfs_csi" {
  source = "./helm-nfs-csi"
  
  cpu_arch = "arm64"
  
  # ARM64 optimized resources
  cpu_limit      = "100m"
  memory_limit   = "64Mi"
  cpu_request    = "25m"
  memory_request = "32Mi"
  
  nfs_server = "192.168.1.100"
  nfs_path   = "/exports/pi-cluster"
}
```

### AMD64 (x86_64)

```hcl
module "nfs_csi" {
  source = "./helm-nfs-csi"
  
  cpu_arch = "amd64"
  
  # Higher performance resources
  cpu_limit      = "200m"
  memory_limit   = "128Mi"
  cpu_request    = "50m"
  memory_request = "64Mi"
  
  nfs_server = "nfs.datacenter.local"
  nfs_path   = "/exports/production"
}
```

## Troubleshooting

### Common Issues

1. **Connection Timeouts**: Check network connectivity and firewall
2. **Permission Denied**: Verify NFS export permissions and no_root_squash
3. **Mount Failures**: Check NFS server status and export configuration
4. **Performance Issues**: Try different storage classes or mount options

### Diagnostic Commands

```bash
# Check NFS CSI pods
kubectl get pods -n nfs-csi-stack

# View provisioner logs
kubectl logs -n nfs-csi-stack -l app=nfs-subdir-external-provisioner

# Check storage classes
kubectl get storageclass

# Test NFS connectivity
showmount -e <NFS_SERVER>
```

### Debug Script

Run the provided diagnostic script:

```bash
./scripts/diagnose-nfs.sh
```

### Manual NFS Test

```bash
# Test manual mount on cluster node
sudo mkdir -p /tmp/nfs-test
sudo mount -t nfs -o vers=4 <NFS_SERVER>:<NFS_PATH> /tmp/nfs-test
ls -la /tmp/nfs-test
sudo umount /tmp/nfs-test
```

## Performance Tuning

### Network Optimization

```hcl
# For high-bandwidth networks
mount_options = [
  "vers=4.1",
  "rsize=1048576",   # 1MB read size
  "wsize=1048576",   # 1MB write size
  "hard",
  "timeo=600"
]

# For unstable networks
mount_options = [
  "vers=4",
  "rsize=32768",     # Smaller chunks
  "wsize=32768",
  "hard",
  "timeo=900",       # Longer timeout
  "retrans=5"        # More retries
]
```

### Resource Scaling

```hcl
# High-volume environments
cpu_limit      = "500m"
memory_limit   = "256Mi"

# Resource-constrained environments
cpu_limit      = "50m"
memory_limit   = "32Mi"
```

## Security Considerations

- **Network Security**: Use firewalls to restrict NFS access
- **Export Security**: Use `no_root_squash` carefully
- **Authentication**: Consider NFSv4 with Kerberos for production
- **Encryption**: Use `sec=krb5p` for encrypted NFS traffic
- **Network Policies**: Restrict pod-to-NFS traffic

## Migration and Backup

### Data Migration

```bash
# Migrate from hostpath to NFS
kubectl get pv -o yaml > hostpath-volumes.yaml
# Edit storage class in YAML
kubectl apply -f hostpath-volumes.yaml
```

### Backup Strategy

```bash
# Backup NFS data
rsync -av /exports/k8s/ /backup/nfs-k8s-$(date +%Y%m%d)/

# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
rsync -av --delete /exports/k8s/ /backup/k8s-$DATE/
find /backup -name "k8s-*" -mtime +7 -exec rm -rf {} \;
```

## Best Practices

### Production Deployment

1. **Use dedicated NFS server** with high availability
2. **Configure multiple storage classes** for different workloads
3. **Monitor NFS performance** and tune mount options
4. **Implement backup strategy** for critical data
5. **Use network policies** to secure NFS traffic

### Development Environment

1. **Single storage class** may be sufficient
2. **Use local NFS server** for simplicity
3. **Faster timeout settings** for development speed
4. **Regular cleanup** of test volumes

### Resource Management

1. **Set appropriate resource limits** based on cluster size
2. **Monitor provisioner performance** under load
3. **Scale resources** based on volume creation frequency
4. **Use node affinity** for provisioner placement

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT
