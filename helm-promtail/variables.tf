variable "namespace" {
  description = "Kubernetes namespace for Promtail deployment"
  type        = string
  default     = "loki-system"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "name" {
  description = "Helm release name"
  type        = string
  default     = "promtail"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name."
  }
}

# Service overrides for backward compatibility and customization
variable "service_overrides" {
  description = "Override default service configuration for backward compatibility"
  type = object({
    helm_config = optional(object({
      name      = optional(string)
      namespace = optional(string)
      resource_limits = optional(object({
        requests = optional(object({
          cpu    = optional(string)
          memory = optional(string)
        }))
        limits = optional(object({
          cpu    = optional(string)
          memory = optional(string)
        }))
      }))
    }))
    labels          = optional(map(string))
    template_values = optional(map(any))
  })
  default = {}
}

variable "chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "promtail"
}

variable "chart_repo" {
  description = "Helm repository URL"
  type        = string
  default     = "https://grafana.github.io/helm-charts"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTP/HTTPS URL."
  }
}

variable "chart_version" {
  description = "Helm chart version for Promtail"
  type        = string
  default     = "6.16.6"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "Chart version must be in semver format (x.y.z)."
  }
}

variable "loki_url" {
  description = "Loki endpoint URL for log forwarding"
  type        = string
  default     = "http://loki:3100"

  validation {
    condition     = can(regex("^https?://", var.loki_url))
    error_message = "Loki URL must be a valid HTTP/HTTPS URL."
  }
}

variable "additional_scrape_configs" {
  description = "Additional scrape configurations for Promtail"
  type = list(object({
    job_name = string
    static_configs = list(object({
      targets = list(string)
      labels  = map(string)
    }))
    pipeline_stages = optional(list(any), [])
  }))
  default = []
}

variable "resource_limits" {
  description = "Resource limits and requests for Promtail pods"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }

  validation {
    condition = (
      can(regex("^[0-9]+m?$", var.resource_limits.requests.cpu)) &&
      can(regex("^[0-9]+[KMGT]?i?$", var.resource_limits.requests.memory))
    )
    error_message = "Resource requests must be valid Kubernetes resource format."
  }
}

variable "node_selector" {
  description = "Node selector for Promtail pods"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for Promtail pods"
  type = list(object({
    key      = optional(string)
    operator = optional(string, "Equal")
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "affinity" {
  description = "Affinity rules for Promtail pods"
  type        = any
  default     = {}
}

variable "service_monitor_enabled" {
  description = "Enable ServiceMonitor for Prometheus scraping"
  type        = bool
  default     = true
}

variable "security_context" {
  description = "Security context for Promtail containers"
  type = object({
    run_as_user               = optional(number, 0)
    run_as_group              = optional(number, 0)
    run_as_non_root           = optional(bool, true)
    read_only_root_filesystem = optional(bool, true)
    privileged                = optional(bool, false)
  })
  default = {
    run_as_user               = 0
    run_as_group              = 0
    run_as_non_root           = true
    read_only_root_filesystem = true
    privileged                = false
  }
}

variable "log_level" {
  description = "Log level for Promtail"
  type        = string
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}

variable "persistence" {
  description = "Persistence configuration for Promtail positions"
  type = object({
    enabled       = optional(bool, true)
    size          = optional(string, "10Gi")
    storage_class = optional(string, "")
  })
  default = {
    enabled       = true
    size          = "10Gi"
    storage_class = ""
  }
}

# Legacy support - keeping old variables for backward compatibility
variable "cpu_arch" {
  description = "[DEPRECATED] CPU architecture - use node_selector instead"
  type        = string
  default     = "amd64"
}

variable "cpu_limit" {
  description = "[DEPRECATED] CPU limit - use resource_limits instead"
  type        = string
  default     = "100m"
}

variable "memory_limit" {
  description = "[DEPRECATED] Memory limit - use resource_limits instead"
  type        = string
  default     = "128Mi"
}

variable "cpu_request" {
  description = "[DEPRECATED] CPU request - use resource_limits instead"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "[DEPRECATED] Memory request - use resource_limits instead"
  type        = string
  default     = "64Mi"
}

# Helm configuration
variable "helm_timeout" {
  description = "Helm timeout"
  type        = number
  default     = 300
}

variable "helm_disable_webhooks" {
  description = "Disable webhooks"
  type        = bool
  default     = true
}

variable "helm_skip_crds" {
  description = "Skip CRDs"
  type        = bool
  default     = false
}

variable "helm_replace" {
  description = "Replace resources"
  type        = bool
  default     = false
}

variable "helm_force_update" {
  description = "Force update"
  type        = bool
  default     = true
}

variable "helm_cleanup_on_fail" {
  description = "Cleanup on fail"
  type        = bool
  default     = true
}

variable "helm_wait" {
  description = "Wait for deployment"
  type        = bool
  default     = true
}

variable "helm_wait_for_jobs" {
  description = "Wait for jobs"
  type        = bool
  default     = true
}

# Limit range configuration variables
variable "limit_range_enabled" {
  description = "Enable limit range for the namespace"
  type        = bool
  default     = true
}

variable "container_default_cpu" {
  description = "Default CPU for containers"
  type        = string
  default     = "200m"
}

variable "container_default_memory" {
  description = "Default memory for containers"
  type        = string
  default     = "256Mi"
}

variable "container_request_cpu" {
  description = "Default CPU request for containers"
  type        = string
  default     = "50m"
}

variable "container_request_memory" {
  description = "Default memory request for containers"
  type        = string
  default     = "64Mi"
}

variable "container_max_cpu" {
  description = "Maximum CPU for containers"
  type        = string
  default     = "1000m"
}

variable "container_max_memory" {
  description = "Maximum memory for containers"
  type        = string
  default     = "1Gi"
}

variable "pvc_max_storage" {
  description = "Maximum storage for PVCs"
  type        = string
  default     = "100Gi"
}

variable "pvc_min_storage" {
  description = "Minimum storage for PVCs"
  type        = string
  default     = "1Gi"
}
