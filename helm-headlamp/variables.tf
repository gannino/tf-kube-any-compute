variable "namespace" {
  type        = string
  description = "Namespace for Headlamp Kubernetes UI."
  default     = "headlamp-system"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name (lowercase alphanumeric and hyphens only)."
  }
}

variable "name" {
  type        = string
  description = "Helm release name for Headlamp."
  default     = "headlamp"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name (lowercase alphanumeric and hyphens only)."
  }
}

variable "chart_name" {
  type        = string
  description = "Helm chart name for Headlamp."
  default     = "headlamp"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL for Headlamp charts."
  default     = "https://kubernetes-sigs.github.io/headlamp/"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTP or HTTPS URL."
  }
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for Headlamp."
  default     = "0.40.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "Chart version must follow semantic versioning format (e.g., 0.39.0)."
  }
}

variable "domain_name" {
  type        = string
  description = "Domain name for Headlamp ingress."
  default     = ".local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "enable_headlamp_ingress" {
  type        = bool
  description = "Enable Headlamp ingress configuration."
  default     = true
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
  description = "CPU limit for Headlamp containers."
  default     = "200m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in Kubernetes format (e.g., 200m, 1)."
  }
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for Headlamp containers."
  default     = "256Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in Kubernetes format (e.g., 256Mi, 1Gi)."
  }
}

variable "cpu_request" {
  type        = string
  description = "CPU request for Headlamp containers."
  default     = "100m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in Kubernetes format (e.g., 100m, 1)."
  }
}

variable "memory_request" {
  type        = string
  description = "Memory request for Headlamp containers."
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in Kubernetes format (e.g., 128Mi, 1Gi)."
  }
}

variable "persistent_disk_size" {
  type        = string
  description = "Persistent disk size for Headlamp data storage."
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.persistent_disk_size))
    error_message = "Disk size must be in Kubernetes format (e.g., 1Gi, 500Mi)."
  }
}

variable "enable_persistence" {
  type        = bool
  description = "Enable persistent storage for Headlamp configuration."
  default     = true
}

variable "enabled_plugins" {
  type        = list(string)
  description = "List of Headlamp plugins to enable (e.g., ['kubevirt'])."
  default     = []
}

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

variable "storage_class" {
  type        = string
  description = "Storage class for Headlamp persistent volume."
  default     = "hostpath"
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

variable "traefik_middleware" {
  type        = list(string)
  description = "List of Traefik middleware names to apply to Headlamp ingress."
  default     = []
}

variable "kubevirt_enabled" {
  type        = bool
  description = "Whether KubeVirt is enabled in the cluster (auto-enables KubeVirt plugin)."
  default     = false
}

variable "oidc_config" {
  description = "OIDC authentication configuration for Headlamp (Headlamp uses OIDC, not direct LDAP - see HEADLAMP-AUTHENTICATION-GUIDE.md)"
  type = object({
    enabled              = optional(bool, false)
    client_id            = optional(string, "")
    client_secret        = optional(string, "")
    issuer_url           = optional(string, "")
    scopes               = optional(string, "profile,email")
    use_access_token     = optional(bool, false)
    validator_client_id  = optional(string, "")
    validator_issuer_url = optional(string, "")
  })
  default = {}

  validation {
    condition = !try(var.oidc_config.enabled, false) || (
      try(var.oidc_config.client_id, "") != "" &&
      try(var.oidc_config.client_secret, "") != "" &&
      try(var.oidc_config.issuer_url, "") != ""
    )
    error_message = "When OIDC is enabled, client_id, client_secret, and issuer_url must be provided."
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
# RBAC PERMISSION LEVEL
# ============================================================================

variable "rbac_permission_level" {
  type        = string
  description = "RBAC permission level for Headlamp service account: 'cluster-admin' (full cluster access), 'admin' (full namespace access + cluster-wide read), 'edit' (modify namespace resources), 'view' (read-only). WARNING: 'cluster-admin' gives full control over the cluster."
  default     = "cluster-admin"

  validation {
    condition     = contains(["cluster-admin", "admin", "edit", "view"], var.rbac_permission_level)
    error_message = "RBAC permission level must be one of: cluster-admin, admin, edit, view."
  }
}

# ============================================================================
# TLS VERIFICATION CONFIGURATION
# ============================================================================

variable "enable_cluster_tls_verification" {
  type        = bool
  description = "Enable TLS verification for cluster API connections. When true, validates cluster certificates. When false, allows man-in-the-middle attacks (not recommended for production)."
  default     = true
}

variable "enable_oidc_tls_verification" {
  type        = bool
  description = "Enable TLS verification for OIDC provider connections. When true, validates OIDC provider certificates. When false, allows man-in-the-middle attacks (not recommended for production)."
  default     = true
}
