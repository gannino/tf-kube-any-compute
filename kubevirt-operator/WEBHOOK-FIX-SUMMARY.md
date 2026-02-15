# KubeVirt Webhook Fix - Complete Implementation

## Problem

KubeVirt had a chicken-and-egg webhook validation problem:
- **Creation**: CR requires webhook validation, but webhooks are created AFTER CR is applied
- **Old Webhooks**: Previous installations leave stale webhook configurations that block new deployments

## Solution Implemented

### 1. Removed kubectl Provider Dependency
- Changed from `kubectl_manifest` to `null_resource` with kubectl commands
- Removed `gavinbunney/kubectl` provider requirement
- Simplified provider dependencies

### 2. Server-Side Apply
```bash
kubectl apply --server-side=true --force-conflicts -f -
```
- Bypasses client-side validation
- Handles ownership conflicts gracefully
- Works even when webhooks are not ready

### 3. Webhook Cleanup
Added automatic cleanup of stale webhooks before CR creation:
```bash
kubectl delete validatingwebhookconfiguration virt-operator-validator --ignore-not-found=true
kubectl delete validatingwebhookconfiguration virt-api-validator --ignore-not-found=true
kubectl delete mutatingwebhookconfiguration virt-api-mutator --ignore-not-found=true
```

### 4. Proper Wait Logic
- Wait for operator deployment to be available
- Wait for operator pods to be ready
- Clean up old webhooks before CR creation
- 10-second buffer after operator is ready

### 5. Fixed Destroy Provisioners
All destroy provisioners now use `self.triggers.kubeconfig_path` instead of `local.kubeconfig_path` to avoid dependency cycles.

## Files Modified

1. **kubevirt-operator/main.tf**
   - Changed all `kubectl_manifest` to `null_resource`
   - Added webhook cleanup logic
   - Fixed destroy provisioner references
   - Added kubeconfig_path to all triggers

2. **kubevirt-operator/version.tf**
   - Removed `kubectl` provider requirement
   - Kept only `kubernetes` and `null` providers

3. **kubevirt-operator/outputs.tf**
   - Updated depends_on references

4. **kubevirt-operator/templates/kubevirt-cr.yaml.tpl**
   - Removed bypass annotations (no longer needed with server-side apply)

5. **main.tf** (root)
   - Removed `kubectl` provider from kubevirt module

## Testing

```bash
# Deploy KubeVirt
terraform apply -var="services.kubevirt=true"

# Verify deployment
kubectl get pods -n prod-kubevirt-system
kubectl get kubevirt kubevirt -n prod-kubevirt-system

# Clean removal
terraform apply -var="services.kubevirt=false"
```

## Benefits

✅ **Fully Automated**: No manual intervention required
✅ **No Import Needed**: CR managed by Terraform from start
✅ **Clean Deletion**: Proper cleanup without webhook deadlocks
✅ **Idempotent**: Can be applied multiple times safely
✅ **Simpler**: Removed kubectl provider dependency
✅ **Handles Stale Webhooks**: Automatically cleans up old configurations

## Migration from Manual CR

If you have an existing manually-created CR:

```bash
# The new implementation will handle it automatically
# Old webhooks will be cleaned up
# CR will be recreated with server-side apply
terraform apply
```

No manual cleanup required - the module handles everything automatically.
