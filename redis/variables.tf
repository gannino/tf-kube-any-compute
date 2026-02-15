# ============================================================================
# BASIC CONFIGURATION
# ============================================================================

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for Redis"
  default     = "redis-system"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name (lowercase alphanumeric and hyphens only)."
  }
}

variable "name" {
  type        = string
  description = "Helm release name for Redis"
  default     = "redis"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name (lowercase alphanumeric and hyphens only)."
  }
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "enable_persistence" {
  type        = bool
  description = "Enable persistent storage for Redis data"
  default     = true
}

variable "storage_class" {
  type        = string
  description = "Storage class for Redis PVC (auto-detect if empty)"
  default     = ""
}

variable "storage_size" {
  type        = string
  description = "Persistent volume size for Redis data"
  default     = "8Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?(Gi|Mi|G|M|Ki|K)$", var.storage_size))
    error_message = "Storage size must be in Kubernetes resource format (e.g., 8Gi, 512Mi)."
  }
}

# ============================================================================
# RESOURCE CONFIGURATION
# ============================================================================

variable "cpu_limit" {
  type        = string
  description = "CPU limit for Redis containers"
  default     = "300m"

  validation {
    condition     = can(regex("^[0-9]+(m)?$", var.cpu_limit))
    error_message = "CPU limit must be in milliscores (e.g., 300m) or cores (e.g., 1)."
  }
}

variable "memory_limit" {
  type        = string
  description = "Memory limit for Redis containers"
  default     = "512Mi"

  validation {
    condition     = can(regex("^[0-9]+(Gi|Mi|G|M|K|Ki)?$", var.memory_limit))
    error_message = "Memory limit must be in Kubernetes resource format (e.g., 512Mi, 1Gi)."
  }
}

variable "cpu_request" {
  type        = string
  description = "CPU request for Redis containers"
  default     = "100m"

  validation {
    condition     = can(regex("^[0-9]+(m)?$", var.cpu_request))
    error_message = "CPU request must be in milliscores (e.g., 100m) or cores (e.g., 1)."
  }
}

variable "memory_request" {
  type        = string
  description = "Memory request for Redis containers"
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+(Gi|Mi|G|M|K|Ki)?$", var.memory_request))
    error_message = "Memory request must be in Kubernetes resource format (e.g., 128Mi, 512Mi)."
  }
}

# ============================================================================
# ARCHITECTURE CONFIGURATION
# ============================================================================

variable "cpu_arch" {
  type        = string
  description = "CPU architecture for node scheduling (auto-detect if empty)"
  default     = ""

  validation {
    condition     = var.cpu_arch == "" || contains(["amd64", "arm64", "arm", "386"], var.cpu_arch)
    error_message = "CPU architecture must be empty (auto-detect) or one of: amd64, arm64, arm, 386."
  }
}

variable "disable_arch_scheduling" {
  type        = bool
  description = "Disable architecture-based node scheduling (useful for single-architecture clusters)"
  default     = false
}

# ============================================================================
# PROMETHEUS INTEGRATION
# ============================================================================

variable "enable_servicemonitor" {
  type        = bool
  description = "Enable Prometheus ServiceMonitor for Redis metrics"
  default     = false
}

variable "servicemonitor_namespace" {
  type        = string
  description = "Namespace for ServiceMonitor resource (typically where Prometheus Operator is deployed)"
  default     = "monitoring"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.servicemonitor_namespace))
    error_message = "ServiceMonitor namespace must be a valid Kubernetes namespace name."
  }
}
