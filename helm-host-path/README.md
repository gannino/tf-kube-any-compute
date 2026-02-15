# HostPath Storage Helm Module

This Terraform module deploys the Local Path Provisioner for dynamic provisioning of Kubernetes persistent volumes using local node storage (hostpath).

## Features

- **💾 Local Storage**: Uses node filesystem for persistent volumes
- **🚀 Dynamic Provisioning**: Automatically creates PVs on-demand
- **⚡ High Performance**: Direct disk access without network overhead
- **🏗️ Architecture Support**: ARM64 and AMD64 compatibility
- **🔧 Simple Setup**: No external dependencies or storage servers
- **📊 Development Friendly**: Perfect for development and testing environments
- **🎯 Node-Local**: Volumes tied to specific nodes for optimal performance
- **💰 Cost Effective**: Uses existing node storage without additional hardware

## Use Cases

### **Perfect For:**

- **Development Environments**: Fast, simple storage for testing
- **Single-Node Clusters**: Ideal for development machines
- **High-Performance Workloads**: Direct disk access without network latency
- **Stateful Applications**: Databases, file servers on dedicated nodes
- **Edge Computing**: Local storage for edge devices and IoT

### **Not Suitable For:**

- **Multi-Node HA**: Volumes can't move between nodes
- **Shared Storage**: No ReadWriteMany support
- **Data Replication**: No built-in redundancy
- **Cloud Environments**: Cloud storage classes usually better

## Usage

### Basic Usage

```hcl
module "hostpath" {
  source = "./helm-host-path"

  set_as_default_storage_class = true
}
```

### Advanced Configuration

```hcl
module "hostpath" {
  source = "./helm-host-path"

  namespace     = "hostpath-system"
  chart_version = "0.0.33"

  # Storage configuration
  set_as_default_storage_class = false  # Use as secondary storage

  # Architecture
  cpu_arch                = "amd64"
  disable_arch_scheduling = false

  # Resource limits
  cpu_limit      = "200m"
  memory_limit   = "128Mi"
  cpu_request    = "50m"
  memory_request = "64Mi"

  # Helm configuration
  helm_timeout = 600
  helm_wait    = true
}
```

### Development Environment

```hcl
module "hostpath" {
  source = "./helm-host-path"

  # Default storage for development
  set_as_default_storage_class = true

  # Minimal resources for development
  cpu_limit      = "50m"
  memory_limit   = "32Mi"
  cpu_request    = "10m"
  memory_request = "16Mi"
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
| helm_release.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Namespace for HostPath provisioner | `string` | `"host-path-stack"` | no |
| name | Helm release name | `string` | `"host-path"` | no |
| chart_name | Helm chart name | `string` | `"local-path-provisioner"` | no |
| chart_repo | Helm repository | `string` | `"https://charts.containeroo.ch"` | no |
| chart_version | Helm chart version | `string` | `"0.0.33"` | no |
| set_as_default_storage_class | Set as default storage class | `bool` | `false` | no |
| cpu_arch | CPU architecture constraint | `string` | `"amd64"` | no |
| disable_arch_scheduling | Disable architecture scheduling | `bool` | `false` | no |
| cpu_limit | CPU limit for provisioner | `string` | `"100m"` | no |
| memory_limit | Memory limit for provisioner | `string` | `"64Mi"` | no |
| cpu_request | CPU request for provisioner | `string` | `"25m"` | no |
| memory_request | Memory request for provisioner | `string` | `"32Mi"` | no |
| let_helm_create_storage_class | Let Helm manage storage class | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | HostPath provisioner namespace |

## Storage Class Configuration

The module creates a `hostpath` storage class with the following characteristics:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hostpath
provisioner: rancher.io/local-path
parameters:
  # No parameters needed for hostpath
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: false
```

### Key Features

- **`WaitForFirstConsumer`**: Volumes created when pod is scheduled
- **`Retain` Policy**: Data preserved when PVC is deleted
- **No Volume Expansion**: Size fixed at creation time
- **ReadWriteOnce Only**: Single pod access per volume

## Node Storage Paths

The provisioner creates volumes under:

```bash
# Default path on nodes
/opt/local-path-provisioner/

# Structure
/opt/local-path-provisioner/
├── pvc-<uuid>/           # Individual volume directories
│   └── <your-data>
├── pvc-<uuid>/
└── ...
```

### Storage Locations by OS

| Operating System | Default Path |
|------------------|--------------|
| Linux | `/opt/local-path-provisioner/` |
| K3s | `/var/lib/rancher/k3s/storage/` |
| MicroK8s | `/var/snap/microk8s/common/default-storage/` |
| Docker Desktop | `/tmp/hostpath-provisioner/` |

## Usage Examples

### Basic Persistent Volume Claim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-storage
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: hostpath
  resources:
    requests:
      storage: 10Gi
```

### Database with HostPath Storage

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_PASSWORD
          value: secretpassword
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        ports:
        - containerPort: 5432
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: hostpath
      resources:
        requests:
          storage: 20Gi
```

### Development Pod with Storage

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dev-environment
spec:
  containers:
  - name: dev
    image: ubuntu:20.04
    command: ["/bin/sleep", "infinity"]
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    - name: cache
      mountPath: /home/cache
  volumes:
  - name: workspace
    persistentVolumeClaim:
      claimName: dev-workspace
  - name: cache
    persistentVolumeClaim:
      claimName: dev-cache
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dev-workspace
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: hostpath
  resources:
    requests:
      storage: 50Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dev-cache
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: hostpath
  resources:
    requests:
      storage: 20Gi
```

## Architecture Support

### ARM64 (Raspberry Pi)

```hcl
module "hostpath" {
  source = "./helm-host-path"

  cpu_arch = "arm64"

  # Optimized for Raspberry Pi
  cpu_limit      = "50m"
  memory_limit   = "32Mi"
  cpu_request    = "10m"
  memory_request = "16Mi"

  set_as_default_storage_class = true
}
```

### AMD64 (x86_64)

```hcl
module "hostpath" {
  source = "./helm-host-path"

  cpu_arch = "amd64"

  # Higher performance setup
  cpu_limit      = "200m"
  memory_limit   = "128Mi"
  cpu_request    = "50m"
  memory_request = "64Mi"
}
```

### Multi-Architecture Clusters

```hcl
module "hostpath" {
  source = "./helm-host-path"

  # Disable architecture constraints for mixed clusters
  disable_arch_scheduling = true

  # Conservative resource limits
  cpu_limit      = "100m"
  memory_limit   = "64Mi"
}
```

## Performance Characteristics

### Advantages

- **🚀 Fastest I/O**: Direct disk access without network overhead
- **⚡ Low Latency**: No network round-trips for storage operations
- **📊 High Throughput**: Limited only by local disk performance
- **💰 No Additional Cost**: Uses existing node storage

### Limitations

- **📍 Node Affinity**: Pods tied to specific nodes
- **🔄 No Migration**: Volumes can't move between nodes
- **📈 No Scaling**: Limited by individual node storage capacity
- **🛡️ No Redundancy**: Single point of failure per volume

## Monitoring and Management

### Check Storage Usage

```bash
# View all hostpath volumes
kubectl get pv | grep hostpath

# Check PVC status
kubectl get pvc -A

# View provisioner logs
kubectl logs -n host-path-stack -l app=local-path-provisioner

# Check node storage usage
kubectl top nodes
```

### Node Storage Monitoring

```bash
# Check available space on nodes
kubectl get nodes -o wide
kubectl describe node <node-name>

# SSH to node and check storage
ssh <node-ip>
df -h /opt/local-path-provisioner/
du -sh /opt/local-path-provisioner/*/
```

## Troubleshooting

### Common Issues

1. **Pod Stuck Pending**: Check node storage capacity
2. **Volume Mount Failures**: Verify provisioner is running
3. **Permission Denied**: Check node filesystem permissions
4. **Out of Space**: Monitor node disk usage

### Debug Commands

```bash
# Check provisioner status
kubectl get pods -n host-path-stack
kubectl logs -n host-path-stack -l app=local-path-provisioner

# Check storage class
kubectl describe storageclass hostpath

# Debug PVC issues
kubectl describe pvc <pvc-name>
kubectl get events --sort-by='.lastTimestamp'

# Check volume binding
kubectl get pv -o wide
```

### Manual Volume Creation

```bash
# SSH to target node
ssh <node-ip>

# Check/create directory
sudo mkdir -p /opt/local-path-provisioner/manual-volume
sudo chown -R 1000:1000 /opt/local-path-provisioner/manual-volume

# Create manual PV (if needed)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: manual-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: hostpath
  hostPath:
    path: /opt/local-path-provisioner/manual-volume
EOF
```

## Backup and Recovery

### Backup Strategy

```bash
#!/bin/bash
# Backup script for hostpath volumes

BACKUP_DIR="/backup/k8s-hostpath"
VOLUME_DIR="/opt/local-path-provisioner"
DATE=$(date +%Y%m%d-%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR/$DATE"

# Backup all volumes
for volume in "$VOLUME_DIR"/pvc-*; do
  if [ -d "$volume" ]; then
    volume_name=$(basename "$volume")
    echo "Backing up $volume_name..."
    tar -czf "$BACKUP_DIR/$DATE/$volume_name.tar.gz" -C "$volume" .
  fi
done

# Cleanup old backups (keep 7 days)
find "$BACKUP_DIR" -type d -mtime +7 -exec rm -rf {} \;
```

### Automated Backup with CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hostpath-backup
  namespace: host-path-stack
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          nodeSelector:
            # Run on specific node with volumes
            kubernetes.io/hostname: worker-node-1
          hostNetwork: true
          containers:
          - name: backup
            image: ubuntu:20.04
            command:
            - /bin/bash
            - -c
            - |
              apt-get update && apt-get install -y tar gzip
              DATE=$(date +%Y%m%d-%H%M%S)
              mkdir -p /backup/$DATE
              for vol in /hostpath/pvc-*; do
                if [ -d "$vol" ]; then
                  name=$(basename "$vol")
                  tar -czf "/backup/$DATE/$name.tar.gz" -C "$vol" .
                fi
              done
              # Cleanup old backups
              find /backup -type d -mtime +7 -exec rm -rf {} \;
            volumeMounts:
            - name: hostpath-volumes
              mountPath: /hostpath
              readOnly: true
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: hostpath-volumes
            hostPath:
              path: /opt/local-path-provisioner
          - name: backup-storage
            hostPath:
              path: /backup/k8s-hostpath
          restartPolicy: OnFailure
```

## Migration Strategies

### From HostPath to NFS

```bash
# 1. Create equivalent NFS PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-storage-nfs
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nfs-csi
  resources:
    requests:
      storage: 10Gi
EOF

# 2. Copy data using temporary pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: data-migration
spec:
  containers:
  - name: copier
    image: ubuntu:20.04
    command: ["/bin/sleep", "infinity"]
    volumeMounts:
    - name: source
      mountPath: /source
      readOnly: true
    - name: destination
      mountPath: /destination
  volumes:
  - name: source
    persistentVolumeClaim:
      claimName: app-storage-hostpath
  - name: destination
    persistentVolumeClaim:
      claimName: app-storage-nfs
EOF

# 3. Copy data
kubectl exec data-migration -- cp -a /source/. /destination/

# 4. Update application to use NFS PVC
# 5. Delete old hostpath PVC
```

## Best Practices

### Development Environment

- **Use as default storage class** for simplicity
- **Set small resource limits** to minimize overhead
- **Regular cleanup** of unused volumes
- **Backup important development data**

### Production Considerations

- **Use only for node-specific applications**
- **Monitor disk usage** on all nodes
- **Implement backup strategy** for critical data
- **Consider storage quotas** to prevent disk exhaustion
- **Document node-to-application mapping**

### Performance Optimization

```hcl
# For high-I/O applications
cpu_limit = "500m"
memory_limit = "256Mi"

# For minimal overhead
cpu_limit = "50m"
memory_limit = "32Mi"
```

### Node Preparation

```bash
# Ensure adequate disk space
df -h /opt/local-path-provisioner/

# Set up log rotation for large volumes
sudo logrotate /var/log/containers/

# Monitor inode usage
df -i /opt/local-path-provisioner/
```

## Security Considerations

- **File Permissions**: Volumes inherit node filesystem permissions
- **Node Access**: Physical access to nodes = access to data
- **Pod Security**: Use security contexts to control file access
- **Backup Security**: Encrypt backup files if containing sensitive data
- **Network Policies**: Not applicable (local storage)

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
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.hostpath_pvc_limit](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_resource_quota.hostpath_quota](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/resource_quota) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name. | `string` | `"local-path-provisioner"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL. | `string` | `"https://charts.containeroo.ch"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version. | `string` | `"0.0.33"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"25m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name to be used for the deployment. | `string` | `".local"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_hostpath_storage_quota_limit"></a> [hostpath\_storage\_quota\_limit](#input\_hostpath\_storage\_quota\_limit) | Storage quota limit for hostpath volumes | `string` | `"50Gi"` | no |
| <a name="input_let_helm_create_storage_class"></a> [let\_helm\_create\_storage\_class](#input\_let\_helm\_create\_storage\_class) | Create a storage class using helm | `bool` | `false` | no |
| <a name="input_limit_range_container_max_cpu"></a> [limit\_range\_container\_max\_cpu](#input\_limit\_range\_container\_max\_cpu) | Maximum CPU limit for containers (default: same as cpu\_limit) | `string` | `null` | no |
| <a name="input_limit_range_container_max_memory"></a> [limit\_range\_container\_max\_memory](#input\_limit\_range\_container\_max\_memory) | Maximum memory limit for containers (default: same as memory\_limit) | `string` | `null` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_limit_range_pvc_max_storage"></a> [limit\_range\_pvc\_max\_storage](#input\_limit\_range\_pvc\_max\_storage) | Maximum storage size for PVCs | `string` | `"10Gi"` | no |
| <a name="input_limit_range_pvc_min_storage"></a> [limit\_range\_pvc\_min\_storage](#input\_limit\_range\_pvc\_min\_storage) | Minimum storage size for PVCs | `string` | `"100Mi"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"64Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"32Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"host-path"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"host-path-stack"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Service-specific overrides for labels, annotations, and other configurations | <pre>object({<br/>    labels      = optional(map(string), {})<br/>    annotations = optional(map(string), {})<br/>  })</pre> | <pre>{<br/>  "annotations": {},<br/>  "labels": {}<br/>}</pre> | no |
| <a name="input_set_as_default_storage_class"></a> [set\_as\_default\_storage\_class](#input\_set\_as\_default\_storage\_class) | Set the NFS storage class as the default storage class | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release"></a> [helm\_release](#output\_helm\_release) | Helm release information |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The namespace where the host path provisioner is deployed |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limit configuration |
| <a name="output_storage_configuration"></a> [storage\_configuration](#output\_storage\_configuration) | Storage configuration details |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.0.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.hostpath_pvc_limit](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_resource_quota.hostpath_quota](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/resource_quota) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name. | `string` | `"local-path-provisioner"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL. | `string` | `"https://charts.containeroo.ch"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version. | `string` | `"0.0.33"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture for node selection (amd64, arm64) | `string` | `"amd64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for the container | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for the container | `string` | `"25m"` | no |
| <a name="input_disable_arch_scheduling"></a> [disable\_arch\_scheduling](#input\_disable\_arch\_scheduling) | Disable architecture-based node scheduling (useful for cluster-wide services) | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name to be used for the deployment. | `string` | `".local"` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `300` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_hostpath_storage_quota_limit"></a> [hostpath\_storage\_quota\_limit](#input\_hostpath\_storage\_quota\_limit) | Storage quota limit for hostpath volumes | `string` | `"50Gi"` | no |
| <a name="input_let_helm_create_storage_class"></a> [let\_helm\_create\_storage\_class](#input\_let\_helm\_create\_storage\_class) | Create a storage class using helm | `bool` | `false` | no |
| <a name="input_limit_range_container_max_cpu"></a> [limit\_range\_container\_max\_cpu](#input\_limit\_range\_container\_max\_cpu) | Maximum CPU limit for containers (default: same as cpu\_limit) | `string` | `null` | no |
| <a name="input_limit_range_container_max_memory"></a> [limit\_range\_container\_max\_memory](#input\_limit\_range\_container\_max\_memory) | Maximum memory limit for containers (default: same as memory\_limit) | `string` | `null` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_limit_range_pvc_max_storage"></a> [limit\_range\_pvc\_max\_storage](#input\_limit\_range\_pvc\_max\_storage) | Maximum storage size for PVCs | `string` | `"10Gi"` | no |
| <a name="input_limit_range_pvc_min_storage"></a> [limit\_range\_pvc\_min\_storage](#input\_limit\_range\_pvc\_min\_storage) | Minimum storage size for PVCs | `string` | `"100Mi"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for the container | `string` | `"64Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for the container | `string` | `"32Mi"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm name. | `string` | `"host-path"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace. | `string` | `"host-path-stack"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Service-specific overrides for labels, annotations, and other configurations | <pre>object({<br/>    labels      = optional(map(string), {})<br/>    annotations = optional(map(string), {})<br/>  })</pre> | <pre>{<br/>  "annotations": {},<br/>  "labels": {}<br/>}</pre> | no |
| <a name="input_set_as_default_storage_class"></a> [set\_as\_default\_storage\_class](#input\_set\_as\_default\_storage\_class) | Set the NFS storage class as the default storage class | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release"></a> [helm\_release](#output\_helm\_release) | Helm release information |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | The namespace where the host path provisioner is deployed |
| <a name="output_resource_limits"></a> [resource\_limits](#output\_resource\_limits) | Resource limit configuration |
| <a name="output_storage_configuration"></a> [storage\_configuration](#output\_storage\_configuration) | Storage configuration details |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
