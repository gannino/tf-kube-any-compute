resource "kubernetes_namespace" "this" {
  metadata {
    name        = local.module_config.namespace
    labels      = local.common_labels
    annotations = local.common_labels
  }
}

# ============================================================================
# PRE-DESTROY HELM RELEASE METADATA DELETION
# ============================================================================
# This resource deletes Helm release metadata BEFORE the Helm release is
# destroyed, preventing Helm from running the problematic uninstall job.

resource "null_resource" "helm_release_remover" {
  # Use create_before_destroy to ensure this runs during destroy
  lifecycle {
    create_before_destroy = true
  }

  # Implicit dependency: references helm_release outputs in triggers
  # Create: helm_release → helm_release_remover
  # Destroy: helm_release_remover → helm_release
  triggers = {
    helm_release_name      = helm_release.this.name
    helm_release_namespace = helm_release.this.namespace
    release_name           = local.module_config.name
    release_namespace      = local.module_config.namespace
    kubeconfig_path        = local.kubeconfig_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      set -e
      if [ -n "${self.triggers.kubeconfig_path}" ]; then
        export KUBECONFIG="${self.triggers.kubeconfig_path}"
      fi

      echo "========================================"
      echo "LONGHORN DESTROY SEQUENCE STARTING"
      echo "========================================"

      # STEP 1: Delete webhooks FIRST (30s timeout)
      echo "[1/3] Deleting admission webhooks..."
      kubectl delete mutatingwebhookconfiguration longhorn-webhook-mutator --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete validatingwebhookconfiguration longhorn-webhook-validator --ignore-not-found=true --timeout=30s 2>/dev/null || true
      echo "✓ Webhooks deleted"

      # STEP 2: Fast Helm uninstall with --no-hooks (30s timeout)
      echo "[2/3] Running fast Helm uninstall (no hooks, 30s timeout)..."
      helm uninstall ${self.triggers.release_name} -n ${self.triggers.release_namespace} --no-hooks --timeout 30s 2>/dev/null || echo "  (Helm uninstall skipped or failed - continuing with cleanup)"

      # STEP 3: Delete Helm metadata (cleanup)
      echo "[3/3] Deleting Helm release metadata..."
      kubectl delete secret ${self.triggers.release_namespace}.${self.triggers.release_name} --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete secret ${self.triggers.release_namespace}.${self.triggers.release_name}.v1 --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete secret ${self.triggers.release_namespace}.${self.triggers.release_name}.v2 --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete configmap ${self.triggers.release_namespace}.${self.triggers.release_name} --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete configmap ${self.triggers.release_namespace}.${self.triggers.release_name}.v1 --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete configmap ${self.triggers.release_namespace}.${self.triggers.release_name}.v2 --ignore-not-found=true --timeout=30s 2>/dev/null || true

      echo "✓ Helm release cleanup completed"
      echo "========================================"
    EOT
  }
}

# ============================================================================
# CLEANUP RESOURCES FOR STUCK NAMESPACES
# ============================================================================

# Basic cleanup provisioner to handle stuck deletions (always runs)
# This MUST run AFTER helm_release is destroyed to clean up any resources
# that Helm uninstall couldn't delete due to finalizers
resource "null_resource" "cleanup" {
  # Use create_before_destroy to ensure cleanup runs BEFORE namespace deletion
  lifecycle {
    create_before_destroy = true
  }

  # Explicit dependency on helm_release to ensure cleanup runs AFTER Helm uninstall
  # This means during destroy: helm_release → cleanup → namespace
  triggers = {
    namespace           = local.module_config.namespace
    kubeconfig_path     = local.kubeconfig_path
    helm_release_name   = local.module_config.name
    helm_release_exists = "true"
  }

  # Ensure this runs after helm_release_remover AND helm_release
  depends_on = [null_resource.helm_release_remover, helm_release.this]

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      if [ -n "${self.triggers.kubeconfig_path}" ]; then
        export KUBECONFIG="${self.triggers.kubeconfig_path}"
      fi

      echo "========================================"
      echo "COMPREHENSIVE LONGHORN CLEANUP"
      echo "========================================"

      # PRE-FLIGHT SAFETY CHECKS
      echo "[SAFETY] Running pre-flight checks..."
      node_count=$(kubectl get nodes -o json 2>/dev/null | jq '.items | length' || echo "0")
      echo "  - Cluster has $node_count nodes (will be preserved)"
      echo "  - Only resources in namespace '${self.triggers.namespace}' will be affected"
      echo ""

      # STEP 0: Delete webhooks FIRST (they block deletion with finalizers)
      echo "[0/6] Deleting admission webhooks (critical - they block resource deletion)..."
      kubectl delete mutatingwebhookconfiguration longhorn-webhook-mutator --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete validatingwebhookconfiguration longhorn-webhook-validator --ignore-not-found=true --timeout=30s 2>/dev/null || true
      echo "  ✓ Webhooks deleted"

      # STEP 1: Delete custom resources FIRST (removes ownerReferences)
      echo "[1/5] Discovering and deleting Longhorn custom resources..."
      # Dynamically discover all Longhorn CRDs and clean up their instances
      # SAFETY: Use fully qualified resource names to avoid conflicts with core K8s resources
      kubectl get crd -o name 2>/dev/null | grep longhorn.io | while read crd; do
        # Extract full resource name with group (e.g., volumes.longhorn.io)
        resource_name=$(echo $crd | sed 's/.*\///') # volumes.longhorn.io

        # SAFETY CHECK #1: Verify CRD is namespaced (not cluster-scoped)
        crd_scope=$(kubectl get $crd -o jsonpath='{.spec.scope}' 2>/dev/null || echo "Namespaced")
        if [[ "$crd_scope" != "Namespaced" ]]; then
          echo "  - Skipping $resource_name (cluster-scoped CRD, handled by CRD deletion)"
          continue
        fi

        # SPECIAL HANDLING: nodes.longhorn.io shares name with core nodes
        # Must handle carefully: remove finalizers ONLY in target namespace
        if [[ "$resource_name" =~ ^nodes\.longhorn\.io$ ]]; then
          echo "  - Processing $resource_name (namespace-scoped only)..."
          kubectl get $resource_name -n ${self.triggers.namespace} -o name 2>/dev/null | while read res; do
            echo "    - Removing finalizers from $res"
            kubectl patch -n ${self.triggers.namespace} $res -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
            kubectl delete -n ${self.triggers.namespace} $res --ignore-not-found=true --timeout=30s 2>/dev/null || true
          done
          continue
        fi

        echo "  - Processing $resource_name..."
        # Use fully qualified name to ensure we only get Longhorn resources
        kubectl get $resource_name -n ${self.triggers.namespace} -o name 2>/dev/null | while read res; do
          kubectl patch -n ${self.triggers.namespace} $res -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
          kubectl delete -n ${self.triggers.namespace} $res --ignore-not-found=true --timeout=30s 2>/dev/null || true
        done
      done

      # STEP 2: Delete workloads (now orphaned since owners are gone)
      echo "[2/5] Deleting workloads..."
      kubectl delete deployment,daemonset,statefulset -n ${self.triggers.namespace} --all --ignore-not-found=true --timeout=60s 2>/dev/null || true

      # STEP 3: Force delete pods
      echo "[3/5] Force deleting pods..."
      kubectl delete pods -n ${self.triggers.namespace} --all --force --grace-period=0 --ignore-not-found=true --timeout=60s 2>/dev/null || true

      # STEP 4: Delete storage, CSI driver
      echo "[4/6] Deleting storage classes and CSI driver..."
      kubectl delete csidriver driver.longhorn.io --ignore-not-found=true --timeout=30s 2>/dev/null || true
      for sc in $(kubectl get storageclass -o name 2>/dev/null | grep longhorn); do
        kubectl patch $sc -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        kubectl delete $sc --ignore-not-found=true --timeout=30s 2>/dev/null || true
      done

      # STEP 5: Delete custom resource instances BEFORE deleting CRDs
      # This is critical because CRD deletion will try to delete instances,
      # and instances with finalizers will block CRD deletion
      echo "[5/6] Deleting Longhorn custom resource instances..."
      kubectl get crd -o name 2>/dev/null | grep longhorn.io | while read crd; do
        resource_name=$(echo $crd | sed 's/.*\///')
        crd_scope=$(kubectl get $crd -o jsonpath='{.spec.scope}' 2>/dev/null || echo "Namespaced")
        if [[ "$crd_scope" != "Namespaced" ]]; then
          continue
        fi
        # Delete all instances in the target namespace
        kubectl get $resource_name -n ${self.triggers.namespace} -o name 2>/dev/null | while read res; do
          kubectl delete -n ${self.triggers.namespace} $res --ignore-not-found=true --timeout=30s 2>/dev/null || true
        done
      done

      # STEP 6: Delete CRDs and remaining webhooks (now that instances are gone)
      echo "[6/6] Deleting CRDs and webhooks..."
      kubectl get crd -o name 2>/dev/null | grep longhorn.io | xargs -r kubectl delete --ignore-not-found=true --timeout=60s 2>/dev/null || true
      kubectl delete mutatingwebhookconfiguration,validatingwebhookconfiguration -l app.kubernetes.io/name=longhorn --ignore-not-found=true --timeout=30s 2>/dev/null || true

      echo "✓ Comprehensive cleanup completed!"
      echo "========================================"
    EOT
  }
}

# Force cleanup resource (opt-in via var.force_namespace_cleanup)
resource "null_resource" "force_namespace_cleanup" {
  count = var.force_namespace_cleanup ? 1 : 0

  triggers = {
    namespace       = var.namespace
    cleanup_timeout = var.cleanup_timeout
    kubeconfig_path = local.kubeconfig_path
  }

  # Ensure this runs after cleanup AND helm_release
  depends_on = [null_resource.cleanup, helm_release.this]

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      if [ -n "${self.triggers.kubeconfig_path}" ]; then
        export KUBECONFIG="${self.triggers.kubeconfig_path}"
      fi

      echo "Starting force Longhorn namespace cleanup for ${self.triggers.namespace}..."

      # PRE-FLIGHT SAFETY CHECKS
      echo "[SAFETY] Running pre-flight checks..."
      node_count=$(kubectl get nodes -o json 2>/dev/null | jq '.items | length' || echo "0")
      echo "  - Cluster has $node_count nodes (will be preserved)"
      echo "  - WARNING: Force cleanup will remove finalizers from resources"
      echo "  - Only resources in namespace '${self.triggers.namespace}' will be affected"
      echo ""

      # Force delete all workload resources
      kubectl delete deployment,daemonset,statefulset -n ${self.triggers.namespace} --all --force --grace-period=0 --timeout=60s 2>/dev/null || true
      kubectl delete pods -n ${self.triggers.namespace} --all --force --grace-period=0 --timeout=30s 2>/dev/null || true

      # Delete PVCs/PVs with Longhorn provisioner
      kubectl delete pvc -n ${self.triggers.namespace} --all --force --grace-period=0 --timeout=60s 2>/dev/null || true
      for pv in $(kubectl get pv -o name 2>/dev/null | grep longhorn); do
        kubectl patch $pv -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
        kubectl delete $pv --force --grace-period=0 --timeout=30s 2>/dev/null || true
      done

      # Delete all Longhorn custom resources with finalizer removal
      # Dynamically discover all Longhorn CRDs and clean up their instances
      # SAFETY: Use fully qualified resource names to avoid conflicts with core K8s resources
      kubectl get crd -o name 2>/dev/null | grep longhorn.io | while read crd; do
        # Extract full resource name with group (e.g., volumes.longhorn.io)
        resource_name=$(echo $crd | sed 's/.*\///')

        # SAFETY CHECK #1: Verify CRD is namespaced (not cluster-scoped)
        crd_scope=$(kubectl get $crd -o jsonpath='{.spec.scope}' 2>/dev/null || echo "Namespaced")
        if [[ "$crd_scope" != "Namespaced" ]]; then
          echo "  - Skipping $resource_name (cluster-scoped CRD, handled by CRD deletion)"
          continue
        fi

        # SPECIAL HANDLING: nodes.longhorn.io shares name with core nodes
        # Must handle carefully: remove finalizers ONLY in target namespace
        if [[ "$resource_name" =~ ^nodes\.longhorn\.io$ ]]; then
          echo "  - Processing $resource_name (namespace-scoped only)..."
          kubectl get $resource_name -n ${self.triggers.namespace} -o name 2>/dev/null | while read res; do
            echo "    - Removing finalizers from $res"
            kubectl patch -n ${self.triggers.namespace} $res -p '{"metadata":{"finalizers":[]}}' --type=merge || true
            kubectl delete $res -n ${self.triggers.namespace} --ignore-not-found=true --force --grace-period=0 --timeout=60s 2>/dev/null || true
          done
          continue
        fi

        kubectl get $resource_name -n ${self.triggers.namespace} -o name 2>/dev/null | xargs -r kubectl patch -n ${self.triggers.namespace} -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        kubectl delete $resource_name -n ${self.triggers.namespace} --all --ignore-not-found=true --force --grace-period=0 --timeout=60s 2>/dev/null || true
      done

      # Delete CSI driver
      kubectl delete csidriver driver.longhorn.io --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete storage classes
      kubectl get storageclass -o name 2>/dev/null | grep longhorn | xargs -r kubectl delete --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Delete custom resource instances BEFORE deleting CRDs (critical ordering)
      kubectl get crd -o name 2>/dev/null | grep longhorn.io | while read crd; do
        resource_name=$(echo $crd | sed 's/.*\///')
        crd_scope=$(kubectl get $crd -o jsonpath='{.spec.scope}' 2>/dev/null || echo "Namespaced")
        if [[ "$crd_scope" != "Namespaced" ]]; then
          continue
        fi
        kubectl get $resource_name -n ${self.triggers.namespace} -o name 2>/dev/null | xargs -r kubectl delete -n ${self.triggers.namespace} --ignore-not-found=true --timeout=30s 2>/dev/null || true
      done

      # Delete CRDs (now that instances are gone)
      kubectl get crd -o name 2>/dev/null | grep longhorn.io | xargs -r kubectl delete --ignore-not-found=true --timeout=60s 2>/dev/null || true

      # Delete webhooks
      kubectl delete mutatingwebhookconfiguration,validatingwebhookconfiguration -l app.kubernetes.io/name=longhorn --ignore-not-found=true --timeout=30s 2>/dev/null || true

      # Force remove namespace finalizers if stuck
      if kubectl get namespace ${self.triggers.namespace} 2>/dev/null | grep -q Terminating; then
        echo "Namespace stuck in Terminating, removing finalizers..."
        kubectl get namespace ${self.triggers.namespace} -o json 2>/dev/null | \
          jq 'del(.spec.finalizers)' | \
          kubectl replace --raw "/api/v1/namespaces/${self.triggers.namespace}/finalize" -f - 2>/dev/null || true
      fi

      echo "✓ Namespace ${self.triggers.namespace} force cleanup completed."
    EOT
  }
}

resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  create_namespace = false
  values = [
    templatefile("${path.module}/values.yaml.tpl", local.template_values)
  ]

  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  # Prevent uninstall issues
  disable_openapi_validation = true
  atomic                     = false

  # Lifecycle configuration to handle stuck deletions
  lifecycle {
    # Provider-controlled attributes are automatically ignored
  }

  depends_on = [
    kubernetes_namespace.this
  ]
}
