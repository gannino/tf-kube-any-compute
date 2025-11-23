# \ud83d\ude80 Automation Services Quick Start Guide

## Overview

Deploy Home Assistant, openHAB, and Homebridge on your Kubernetes cluster with optimized configurations for ARM64 and NFS storage.

---

## \u23f1\ufe0f Expected Startup Times

| Service | ARM64 | AMD64 | Notes |
|---------|-------|-------|-------|
| **Home Assistant** | 2-5 min | 2-4 min | Python-based, fast startup |
| **openHAB** | 8-12 min | 5-8 min | Java/OSGi, longer initialization |
| **Homebridge** | 1-3 min | 1-2 min | Node.js-based, quick startup |

> \u26a0\ufe0f **Important**: openHAB takes 8-12 minutes on ARM64 due to Java runtime initialization. This is **normal behavior**.

---

## \ud83d\udee0\ufe0f Quick Deploy

### 1. Minimal Configuration

```hcl
# terraform.tfvars
services = {
  home_assistant = true
  openhab        = true
  homebridge     = true
}
```

```bash
terraform apply
```

### 2. Monitor Deployment

```bash
# Watch all automation services
watch kubectl get pods -A | grep -E "(home-assistant|openhab|homebridge)"

# Monitor openHAB startup (takes longest)
kubectl logs -f -n prod-openhab-system -l app=prod-openhab

# Check when port is listening
kubectl exec -n prod-openhab-system deployment/prod-openhab -- netstat -tlnp | grep 8080
```

### 3. Access Services

```bash
# Get ingress URLs
kubectl get ingress -A | grep -E "(home-assistant|openhab|homebridge)"

# Example URLs:
# https://home-assistant.homelab.k3s.example.com
# https://openhab.homelab.k3s.example.com
# https://homebridge.homelab.k3s.example.com
```

---

## \ud83d\udcbb Production Configuration

### With NFS Storage

```hcl
# terraform.tfvars
services = {
  home_assistant = true
  openhab        = true
  homebridge     = true
}

service_overrides = {
  home_assistant = {
    cpu_arch             = "arm64"
    storage_class        = "nfs-csi"
    persistent_disk_size = "10Gi"
    enable_persistence   = true
    enable_host_network  = true  # For device discovery
    cpu_limit            = "2000m"
    memory_limit         = "2Gi"
  }

  openhab = {
    cpu_arch             = "arm64"
    storage_class        = "nfs-csi"
    persistent_disk_size = "10Gi"
    addons_disk_size     = "3Gi"
    conf_disk_size       = "2Gi"
    enable_persistence   = true
    enable_host_network  = true  # For device discovery
    cpu_limit            = "2000m"  # Java needs more resources
    memory_limit         = "2Gi"
    cpu_request          = "500m"
    memory_request       = "512Mi"
  }

  homebridge = {
    cpu_arch             = "arm64"
    storage_class        = "nfs-csi"
    persistent_disk_size = "3Gi"
    enable_persistence   = true
    enable_host_network  = true  # For HomeKit discovery
    cpu_limit            = "1000m"
    memory_limit         = "1Gi"
  }
}
```

---

## \ud83d\udc1b Common Issues & Solutions

### Home Assistant: 400 Bad Request

**Symptom**: Web UI shows "400 Bad Request" error

**Solution**: \u2705 Fixed in current version
- ConfigMap now mounts at `/config/configuration.yaml`
- Reverse proxy configuration corrected

**Verify**:
```bash
kubectl exec -n prod-home-assistant-system deployment/prod-home-assistant -- cat /config/configuration.yaml
```

---

### openHAB: Slow Startup

**Symptom**: Pod takes 8-12 minutes to become ready

**Solution**: \u2705 This is **normal behavior** on ARM64
- Java runtime initialization takes time
- OSGi bundles load sequentially
- Karaf framework startup is CPU-intensive

**Optimizations Applied**:
```bash
EXTRA_JAVA_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
KARAF_OPTS="-Xms256m -Xmx512m"
```

**Monitor Progress**:
```bash
# Watch logs for startup progress
kubectl logs -f -n prod-openhab-system -l app=prod-openhab

# Look for these messages:
# "Launching the openHAB runtime..."
# "Karaf started in XXXXms"
# "openHAB X.X.X is up and running"
```

---

### openHAB: NFS Permission Errors

**Symptom**: "Operation not permitted" errors in logs

**Solution**: \u2705 Fixed in current version
- Init container uses `chmod 777` instead of `chown -R`
- Works with NFS `root_squash` enabled
- PVC access mode changed to `ReadWriteMany`

**Verify**:
```bash
# Check PVC access mode
kubectl get pvc -n prod-openhab-system -o yaml | grep accessModes

# Should show:
# accessModes:
# - ReadWriteMany
```

---

### Homebridge: Connection Refused

**Symptom**: Startup probe fails with "connection refused"

**Solution**: \u2705 Fixed in current version
- Startup probe changed from HTTP to TCP
- Added 30-second initial delay
- Allows container to fully initialize

**Verify**:
```bash
# Check if port is listening
kubectl exec -n prod-homebridge-system deployment/prod-homebridge -- netstat -tlnp | grep 8581
```

---

## \ud83d\udcca Health Check Commands

### Check Pod Status
```bash
# All automation services
kubectl get pods -A | grep -E "(home-assistant|openhab|homebridge)"

# Specific service
kubectl get pods -n prod-openhab-system
```

### Check Logs
```bash
# Home Assistant
kubectl logs -n prod-home-assistant-system -l app=prod-home-assistant

# openHAB (follow mode)
kubectl logs -f -n prod-openhab-system -l app=prod-openhab

# Homebridge
kubectl logs -n prod-homebridge-system -l app=prod-homebridge
```

### Check Service Endpoints
```bash
# List all services
kubectl get svc -A | grep -E "(home-assistant|openhab|homebridge)"

# Check ingress
kubectl get ingress -A | grep -E "(home-assistant|openhab|homebridge)"
```

### Check Storage
```bash
# List PVCs
kubectl get pvc -A | grep -E "(home-assistant|openhab|homebridge)"

# Check PVC details
kubectl describe pvc -n prod-openhab-system
```

---

## \ud83d\udd0d Troubleshooting Script

```bash
#!/bin/bash
# Save as: check-automation-services.sh

echo "=== Automation Services Health Check ==="
echo ""

echo "1. Pod Status:"
kubectl get pods -A | grep -E "(home-assistant|openhab|homebridge)" | grep -v "Running.*1/1"
echo ""

echo "2. Recent Events:"
kubectl get events -A --sort-by='.lastTimestamp' | grep -E "(home-assistant|openhab|homebridge)" | tail -10
echo ""

echo "3. Storage Status:"
kubectl get pvc -A | grep -E "(home-assistant|openhab|homebridge)"
echo ""

echo "4. Service Endpoints:"
kubectl get ingress -A | grep -E "(home-assistant|openhab|homebridge)"
echo ""

echo "5. Resource Usage:"
kubectl top pods -A | grep -E "(home-assistant|openhab|homebridge)"
```

---

## \ud83d\udcda Additional Resources

- **Detailed Fixes**: [AUTOMATION-SERVICES-FIXES.md](AUTOMATION-SERVICES-FIXES.md)
- **Changelog**: [../../CHANGELOG.md](../../CHANGELOG.md)
- **Main README**: [../../README.md](../../README.md)
- **Testing Script**: [../../scripts/test-automation-services.sh](../../scripts/test-automation-services.sh)

---

## \u2705 Success Criteria

Your deployment is successful when:

1. **Pods are Running**
   ```bash
   kubectl get pods -A | grep -E "(home-assistant|openhab|homebridge)"
   # All should show: Running 1/1
   ```

2. **Services are Accessible**
   - Home Assistant: Web UI loads at ingress URL
   - openHAB: Web UI loads at ingress URL (after 8-12 min)
   - Homebridge: Web UI loads at ingress URL

3. **Storage is Bound**
   ```bash
   kubectl get pvc -A | grep -E "(home-assistant|openhab|homebridge)"
   # All should show: Bound
   ```

4. **No Error Events**
   ```bash
   kubectl get events -A | grep -E "(home-assistant|openhab|homebridge)" | grep -i error
   # Should return no results
   ```

---

## \ud83d\udcde Support

If you encounter issues:

1. **Check logs**: `kubectl logs -n <namespace> -l app=<service>`
2. **Check events**: `kubectl get events -n <namespace> --sort-by='.lastTimestamp'`
3. **Review documentation**: [AUTOMATION-SERVICES-FIXES.md](AUTOMATION-SERVICES-FIXES.md)
4. **Run health check**: `./scripts/test-automation-services.sh`
5. **Open issue**: [GitHub Issues](https://github.com/gannino/tf-kube-any-compute/issues)

---

**Last Updated**: January 2024
**Tested On**: Raspberry Pi 4 (ARM64), K3s 1.28+, NFS storage
**Status**: \u2705 Production Ready
