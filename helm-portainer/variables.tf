variable "namespace" {
  type        = string
  description = "Namespace for Portainer container management system."
  default     = "portainer-stack"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name (lowercase alphanumeric and hyphens only)."
  }
}

variable "name" {
  type        = string
  description = "Helm release name for Portainer."
  default     = "portainer"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name (lowercase alphanumeric and hyphens only)."
  }
}

variable "chart_name" {
  type        = string
  description = "Helm chart name for Portainer."
  default     = "portainer"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL for Portainer charts."
  default     = "https://portainer.github.io/k8s/"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTP or HTTPS URL."
  }
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for Portainer."
  default     = "1.0.69"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "Chart version must follow semantic versioning format (e.g., 1.0.69)."
  }
}

variable "domain_name" {
  type        = string
  description = "Domain name for Portainer ingress."
  default     = ".local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "enable_portainer_ingress" {
  type        = bool
  description = "Enable Portainer ingress configuration."
  default     = false
}

variable "enable_portainer_ingress_route" {
  type        = bool
  description = "Enable Portainer ingress route configuration."
  default     = false
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
  description = "CPU limit for Portainer containers."
  default     = "200m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in Kubernetes format (e.g., 200m, 1)."
  }
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for Portainer containers."
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in Kubernetes format (e.g., 128Mi, 1Gi)."
  }
}

variable "cpu_request" {
  type        = string
  description = "CPU request for Portainer containers."
  default     = "25m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in Kubernetes format (e.g., 25m, 1)."
  }
}

variable "memory_request" {
  type        = string
  description = "Memory request for Portainer containers."
  default     = "64Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in Kubernetes format (e.g., 64Mi, 1Gi)."
  }
}

variable "persistent_disk_size" {
  type        = string
  description = "Persistent disk size for Portainer data storage."
  default     = "4Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.persistent_disk_size))
    error_message = "Disk size must be in Kubernetes format (e.g., 4Gi, 500Mi)."
  }
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

variable "portainer_admin_password" {
  type        = string
  description = "Custom password for Portainer admin (empty = auto-generate)."
  default     = ""
  sensitive   = true

  validation {
    condition     = var.portainer_admin_password == null || var.portainer_admin_password == "" || length(var.portainer_admin_password) >= 8
    error_message = "Admin password must be at least 8 characters long (or empty for auto-generation)."
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

variable "storage_class" {
  type        = string
  description = "Storage class for Portainer persistent volume."
  default     = "hostpath"
}
