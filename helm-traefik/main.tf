# ============================================================================
# HELM-TRAEFIK MODULE - STANDARDIZED RESOURCE DEPLOYMENT
# ============================================================================

# Create Traefik namespace
resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(
      {
        name = local.module_config.namespace
      },
      local.common_labels
    )
    labels = local.common_labels
    name   = local.module_config.namespace
  }
}

# Deploy Traefik Ingress Controller
resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  # Helm configuration using locals
  timeout          = local.helm_config.timeout
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  values = [
    templatefile("${path.module}/templates/traefik-values.yaml.tpl", local.template_values)
  ]

  depends_on = [
    kubernetes_secret.he_dns_token,
    kubernetes_namespace.this
  ]
}

# Wait for Traefik CRDs to be registered
resource "null_resource" "wait_for_traefik_crds" {
  depends_on = [helm_release.this]

  provisioner "local-exec" {
    command     = <<EOT
      echo "Waiting for Traefik CRDs to be registered..."

      # List of critical Traefik CRDs to wait for
      CRDS=(
        "ingressroutes.traefik.io"
        "ingressroutetcps.traefik.io"
        "ingressrouteudps.traefik.io"
        "middlewares.traefik.io"
        "tlsoptions.traefik.io"
        "tlsstores.traefik.io"
        "traefikservices.traefik.io"
        "serverstransports.traefik.io"
      )

      for crd in "$${CRDS[@]}"; do
        echo "Waiting for CRD: $crd"
        for i in {1..60}; do
          if kubectl get crd "$crd" >/dev/null 2>&1; then
            echo "CRD $crd is ready"
            break
          fi
          echo "Waiting for CRD $crd... ($i/60)"
          sleep 3
        done

        if ! kubectl get crd "$crd" >/dev/null 2>&1; then
          echo "Error: CRD $crd was not registered after waiting."
          exit 1
        fi
      done

      echo "All Traefik CRDs are ready!"

      # Final verification - ensure CRDs are actually usable
      echo "Verifying CRDs are functional..."
      kubectl api-resources --api-group=traefik.io >/dev/null 2>&1 || {
        echo "Error: Traefik CRDs are not properly registered in the API server"
        exit 1
      }
      echo "Traefik CRDs verification complete!"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# Wait for Traefik deployment to be ready
resource "null_resource" "wait_for_traefik_deployment" {
  depends_on = [null_resource.wait_for_traefik_crds]

  provisioner "local-exec" {
    command     = <<EOT
      echo "Waiting for Traefik deployment to be ready..."
      kubectl wait --for=condition=available --timeout=${local.module_config.deployment_wait_timeout}s deployment/${var.name} -n ${kubernetes_namespace.this.metadata[0].name}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "kubernetes_manifest" "traefik_ingress_class" {
  manifest = {
    apiVersion = var.ingress_api_version
    kind       = "IngressClass"
    metadata = {
      name = "traefik"
      annotations = {
        "ingressclass.kubernetes.io/is-default-class" = "true"
      }
    }
    spec = {
      controller = "traefik.io/ingress-controller"
    }
  }
  depends_on = [null_resource.wait_for_traefik_deployment]
}

data "kubernetes_service" "this" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}


module "ingress" {
  count                      = var.enable_ingress ? 1 : 0
  source                     = "./ingress"
  namespace                  = kubernetes_namespace.this.metadata[0].name
  domain_name                = var.domain_name
  service_name               = data.kubernetes_service.this.metadata[0].name
  traefik_cert_resolver      = var.traefik_cert_resolver
  traefik_dashboard_password = var.traefik_dashboard_password
  depends_on = [
    null_resource.wait_for_traefik_crds,
    null_resource.wait_for_traefik_deployment,
  ]
}

# Hurricane DNS secret
resource "random_password" "hurricane_token" {
  length  = 12
  special = false
}

resource "kubernetes_secret" "he_dns_token" {
  metadata {
    name      = "he-dns-tokens-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    tokens = "${var.domain_name}:${random_password.hurricane_token.result}"
  }
}
