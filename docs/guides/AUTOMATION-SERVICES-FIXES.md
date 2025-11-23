# 🔧 Automation Services Fixes

## Issues Fixed

### **1. Home Assistant**
- ✅ Fixed 400 Bad Request errors by correcting ConfigMap mount path
- ✅ Changed ConfigMap mount from `/config/packages` to `/config/configuration.yaml`
- ✅ Added deployment timeouts (10 minutes)
- ✅ Improved health probe timings (startup probe: 10min, readiness: 60s, liveness: 120s)
- ✅ Added `wait_for_rollout = true` for proper deployment tracking

### **2. openHAB**
- ✅ Fixed NFS permission errors by changing init container from `chown -R` to `chmod 777`
- ✅ Added JVM optimization flags for faster startup (`-XX:+TieredCompilation -XX:TieredStopAtLevel=1`)
- ✅ Removed deprecated `-Xverify:none` JVM flag (removed in Java 13+)
- ✅ Added `KARAF_OPTS` for heap memory pre-allocation (`-Xms256m -Xmx512m`)
- ✅ Replaced aggressive HTTP probes with TCP socket checks
- ✅ Extended startup probe window to 30 minutes (90 failures × 20s) for ARM64 compatibility
- ✅ Changed PVC access mode from `ReadWriteOnce` to `ReadWriteMany` for NFS compatibility
- ✅ Added lifecycle rules to PVCs for safe recreation
- ✅ Removed problematic `null_resource` wait blocks

### **3. Homebridge**
- ✅ Fixed "Connection Refused" errors by changing startup probe from HTTP to TCP
- ✅ Added 30-second initial delay to allow container startup
- ✅ Added deployment timeouts (10 minutes)
- ✅ Improved health probe timings (startup probe: 10min, readiness: 60s, liveness: 120s)
- ✅ Removed problematic `null_resource` wait blocks
- ✅ Added `wait_for_rollout = true` for proper deployment tracking

## Key Changes

### Health Probe Strategy
**Before**: Aggressive probes causing premature pod restarts
**After**: Conservative probes with proper startup windows

```hcl
# Startup Probe (allows 10-30 minutes for initialization)
startup_probe {
  tcp_socket {
    port = 8080
  }
  initial_delay_seconds = 30-60
  period_seconds        = 20
  timeout_seconds       = 10
  failure_threshold     = 60-90  # 20-30 minutes total
}

# Readiness Probe (checks every 20 seconds)
readiness_probe {
  tcp_socket {
    port = 8080
  }
  initial_delay_seconds = 120
  period_seconds        = 20
  timeout_seconds       = 10
  failure_threshold     = 10
}

# Liveness Probe (checks every 30 seconds)
liveness_probe {
  tcp_socket {
    port = 8080
  }
  initial_delay_seconds = 180
  period_seconds        = 30
  timeout_seconds       = 10
  failure_threshold     = 5
}
```

### PVC Access Modes
**Before**: `ReadWriteOnce` (single node only)
**After**: `ReadWriteMany` (multi-node compatible)

This allows:
- Better compatibility with NFS storage
- Pod rescheduling across nodes
- Backup and maintenance operations

### NFS Permission Handling
**Before**: `chown -R` in init container (fails with "Operation not permitted")
**After**: `chmod 777` for world-writable directories

This approach:
- Works with NFS `root_squash` enabled
- Avoids ownership conflicts
- Allows containers to write with any UID/GID

### JVM Optimization for openHAB
**Added**: Performance flags for faster startup on ARM64

```bash
EXTRA_JAVA_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
KARAF_OPTS="-Xms256m -Xmx512m"
```

Benefits:
- Faster JIT compilation during startup
- Pre-allocated heap memory reduces GC overhead
- Removed deprecated `-Xverify:none` (not supported in Java 13+)

## Testing

Deploy the services:

```bash
# Enable services in terraform.tfvars
services = {
  home_assistant = true
  openhab        = true
  homebridge     = true
}

# Apply changes
terraform apply

# Monitor deployment
kubectl get pods -n prod-home-assistant-system -w
kubectl get pods -n prod-openhab-system -w
kubectl get pods -n prod-homebridge-system -w

# Check logs if issues occur
kubectl logs -n prod-home-assistant-system -l app=prod-home-assistant
kubectl logs -n prod-openhab-system -l app=prod-openhab
kubectl logs -n prod-homebridge-system -l app=prod-homebridge
```

## Troubleshooting

### If pods are stuck in CrashLoopBackOff:

```bash
# Check events
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace> --previous

# Check PVC status
kubectl get pvc -n <namespace>
```

### Common Issues:

1. **PVC not binding**: Check storage class availability
   ```bash
   kubectl get storageclass
   kubectl get pv
   ```

2. **Permission errors**: Verify `nfs_fs_group` setting
   ```bash
   # In terraform.tfvars
   nfs_fs_group = 1000  # Match your NFS server UID/GID
   ```

3. **Slow startup**: These services need time to initialize
   - Home Assistant: 2-5 minutes
   - openHAB: 8-12 minutes on ARM64, 5-8 minutes on AMD64 (Java runtime)
   - Homebridge: 1-3 minutes

4. **NFS permission errors**: If you see "Operation not permitted" errors
   ```bash
   # Check NFS server exports configuration
   # Ensure root_squash is enabled (default and recommended)
   # The init container uses chmod 777 to work with root_squash
   ```

## Configuration Examples

### Minimal Configuration
```hcl
services = {
  home_assistant = true
  openhab        = true
  homebridge     = true
}

service_overrides = {
  home_assistant = {
    storage_class = "nfs-csi"
    enable_host_network = true  # For device discovery
  }
  openhab = {
    storage_class = "nfs-csi"
    enable_host_network = true  # For device discovery
  }
  homebridge = {
    storage_class = "nfs-csi"
    enable_host_network = true  # For HomeKit discovery
  }
}
```

### Production Configuration
```hcl
service_overrides = {
  home_assistant = {
    cpu_arch = "arm64"
    storage_class = "nfs-csi"
    persistent_disk_size = "10Gi"
    cpu_limit = "2000m"
    memory_limit = "2Gi"
    enable_host_network = true
    enable_persistence = true
  }
  openhab = {
    cpu_arch = "arm64"  # Works well on ARM64 with JVM optimizations
    storage_class = "nfs-csi"
    persistent_disk_size = "10Gi"
    addons_disk_size = "3Gi"
    conf_disk_size = "2Gi"
    cpu_limit = "2000m"  # Increased for Java runtime
    memory_limit = "2Gi" # Increased for Java heap
    cpu_request = "500m"
    memory_request = "512Mi"
    enable_host_network = true
    enable_persistence = true
    enable_karaf_console = false  # Disable unless needed for debugging
  }
  homebridge = {
    cpu_arch = "arm64"
    storage_class = "nfs-csi"
    persistent_disk_size = "3Gi"
    cpu_limit = "1000m"
    memory_limit = "1Gi"
    enable_host_network = true
    enable_persistence = true
  }
}
```

## Expected Startup Times

### Home Assistant
- **Initial startup**: 2-5 minutes
- **Ready for use**: 3-5 minutes
- **Startup probe window**: 10 minutes

### openHAB
- **Initial startup (ARM64)**: 8-12 minutes
- **Initial startup (AMD64)**: 5-8 minutes
- **Ready for use**: Add 1-2 minutes after port listening
- **Startup probe window**: 30 minutes (90 failures × 20s)
- **Why so long?**: Java runtime initialization, OSGi bundle loading, Karaf framework startup

### Homebridge
- **Initial startup**: 1-3 minutes
- **Ready for use**: 2-3 minutes
- **Startup probe window**: 10 minutes

## Next Steps

1. **Test deployment** in your environment
2. **Monitor pod status** for 10-15 minutes (30 minutes for openHAB)
3. **Check logs** if pods don't become ready within expected timeframe
4. **Access services** via ingress URLs once ready
5. **Configure integrations** in each service UI
6. **Set up backups** for persistent data

## Support

If issues persist:
1. Check pod logs: `kubectl logs <pod-name> -n <namespace>`
2. Check events: `kubectl get events -n <namespace> --sort-by='.lastTimestamp'`
3. Verify storage: `kubectl get pvc,pv -n <namespace>`
4. Review configuration: `kubectl describe deployment <name> -n <namespace>`
