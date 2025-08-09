variable "namespace" {
  type        = string
  description = "Namespace."
  default     = "pre-monitoring-system"
}
variable "name" {
  type        = string
  description = "Helm release name."
  default     = "prometheus-operator-crds"
}
variable "release_name" {
  type        = string
  description = "Helm release name."
  default     = "prometheus-operator-crds"
}
variable "chart_name" {
  type        = string
  description = "Helm name."
  default     = "kube-prometheus-stack"
}
variable "chart_repo" {
  type        = string
  description = "Helm repository name."
  default     = "https://prometheus-community.github.io/helm-charts"
}
variable "chart_version" {
  type        = string
  description = "Helm version."
  default     = "14.0.0"
}
variable "domain_name" {
  description = "Domain name for the deployment."
  default     = ".local"
}

variable "enable_prometheus_ingress" {
  description = "Enable ingress for Prometheus."
  type        = bool
  default     = false
}
variable "enable_prometheus_ingress_route" {
  description = "Enable ingress route for Prometheus."
  type        = bool
  default     = false
}
variable "enable_alertmanager_ingress" {
  description = "Enable ingress for Alertmanager."
  type        = bool
  default     = false
}

variable "prometheus_url" {
  default = ""
}

variable "cpu_arch" {
  default = "arm64"
}

variable "prometheus_storage_size" {
  default = "8Gi"
}

variable "alertmanager_storage_size" {
  default = "2Gi"
}

variable "grafana_storage_size" {
  default = "4Gi"
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "256Mi"
}

variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "128Mi"
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
  default     = "256Mi"
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

variable "crd_wait_timeout_minutes" {
  description = "Timeout in minutes to wait for CRDs to be registered"
  type        = number
  default     = 20

  validation {
    condition     = var.crd_wait_timeout_minutes > 0 && var.crd_wait_timeout_minutes <= 60
    error_message = "CRD wait timeout must be between 1 and 60 minutes."
  }
}