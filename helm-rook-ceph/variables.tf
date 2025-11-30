variable "name" {
  type        = string
  description = "Helm release name"
  default     = "rook-ceph"
}

variable "namespace" {
  type        = string
  description = "Namespace for Rook Ceph"
  default     = "rook-ceph"
}

variable "chart_name" {
  type        = string
  description = "Helm chart name"
  default     = "rook-ceph"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL"
  default     = "https://charts.rook.io/release"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version"
  default     = "v1.15.7"
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

variable "cpu_limit" {
  description = "CPU limit for containers"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for containers"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request for containers"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request for containers"
  type        = string
  default     = "256Mi"
}

variable "limit_range_enabled" {
  description = "Enable limit range for namespace"
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

variable "enable_ceph_cluster" {
  description = "Deploy CephCluster resource (creates actual Ceph storage cluster)"
  type        = bool
  default     = true
}

variable "enable_dashboard" {
  description = "Enable Ceph Dashboard web interface"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable Traefik ingress for Ceph Dashboard"
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

variable "rook_csi_provisioner_replicas" {
  description = "Number of CSI provisioner replicas"
  type        = number
  default     = 1
}

variable "rook_csi_rbd_provisioner_cpu_limit" {
  description = "CPU limit for RBD provisioner"
  type        = string
  default     = "200m"
}

variable "rook_csi_rbd_provisioner_memory_limit" {
  description = "Memory limit for RBD provisioner"
  type        = string
  default     = "256Mi"
}

variable "rook_csi_rbd_plugin_cpu_limit" {
  description = "CPU limit for RBD plugin"
  type        = string
  default     = "200m"
}

variable "rook_csi_rbd_plugin_memory_limit" {
  description = "Memory limit for RBD plugin"
  type        = string
  default     = "512Mi"
}
