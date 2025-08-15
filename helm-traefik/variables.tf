
# ============================================================================
# HELM-TRAEFIK MODULE VARIABLES - STANDARDIZED PATTERNS
# ============================================================================
# Following Task 3 standardization:
# - Clear descriptions and types
# - Proper validation for critical inputs
# - Logical grouping of related variables
# ============================================================================

# ============================================================================
# CORE MODULE CONFIGURATION
# ============================================================================

variable "namespace" {
  description = "Kubernetes namespace for Traefik deployment"
  type        = string
  default     = "traefik-ingress-controller"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "name" {
  description = "Helm release name for Traefik"
  type        = string
  default     = "traefik"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Helm release name."
  }
}

variable "chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "traefik"
}

variable "chart_repo" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://helm.traefik.io/traefik"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTPS URL."
  }
}

variable "chart_version" {
  description = "Helm chart version"
  type        = string
  default     = "37.0.0"
}

# ============================================================================
# FEATURE CONFIGURATION
# ============================================================================

variable "enable_ingress" {
  description = "Enable ingress functionality for external access"
  type        = bool
  default     = false
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "persistent_disk_size" {
  description = "Size of persistent disk for Traefik data"
  type        = string
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.persistent_disk_size))
    error_message = "Disk size must be in format like '1Gi', '500Mi', etc."
  }
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "hostpath"
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "domain_name" {
  description = "Domain name for ingress resources"
  type        = string
  default     = ".local"
}

# ============================================================================
# RESOURCE CONFIGURATION
# ============================================================================

variable "cpu_arch" {
  description = "CPU architecture for node selection"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be 'amd64' or 'arm64'."
  }
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based node scheduling (useful for cluster-wide services)"
  type        = bool
  default     = false
}

variable "cpu_limit" {
  description = "CPU limit for Traefik containers"
  type        = string
  default     = "200m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in format like '200m' or '1'."
  }
}

variable "memory_limit" {
  description = "Memory limit for Traefik containers"
  type        = string
  default     = "256Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in format like '256Mi', '1Gi', etc."
  }
}

variable "cpu_request" {
  description = "CPU request for Traefik containers"
  type        = string
  default     = "100m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in format like '100m' or '1'."
  }
}

variable "memory_request" {
  description = "Memory request for Traefik containers"
  type        = string
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in format like '128Mi', '1Gi', etc."
  }
}

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

variable "le_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
  default     = ""

  validation {
    condition     = var.le_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.le_email))
    error_message = "Email must be a valid email address or empty."
  }
}

variable "traefik_cert_resolver" {
  description = "Traefik certificate resolver name"
  type        = string
  default     = "default"
}

# ============================================================================
# DNS PROVIDER CONFIGURATION
# ============================================================================

variable "dns_providers" {
  description = "DNS providers configuration for Let's Encrypt DNS challenge"
  type = object({
    # Primary DNS provider
    primary = optional(object({
      name   = string # hurricane, cloudflare, route53, digitalocean, etc.
      config = optional(map(string), {})
      }), {
      name   = "hurricane"
      config = {}
    })

    # Additional DNS providers for multi-domain setups
    additional = optional(list(object({
      name   = string
      config = map(string)
    })), [])
  })
  default = {
    primary = {
      name   = "hurricane"
      config = {}
    }
    additional = []
  }

  validation {
    condition = var.dns_providers == null || contains([
      "hurricane", "cloudflare", "route53", "digitalocean", "gandi",
      "namecheap", "godaddy", "ovh", "linode", "vultr", "hetzner"
    ], var.dns_providers.primary.name)
    error_message = "Primary DNS provider must be one of: hurricane, cloudflare, route53, digitalocean, gandi, namecheap, godaddy, ovh, linode, vultr, hetzner."
  }
}

variable "dns_challenge_config" {
  description = "DNS challenge configuration options"
  type = object({
    resolvers                 = optional(list(string), ["1.1.1.1:53", "8.8.8.8:53"])
    delay_before_check        = optional(string, "150s")
    disable_propagation_check = optional(bool, false)
    polling_interval          = optional(string, "5")
    propagation_timeout       = optional(string, "300")
    sequence_interval         = optional(string, "60")
    http_timeout              = optional(string, "30")
  })
  default = {}
}

variable "consul_url" {
  description = "Consul URL for service discovery and service mesh integration"
  type        = string
  default     = ""

  validation {
    condition     = var.consul_url == "" || can(regex("^https?://[a-zA-Z0-9.-]+(:[0-9]+)?", var.consul_url)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-]*[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9\\-]*[a-zA-Z0-9])?)*$", var.consul_url))
    error_message = "Consul URL must be a valid HTTP/HTTPS URL, Kubernetes service DNS name, or empty."
  }
}

# Legacy Hurricane Electric specific variables (for backward compatibility)
variable "hurricane_tokens" {
  description = "Hurricane Electric DNS tokens (DEPRECATED: use dns_providers configuration)"
  type        = string
  default     = ""
  sensitive   = true
}

# ============================================================================
# HELM DEPLOYMENT CONFIGURATION
# ============================================================================

variable "helm_timeout" {
  description = "Timeout for Helm deployment in seconds"
  type        = number
  default     = 600

  validation {
    condition     = var.helm_timeout >= 60 && var.helm_timeout <= 3600
    error_message = "Helm timeout must be between 60 and 3600 seconds."
  }
}

variable "helm_disable_webhooks" {
  description = "Disable webhooks for Helm release"
  type        = bool
  default     = true
}

variable "helm_skip_crds" {
  description = "Skip CRDs for Helm release"
  type        = bool
  default     = false
}

variable "helm_replace" {
  description = "Allow Helm to replace existing resources"
  type        = bool
  default     = false
}

variable "helm_force_update" {
  description = "Force resource updates if needed"
  type        = bool
  default     = false
}

variable "helm_cleanup_on_fail" {
  description = "Cleanup resources on failure"
  type        = bool
  default     = false
}

variable "helm_wait" {
  description = "Wait for Helm release to be ready"
  type        = bool
  default     = false
}

variable "helm_wait_for_jobs" {
  description = "Wait for Helm jobs to complete"
  type        = bool
  default     = false
}

variable "traefik_dashboard_password" {
  description = "Custom password for Traefik dashboard (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

# Traefik port configuration
variable "http_port" {
  description = "HTTP port for Traefik entrypoint"
  type        = number
  default     = 80

  validation {
    condition     = var.http_port > 0 && var.http_port <= 65535
    error_message = "HTTP port must be between 1 and 65535."
  }
}

variable "https_port" {
  description = "HTTPS port for Traefik entrypoint"
  type        = number
  default     = 443

  validation {
    condition     = var.https_port > 0 && var.https_port <= 65535
    error_message = "HTTPS port must be between 1 and 65535."
  }
}

variable "dashboard_port" {
  description = "Dashboard port for Traefik web UI"
  type        = number
  default     = 8080

  validation {
    condition     = var.dashboard_port > 0 && var.dashboard_port <= 65535
    error_message = "Dashboard port must be between 1 and 65535."
  }
}

variable "metrics_port" {
  description = "Metrics port for Traefik Prometheus metrics"
  type        = number
  default     = 9100

  validation {
    condition     = var.metrics_port > 0 && var.metrics_port <= 65535
    error_message = "Metrics port must be between 1 and 65535."
  }
}

variable "deployment_wait_timeout" {
  description = "Timeout in seconds to wait for Traefik deployment to be ready"
  type        = number
  default     = 300

  validation {
    condition     = var.deployment_wait_timeout > 0 && var.deployment_wait_timeout <= 1800
    error_message = "Deployment wait timeout must be between 1 and 1800 seconds."
  }
}

variable "ingress_api_version" {
  description = "API version for ingress resources"
  type        = string
  default     = "networking.k8s.io/v1"

  validation {
    condition     = can(regex("^[a-z0-9.-]+/v[0-9]+", var.ingress_api_version))
    error_message = "API version must be in format like 'networking.k8s.io/v1'."
  }
}

# ============================================================================
# TRACING CONFIGURATION
# ============================================================================

variable "enable_tracing" {
  description = "Enable distributed tracing in Traefik"
  type        = bool
  default     = false
}

variable "tracing_backend" {
  description = "Tracing backend to use (loki, jaeger)"
  type        = string
  default     = "loki"

  validation {
    condition     = contains(["loki", "jaeger"], var.tracing_backend)
    error_message = "Tracing backend must be either 'loki' or 'jaeger'."
  }
}

variable "loki_endpoint" {
  description = "Loki endpoint for tracing (when using loki backend)"
  type        = string
  default     = ""
}

variable "jaeger_endpoint" {
  description = "Jaeger endpoint for tracing (when using jaeger backend)"
  type        = string
  default     = ""
}

# ============================================================================
# CERTIFICATE RESOLVER CONFIGURATION
# ============================================================================

variable "cert_resolvers" {
  description = "Certificate resolver configurations - uses DNS provider names as resolver names"
  type = object({
    default = optional(object({
      challenge_type = optional(string, "http")
      dns_provider   = optional(string)
      }), {
      challenge_type = "http"
    })

    # DNS provider-based resolvers (e.g., hurricane, cloudflare, route53)
    custom = optional(map(object({
      challenge_type = string
      dns_provider   = optional(string)
    })), {})
  })
  default = {}

  validation {
    condition = var.cert_resolvers == null || alltrue([
      for resolver_name, resolver in merge(
        {
          default = try(var.cert_resolvers.default, { challenge_type = "http" })
        },
        try(var.cert_resolvers.custom, {})
      ) : contains(["http", "dns"], resolver.challenge_type)
    ])
    error_message = "Certificate resolver challenge_type must be either 'http' or 'dns'."
  }
}
