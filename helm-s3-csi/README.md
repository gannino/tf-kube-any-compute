# Yandex S3 CSI Helm Module

This Terraform module deploys the Yandex Cloud S3 CSI Driver for Kubernetes, enabling dynamic provisioning of persistent volumes using S3-compatible object storage (Yandex Object Storage, AWS S3, MinIO, etc.).

## Features

- **☁️ Object Storage Integration**: Mount S3 buckets as Kubernetes volumes
- **🔄 Dynamic Volume Provisioning**: Automatic PV creation from S3 objects
- **🔒 Secure Credential Management**: Kubernetes Secret-based authentication
- **⚙️ Flexible Mounter Options**: Support for geesefs, rclone, and s3backer
- **🏗️ Architecture Support**: ARM64 and AMD64 compatibility
- **📊 Storage Class Management**: Customizable reclaim policies and volume binding
- **🎯 Kubernetes Native**: Full integration with Kubernetes storage APIs

## Why S3 CSI?

### Use Cases

- **Backups and Archives**: Long-term data retention with object storage durability
- **Content Management**: Static assets, media files, documents
- **Data Lakes**: Analytics workloads with S3-compatible storage
- **Multi-Cloud Portability**: S3 API works across providers

### Limitations

- **Not Block Storage**: FUSE filesystem over S3 - slower than local disks
- **No Sub-second Latency**: S3 has inherent network latency
- **Eventually Consistent**: S3 read-after-write consistency semantics
- **Not for Databases**: Use block storage (Rook Ceph, Longhorn) instead

## Usage

### Basic Usage

```hcl
module "s3_csi" {
  source = "./helm-s3-csi"

  # S3 credentials
  s3_endpoint          = "https://storage.yandexcloud.net"
  s3_access_key_id     = "your-access-key-id"
  s3_secret_access_key = "your-secret-access-key"
  s3_bucket            = "my-existing-bucket"
  s3_region            = "ru-central1"
}
```

### Yandex Cloud Configuration

```hcl
module "s3_csi" {
  source = "./helm-s3-csi"

  # Yandex Cloud Object Storage
  s3_endpoint          = "https://storage.yandexcloud.net"
  s3_access_key_id     = var.yc_access_key_id
  s3_secret_access_key = var.yc_secret_key
  s3_bucket            = "my-k8s-storage"
  s3_region            = "ru-central1"

  # Mounter configuration
  mounter         = "geesefs"
  mounter_options = "--memory-limit=1000 --dir-mode=0777 --file-mode=0666"

  # Storage class
  storage_class_name  = "csi-s3"
  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"
}
```

### AWS S3 Configuration

```hcl
module "s3_csi" {
  source = "./helm-s3-csi"

  # AWS S3
  s3_endpoint          = "https://s3.amazonaws.com"
  s3_access_key_id     = var.aws_access_key_id
  s3_secret_access_key = var.aws_secret_key
  s3_bucket            = "my-k8s-s3-bucket"
  s3_region            = "us-east-1"

  # AWS S3 typically works better with rclone mounter
  mounter         = "rclone"
  mounter_options = "--s3-region us-east-1"
}
```

### MinIO Configuration

```hcl
module "s3_csi" {
  source = "./helm-s3-csi"

  # Self-hosted MinIO
  s3_endpoint          = "http://minio.example.com:9000"
  s3_access_key_id     = var.minio_access_key
  s3_secret_access_key = var.minio_secret_key
  s3_bucket            = "kubernetes-volumes"
  s3_region            = ""  # MinIO doesn't use regions

  # Disable SSL for self-signed certs (production: use proper certs)
  mounter_options = "--memory-limit=1000 --no-ssl"
}
```

### QNAP NAS Configuration

```hcl
module "s3_csi" {
  source = "./helm-s3-csi"

  # QNAP QuTScloud Hero S3-compatible storage
  s3_endpoint          = "https://qnap.example.com:8010"
  s3_access_key_id     = var.qnap_access_key
  s3_secret_access_key = var.qnap_secret_key
  s3_bucket            = "kubernetes-storage"
  s3_region            = ""  # QNAP doesn't use regions

  # QNAP works well with geesefs or rclone
  mounter         = "geesefs"
  mounter_options = "--memory-limit=1000 --dir-mode=0777 --file-mode=0666"
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
| kubernetes_secret.s3_credentials | resource |
| kubernetes_storage_class.s3_csi | resource |
| kubernetes_limit_range.namespace_limits | resource |
| helm_release.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Namespace for S3 CSI driver | `string` | `"s3-csi-system"` | no |
| name | Helm release name | `string` | `"s3-csi"` | no |
| chart_name | Helm chart name | `string` | `"csi-s3"` | no |
| chart_repo | Helm chart repository URL | `string` | `"https://yandex-cloud.github.io/k8s-csi-s3/charts"` | no |
| chart_version | Helm chart version | `string` | `"v0.43.4"` | no |
| s3_endpoint | S3 endpoint URL | `string` | n/a | **yes** |
| s3_access_key_id | S3 access key ID | `string` | n/a | **yes** |
| s3_secret_access_key | S3 secret access key | `string` | n/a | **yes** |
| s3_bucket | Existing S3 bucket name | `string` | n/a | **yes** |
| s3_region | S3 region | `string` | `"ru-central1"` | no |
| mounter | Mounter type (geesefs/rclone/s3backer) | `string` | `"geesefs"` | no |
| mounter_options | Mounter command line options | `string` | `"--memory-limit=1000..."` | no |
| storage_class_name | StorageClass name | `string` | `"csi-s3"` | no |
| set_as_default_storage_class | Set as default StorageClass | `bool` | `false` | no |
| reclaim_policy | Reclaim policy (Retain/Delete) | `string` | `"Retain"` | no |
| volume_binding_mode | Volume binding mode | `string` | `"Immediate"` | no |
| allow_volume_expansion | Allow volume expansion | `bool` | `false` | no |
| secret_name | Kubernetes Secret name | `string` | `"csi-s3-secret"` | no |
| create_secret | Create S3 credentials Secret | `bool` | `true` | no |
| cpu_arch | CPU architecture | `string` | `"arm64"` | no |
| disable_arch_scheduling | Disable arch scheduling | `bool` | `true` | no |
| cpu_limit | CPU limit for containers | `string` | `"200m"` | no |
| memory_limit | Memory limit for containers | `string` | `"256Mi"` | no |
| cpu_request | CPU request for containers | `string` | `"50m"` | no |
| memory_request | Memory request for containers | `string` | `"64Mi"` | no |
| helm_timeout | Helm timeout in seconds | `number` | `600` | no |
| helm_wait | Wait for Helm release | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Namespace where S3 CSI is deployed |
| storage_class_name | Name of the S3 CSI storage class |
| helm_release_name | Name of the Helm release |
| helm_release_status | Status of the Helm release |
| s3_endpoint | S3 endpoint used by the CSI driver |
| s3_bucket | S3 bucket used for storage |
| secret_name | Name of the Kubernetes Secret |
| mounter | S3 mounter type |
| service_discovery_host | Service hostname for service discovery |

## Storage Classes Created

### Default StorageClass (`csi-s3`)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-s3
provisioner: ru.yandex.s3.csi
parameters:
  mounter: geesefs
  options: --memory-limit=1000 --dir-mode=0777 --file-mode=0666
  bucket: your-existing-bucket
  csi.storage.k8s.io/provisioner-secret-name: csi-s3-secret
  csi.storage.k8s.io/provisioner-secret-namespace: s3-csi-system
allowVolumeExpansion: false
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

## Mounter Comparison

### geesefs (Recommended for Yandex Cloud)

- **Type**: FUSE filesystem
- **Pros**: Good performance, Yandex Cloud optimized
- **Cons**: Higher memory usage
- **Use Case**: General purpose, Yandex Cloud

### rclone

- **Type**: FUSE filesystem via rclone
- **Pros**: Wide S3 provider support, many options
- **Cons**: Slightly higher latency
- **Use Case**: AWS S3, MinIO, custom providers

### s3backer

- **Type**: Block device overlay
- **Pros**: Lower memory usage
- **Cons**: Experimental, limited features
- **Use Case**: Resource-constrained environments

## S3 Provider Setup

### Yandex Cloud

1. Create service account: https://cloud.yandex.com/en/docs/iam/operations/sa/create
2. Create static access key: https://cloud.yandex.com/en/docs/iam/operations/sa/create-access-key
3. Create Object Storage bucket: https://cloud.yandex.com/en/docs/storage/operations/buckets/create
4. Configure bucket permissions for the service account

### AWS S3

1. Create IAM user: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html
2. Attach S3 access policy: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage-attach.html
3. Create access keys: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_create-keys.html
4. Create S3 bucket: https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket.html

### MinIO

1. Deploy MinIO: `kubectl create deployment minio --image=minio/minio --server=/data`
2. Create bucket: `mc mb myminio/kubernetes-volumes`
3. Create access credentials: `mc admin user add myminio admin password`
4. Configure service: Expose MinIO service

## Usage Examples

### Basic Persistent Volume Claim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: s3-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: csi-s3
  resources:
    requests:
      storage: 10Gi
```

### Pod Using S3 Storage

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-s3
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
      claimName: s3-pvc
```

### Deployment with S3 Backup

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backup-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backup
  template:
    metadata:
      labels:
        app: backup
    spec:
      containers:
      - name: app
        image: busybox
        command: ["/bin/sh", "-c", "while true; do date >> /data/backup.txt; sleep 60; done"]
        volumeMounts:
        - name: backup
          mountPath: /data
      volumes:
      - name: backup
        persistentVolumeClaim:
          claimName: s3-backup-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: s3-backup-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: csi-s3
  resources:
    requests:
      storage: 50Gi
```

## Architecture Support

### ARM64 (Raspberry Pi)

```hcl
module "s3_csi" {
  source = "./helm-s3-csi"

  cpu_arch = "arm64"

  # ARM64 optimized resources
  cpu_limit      = "200m"
  memory_limit   = "256Mi"
  cpu_request    = "50m"
  memory_request = "64Mi"

  s3_endpoint          = "https://storage.yandexcloud.net"
  s3_access_key_id     = var.yc_access_key_id
  s3_secret_access_key = var.yc_secret_key
  s3_bucket            = "pi-cluster-storage"
  s3_region            = "ru-central1"
}
```

### AMD64 (x86_64)

```hcl
module "s3_csi" {
  source = "./helm-s3-csi"

  cpu_arch = "amd64"

  # Higher performance resources
  cpu_limit      = "500m"
  memory_limit   = "512Mi"
  cpu_request    = "100m"
  memory_request = "128Mi"

  s3_endpoint          = "https://s3.amazonaws.com"
  s3_access_key_id     = var.aws_access_key_id
  s3_secret_access_key = var.aws_secret_key
  s3_bucket            = "prod-cluster-storage"
  s3_region            = "us-east-1"
}
```

## Troubleshooting

### Common Issues

1. **Connection Timeouts**: Check endpoint URL and network connectivity
2. **Authentication Failed**: Verify access key ID and secret access key
3. **Bucket Not Found**: Ensure bucket exists before using CSI
4. **Mount Failures**: Check mounter options and compatibility

### Diagnostic Commands

```bash
# Check S3 CSI pods
kubectl get pods -n s3-csi-system

# View provisioner logs
kubectl logs -n s3-csi-system -l app=csi-s3-provisioner

# Check storage classes
kubectl get storageclass csi-s3

# View S3 secret
kubectl get secret csi-s3-secret -n s3-csi-system -o yaml

# Test PVC creation
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-s3-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: csi-s3
  resources:
    requests:
      storage: 1Gi
EOF

# Check PVC status
kubectl get pvc test-s3-pvc
```

### Performance Tuning

```hcl
# Increase memory limit for geesefs
mounter_options = "--memory-limit=2000 --dir-mode=0777 --file-mode=0666"

# Adjust mounter for different workloads
# For high throughput: increase memory limit
# For low memory: decrease memory limit
# For strict consistency: add --sync-flag
```

## Security Considerations

- **Credential Rotation**: Rotate S3 access keys regularly
- **Bucket Policies**: Implement least-privilege bucket access
- **Encryption**: Use S3 server-side encryption
- **Network Policies**: Restrict CSI driver network access
- **Secret Management**: Consider using External Secrets Operator

### S3 Bucket Policy Example

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_ID:user/service-account"
      },
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::your-bucket/*"
    }
  ]
}
```

## Best Practices

### Production Deployment

1. **Use existing S3 bucket** with proper lifecycle policies
2. **Set reclaim policy to Retain** to prevent data loss
3. **Monitor S3 costs** - object storage has per-operation pricing
4. **Implement backup strategy** for critical data
5. **Use network policies** to secure CSI driver

### Development Environment

1. **Use MinIO** for local S3-compatible testing
2. **Lower resource limits** for development
3. **Delete reclaim policy** for automatic cleanup
4. **Small PVC sizes** for faster testing

### Resource Management

1. **Set appropriate resource limits** based on workload
2. **Monitor mounter memory usage** under load
3. **Scale resources** based on volume creation frequency
4. **Use node affinity** for CSI driver placement

## Migration and Backup

### Data Migration

```bash
# List S3 objects
aws s3 ls s3://your-bucket/ --recursive

# Sync to another bucket
aws s3 sync s3://your-bucket/ s3://backup-bucket/
```

### Backup Strategy

```bash
# Snapshot bucket versioning
aws s3api list-object-versions --bucket your-bucket

# Cross-region replication
aws s3api put-bucket-replication --bucket your-bucket \
  --replication-configuration file://replication.json
```

## Limitations

- **Performance**: FUSE filesystem has overhead compared to local disks
- **Consistency**: S3 is eventually consistent (read-after-write)
- **Latency**: Network latency to S3 endpoint
- **Not for Databases**: Use block storage for databases (PostgreSQL, MySQL)
- **No Sub-second Operations**: Not suitable for high-frequency writes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

APACHE

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_limit_range.namespace_limits](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_volume_expansion"></a> [allow\_volume\_expansion](#input\_allow\_volume\_expansion) | Allow volume expansion for S3 PVCs | `bool` | `false` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name | `string` | `"csi-s3"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm chart repository URL for Yandex Cloud S3 CSI driver | `string` | `"https://yandex-cloud.github.io/k8s-csi-s3/charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Helm chart version | `string` | `"v0.43.4"` | no |
| <a name="input_cpu_arch"></a> [cpu\_arch](#input\_cpu\_arch) | CPU architecture | `string` | `"arm64"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | CPU limit for CSI driver containers | `string` | `"200m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for CSI driver containers | `string` | `"50m"` | no |
| <a name="input_create_secret"></a> [create\_secret](#input\_create\_secret) | Create the S3 credentials Secret (set to false if using existing secret) | `bool` | `true` | no |
| <a name="input_helm_cleanup_on_fail"></a> [helm\_cleanup\_on\_fail](#input\_helm\_cleanup\_on\_fail) | Cleanup resources on failure | `bool` | `false` | no |
| <a name="input_helm_disable_webhooks"></a> [helm\_disable\_webhooks](#input\_helm\_disable\_webhooks) | Disable webhooks for Helm release | `bool` | `false` | no |
| <a name="input_helm_force_update"></a> [helm\_force\_update](#input\_helm\_force\_update) | Force resource updates if needed | `bool` | `false` | no |
| <a name="input_helm_replace"></a> [helm\_replace](#input\_helm\_replace) | Allow Helm to replace existing resources | `bool` | `false` | no |
| <a name="input_helm_skip_crds"></a> [helm\_skip\_crds](#input\_helm\_skip\_crds) | Skip CRDs for Helm release | `bool` | `false` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Timeout for Helm deployment in seconds | `number` | `600` | no |
| <a name="input_helm_wait"></a> [helm\_wait](#input\_helm\_wait) | Wait for Helm release to be ready | `bool` | `false` | no |
| <a name="input_helm_wait_for_jobs"></a> [helm\_wait\_for\_jobs](#input\_helm\_wait\_for\_jobs) | Wait for Helm jobs to complete | `bool` | `false` | no |
| <a name="input_limit_range_container_max_cpu"></a> [limit\_range\_container\_max\_cpu](#input\_limit\_range\_container\_max\_cpu) | Maximum CPU limit for containers | `string` | `null` | no |
| <a name="input_limit_range_container_max_memory"></a> [limit\_range\_container\_max\_memory](#input\_limit\_range\_container\_max\_memory) | Maximum memory limit for containers | `string` | `null` | no |
| <a name="input_limit_range_enabled"></a> [limit\_range\_enabled](#input\_limit\_range\_enabled) | Enable limit range for the namespace | `bool` | `true` | no |
| <a name="input_limit_range_pvc_max_storage"></a> [limit\_range\_pvc\_max\_storage](#input\_limit\_range\_pvc\_max\_storage) | Maximum storage size for PVCs | `string` | `"100Gi"` | no |
| <a name="input_limit_range_pvc_min_storage"></a> [limit\_range\_pvc\_min\_storage](#input\_limit\_range\_pvc\_min\_storage) | Minimum storage size for PVCs | `string` | `"1Gi"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for CSI driver containers | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for CSI driver containers | `string` | `"64Mi"` | no |
| <a name="input_mounter"></a> [mounter](#input\_mounter) | S3 mounter type: geesefs (x86\_64 only), s3fs-fuse (ARM64 compatible), rclone (ARM64 compatible), or s3backer | `string` | `"s3fs-fuse"` | no |
| <a name="input_mounter_options"></a> [mounter\_options](#input\_mounter\_options) | Additional options for the mounter (s3fs-fuse: empty, geesefs: --memory-limit=1000 --dir-mode=0777 --file-mode=0666) | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name | `string` | `"s3-csi"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for S3 CSI driver | `string` | `"s3-csi-system"` | no |
| <a name="input_reclaim_policy"></a> [reclaim\_policy](#input\_reclaim\_policy) | Reclaim policy for the storage class (Retain or Delete) | `string` | `"Retain"` | no |
| <a name="input_s3_access_key_id"></a> [s3\_access\_key\_id](#input\_s3\_access\_key\_id) | S3 access key ID | `string` | n/a | yes |
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | Existing S3 bucket name to use for storage (bucket must already exist) | `string` | n/a | yes |
| <a name="input_s3_endpoint"></a> [s3\_endpoint](#input\_s3\_endpoint) | S3 endpoint URL (e.g., https://storage.yandexcloud.net, https://s3.amazonaws.com) | `string` | n/a | yes |
| <a name="input_s3_region"></a> [s3\_region](#input\_s3\_region) | S3 region (empty string for providers like QNAP, MinIO that don't use regions) | `string` | `""` | no |
| <a name="input_s3_secret_access_key"></a> [s3\_secret\_access\_key](#input\_s3\_secret\_access\_key) | S3 secret access key | `string` | n/a | yes |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | Name of the Kubernetes Secret for S3 credentials | `string` | `"csi-s3-secret"` | no |
| <a name="input_service_overrides"></a> [service\_overrides](#input\_service\_overrides) | Override default service configuration for backward compatibility | <pre>object({<br/>    helm_config = optional(object({<br/>      name      = optional(string)<br/>      namespace = optional(string)<br/>      resource_limits = optional(object({<br/>        requests = optional(object({<br/>          cpu    = optional(string)<br/>          memory = optional(string)<br/>        }))<br/>        limits = optional(object({<br/>          cpu    = optional(string)<br/>          memory = optional(string)<br/>        }))<br/>      }))<br/>    }))<br/>    labels          = optional(map(string))<br/>    template_values = optional(map(any))<br/>  })</pre> | `{}` | no |
| <a name="input_set_as_default_storage_class"></a> [set\_as\_default\_storage\_class](#input\_set\_as\_default\_storage\_class) | Set the S3 CSI storage class as the default storage class | `bool` | `false` | no |
| <a name="input_storage_class_name"></a> [storage\_class\_name](#input\_storage\_class\_name) | Name of the StorageClass to create | `string` | `"csi-s3"` | no |
| <a name="input_volume_binding_mode"></a> [volume\_binding\_mode](#input\_volume\_binding\_mode) | Volume binding mode (Immediate or WaitForFirstConsumer) | `string` | `"Immediate"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | Status of the Helm release |
| <a name="output_mounter"></a> [mounter](#output\_mounter) | S3 mounter type (geesefs, rclone, s3backer) |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace where S3 CSI driver is deployed |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | S3 bucket used for storage |
| <a name="output_s3_endpoint"></a> [s3\_endpoint](#output\_s3\_endpoint) | S3 endpoint used by the CSI driver |
| <a name="output_secret_name"></a> [secret\_name](#output\_secret\_name) | Name of the Kubernetes Secret containing S3 credentials |
| <a name="output_service_discovery_host"></a> [service\_discovery\_host](#output\_service\_discovery\_host) | Service hostname for external service discovery |
| <a name="output_storage_class_name"></a> [storage\_class\_name](#output\_storage\_class\_name) | Name of the S3 CSI storage class |
<!-- END_TF_DOCS -->
