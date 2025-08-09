variable "namespace" {
  type        = string
  description = "Namespace."
  default     = "gatekeeper-stack"
}
variable "name" {
  type        = string
  description = "Helm name."
  default     = "gatekeeper"
}
variable "chart_name" {
  type        = string
  description = "Helm chart name."
  default     = "gatekeeper"
}
variable "chart_repo" {
  type        = string
  description = "Helm repository name."
  default     = "https://open-policy-agent.github.io/gatekeeper/charts"
}
variable "chart_version" {
  type        = string
  description = "Helm version."
  default     = "3.15.1"
}

variable "gatekeeper_version" {
  type        = string
  description = "Gatekeeper version for CRD deployment (should match chart version)"
  default     = "3.15"
}

variable "enable_policies" {
  description = "Enable Gatekeeper policies."
  type        = bool
  default     = true
}

variable "enable_hostpath_policy" {
  description = "Enable hostpath PVC size limit policy"
  type        = bool
  default     = true
}

variable "hostpath_max_size" {
  description = "Maximum allowed size for hostpath PVCs"
  type        = string
  default     = "10Gi"
}

variable "hostpath_storage_class" {
  description = "Storage class name for hostpath policy"
  type        = string
  default     = "hostpath"
}

variable "enable_security_policies" {
  description = "Enable security-related policies (security context, privileged containers)"
  type        = bool
  default     = true
}

variable "enable_resource_policies" {
  description = "Enable resource requirement policies (CPU/memory limits)"
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
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "256Mi"
}

variable "helm_timeout" {
  description = "Timeout for Helm deployment in seconds"
  type        = number
  default     = 120
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
  default     = true
}

variable "helm_wait_for_jobs" {
  description = "Wait for Helm jobs to complete"
  type        = bool
  default     = true
}

# Service overrides for backward compatibility
variable "service_overrides" {
  description = "Override values for existing helm deployment configurations"
  type        = map(any)
  default     = {}
}

# Limit range configuration
variable "limit_range_enabled" {
  description = "Enable limit range for the namespace"
  type        = bool
  default     = true
}

variable "container_max_cpu" {
  description = "Maximum CPU limit for containers"
  type        = string
  default     = "500m"
}

variable "container_max_memory" {
  description = "Maximum memory limit for containers"
  type        = string
  default     = "512Mi"
}

variable "pvc_max_storage" {
  description = "Maximum storage for persistent volume claims"
  type        = string
  default     = "10Gi"
}

variable "pvc_min_storage" {
  description = "Minimum storage for persistent volume claims"
  type        = string
  default     = "1Gi"
}

variable "crd_wait_timeout" {
  description = "Timeout for CRD readiness checks"
  type        = string
  default     = "60s"

  validation {
    condition     = can(regex("^[0-9]+[smh]$", var.crd_wait_timeout))
    error_message = "CRD wait timeout must be in format like '60s', '5m', '1h'."
  }
}

variable "crd_api_version" {
  description = "API version for CRD operations"
  type        = string
  default     = "apiextensions.k8s.io/v1"

  validation {
    condition     = can(regex("^[a-z0-9.-]+/v[0-9]+", var.crd_api_version))
    error_message = "API version must be in format like 'apiextensions.k8s.io/v1'."
  }
}