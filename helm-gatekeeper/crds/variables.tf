# Gatekeeper CRDs Module Variables

variable "name" {
  description = "Name for the Gatekeeper CRDs deployment"
  type        = string
  default     = "gatekeeper"
}

variable "chart_name" {
  description = "Name of the Gatekeeper Helm chart"
  type        = string
  default     = "gatekeeper"
}

variable "chart_repo" {
  description = "Repository URL for the Gatekeeper Helm chart"
  type        = string
  default     = "https://open-policy-agent.github.io/gatekeeper/charts"
}

variable "chart_version" {
  description = "Version of the Gatekeeper Helm chart to deploy"
  type        = string
  default     = null
}

variable "gatekeeper_version" {
  description = "Version of Gatekeeper to deploy CRDs for"
  type        = string
  default     = "3.14"
}

variable "namespace" {
  description = "Kubernetes namespace for Gatekeeper CRDs"
  type        = string
  default     = "gatekeeper"
}

variable "helm_timeout" {
  description = "Timeout for helm operations in seconds"
  type        = number
  default     = 900
}

variable "helm_wait" {
  description = "Whether to wait for the deployment to be ready"
  type        = bool
  default     = true
}

variable "helm_wait_for_jobs" {
  description = "Whether to wait for jobs to complete"
  type        = bool
  default     = true
}

variable "helm_cleanup_on_fail" {
  description = "Whether to cleanup resources on failure"
  type        = bool
  default     = true
}

variable "crd_wait_duration" {
  description = "Duration to wait after CRD creation for stabilization"
  type        = string
  default     = "30s"

  validation {
    condition     = can(regex("^[0-9]+[smh]$", var.crd_wait_duration))
    error_message = "CRD wait duration must be in format like '30s', '2m', '1h'."
  }
}

variable "crd_api_version" {
  description = "API version for CRD manifests"
  type        = string
  default     = "apiextensions.k8s.io/v1"

  validation {
    condition     = can(regex("^[a-z0-9.-]+/v[0-9]+", var.crd_api_version))
    error_message = "API version must be in format like 'apiextensions.k8s.io/v1'."
  }
}
