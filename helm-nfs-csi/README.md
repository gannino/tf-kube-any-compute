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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_storage_class.nfs_fast](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_storage_class.nfs_safe](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_storage_class.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_service.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm name. | `string` | `"nfs-subdir-external-provisioner"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository name. | `string` | `"https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm version. | `string` | `"4.0.17"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | n/a | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"25m"` | no |
| <a name="input_create_fast_storage_class"></a> [create\_fast\_storage\_class](#input\_create\_fast\_storage\_class) | Create an additional high-performance NFS storage class | `bool` | `false` | no |
| <a name="input_create_safe_storage_class"></a> [create\_safe\_storage\_class](#input\_create\_safe\_storage\_class) | Create an additional safety-focused NFS storage class | `bool` | `true` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `true` | no |
| <a name="input_enable_nfs_csi_ingress"></a> [enable\_nfs\_csi\_ingress](#input\_enable\_nfs\_csi\_ingress) | n/a | `bool` | `false` | no |
| <a name="input_enable_nfs_csi_ingress_route"></a> [enable\_nfs\_csi\_ingress\_route](#input\_enable\_nfs\_csi\_ingress\_route) | n/a | `bool` | `false` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_let_helm_create_storage_class"></a> [let\_helm\_create\_storage\_class](#input\_let\_helm\_create\_storage\_class) | Create a storage class using helm | `bool` | `false` | no |
| <a name="input_limit_range_container_max_cpu"></a> [limit\_range\_container\_max\_cpu](#input\_limit\_range\_container\_max\_cpu) | Maximum CPU limit for containers (default: same as cpu\_limit) | `string` | `null` | no |
| <a name="input_limit_range_container_max_memory"></a> [limit\_range\_container\_max\_memory](#input\_limit\_range\_container\_max\_memory) | Maximum memory limit for containers (default: same as memory\_limit) | `string` | `null` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_limit_range_pvc_max_storage"></a> [limit\_range\_pvc\_max\_storage](#input\_limit\_range\_pvc\_max\_storage) | Maximum storage size for PVCs | `string` | `"10Gi"` | no |
| <a name="input_limit_range_pvc_min_storage"></a> [limit\_range\_pvc\_min\_storage](#input\_limit\_range\_pvc\_min\_storage) | Minimum storage size for PVCs | `string` | `"100Mi"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"64Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"32Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"nfs-csi"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"nfs-csi-stack"` | no |
| <a name="input_nfs_domain_name"></a> [nfs\_domain\_name](#input\_nfs\_domain\_name) | Domain name for NFS server. | `string` | `".local"` | no |
| <a name="input_nfs_path"></a> [nfs\_path](#input\_nfs\_path) | n/a | `string` | n/a | yes |
| <a name="input_nfs_retrans_default"></a> [nfs\_retrans\_default](#input\_nfs\_retrans\_default) | Default number of NFS retries | `number` | `2` | no |
| <a name="input_nfs_retrans_fast"></a> [nfs\_retrans\_fast](#input\_nfs\_retrans\_fast) | Number of NFS retries for fast storage class | `number` | `3` | no |
| <a name="input_nfs_retrans_safe"></a> [nfs\_retrans\_safe](#input\_nfs\_retrans\_safe) | Number of NFS retries for safe storage class | `number` | `5` | no |
| <a name="input_nfs_server"></a> [nfs\_server](#input\_nfs\_server) | n/a | `string` | n/a | yes |
| <a name="input_nfs_timeout_default"></a> [nfs\_timeout\_default](#input\_nfs\_timeout\_default) | Default NFS timeout in deciseconds (600 = 60 seconds) | `number` | `600` | no |
| <a name="input_nfs_timeout_fast"></a> [nfs\_timeout\_fast](#input\_nfs\_timeout\_fast) | Fast NFS timeout in deciseconds for quick failover (150 = 15 seconds) | `number` | `150` | no |
| <a name="input_nfs_timeout_safe"></a> [nfs\_timeout\_safe](#input\_nfs\_timeout\_safe) | Safe NFS timeout in deciseconds for stability (900 = 90 seconds) | `number` | `900` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override default service configuration for backward compatibility | <pre>object({<br/>    helm_config = optional(object({<br/>      name      = optional(string)<br/>      namespace = optional(string)<br/>      resource_limits = optional(object({<br/>        requests = optional(object({<br/>          cpu    = optional(string)<br/>          memory = optional(string)<br/>        }))<br/>        limits = optional(object({<br/>          cpu    = optional(string)<br/>          memory = optional(string)<br/>        }))<br/>      }))<br/>    }))<br/>    labels          = optional(map(string))<br/>    template_values = optional(map(any))<br/>  })</pre> | `{}` | no |
| <a name="input_set_as_default_storage_class"></a> [set\_as\_default\_storage\_class](#input\_set\_as\_default\_storage\_class) | Set the NFS storage class as the default storage class | `bool` | `true` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class name for NFS CSI | `string` | `"nfs-csi"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | Status of the Helm release |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where NFS CSI is deployed |
| <a name="output_nfs_path"></a> [nfs\_path](#output\_nfs\_path) | NFS path used by the CSI driver |
| <a name="output_nfs_server"></a> [nfs\_server](#output\_nfs\_server) | NFS server used by the CSI driver |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the NFS CSI frontend service |
| <a name="output_storage_classes"></a> [storage\_classes](#output\_storage\_classes) | Created storage classes |
<!-- END_TF_DOCS -->
