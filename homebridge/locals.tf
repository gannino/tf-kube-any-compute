locals {
  # Architecture-based node selector
  node_selector = var.disable_arch_scheduling ? {} : {
    "kubernetes.io/arch" = var.cpu_arch
  }

  # Common labels
  common_labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/instance"   = var.name
    "app.kubernetes.io/component"  = "homebridge"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Ingress configuration
  ingress_config = {
    host         = "homebridge.${var.domain_name}"
    service_name = var.name
    service_port = 8581
    path         = "/"

    # TLS configuration based on cert resolver type
    tls_annotations = var.traefik_cert_resolver != "default" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = var.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${var.domain_name}"
    } : {}

    # Base annotations for ingress
    base_annotations = {
      "kubernetes.io/ingress.class"                           = "traefik"
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.pathmatcher"      = "PathPrefix"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = var.traefik_cert_resolver
    }
  }
}
