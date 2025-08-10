# ServiceAccount for Vault
data "kubernetes_service_account" "vault" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}

# Role with permissions to manage secrets
resource "kubernetes_role" "vault" {
  metadata {
    namespace = kubernetes_namespace.this.metadata[0].name
    name      = "vault-unsealer"
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get", "list", "patch", "update"]
  }
}

# RoleBinding
resource "kubernetes_role_binding" "vault" {
  metadata {
    name      = "vault-unsealer"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.vault.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = data.kubernetes_service_account.vault.metadata[0].name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
}
