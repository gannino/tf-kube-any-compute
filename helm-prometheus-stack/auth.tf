# Basic Authentication for Prometheus and AlertManager
resource "random_password" "monitoring_password" {
  count   = var.monitoring_admin_password == "" ? 1 : 0
  length  = 12
  special = false
}

resource "kubernetes_secret" "monitoring_auth" {
  metadata {
    name      = "monitoring-basic-auth"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    users = "admin:${bcrypt(local.monitoring_password, 6)}"
  }

  type = "Opaque"
}

# Wait for Traefik CRDs to be available
resource "null_resource" "wait_for_traefik_crds" {
  count = var.enable_prometheus_ingress || var.enable_alertmanager_ingress ? 1 : 0
  
  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for Traefik Middleware CRD..."
      for i in {1..60}; do
        if kubectl get crd middlewares.traefik.io >/dev/null 2>&1; then
          echo "Traefik Middleware CRD is ready"
          exit 0
        fi
        echo "Waiting for Traefik CRDs... ($i/60)"
        sleep 5
      done
      echo "Timeout waiting for Traefik CRDs"
      exit 1
    EOT
  }
}

# TODO: Known issue with Traefik CRD dependencies during initial deployment
# The Middleware CRD may not be available when Terraform tries to create this resource
# Enable monitoring authentication after first successful apply when Traefik CRDs are ready
# Basic Auth Middleware for Prometheus and AlertManager
resource "kubernetes_manifest" "monitoring_auth_middleware" {
  count = var.enable_monitoring_auth && (var.enable_prometheus_ingress || var.enable_alertmanager_ingress) ? 1 : 0
  
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "monitoring-basic-auth"
      namespace = kubernetes_namespace.this.metadata[0].name
      labels    = local.common_labels
    }
    spec = {
      basicAuth = {
        secret = kubernetes_secret.monitoring_auth.metadata[0].name
      }
    }
  }
  
  depends_on = [null_resource.wait_for_traefik_crds]
}