variable "namespace" {
  type        = string
  description = "Namespace for kube-state-metrics."
  default     = "kube-state-metrics-system"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name (lowercase alphanumeric and hyphens only)."
  }
}

variable "name" {
  type        = string
  description = "Helm release name for kube-state-metrics."
  default     = "kube-state-metrics"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name (lowercase alphanumeric and hyphens only)."
  }
}

variable "chart_name" {
  type        = string
  description = "Helm chart name for kube-state-metrics."
  default     = "kube-state-metrics"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL for kube-state-metrics charts."
  default     = "https://prometheus-community.github.io/helm-charts"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTP or HTTPS URL."
  }
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for kube-state-metrics."
  default     = "5.15.2"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "Chart version must follow semantic versioning format (e.g., 5.15.2)."
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

variable "disable_arch_scheduling" {
  type        = bool
  description = "Disable architecture-based scheduling (useful for development)."
  default     = false
}

variable "cpu_limit" {
  type        = string
  description = "CPU limit for kube-state-metrics containers."
  default     = "100m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in Kubernetes format (e.g., 100m, 1)."
  }
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for kube-state-metrics containers."
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in Kubernetes format (e.g., 128Mi, 1Gi)."
  }
}

variable "cpu_request" {
  type        = string
  description = "CPU request for kube-state-metrics containers."
  default     = "50m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in Kubernetes format (e.g., 50m, 1)."
  }
}

variable "memory_request" {
  type        = string
  description = "Memory request for kube-state-metrics containers."
  default     = "64Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in Kubernetes format (e.g., 64Mi, 1Gi)."
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
