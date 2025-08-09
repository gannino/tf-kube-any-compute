variable "namespace" {
  type        = string
  description = "Namespace for Grafana visualization system."
  default     = "grafana-system"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name (lowercase alphanumeric and hyphens only)."
  }
}

variable "name" {
  type        = string
  description = "Helm release name for Grafana."
  default     = "grafana"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name (lowercase alphanumeric and hyphens only)."
  }
}

variable "chart_name" {
  type        = string
  description = "Helm chart name for Grafana."
  default     = "grafana"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL for Grafana charts."
  default     = "https://grafana.github.io/helm-charts"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTP or HTTPS URL."
  }
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for Grafana."
  default     = "9.3.1"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "Chart version must follow semantic versioning format (e.g., 9.3.1)."
  }
}

variable "domain_name" {
  type        = string
  description = "Domain name for Grafana ingress."
  default     = ".local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}
variable "prometheus_url" {
  type        = string
  description = "Prometheus datasource URL for Grafana."
  default     = "build-prometheus-server"
}

variable "prometheus_namespace" {
  type        = string
  description = "Prometheus namespace for service discovery."
  default     = "prometheus_namespace"
}

variable "alertmanager_url" {
  type        = string
  description = "Alertmanager URL for datasource configuration."
  default     = "http://localhost:9093"

  validation {
    condition     = can(regex("^https?://", var.alertmanager_url))
    error_message = "Alertmanager URL must be a valid HTTP or HTTPS URL."
  }
}

variable "loki_url" {
  type        = string
  description = "Loki URL for datasource configuration."
  default     = "http://localhost:3100"

  validation {
    condition     = can(regex("^https?://", var.loki_url))
    error_message = "Loki URL must be a valid HTTP or HTTPS URL."
  }
}

variable "cpu_arch" {
  type        = string
  description = "CPU architecture for container images (amd64, arm64)."
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64' or 'arm64'."
  }
}

variable "cpu_limit" {
  type        = string
  description = "CPU limit for Grafana containers."
  default     = "200m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in Kubernetes format (e.g., 200m, 1)."
  }
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for Grafana containers."
  default     = "256Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in Kubernetes format (e.g., 256Mi, 1Gi)."
  }
}

variable "cpu_request" {
  type        = string
  description = "CPU request for Grafana containers."
  default     = "100m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in Kubernetes format (e.g., 100m, 1)."
  }
}

variable "memory_request" {
  type        = string
  description = "Memory request for Grafana containers."
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in Kubernetes format (e.g., 128Mi, 1Gi)."
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

# Storage configuration variables
variable "enable_persistence" {
  type        = bool
  description = "Enable persistent storage for Grafana."
  default     = true
}

variable "storage_class" {
  type        = string
  description = "Storage class for Grafana persistent volume."
  default     = "hostpath"
}

variable "storage_size" {
  type        = string
  description = "Size of the persistent volume for Grafana."
  default     = "2Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.storage_size))
    error_message = "Storage size must be in Kubernetes format (e.g., 2Gi, 500Mi)."
  }
}

variable "traefik_cert_resolver" {
  type        = string
  description = "Traefik certificate resolver for TLS."
  default     = "default"

  validation {
    condition     = contains(["default", "wildcard", "letsencrypt", "letsencrypt-staging"], var.traefik_cert_resolver)
    error_message = "Certificate resolver must be 'default', 'wildcard', 'letsencrypt', or 'letsencrypt-staging'."
  }
}

# Ingress handled by traefik-ingress.tf - variable removed

variable "grafana_admin_user" {
  type        = string
  description = "Grafana admin username."
  default     = "admin"

  validation {
    condition     = length(var.grafana_admin_user) >= 3
    error_message = "Admin username must be at least 3 characters long."
  }
}

variable "grafana_admin_password" {
  type        = string
  description = "Custom password for Grafana admin (empty = auto-generate)."
  default     = ""
  sensitive   = true

  validation {
    condition     = var.grafana_admin_password == "" || length(var.grafana_admin_password) >= 8
    error_message = "Admin password must be at least 8 characters long (or empty for auto-generation)."
  }
}

variable "grafana_node_name" {
  type        = string
  description = "Specific node name to run Grafana (for high-disk nodes)."
  default     = ""
}