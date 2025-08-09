variable "namespace" {
  type        = string
  description = "Namespace."
  default     = "nfs-csi-stack"
}

variable "name" {
  type        = string
  description = "Helm name."
  default     = "nfs-csi"
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
  type        = string
  description = "Helm name."
  default     = "nfs-subdir-external-provisioner"
}
variable "chart_repo" {
  type        = string
  description = "Helm repository name."
  default     = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
}
variable "chart_version" {
  type        = string
  description = "Helm version."
  default     = "4.0.17"
}
variable "nfs_domain_name" {
  type        = string
  description = "Domain name for NFS server."
  default     = ".local"
}

variable "enable_nfs_csi_ingress" {
  type    = bool
  default = false
}
variable "enable_nfs_csi_ingress_route" {
  type    = bool
  default = false
}

variable "cpu_arch" {
  type    = string
  default = "arm64"
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based node scheduling (useful for cluster-wide services)"
  type        = bool
  default     = true
}

variable "nfs_server" {
  type = string
}

variable "nfs_path" {
  type = string
}

# New variables for improved storage class functionality
variable "set_as_default_storage_class" {
  description = "Set the NFS storage class as the default storage class"
  type        = bool
  default     = true
}

variable "create_fast_storage_class" {
  description = "Create an additional high-performance NFS storage class"
  type        = bool
  default     = false
}

variable "create_safe_storage_class" {
  description = "Create an additional safety-focused NFS storage class"
  type        = bool
  default     = true
}

variable "let_helm_create_storage_class" {
  description = "Create a storage class using helm"
  type        = bool
  default     = false
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "100m"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "64Mi"
}

variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "25m"
}

variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "32Mi"
}

# Limit Range Configuration
variable "limit_range_enabled" {
  description = "Enable limit range for the namespace"
  type        = bool
  default     = true
}

variable "limit_range_container_max_cpu" {
  description = "Maximum CPU limit for containers (default: same as cpu_limit)"
  type        = string
  default     = null
}

variable "limit_range_container_max_memory" {
  description = "Maximum memory limit for containers (default: same as memory_limit)"
  type        = string
  default     = null
}

variable "limit_range_pvc_max_storage" {
  description = "Maximum storage size for PVCs"
  type        = string
  default     = "10Gi"
}

variable "limit_range_pvc_min_storage" {
  description = "Minimum storage size for PVCs"
  type        = string
  default     = "100Mi"
}

variable "helm_timeout" {
  description = "Timeout for Helm deployment in seconds"
  type        = number
  default     = 300
}

variable "helm_disable_webhooks" {
  description = "Disable webhooks for Helm release"
  type        = bool
  default     = false
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

variable "storage_class" {
  description = "Storage class name for NFS CSI"
  type        = string
  default     = "nfs-csi"
}

# NFS mount option variables
variable "nfs_timeout_default" {
  description = "Default NFS timeout in deciseconds (600 = 60 seconds)"
  type        = number
  default     = 600

  validation {
    condition     = var.nfs_timeout_default > 0 && var.nfs_timeout_default <= 3600
    error_message = "NFS timeout must be between 1 and 3600 deciseconds."
  }
}

variable "nfs_timeout_fast" {
  description = "Fast NFS timeout in deciseconds for quick failover (150 = 15 seconds)"
  type        = number
  default     = 150

  validation {
    condition     = var.nfs_timeout_fast > 0 && var.nfs_timeout_fast <= 1800
    error_message = "Fast NFS timeout must be between 1 and 1800 deciseconds."
  }
}

variable "nfs_timeout_safe" {
  description = "Safe NFS timeout in deciseconds for stability (900 = 90 seconds)"
  type        = number
  default     = 900

  validation {
    condition     = var.nfs_timeout_safe > 0 && var.nfs_timeout_safe <= 7200
    error_message = "Safe NFS timeout must be between 1 and 7200 deciseconds."
  }
}

variable "nfs_retrans_default" {
  description = "Default number of NFS retries"
  type        = number
  default     = 2

  validation {
    condition     = var.nfs_retrans_default >= 1 && var.nfs_retrans_default <= 10
    error_message = "NFS retrans must be between 1 and 10."
  }
}

variable "nfs_retrans_fast" {
  description = "Number of NFS retries for fast storage class"
  type        = number
  default     = 3

  validation {
    condition     = var.nfs_retrans_fast >= 1 && var.nfs_retrans_fast <= 10
    error_message = "Fast NFS retrans must be between 1 and 10."
  }
}

variable "nfs_retrans_safe" {
  description = "Number of NFS retries for safe storage class"
  type        = number
  default     = 5

  validation {
    condition     = var.nfs_retrans_safe >= 1 && var.nfs_retrans_safe <= 10
    error_message = "Safe NFS retrans must be between 1 and 10."
  }
}