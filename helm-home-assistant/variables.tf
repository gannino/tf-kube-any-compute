# ============================================================================
# HELM-HOME-ASSISTANT MODULE VARIABLES - HOME AUTOMATION PLATFORM
# ============================================================================

# ============================================================================
# CORE MODULE CONFIGURATION
# ============================================================================

variable "namespace" {
  description = "Kubernetes namespace for Home Assistant deployment"
  type        = string
  default     = "home-assistant-system"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "name" {
  description = "Helm release name for Home Assistant"
  type        = string
  default     = "home-assistant"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Helm release name."
  }
}

variable "chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "home-assistant"
}

variable "chart_repo" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://pajikos.github.io/home-assistant-helm-chart/"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTPS URL."
  }
}

variable "chart_version" {
  description = "Helm chart version"
  type        = string
  default     = "0.2.63"
}

# ============================================================================
# FEATURE CONFIGURATION
# ============================================================================

variable "enable_ingress" {
  description = "Enable ingress functionality for external access"
  type        = bool
  default     = true
}

variable "enable_persistence" {
  description = "Enable persistent storage for Home Assistant data"
  type        = bool
  default     = true
}

variable "enable_privileged" {
  description = "Enable privileged mode for device access (USB, GPIO)"
  type        = bool
  default     = false
}

variable "enable_host_network" {
  description = "Enable host network for device discovery"
  type        = bool
  default     = false
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "persistent_disk_size" {
  description = "Size of persistent disk for Home Assistant data"
  type        = string
  default     = "5Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.persistent_disk_size))
    error_message = "Disk size must be in format like '5Gi', '500Mi', etc."
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

variable "traefik_cert_resolver" {
  description = "Traefik certificate resolver name"
  type        = string
  default     = "default"
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
  description = "Disable architecture-based node scheduling"
  type        = bool
  default     = false
}

variable "cpu_limit" {
  description = "CPU limit for Home Assistant containers"
  type        = string
  default     = "1000m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in format like '1000m' or '1'."
  }
}

variable "memory_limit" {
  description = "Memory limit for Home Assistant containers"
  type        = string
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in format like '1Gi', '512Mi', etc."
  }
}

variable "cpu_request" {
  description = "CPU request for Home Assistant containers"
  type        = string
  default     = "500m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in format like '500m' or '1'."
  }
}

variable "memory_request" {
  description = "Memory request for Home Assistant containers"
  type        = string
  default     = "512Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in format like '512Mi', '1Gi', etc."
  }
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

variable "deployment_wait_timeout" {
  description = "Timeout in seconds to wait for deployment to be ready"
  type        = number
  default     = 300

  validation {
    condition     = var.deployment_wait_timeout > 0 && var.deployment_wait_timeout <= 1800
    error_message = "Deployment wait timeout must be between 1 and 1800 seconds."
  }
}
