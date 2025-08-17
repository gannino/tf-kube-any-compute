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
