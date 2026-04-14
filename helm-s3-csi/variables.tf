variable "namespace" {
  type        = string
  description = "Namespace for S3 CSI driver"
  default     = "s3-csi-system"
}

variable "name" {
  type        = string
  description = "Helm release name"
  default     = "s3-csi"
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
  description = "Helm chart name"
  default     = "csi-s3"
}

variable "chart_repo" {
  type        = string
  description = "Helm chart repository URL for Yandex Cloud S3 CSI driver"
  default     = "https://yandex-cloud.github.io/k8s-csi-s3/charts"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version"
  default     = "v0.43.4"
}

# S3 Configuration
variable "s3_endpoint" {
  type        = string
  description = "S3 endpoint URL (e.g., https://storage.yandexcloud.net, https://s3.amazonaws.com)"
  validation {
    condition     = can(regex("^https?://", var.s3_endpoint))
    error_message = "S3 endpoint must start with http:// or https://"
  }
}

variable "s3_access_key_id" {
  type        = string
  description = "S3 access key ID"
  sensitive   = true
}

variable "s3_secret_access_key" {
  type        = string
  description = "S3 secret access key"
  sensitive   = true
}

variable "s3_bucket" {
  type        = string
  description = "Existing S3 bucket name to use for storage (bucket must already exist)"
}

variable "s3_region" {
  type        = string
  description = "S3 region (empty string for providers like QNAP, MinIO that don't use regions)"
  default     = ""
}

# Mounter Configuration
variable "mounter" {
  type        = string
  description = "S3 mounter type: geesefs (x86_64 only), s3fs-fuse (ARM64 compatible), rclone (ARM64 compatible), or s3backer"
  default     = "s3fs-fuse"

  validation {
    condition     = contains(["geesefs", "s3fs-fuse", "rclone", "s3backer"], var.mounter)
    error_message = "Mounter must be one of: geesefs (x86_64), s3fs-fuse (ARM64), rclone (ARM64), s3backer"
  }
}

variable "mounter_options" {
  type        = string
  description = "Additional options for the mounter (s3fs-fuse: empty, geesefs: --memory-limit=1000 --dir-mode=0777 --file-mode=0666)"
  default     = ""
}

# Storage Class Configuration
variable "storage_class_name" {
  type        = string
  description = "Name of the StorageClass to create"
  default     = "csi-s3"
}

variable "set_as_default_storage_class" {
  description = "Set the S3 CSI storage class as the default storage class"
  type        = bool
  default     = false
}

variable "reclaim_policy" {
  type        = string
  description = "Reclaim policy for the storage class (Retain or Delete)"
  default     = "Retain"

  validation {
    condition     = contains(["Retain", "Delete"], var.reclaim_policy)
    error_message = "Reclaim policy must be either Retain or Delete"
  }
}

variable "volume_binding_mode" {
  type        = string
  description = "Volume binding mode (Immediate or WaitForFirstConsumer)"
  default     = "Immediate"

  validation {
    condition     = contains(["Immediate", "WaitForFirstConsumer"], var.volume_binding_mode)
    error_message = "Volume binding mode must be either Immediate or WaitForFirstConsumer"
  }
}

variable "allow_volume_expansion" {
  type        = bool
  description = "Allow volume expansion for S3 PVCs"
  default     = false
}

# Architecture and Scheduling
variable "cpu_arch" {
  description = "CPU architecture"
  type        = string
  default     = "arm64"
}


# Resource Configuration
variable "cpu_limit" {
  description = "CPU limit for CSI driver containers"
  type        = string
  default     = "200m"
}

variable "memory_limit" {
  description = "Memory limit for CSI driver containers"
  type        = string
  default     = "256Mi"
}

variable "cpu_request" {
  description = "CPU request for CSI driver containers"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "Memory request for CSI driver containers"
  type        = string
  default     = "64Mi"
}

# Helm Configuration
variable "helm_timeout" {
  description = "Timeout for Helm deployment in seconds"
  type        = number
  default     = 600
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

# Limit Range Configuration
variable "limit_range_enabled" {
  description = "Enable limit range for the namespace"
  type        = bool
  default     = true
}

variable "limit_range_container_max_cpu" {
  description = "Maximum CPU limit for containers"
  type        = string
  default     = null
}

variable "limit_range_container_max_memory" {
  description = "Maximum memory limit for containers"
  type        = string
  default     = null
}

variable "limit_range_pvc_max_storage" {
  description = "Maximum storage size for PVCs"
  type        = string
  default     = "100Gi"
}

variable "limit_range_pvc_min_storage" {
  description = "Minimum storage size for PVCs"
  type        = string
  default     = "1Gi"
}

# Secret Management
variable "secret_name" {
  type        = string
  description = "Name of the Kubernetes Secret for S3 credentials"
  default     = "csi-s3-secret"
}

variable "create_secret" {
  type        = bool
  description = "Create the S3 credentials Secret (set to false if using existing secret)"
  default     = true
}
