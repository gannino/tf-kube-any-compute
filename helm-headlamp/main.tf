resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(local.common_labels, {
      name = var.namespace
    })
    labels = local.common_labels
    name   = var.namespace
  }

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    delete = var.cleanup_timeout
  }
}

# Service Account for Headlamp
resource "kubernetes_service_account" "headlamp_admin" {
  metadata {
    name      = "headlamp-admin"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  automount_service_account_token = true
}

# ClusterRole for Headlamp with configurable permission level
resource "kubernetes_cluster_role" "headlamp" {
  metadata {
    name = var.rbac_permission_level == "cluster-admin" ? "headlamp-cluster-admin" : "headlamp-${var.rbac_permission_level}"
    labels = {
      "app.kubernetes.io/name"       = "headlamp"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "k8s-infrastructure"
    }
  }

  dynamic "rule" {
    for_each = var.rbac_permission_level == "cluster-admin" ? [1] : []
    content {
      api_groups = ["*"]
      resources  = ["*"]
      verbs      = ["*"]
    }
  }

  # Admin level: full namespace access + cluster-wide read access
  dynamic "rule" {
    for_each = var.rbac_permission_level == "admin" ? [1] : []
    content {
      api_groups = ["*"]
      resources  = ["*"]
      verbs      = ["get", "list", "watch"]
    }
  }

  dynamic "rule" {
    for_each = var.rbac_permission_level == "admin" ? [1] : []
    content {
      api_groups = ["", "apps", "batch", "networking.k8s.io", "extensions"]
      resources  = ["*"]
      verbs      = ["*"]
    }
  }

  # Edit level: modify namespace resources (no RBAC changes)
  dynamic "rule" {
    for_each = var.rbac_permission_level == "edit" ? [1] : []
    content {
      api_groups = ["", "apps", "batch", "networking.k8s.io", "extensions"]
      resources  = ["configmaps", "endpoints", "persistentvolumeclaims", "pods", "pods/exec", "pods/log", "pods/portforward", "replicationcontrollers", "replicasets", "statefulsets", "daemonsets", "deployments", "services", "ingresses"]
      verbs      = ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
    }
  }

  dynamic "rule" {
    for_each = var.rbac_permission_level == "edit" ? [1] : []
    content {
      api_groups = ["", "apps", "batch"]
      resources  = ["jobs", "cronjobs"]
      verbs      = ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
    }
  }

  # View level: read-only access
  dynamic "rule" {
    for_each = var.rbac_permission_level == "view" ? [1] : []
    content {
      api_groups = ["", "apps", "batch", "networking.k8s.io", "extensions"]
      resources  = ["*"]
      verbs      = ["get", "list", "watch"]
    }
  }
}

# ClusterRoleBinding to bind headlamp-admin SA to ClusterRole
resource "kubernetes_cluster_role_binding" "headlamp_admin" {
  metadata {
    name = "headlamp-admin"
    labels = {
      "app.kubernetes.io/name"       = "headlamp"
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "k8s-infrastructure"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.headlamp.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.headlamp_admin.metadata[0].name
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  depends_on = [
    kubernetes_cluster_role.headlamp,
    kubernetes_service_account.headlamp_admin
  ]
}

# Headlamp values template using standardized template values
locals {
  headlamp_values = templatefile("${path.module}/templates/headlamp-values.yaml.tpl", local.template_values)
}

# Install helm release Headlamp
resource "helm_release" "this" {
  name       = var.name
  chart      = local.helm_config.chart
  repository = local.helm_config.repository
  version    = local.helm_config.version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [
    local.headlamp_values
  ]

  # Helm deployment configuration using locals
  disable_webhooks = var.helm_disable_webhooks
  skip_crds        = var.helm_skip_crds
  replace          = var.helm_replace
  force_update     = var.helm_force_update
  cleanup_on_fail  = var.helm_cleanup_on_fail
  timeout          = var.helm_timeout
  wait             = var.helm_wait
  wait_for_jobs    = var.helm_wait_for_jobs

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_service_account.headlamp_admin,
    kubernetes_cluster_role.headlamp,
    kubernetes_cluster_role_binding.headlamp_admin
  ]
}

# Force cleanup resource for stuck namespaces (handles KubeVirt subresources)
resource "null_resource" "force_namespace_cleanup" {
  count = var.force_namespace_cleanup ? 1 : 0

  triggers = {
    namespace       = var.namespace
    cleanup_timeout = var.cleanup_timeout
    kubeconfig_path = local.kubeconfig_path
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      # Set KUBECONFIG from trigger
      export KUBECONFIG="$${KUBECONFIG_PATH}"

      # Wait for namespace to enter terminating state
      echo "Waiting for namespace to enter terminating phase..."
      timeout 300 bash -c "until kubectl get namespace $$NAMESPACE -o jsonpath='{.status.phase}' | grep -q 'Terminating'; do sleep 2; done"

      # Handle KubeVirt stale subresources
      echo "Checking for KubeVirt stale subresources..."
      kubectl api-resources --api-group=subresources.kubevirt.io 2>/dev/null && {
        echo "Cleaning up stale KubeVirt subresources..."
        kubectl delete apiservice v1alpha3.subresources.kubevirt.io --ignore-not-found=true || true
        kubectl delete apiservice v1.subresources.kubevirt.io --ignore-not-found=true || true
      }

      # Force remove namespace finalizers
      echo "Force removing namespace finalizers..."
      kubectl get namespace $$NAMESPACE -o json | \
        jq 'del(.spec.finalizers)' | \
        kubectl replace --raw "/api/v1/namespaces/$$NAMESPACE/finalize" -f - --timeout=$$CLEANUP_TIMEOUT

      # Verify namespace is deleted
      echo "Verifying namespace deletion..."
      timeout 300 bash -c "until ! kubectl get namespace $$NAMESPACE 2>/dev/null; do sleep 2; done"
      echo "Namespace $$NAMESPACE successfully cleaned up."
    EOT

    environment = {
      KUBECONFIG_PATH = self.triggers.kubeconfig_path
      NAMESPACE       = self.triggers.namespace
      CLEANUP_TIMEOUT = self.triggers.cleanup_timeout
    }
  }

  depends_on = [
    helm_release.this
  ]
}
