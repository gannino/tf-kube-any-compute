# NFS Storage Options

## Overview

tf-kube-any-compute supports dynamic NFS storage provisioning with configurable mount options for optimal performance and reliability.

## NFS Storage Class Configurations

The system provides four pre-configured NFS storage class types:

- **reliable** (default) - Stability-focused with more retries and sync writes
- **default** - Balanced configuration for general use
- **performance** - High-performance with larger buffers and async writes
- **low_latency** - Optimized for real-time applications

### Per-Service Configuration

```hcl
service_overrides = {
  prometheus = {
    nfs_storage_class_type = "performance"  # High-performance for metrics
  }
  vault = {
    nfs_storage_class_type = "reliable"     # Extra safety for secrets (default)
  }
}
```

## Dynamic NFS Provisioning

The NFS CSI driver automatically creates folders with generated names:

```hcl
use_nfs_storage = true
nfs_server_address = "192.168.1.100"
nfs_server_path = "/export/k8s"
```

**Result**: `/export/k8s/prod-grafana-system-pvc-grafana-12345`

**Benefits:**
- ✅ Automatic volume provisioning and cleanup
- ✅ Multiple environments (dev/staging/prod)
- ✅ Standard Kubernetes PVC behavior
- ✅ No manual volume management required

## Complete Configuration Example

```hcl
# Enable NFS with custom storage class configurations
use_nfs_storage = true
nfs_server_address = "192.168.1.100"
nfs_server_path = "/export/k8s"

# Custom NFS storage class configurations
nfs_storage_class_config = {
  # Override default reliable configuration
  reliable = {
    mount_options = [
      "hard",
      "retrans=15",  # More retries for extra safety
      "rsize=32768",
      "sync",
      "timeo=1500",  # Longer timeout
      "vers=4.1",
      "wsize=32768",
      "intr"
    ]
    reclaim_policy = "Retain"
    access_modes   = ["ReadWriteMany"]
  }
}

# Per-service NFS configuration
service_overrides = {
  prometheus = {
    nfs_storage_class_type = "performance"  # Fast for metrics
  }
  grafana = {
    nfs_storage_class_type = "reliable"     # Safe for dashboards (default)
  }
}
```

## Default Configuration

By default, all services use the **"reliable"** NFS storage class type, which provides:
- More retries (`retrans=10`)
- Longer timeouts (`timeo=1200`)
- Synchronous writes for data safety
- Smaller buffer sizes for stability
- Interrupt support (`intr`)

See `terraform.tfvars.example` for complete configuration examples.
