# Random password for basic authentication (only when static password not provided)
resource "random_password" "basic_auth_password" {
  count   = var.basic_auth.enabled && var.basic_auth.static_password == "" ? 1 : 0
  length  = 16
  special = true
}

# Local value to determine the password to use
locals {
  basic_auth_password = var.basic_auth.enabled ? (
    var.basic_auth.static_password != "" ? var.basic_auth.static_password : random_password.basic_auth_password[0].result
  ) : ""
}

# Basic authentication secret
resource "kubernetes_secret" "basic_auth" {
  count = var.basic_auth.enabled ? 1 : 0

  metadata {
    name      = var.basic_auth.secret_name != "" ? var.basic_auth.secret_name : "${var.name_prefix}-basic-auth-secret"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    users = "${var.basic_auth.username}:${bcrypt(local.basic_auth_password, 10)}"
  }

  type = "Opaque"
}

# Basic Authentication Middleware - only create when CRDs are available
resource "kubectl_manifest" "basic_auth" {
  count = var.basic_auth.enabled && var.enable_middleware_resources ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-basic-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      basicAuth = {
        secret = kubernetes_secret.basic_auth[0].metadata[0].name
        realm  = var.basic_auth.realm
      }
    }
  })

  depends_on = [kubernetes_secret.basic_auth]
}
