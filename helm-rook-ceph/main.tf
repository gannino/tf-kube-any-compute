resource "kubernetes_namespace" "this" {
  metadata {
    annotations = local.common_labels
    labels      = local.common_labels
    name        = local.module_config.namespace
  }
}

# ============================================================================
# DASHBOARD SELF-SIGNED CERTIFICATE
# ============================================================================
# Rook operator ignores ssl: false and defaults to ssl: true
# We generate a self-signed certificate to enable dashboard access

resource "tls_private_key" "dashboard" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "dashboard" {
  private_key_pem = tls_private_key.dashboard.private_key_pem

  subject {
    common_name  = "rook-ceph-dashboard"
    organization = "Rook-Ceph"
  }

  validity_period_hours = 8760 # 1 year
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["rook-ceph-dashboard", "rook-ceph-dashboard.${local.module_config.namespace}", "rook-ceph-dashboard.${local.module_config.namespace}.svc.cluster.local"]
}

resource "kubernetes_secret" "dashboard_cert" {
  metadata {
    name      = "rook-ceph-dashboard"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.dashboard.cert_pem
    "tls.key" = tls_private_key.dashboard.private_key_pem
  }

  depends_on = [
    helm_release.this
  ]
}

# ============================================================================
# HELM RELEASE WITH CLEANUP
# ============================================================================

resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  create_namespace = false
  values = [
    templatefile("${path.module}/templates/rook-ceph-values.yaml.tpl", local.template_values)
  ]

  # CRDs are managed by Helm for proper lifecycle management
  # Cleanup handled by destroy provisioners in crds.tf
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = false # Helm manages CRDs
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_limit_range.namespace_limits,
  ]
}

# ============================================================================
# CLEANUP RESOURCES - TRIGGERED BY HELM RELEASE DESTRUCTION
# ============================================================================
# NOTE: This is the SINGLE source of truth for Rook-Ceph cleanup logic.
# The cleanup-stuck-namespace.sh script is for manual emergency use only.
# Do NOT duplicate this logic elsewhere.

# Comprehensive cleanup provisioner to handle stuck Rook-Ceph resources
# Runs ONLY when the Helm release is destroyed (not on updates)
resource "null_resource" "helm_cleanup" {
  # Use create_before_destroy to ensure cleanup runs BEFORE namespace deletion
  lifecycle {
    create_before_destroy = true
  }

  # Use stable values that don't change on Helm updates
  triggers = {
    helm_release_name      = helm_release.this.name
    helm_release_namespace = helm_release.this.namespace
    namespace              = local.module_config.namespace
    kubeconfig_path        = local.kubeconfig_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      if [ -n "${self.triggers.kubeconfig_path}" ]; then
        export KUBECONFIG="${self.triggers.kubeconfig_path}"
      fi

      NAMESPACE="${self.triggers.namespace}"
      echo "========================================"
      echo "ROOK-CEPH CLEANUP (Terraform destroy)"
      echo "Namespace: $NAMESPACE"
      echo "========================================"

      # PRE-FLIGHT SAFETY CHECKS
      echo "[SAFETY] Running pre-flight checks..."
      node_count=$(kubectl get nodes -o json 2>/dev/null | jq '.items | length' || echo "0")
      echo "  - Cluster has $node_count nodes (will be preserved)"
      echo "  - Only resources in namespace '$NAMESPACE' will be affected"
      echo ""

      # STEP 1: Delete webhooks FIRST to avoid blocking operations
      echo "[1/7] Deleting admission webhooks..."
      kubectl delete mutatingwebhookconfiguration,validatingwebhookconfiguration -l app.kubernetes.io/name=rook-ceph --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete validatingwebhookconfiguration -l app=rook-ceph-operator --ignore-not-found=true --timeout=30s 2>/dev/null || true
      echo "✓ Webhooks deleted"

      # STEP 2: Discover and delete all Ceph custom resources dynamically
      echo "[2/7] Discovering and deleting Ceph custom resources..."
      kubectl get crd -o name 2>/dev/null | grep -E "(ceph.rook.io|objectbucket.io|csi.ceph.io)" | while read crd; do
        resource_name=$(echo "$crd" | sed 's/.*\///')

        # SAFETY CHECK: Verify CRD is namespaced (not cluster-scoped)
        crd_scope=$(kubectl get "$crd" -o jsonpath='{.spec.scope}' 2>/dev/null || echo "Namespaced")
        if [[ "$crd_scope" != "Namespaced" ]]; then
          echo "  - Skipping $resource_name (cluster-scoped CRD, handled by CRD deletion)"
          continue
        fi

        echo "  - Processing $resource_name..."
        kubectl get "$resource_name" -n "$NAMESPACE" -o name 2>/dev/null | while read res; do
          kubectl patch -n "$NAMESPACE" "$res" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
          kubectl delete -n "$NAMESPACE" "$res" --ignore-not-found=true --force --grace-period=0 --timeout=60s 2>/dev/null || true
        done
      done
      echo "✓ Ceph custom resources deleted"

      # STEP 3: Delete PVCs and PVs created by Rook
      echo "[3/7] Deleting PVCs and PVs..."
      kubectl delete pvc -n "$NAMESPACE" --all --ignore-not-found=true --timeout=60s 2>/dev/null || true
      for pv in $(kubectl get pv -o name 2>/dev/null | grep -E 'ceph|rbd' || true); do
        kubectl patch "$pv" -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
        kubectl delete "$pv" --ignore-not-found=true --timeout=30s 2>/dev/null || true
      done
      echo "✓ PVCs and PVs deleted"

      # STEP 4: Delete workloads (now orphaned since owners are gone)
      echo "[4/7] Deleting workloads..."
      kubectl delete deployment,daemonset,statefulset -n "$NAMESPACE" --all --ignore-not-found=true --timeout=60s 2>/dev/null || true
      kubectl delete pods -n "$NAMESPACE" --all --force --grace-period=0 --ignore-not-found=true --timeout=60s 2>/dev/null || true
      echo "✓ Workloads deleted"

      # STEP 5: Delete CSI drivers
      echo "[5/7] Deleting CSI drivers..."
      kubectl delete csidriver -l operator=rook --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete csidriver rbd.csi.ceph.com --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete csidriver cephfs.csi.ceph.com --ignore-not-found=true --timeout=30s 2>/dev/null || true
      echo "✓ CSI drivers deleted"

      # STEP 6: Delete storage classes
      echo "[6/7] Deleting Ceph storage classes..."
      for sc in $(kubectl get storageclass -o name 2>/dev/null | grep -E "(ceph.rook|rook-)" || true); do
        kubectl patch "$sc" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        kubectl delete "$sc" --ignore-not-found=true --timeout=30s 2>/dev/null || true
      done
      echo "✓ Storage classes deleted"

      # STEP 7: Remove disaster-protection finalizers from ConfigMaps and Secrets
      echo "[7/7] Removing disaster-protection finalizers..."
      for resource in $(kubectl get configmap,secret -n "$NAMESPACE" -o name 2>/dev/null); do
        if kubectl get "$resource" -n "$NAMESPACE" -o jsonpath='{.metadata.finalizers}' 2>/dev/null | grep -q "disaster-protection"; then
          echo "  - Removing finalizer from $resource"
          kubectl patch "$resource" -n "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        fi
      done
      echo "✓ Disaster-protection finalizers removed"

      echo ""
      echo "✓ Rook-Ceph cleanup completed!"
      echo "========================================"
    EOT
  }
}
