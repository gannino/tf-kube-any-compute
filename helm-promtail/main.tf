# Create namespace if it doesn't exist
resource "kubernetes_namespace" "this" {
  metadata {
    annotations = local.common_labels
    labels      = local.common_labels
    name        = local.module_config.namespace
  }
}

# ServiceAccount for Promtail
resource "kubernetes_service_account" "this" {
  metadata {
    name      = local.rbac_config.service_account_name
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  depends_on = [kubernetes_namespace.this]
}

# ClusterRole for Promtail
resource "kubernetes_cluster_role" "this" {
  metadata {
    name   = local.rbac_config.cluster_role_name
    labels = local.common_labels
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods", "pods/log"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["daemonsets", "deployments", "replicasets"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "watch", "list"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
}

# ClusterRoleBinding for Promtail
resource "kubernetes_cluster_role_binding" "this" {
  metadata {
    name   = local.rbac_config.cluster_role_binding_name
    labels = local.common_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.this.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata[0].name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
}

# Main Helm deployment
resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  values = [
    templatefile("${path.module}/templates/promtail-values.yaml.tpl", local.template_values)
  ]

  # Helm deployment settings
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  timeout          = local.helm_config.timeout
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_service_account.this,
    kubernetes_cluster_role_binding.this,
    kubernetes_limit_range.namespace_limits
  ]
}