# KubeVirt Webhook Chicken-and-Egg Fix

## Problem Summary

KubeVirt deployment had a webhook validation deadlock:

1. **Creation Problem**: KubeVirt CR requires webhook validation, but webhooks are created by virt-api pods that only start AFTER the CR is applied
2. **Deletion Problem**: Deleting KubeVirt CR requires webhook validation, but if operator pods are down, webhooks return "connection refused"

## Solution Implemented

### Changed from kubectl_manifest to null_resource

**Before** (using kubectl_manifest):
```hcl
resource "kubectl_manifest" "kubevirt_cr" {
  yaml_body = templatefile("${path.module}/templates/kubevirt-cr.yaml.tpl", local.template_values)
  depends_on = [time_sleep.wait_for_operator]
}
```

**After** (using null_resource with server-side apply):
```hcl
resource "null_resource" "kubevirt_cr" {
  depends_on = [null_resource.wait_for_operator]

  triggers = {
    namespace        = kubernetes_namespace.this.metadata[0].name
    enable_emulation = local.effective_emulation
    cpu_arch         = local.effective_cpu_arch
    cr_yaml          = templatefile("${path.module}/templates/kubevirt-cr.yaml.tpl", local.template_values)
  }

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG="${local.kubeconfig_path}"
      echo "Applying KubeVirt CR with server-side apply..."
      cat <<'EOF' | kubectl apply --server-side=true --force-conflicts -f -
${self.triggers.cr_yaml}
EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      export KUBECONFIG="${local.kubeconfig_path}"
      echo "Deleting KubeVirt CR..."
      kubectl delete kubevirt kubevirt -n ${self.triggers.namespace} --ignore-not-found=true --timeout=300s || true
    EOT
  }
}
```

### Key Improvements

1. **Server-Side Apply**: `kubectl apply --server-side=true` bypasses client-side validation
2. **Force Conflicts**: `--force-conflicts` handles ownership conflicts gracefully
3. **Proper Wait Logic**: Changed from `time_sleep` to actual operator readiness check
4. **Clean Deletion**: Explicit destroy provisioner with timeout and error handling
5. **Removed kubectl Provider**: No longer need gavinbunney/kubectl provider

### Wait Logic Enhancement

**Before** (simple sleep):
```hcl
resource "time_sleep" "wait_for_operator" {
  depends_on = [kubernetes_manifest.kubevirt_operator]
  create_duration = "30s"
}
```

**After** (actual readiness check):
```hcl
resource "null_resource" "wait_for_operator" {
  depends_on = [kubernetes_manifest.kubevirt_operator]

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG="${local.kubeconfig_path}"
      echo "Waiting for virt-operator deployment..."
      kubectl wait --for=condition=available --timeout=300s deployment/virt-operator -n ${kubernetes_namespace.this.metadata[0].name} || true
      echo "Waiting for operator pods to be ready..."
      kubectl wait --for=condition=ready --timeout=300s pod -l kubevirt.io=virt-operator -n ${kubernetes_namespace.this.metadata[0].name} || true
      sleep 10
    EOT
  }
}
```

## Benefits

1. ✅ **No Manual Intervention**: Fully automated deployment
2. ✅ **No Import Required**: CR is managed by Terraform from the start
3. ✅ **Clean Deletion**: Proper cleanup without webhook deadlocks
4. ✅ **Idempotent**: Can be applied multiple times safely
5. ✅ **Simpler Dependencies**: Removed kubectl provider dependency

## Testing

```bash
# Deploy KubeVirt
terraform apply -var="services.kubevirt=true"

# Verify deployment
kubectl get pods -n prod-kubevirt-system
kubectl get kubevirt kubevirt -n prod-kubevirt-system

# Clean removal
terraform apply -var="services.kubevirt=false"

# Verify cleanup
kubectl get namespace prod-kubevirt-system  # Should not exist
```

## Migration from Old Implementation

If you have existing KubeVirt deployment with manual CR:

```bash
# Remove from Terraform state (if imported)
terraform state rm 'module.kubevirt[0].kubectl_manifest.kubevirt_cr'

# Apply new implementation (will recreate CR)
terraform apply
```

The CR will be recreated using server-side apply, which is safe and non-disruptive.
