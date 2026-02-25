variable "name" {
  type        = string
  description = "Helm release name"
  default     = "longhorn"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace"
  default     = "longhorn-system"
}

variable "chart_name" {
  type        = string
  description = "Helm chart name"
  default     = "longhorn"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL"
  default     = "https://charts.longhorn.io"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version"
  default     = "1.7.2"
}

variable "cpu_arch" {
  description = "CPU architecture"
  type        = string
  default     = "amd64"
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based node scheduling"
  type        = bool
  default     = false
}

variable "set_as_default_storage_class" {
  description = "Set Longhorn as the default storage class"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Number of replicas for volumes"
  type        = number
  default     = 3
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "256Mi"
}

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
  default     = true
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

variable "enable_dashboard" {
  description = "Enable Longhorn Dashboard web interface"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable Traefik ingress for Longhorn Dashboard"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for ingress"
  type        = string
  default     = "local"
}

variable "traefik_cert_resolver" {
  description = "Traefik certificate resolver"
  type        = string
  default     = "default"
}

variable "traefik_ingress_config" {
  description = "Traefik ingress configuration"
  type        = any
  default     = null
}

variable "kubelet_root_dir" {
  description = "Kubelet root directory path (auto-detected based on k8s_distribution if empty)"
  type        = string
  default     = ""
}

variable "k8s_distribution" {
  description = "Kubernetes distribution (k3s, microk8s, kubernetes, etc.)"
  type        = string
  default     = "microk8s"
}

variable "backup_target" {
  description = "Longhorn backup target (NFS or S3)"
  type        = string
  default     = ""
}

variable "backup_target_credential_secret" {
  description = "Secret name for backup target credentials"
  type        = string
  default     = ""
}

variable "default_data_path" {
  description = "Default path for Longhorn data storage on nodes"
  type        = string
  default     = "/opt/longhorn"
}

# ============================================================================
# CLEANUP CONFIGURATION
# ============================================================================

variable "force_namespace_cleanup" {
  description = "Force cleanup of namespace and Longhorn resources if deletion gets stuck (WARNING: Only use when namespace is stuck in Terminating phase)"
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
