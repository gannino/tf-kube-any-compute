# ============================================================================
# HELM-OPENHAB MODULE VARIABLES - VENDOR-NEUTRAL HOME AUTOMATION PLATFORM
# ============================================================================

# ============================================================================
# CORE MODULE CONFIGURATION
# ============================================================================

variable "namespace" {
  description = "Kubernetes namespace for openHAB deployment"
  type        = string
  default     = "openhab-system"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "name" {
  description = "Helm release name for openHAB"
  type        = string
  default     = "openhab"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Helm release name."
  }
}

variable "chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "openhab"
}

variable "chart_repo" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://openhab.github.io/openhab-helm-chart/"

  validation {
    condition     = can(regex("^https?://", var.chart_repo))
    error_message = "Chart repository must be a valid HTTPS URL."
  }
}

variable "chart_version" {
  description = "Helm chart version"
  type        = string
  default     = "1.2.1"
}

variable "image_version" {
  description = "openHAB container image version"
  type        = string
  default     = "4.2.3"
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
  description = "Enable persistent storage for openHAB data"
  type        = bool
  default     = true
}

variable "enable_privileged" {
  description = "Enable privileged mode for device access (USB, GPIO)"
  type        = bool
  default     = false
}

variable "enable_host_network" {
  description = "Enable host network for device discovery (enabled by default for IoT device access)"
  type        = bool
  default     = true
}

variable "enable_karaf_console" {
  description = "Enable Karaf console access"
  type        = bool
  default     = false
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "persistent_disk_size" {
  description = "Size of persistent disk for openHAB data"
  type        = string
  default     = "8Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.persistent_disk_size))
    error_message = "Disk size must be in format like '8Gi', '500Mi', etc."
  }
}

variable "addons_disk_size" {
  description = "Size of persistent disk for openHAB addons"
  type        = string
  default     = "2Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.addons_disk_size))
    error_message = "Disk size must be in format like '2Gi', '500Mi', etc."
  }
}

variable "conf_disk_size" {
  description = "Size of persistent disk for openHAB configuration"
  type        = string
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.conf_disk_size))
    error_message = "Disk size must be in format like '1Gi', '500Mi', etc."
  }
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "nfs-csi-safe"
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
  description = "CPU limit for openHAB containers"
  type        = string
  default     = "2000m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in format like '2000m' or '2'."
  }
}

variable "memory_limit" {
  description = "Memory limit for openHAB containers"
  type        = string
  default     = "2Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in format like '2Gi', '1024Mi', etc."
  }
}

variable "cpu_request" {
  description = "CPU request for openHAB containers"
  type        = string
  default     = "1000m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in format like '1000m' or '1'."
  }
}

variable "memory_request" {
  description = "Memory request for openHAB containers"
  type        = string
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in format like '1Gi', '1024Mi', etc."
  }
}

variable "nfs_fs_group" {
  description = "File system group ID for NFS storage compatibility"
  type        = number
  default     = 1000
}
