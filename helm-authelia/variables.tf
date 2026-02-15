variable "namespace" {
  type        = string
  description = "Namespace for Authelia authentication service."
  default     = "authelia-stack"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name (lowercase alphanumeric and hyphens only)."
  }
}

variable "name" {
  type        = string
  description = "Helm release name for Authelia."
  default     = "authelia"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name (lowercase alphanumeric and hyphens only)."
  }
}

variable "chart_name" {
  type        = string
  description = "Helm chart name for Authelia."
  default     = "authelia"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL for Authelia charts."
  default     = "https://charts.authelia.com"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTP or HTTPS URL."
  }
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for Authelia."
  default     = "0.10.49"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "Chart version must follow semantic versioning format (e.g., 0.10.49)."
  }
}

variable "domain_name" {
  type        = string
  description = "Domain name for Authelia ingress."
  default     = ".local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "cpu_arch" {
  type        = string
  description = "CPU architecture for container images (amd64, arm64)."

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64' or 'arm64'."
  }
}

variable "cpu_limit" {
  type        = string
  description = "CPU limit for Authelia containers."
  default     = "500m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in Kubernetes format (e.g., 500m, 1)."
  }
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for Authelia containers."
  default     = "512Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in Kubernetes format (e.g., 512Mi, 1Gi)."
  }
}

variable "cpu_request" {
  type        = string
  description = "CPU request for Authelia containers."
  default     = "100m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in Kubernetes format (e.g., 100m, 1)."
  }
}

variable "memory_request" {
  type        = string
  description = "Memory request for Authelia containers."
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in Kubernetes format (e.g., 128Mi, 1Gi)."
  }
}

variable "storage_class" {
  type        = string
  description = "Storage class for Authelia persistent volume."
  default     = "hostpath"
}

variable "persistent_disk_size" {
  type        = string
  description = "Persistent disk size for Authelia data storage."
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.persistent_disk_size))
    error_message = "Disk size must be in Kubernetes format (e.g., 1Gi, 500Mi)."
  }
}

variable "replica_count" {
  type        = number
  description = "Number of Authelia replicas."
  default     = 1

  validation {
    condition     = var.replica_count >= 1 && var.replica_count <= 3
    error_message = "Replica count must be between 1 and 3."
  }
}

variable "disable_arch_scheduling" {
  type        = bool
  description = "Disable architecture-based node scheduling."
  default     = false
}

variable "traefik_cert_resolver" {
  type        = string
  description = "Traefik certificate resolver for TLS."
  default     = "default"

  validation {
    condition = contains([
      "default", "wildcard", "letsencrypt", "letsencrypt-staging",
      "hurricane", "cloudflare", "route53", "digitalocean", "gandi",
      "namecheap", "godaddy", "ovh", "linode", "vultr", "hetzner"
    ], var.traefik_cert_resolver)
    error_message = "Certificate resolver must be a valid resolver name (default, wildcard, letsencrypt, letsencrypt-staging, or a DNS provider name)."
  }
}

variable "traefik_ingress_config" {
  description = "Traefik ingress configuration from Traefik module"
  type = object({
    class_name    = string
    annotations   = map(string)
    cert_resolver = string
    domain_name   = string
  })
  default = null
}

variable "redis_enabled" {
  type        = bool
  description = "Enable Redis for distributed session storage (recommended for HA). When true, either redis_address or redis_module_reference must be provided."
  default     = false
}

variable "redis_address" {
  type        = string
  description = "Redis server address for distributed session storage (e.g., 'redis-master.redis-system.svc.cluster.local'). Use redis_module_reference instead for automatic discovery. Can be empty when redis_enabled is false."
  default     = ""
}

variable "redis_module_reference" {
  type        = string
  description = "Reference to redis module output for automatic configuration (e.g., 'module.redis[0].service_host'). Overrides redis_address when set."
  default     = ""
}

variable "jwt_secret" {
  type        = string
  description = "JWT secret for Authelia (empty = auto-generate)."
  default     = ""
  sensitive   = true
}

variable "session_secret" {
  type        = string
  description = "Session secret for Authelia (empty = auto-generate)."
  default     = ""
  sensitive   = true
}

variable "storage_encryption_key" {
  type        = string
  description = "Storage encryption key for Authelia (empty = auto-generate)."
  default     = ""
  sensitive   = true
}

variable "ldap_enabled" {
  type        = bool
  description = "Enable LDAP authentication backend."
  default     = false
}

variable "ldap_url" {
  type        = string
  description = "LDAP server URL (e.g., ldap://ldap.example.com:389)."
  default     = ""
}

variable "ldap_base_dn" {
  type        = string
  description = "LDAP base DN for user search (e.g., dc=example,dc=com)."
  default     = ""
}

variable "ldap_bind_dn" {
  type        = string
  description = "LDAP bind DN for authentication (e.g., cn=admin,dc=example,dc=com)."
  default     = ""
  sensitive   = true
}

variable "ldap_bind_password" {
  type        = string
  description = "LDAP bind password for authentication."
  default     = ""
  sensitive   = true
}

variable "ldap_user_filter" {
  type        = string
  description = "LDAP user search filter (e.g., (uid={input}))."
  default     = "(uid={input})"
}

variable "ldap_group_filter" {
  type        = string
  description = "LDAP group search filter (e.g., (member={dn}))."
  default     = "(member={dn})"
}

variable "ldap_groups_filter" {
  type        = string
  description = "LDAP groups filter (e.g., (|(objectClass=groupOfNames)(objectClass=group)))."
  default     = "(|(objectClass=groupOfNames)(objectClass=group))"
}

variable "ldap_username_attribute" {
  type        = string
  description = "LDAP username attribute (e.g., uid)."
  default     = "uid"
}

variable "oidc_enabled" {
  type        = bool
  description = "Enable OIDC provider for other services (e.g., Headlamp, Grafana)."
  default     = false
}

variable "oidc_clients" {
  description = "Map of OIDC clients that will use Authelia as identity provider."
  type = map(object({
    client_id                  = string
    client_secret              = string
    authorization_policy       = optional(string, "two_factor")
    scopes                     = optional(list(string), ["openid", "profile", "email", "groups"])
    redirect_uris              = list(string)
    userinfo_signing_algorithm = optional(string, "none")
  }))
  default = {
    headlamp = {
      client_id     = "headlamp"
      client_secret = "headlamp-secret-change-me"
      redirect_uris = ["https://headlamp.k3s.annino.cloud/oauth2/callback"]
    }
  }
  validation {
    condition = alltrue([
      for client in var.oidc_clients : can(regex("^[a-z0-9-]+$", client.client_id))
    ])
    error_message = "All client IDs must be lowercase alphanumeric with hyphens only."
  }
}

variable "default_policy" {
  type        = string
  description = "Default access policy for Authelia (one_factor, two_factor, deny)."
  default     = "one_factor"

  validation {
    condition     = contains(["one_factor", "two_factor", "deny"], var.default_policy)
    error_message = "Default policy must be one of: one_factor, two_factor, deny"
  }
}

variable "totp_enabled" {
  type        = bool
  description = "Enable Time-based One-Time Password (TOTP) for 2FA."
  default     = true
}

variable "duo_enabled" {
  type        = bool
  description = "Enable Duo Security for 2FA."
  default     = false
}

variable "duo_api_hostname" {
  type        = string
  description = "Duo API hostname."
  default     = ""
}

variable "duo_integration_key" {
  type        = string
  description = "Duo integration key."
  default     = ""
  sensitive   = true
}

variable "duo_secret_key" {
  type        = string
  description = "Duo secret key."
  default     = ""
  sensitive   = true
}

# Helm configuration variables
variable "helm_timeout" {
  type        = number
  description = "Timeout for Helm deployment in seconds."
  default     = 300

  validation {
    condition     = var.helm_timeout > 0 && var.helm_timeout <= 3600
    error_message = "Helm timeout must be between 1 and 3600 seconds."
  }
}

variable "helm_disable_webhooks" {
  type        = bool
  description = "Disable webhooks for Helm release."
  default     = false
}

variable "helm_skip_crds" {
  type        = bool
  description = "Skip CRDs for Helm release."
  default     = false
}

variable "helm_replace" {
  type        = bool
  description = "Allow Helm to replace existing resources."
  default     = false
}

variable "helm_force_update" {
  type        = bool
  description = "Force resource updates if needed."
  default     = false
}

variable "helm_cleanup_on_fail" {
  type        = bool
  description = "Cleanup resources on deployment failure."
  default     = false
}

variable "helm_wait" {
  type        = bool
  description = "Wait for Helm release to be ready."
  default     = false
}

variable "helm_wait_for_jobs" {
  type        = bool
  description = "Wait for Helm jobs to complete."
  default     = false
}

variable "enable_servicemonitor" {
  type        = bool
  description = "Enable Prometheus ServiceMonitor for Authelia metrics."
  default     = false
}

variable "servicemonitor_namespace" {
  type        = string
  description = "Namespace for ServiceMonitor (typically where Prometheus Operator is deployed)."
  default     = "monitoring"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.servicemonitor_namespace))
    error_message = "ServiceMonitor namespace must be a valid Kubernetes namespace name (lowercase alphanumeric and hyphens only)."
  }
}

# Namespace cleanup variables
variable "force_namespace_cleanup" {
  type        = bool
  description = "Force cleanup of namespace if deletion gets stuck. WARNING: Only use when namespace is stuck in Terminating phase."
  default     = false

  validation {
    condition     = var.force_namespace_cleanup == false || var.force_namespace_cleanup == true
    error_message = "Force cleanup must be explicitly set to true when needed."
  }
}

variable "cleanup_timeout" {
  type        = string
  description = "Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s)."
  default     = "10m"

  validation {
    condition     = can(regex("^[0-9]+[smh]$", var.cleanup_timeout))
    error_message = "Timeout must be in Kubernetes duration format (e.g., 5m, 10m, 30s)."
  }
}

variable "workspace_prefix" {
  type        = string
  description = "Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev')."
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.workspace_prefix))
    error_message = "Workspace prefix must be lowercase alphanumeric with hyphens only."
  }
}

variable "ci_mode" {
  type        = bool
  description = "Running in CI mode (kubeconfig handled externally)."
  default     = false
}

variable "kubeconfig_path" {
  type        = string
  description = "Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig."
  default     = ""
}

# ============================================================================
# LOGGING AND DEBUG CONFIGURATION
# ============================================================================

variable "log_level" {
  type        = string
  description = "Authelia log level: trace, debug, info, warn, or error. Debug level may expose sensitive information in logs."
  default     = "info"

  validation {
    condition     = contains(["trace", "debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: trace, debug, info, warn, error."
  }
}

variable "ldap_tls_skip_verify" {
  type        = bool
  description = "Skip TLS certificate verification for LDAP connections. When false (recommended), validates LDAP server certificates. When true, allows man-in-the-middle attacks."
  default     = false
}
