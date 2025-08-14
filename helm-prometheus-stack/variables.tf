variable "namespace" {
  type        = string
  description = "Namespace for Prometheus monitoring stack."
  default     = "monitoring-system"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name (lowercase alphanumeric and hyphens only)."
  }
}

variable "name" {
  type        = string
  description = "Helm release name for Prometheus stack."
  default     = "kube-prometheus-stack"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name (lowercase alphanumeric and hyphens only)."
  }
}

variable "chart_name" {
  type        = string
  description = "Helm chart name for Prometheus stack."
  default     = "kube-prometheus-stack"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL for Prometheus charts."
  default     = "https://prometheus-community.github.io/helm-charts"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTP or HTTPS URL."
  }
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for Prometheus stack."
  default     = "75.15.2"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "Chart version must follow semantic versioning format (e.g., 75.15.2)."
  }
}

variable "domain_name" {
  type        = string
  description = "Domain name for ingress resources."
  default     = ".local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "enable_prometheus_ingress" {
  type        = bool
  description = "Enable Prometheus ingress configuration."
  default     = false
}

variable "enable_prometheus_ingress_route" {
  type        = bool
  description = "Enable Prometheus ingress route configuration."
  default     = false
}

variable "enable_alertmanager_ingress" {
  type        = bool
  description = "Enable Alertmanager ingress configuration."
  default     = false
}

variable "prometheus_url" {
  type        = string
  description = "External Prometheus URL if applicable."
  default     = ""
}

variable "cpu_arch" {
  type        = string
  description = "CPU architecture for container images (amd64, arm64)."
  default     = "arm64"

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64' or 'arm64'."
  }
}

variable "prometheus_storage_size" {
  type        = string
  description = "Storage size for Prometheus persistent volume."
  default     = "8Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.prometheus_storage_size))
    error_message = "Storage size must be in Kubernetes format (e.g., 8Gi, 500Mi)."
  }
}

variable "alertmanager_storage_size" {
  type        = string
  description = "Storage size for Alertmanager persistent volume."
  default     = "2Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.alertmanager_storage_size))
    error_message = "Storage size must be in Kubernetes format (e.g., 2Gi, 500Mi)."
  }
}

# Grafana storage size removed - using standalone module

# Grafana variables removed - using standalone Grafana module

variable "cpu_limit" {
  type        = string
  description = "CPU limit for containers in the namespace."
  default     = "300m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in Kubernetes format (e.g., 300m, 1)."
  }
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for containers in the namespace."
  default     = "256Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in Kubernetes format (e.g., 256Mi, 1Gi)."
  }
}

variable "cpu_request" {
  type        = string
  description = "CPU request for containers in the namespace."
  default     = "50m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in Kubernetes format (e.g., 50m, 1)."
  }
}

variable "memory_request" {
  type        = string
  description = "Memory request for containers in the namespace."
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in Kubernetes format (e.g., 128Mi, 1Gi)."
  }
}

variable "enable_node_selector" {
  type        = bool
  description = "Enable node selectors for component scheduling."
  default     = false
}

variable "prometheus_storage_class" {
  type        = string
  description = "Storage class for Prometheus PVC (empty uses cluster default)."
  default     = ""
}

variable "alertmanager_storage_class" {
  type        = string
  description = "Storage class for Alertmanager PVC (empty uses cluster default)."
  default     = ""
}

variable "helm_timeout" {
  type        = number
  description = "Timeout for Helm deployment in seconds."
  default     = 600

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

variable "traefik_cert_resolver" {
  type        = string
  description = "Traefik certificate resolver for TLS."
  default     = "wildcard"

  validation {
    condition = contains([
      "default", "wildcard", "letsencrypt", "letsencrypt-staging",
      "hurricane", "cloudflare", "route53", "digitalocean", "gandi",
      "namecheap", "godaddy", "ovh", "linode", "vultr", "hetzner"
    ], var.traefik_cert_resolver)
    error_message = "Certificate resolver must be a valid resolver name (default, wildcard, letsencrypt, letsencrypt-staging, or a DNS provider name)."
  }
}

variable "monitoring_admin_password" {
  type        = string
  description = "Custom password for monitoring services basic auth (empty = auto-generate)"
  default     = ""
  sensitive   = true
}

variable "enable_monitoring_auth" {
  type        = bool
  description = "Enable basic authentication for monitoring services (requires Traefik CRDs - enable after first apply)"
  default     = false
}
