# ============================================================================
# NATIVE TERRAFORM N8N MODULE VARIABLES - WORKFLOW AUTOMATION PLATFORM
# ============================================================================

# ============================================================================
# CORE MODULE CONFIGURATION
# ============================================================================

variable "namespace" {
  description = "Kubernetes namespace for n8n deployment"
  type        = string
  default     = "n8n-system"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "name" {
  description = "Deployment name for n8n"
  type        = string
  default     = "n8n"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name."
  }
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
  description = "Enable persistent storage for n8n data"
  type        = bool
  default     = true
}

variable "enable_database" {
  description = "Enable external database (PostgreSQL) instead of SQLite"
  type        = bool
  default     = false
}

# ============================================================================
# STORAGE CONFIGURATION
# ============================================================================

variable "persistent_disk_size" {
  description = "Size of persistent disk for n8n data"
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
  description = "CPU limit for n8n containers"
  type        = string
  default     = "1000m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_limit))
    error_message = "CPU limit must be in format like '1000m' or '1'."
  }
}

variable "memory_limit" {
  description = "Memory limit for n8n containers"
  type        = string
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_limit))
    error_message = "Memory limit must be in format like '1Gi', '512Mi', etc."
  }
}

variable "cpu_request" {
  description = "CPU request for n8n containers"
  type        = string
  default     = "500m"

  validation {
    condition     = can(regex("^[0-9]+m?$", var.cpu_request))
    error_message = "CPU request must be in format like '500m' or '1'."
  }
}

variable "memory_request" {
  description = "Memory request for n8n containers"
  type        = string
  default     = "512Mi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i?$", var.memory_request))
    error_message = "Memory request must be in format like '512Mi', '1Gi', etc."
  }
}
