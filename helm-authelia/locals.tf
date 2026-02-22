locals {
  # Kubeconfig detection (matches main provider.tf logic)
  kubeconfig_path = var.kubeconfig_path != "" ? var.kubeconfig_path : (
    var.ci_mode ? null : (
      can(file("~/.kube/${var.workspace_prefix}-config")) ? "~/.kube/${var.workspace_prefix}-config" : "~/.kube/config"
    )
  )

  module_config = {
    namespace = var.namespace
    name      = var.name
  }

  helm_config = {
    name             = var.name
    chart            = var.chart_name
    repository       = var.chart_repo
    version          = var.chart_version
    timeout          = var.helm_timeout
    disable_webhooks = var.helm_disable_webhooks
    skip_crds        = var.helm_skip_crds
    replace          = var.helm_replace
    force_update     = var.helm_force_update
    cleanup_on_fail  = var.helm_cleanup_on_fail
    wait             = var.helm_wait
    wait_for_jobs    = var.helm_wait_for_jobs
  }

  common_labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/component"  = "authentication"
  }

  # Generate secrets if not provided
  jwt_secret             = var.jwt_secret != "" ? var.jwt_secret : random_password.jwt_secret[0].result
  session_secret         = var.session_secret != "" ? var.session_secret : random_password.session_secret[0].result
  storage_encryption_key = var.storage_encryption_key != "" ? var.storage_encryption_key : random_password.storage_encryption_key[0].result

  # Architecture-based node affinity
  node_selector = var.disable_arch_scheduling ? {} : {
    "kubernetes.io/arch" = var.cpu_arch
  }

  # Ingress configuration
  ingress_config = {
    host         = "authelia.${var.domain_name}"
    service_name = var.name
    service_port = 9091

    # TLS configuration based on cert resolver type
    tls_annotations = var.traefik_cert_resolver == "wildcard" ? {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = var.domain_name
      "traefik.ingress.kubernetes.io/router.tls.domains.0.sans" = "*.${var.domain_name}"
      } : {
      "traefik.ingress.kubernetes.io/router.tls.domains.0.main" = "authelia.${var.domain_name}"
    }

    # Base annotations for ingress
    base_annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints"      = "websecure"
      "traefik.ingress.kubernetes.io/router.tls"              = "true"
      "traefik.ingress.kubernetes.io/router.tls.certresolver" = var.traefik_cert_resolver
    }
  }

  template_values = {
    name                  = var.name
    namespace             = var.namespace
    domain_name           = var.domain_name
    traefik_cert_resolver = var.traefik_cert_resolver
    replica_count         = var.replica_count
    cpu_limit             = var.cpu_limit
    memory_limit          = var.memory_limit
    cpu_request           = var.cpu_request
    memory_request        = var.memory_request
    pvc_name              = "${var.name}-storage"
    jwt_secret            = local.jwt_secret
    session_secret        = local.session_secret
    encryption_key        = local.storage_encryption_key
    node_selector         = local.node_selector
    # Auto-disable Redis when no address is available - prevents runtime crash
    redis_enabled = var.redis_enabled && (var.redis_address != "" || var.redis_module_reference != "")
    # Prefer redis_module_reference over redis_address, empty if neither provided
    redis_address           = var.redis_module_reference != "" ? var.redis_module_reference : (var.redis_address != "" ? var.redis_address : "")
    ldap_enabled            = var.ldap_enabled
    ldap_url                = var.ldap_url
    ldap_servername         = var.ldap_url != null ? replace(replace(var.ldap_url, "ldaps://", ""), "ldap://", "") : ""
    ldap_base_dn            = var.ldap_base_dn
    ldap_bind_dn            = var.ldap_bind_dn
    ldap_bind_password      = var.ldap_bind_password
    ldap_user_filter        = var.ldap_user_filter
    ldap_group_filter       = var.ldap_group_filter
    ldap_groups_filter      = var.ldap_groups_filter
    ldap_username_attribute = var.ldap_username_attribute
    ldap_secret_name        = var.ldap_enabled && var.ldap_bind_password != "" ? "${var.name}-ldap-credentials" : ""
    oidc_enabled            = var.oidc_enabled
    oidc_jwt_private_key    = var.oidc_enabled ? try(replace(tls_private_key.oidc_jwt[0].private_key_pem, "\\n", "\n"), "") : ""
    # Pre-process OIDC clients to add $plaintext$ prefix to client_secret
    oidc_clients = var.oidc_enabled ? {
      for client_name, client_config in var.oidc_clients :
      client_name => merge(client_config, {
        client_secret = join("", ["$plaintext$", client_config.client_secret])
      })
    } : {}
    default_policy           = var.default_policy
    totp_enabled             = var.totp_enabled
    duo_enabled              = var.duo_enabled
    duo_api_hostname         = var.duo_api_hostname
    duo_integration_key      = var.duo_integration_key
    duo_secret_key           = var.duo_secret_key
    enable_servicemonitor    = var.enable_servicemonitor
    servicemonitor_namespace = var.servicemonitor_namespace
    log_level                = var.log_level
    ldap_tls_skip_verify     = var.ldap_tls_skip_verify
  }
}

# Generate secrets if not provided
resource "random_password" "jwt_secret" {
  count   = var.jwt_secret == "" ? 1 : 0
  length  = 64
  special = false
}

resource "random_password" "session_secret" {
  count   = var.session_secret == "" ? 1 : 0
  length  = 64
  special = false
}

resource "random_password" "storage_encryption_key" {
  count   = var.storage_encryption_key == "" ? 1 : 0
  length  = 64
  special = false
}
