# ============================================================================
# HELM-KUBEVIRT MODULE VARIABLES
# ============================================================================

variable "namespace" {
  description = "Kubernetes namespace for KubeVirt deployment"
  type        = string
  default     = "kubevirt"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "name" {
  description = "Helm release name for KubeVirt"
  type        = string
  default     = "kubevirt"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Helm release name."
  }
}

variable "chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "kubevirt"
}

variable "chart_repo" {
  description = "Deprecated - KubeVirt uses operator manifests"
  type        = string
  default     = ""
}

variable "chart_version" {
  description = "KubeVirt version"
  type        = string
  default     = "v1.1.1"
}

variable "cdi_version" {
  description = "CDI (Containerized Data Importer) version for DataVolume support"
  type        = string
  default     = "v1.60.3"
}

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
  description = "Disable architecture-based node scheduling"
  type        = bool
  default     = false
}

variable "cpu_limit" {
  description = "CPU limit for KubeVirt containers"
  type        = string
  default     = "1000m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in format like '1000m' or '1'."
  }
}

variable "memory_limit" {
  description = "Memory limit for KubeVirt containers"
  type        = string
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in format like '1Gi', '512Mi', etc."
  }
}

variable "cpu_request" {
  description = "CPU request for KubeVirt containers"
  type        = string
  default     = "500m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in format like '500m' or '1'."
  }
}

variable "memory_request" {
  description = "Memory request for KubeVirt containers"
  type        = string
  default     = "512Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in format like '512Mi', '1Gi', etc."
  }
}

variable "enable_emulation" {
  description = "Enable software emulation for nested virtualization"
  type        = bool
  default     = true
}

variable "enable_servicemonitor" {
  description = "Enable ServiceMonitor for Prometheus metrics collection"
  type        = bool
  default     = false
}

# ============================================================================
# KUBECONFIG AND CLEANUP VARIABLES
# ============================================================================

variable "force_namespace_cleanup" {
  description = "Force cleanup of namespace and KubeVirt resources if deletion gets stuck (WARNING: Only use when namespace is stuck in Terminating phase)"
  type        = bool
  default     = false
}

variable "cleanup_timeout" {
  description = "Timeout for namespace cleanup operations (e.g., 5m, 10m, 30s)"
  type        = string
  default     = "5m"

  validation {
    condition     = can(regex("^[0-9]+(s|m|h)$", var.cleanup_timeout))
    error_message = "Cleanup timeout must be in format like '5m', '10m', '30s'."
  }
}

variable "workspace_prefix" {
  description = "Workspace prefix for kubeconfig file selection (e.g., 'prod', 'sit', 'dev'). Matches main provider.tf logic."
  type        = string
  default     = ""
}

variable "ci_mode" {
  description = "Running in CI mode (kubeconfig handled externally)"
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "Explicit kubeconfig path (overrides automatic detection). Leave empty to use workspace-based or default kubeconfig."
  type        = string
  default     = ""
}
