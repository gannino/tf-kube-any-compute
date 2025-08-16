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

# PVC for plugin storage
resource "kubernetes_persistent_volume_claim" "plugins_storage" {
  metadata {
    name      = "${var.name}-plugins-storage"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = local.module_config.storage_class
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
    kubernetes_secret.cloudflare_dns_credentials,
    kubernetes_secret.route53_dns_credentials,
    kubernetes_secret.digitalocean_dns_credentials,
    kubernetes_secret.gandi_dns_credentials,
    kubernetes_secret.namecheap_dns_credentials,
    kubernetes_secret.godaddy_dns_credentials,
    kubernetes_secret.ovh_dns_credentials,
    kubernetes_secret.linode_dns_credentials,
    kubernetes_secret.vultr_dns_credentials,
    kubernetes_secret.hetzner_dns_credentials,
    kubernetes_secret.additional_dns_credentials,
    kubernetes_namespace.this,
    kubernetes_persistent_volume_claim.plugins_storage
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


# Deploy middleware resources - only after CRDs are available
module "middleware" {
  source = "./middleware"

  namespace   = kubernetes_namespace.this.metadata[0].name
  name_prefix = var.name
  labels      = local.common_labels

  # Enable middleware resources only after CRDs are ready
  enable_middleware_resources = true

  # Authentication middleware configuration
  basic_auth = var.middleware_config.basic_auth
  ldap_auth  = var.middleware_config.ldap_auth

  # Security middleware configuration
  rate_limit   = var.middleware_config.rate_limit
  ip_whitelist = var.middleware_config.ip_whitelist

  # Default authentication middleware
  default_auth = var.middleware_config.default_auth

  depends_on = [
    null_resource.wait_for_traefik_crds,
    null_resource.wait_for_traefik_deployment,
  ]
}

module "ingress" {
  count                 = var.enable_ingress ? 1 : 0
  source                = "./ingress"
  namespace             = kubernetes_namespace.this.metadata[0].name
  domain_name           = var.domain_name
  service_name          = data.kubernetes_service.this.metadata[0].name
  traefik_cert_resolver = var.traefik_cert_resolver
  dashboard_middleware  = var.dashboard_middleware
  depends_on = [
    null_resource.wait_for_traefik_crds,
    null_resource.wait_for_traefik_deployment,
    module.middleware,
  ]
}

# Generate random token for Hurricane Electric (backward compatibility)
resource "random_password" "hurricane_token" {
  length  = 12
  special = false
}

# DNS provider secrets - Hurricane Electric (backward compatibility)
resource "kubernetes_secret" "he_dns_token" {
  count = try(var.dns_providers.primary.name, "hurricane") == "hurricane" ? 1 : 0

  metadata {
    name      = "he-dns-tokens-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    tokens = local.dns_config.hurricane_tokens
  }
}

# DNS provider secrets - Cloudflare
resource "kubernetes_secret" "cloudflare_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "cloudflare" ? 1 : 0

  metadata {
    name      = "cloudflare-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    email     = lookup(var.dns_providers.primary.config, "email", "")
    api-key   = lookup(var.dns_providers.primary.config, "api_key", "")
    dns-token = lookup(var.dns_providers.primary.config, "dns_token", "")
  }
}

# DNS provider secrets - AWS Route53
resource "kubernetes_secret" "route53_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "route53" ? 1 : 0

  metadata {
    name      = "route53-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    access-key-id     = lookup(var.dns_providers.primary.config, "access_key_id", "")
    secret-access-key = lookup(var.dns_providers.primary.config, "secret_access_key", "")
    region            = lookup(var.dns_providers.primary.config, "region", "us-east-1")
  }
}

# DNS provider secrets - DigitalOcean
resource "kubernetes_secret" "digitalocean_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "digitalocean" ? 1 : 0

  metadata {
    name      = "digitalocean-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    auth-token = lookup(var.dns_providers.primary.config, "auth_token", "")
  }
}

# DNS provider secrets - Gandi
resource "kubernetes_secret" "gandi_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "gandi" ? 1 : 0

  metadata {
    name      = "gandi-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    api-key = lookup(var.dns_providers.primary.config, "api_key", "")
  }
}

# DNS provider secrets - Namecheap
resource "kubernetes_secret" "namecheap_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "namecheap" ? 1 : 0

  metadata {
    name      = "namecheap-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    api-user = lookup(var.dns_providers.primary.config, "api_user", "")
    api-key  = lookup(var.dns_providers.primary.config, "api_key", "")
  }
}

# DNS provider secrets - GoDaddy
resource "kubernetes_secret" "godaddy_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "godaddy" ? 1 : 0

  metadata {
    name      = "godaddy-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    api-key    = lookup(var.dns_providers.primary.config, "api_key", "")
    api-secret = lookup(var.dns_providers.primary.config, "api_secret", "")
  }
}

# DNS provider secrets - OVH
resource "kubernetes_secret" "ovh_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "ovh" ? 1 : 0

  metadata {
    name      = "ovh-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    endpoint           = lookup(var.dns_providers.primary.config, "endpoint", "")
    application-key    = lookup(var.dns_providers.primary.config, "application_key", "")
    application-secret = lookup(var.dns_providers.primary.config, "application_secret", "")
    consumer-key       = lookup(var.dns_providers.primary.config, "consumer_key", "")
  }
}

# DNS provider secrets - Linode
resource "kubernetes_secret" "linode_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "linode" ? 1 : 0

  metadata {
    name      = "linode-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    token = lookup(var.dns_providers.primary.config, "token", "")
  }
}

# DNS provider secrets - Vultr
resource "kubernetes_secret" "vultr_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "vultr" ? 1 : 0

  metadata {
    name      = "vultr-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    api-key = lookup(var.dns_providers.primary.config, "api_key", "")
  }
}

# DNS provider secrets - Hetzner
resource "kubernetes_secret" "hetzner_dns_credentials" {
  count = try(var.dns_providers.primary.name, "hurricane") == "hetzner" ? 1 : 0

  metadata {
    name      = "hetzner-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    api-token = lookup(var.dns_providers.primary.config, "api_token", "")
  }
}

# Additional DNS provider secrets
resource "kubernetes_secret" "additional_dns_credentials" {
  for_each = { for idx, provider in try(var.dns_providers.additional, []) : idx => provider }

  metadata {
    name      = "${each.value.name}-dns-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  type = "Opaque"
  data = {
    for key, value in each.value.config : replace(lower(key), "_", "-") => value
  }
}
