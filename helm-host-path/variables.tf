variable "namespace" {
  type        = string
  description = "Namespace."
  default     = "host-path-stack"
}
variable "name" {
  type        = string
  description = "Helm name."
  default     = "host-path"
}
variable "chart_name" {
  type        = string
  description = "Helm chart name."
  default     = "local-path-provisioner"
}
variable "chart_repo" {
  type        = string
  description = "Helm chart repository URL."
  default     = "https://charts.containeroo.ch"
}
variable "chart_version" {
  type        = string
  description = "Helm chart version."
  default     = "0.0.33"
}
variable "domain_name" {
  description = "Domain name to be used for the deployment."
  default     = ".local"
}

variable "let_helm_create_storage_class" {
  description = "Create a storage class using helm"
  type        = bool
  default     = false
}

variable "cpu_arch" {
  description = "CPU architecture for node selection (amd64, arm64)"
  type        = string
  default     = "amd64"
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based node scheduling (useful for cluster-wide services)"
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

variable "set_as_default_storage_class" {
  description = "Set the NFS storage class as the default storage class"
  type        = bool
  default     = false
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

# Service overrides for backward compatibility
variable "service_overrides" {
  description = "Service-specific overrides for labels, annotations, and other configurations"
  type = object({
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
  })
  default = {
    labels      = {}
    annotations = {}
  }
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

variable "hostpath_storage_quota_limit" {
  description = "Storage quota limit for hostpath volumes"
  type        = string
  default     = "50Gi"
}
