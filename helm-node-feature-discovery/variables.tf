variable "namespace" {
  type        = string
  description = "Namespace."
  default     = "node-feature-discovery-stack"
}
variable "name" {
  type        = string
  description = "Helm name."
  default     = "node-feature-discovery"
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based node scheduling (useful for cluster-wide services)"
  type        = bool
  default     = true # NFD should run on all nodes by default
}

variable "chart_name" {
  type        = string
  description = "Helm chart name."
  default     = "node-feature-discovery"
}
variable "chart_repo" {
  type        = string
  description = "Helm repository name."
  default     = "https://kubernetes-sigs.github.io/node-feature-discovery/charts"
}
variable "chart_version" {
  type        = string
  description = "Helm version."
  default     = "0.17.3"
}

variable "cpu_arch" {
  description = "CPU architecture for node selection (amd64, arm64)"
  type        = string
  default     = "amd64"
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "200m"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "128Mi"
}

variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "64Mi"
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
  default     = false
}

variable "helm_wait_for_jobs" {
  description = "Wait for Helm jobs to complete"
  type        = bool
  default     = false
}
