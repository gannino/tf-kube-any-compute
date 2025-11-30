variable "name" {
  description = "Name of the metrics-server deployment"
  type        = string
  default     = "metrics-server"
}

variable "chart_version" {
  description = "Version of the metrics-server Helm chart"
  type        = string
  default     = "3.13.0"
}

variable "cpu_arch" {
  description = "CPU architecture for node selection"
  type        = string
  default     = ""

  validation {
    condition     = var.cpu_arch == "" || contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64', 'arm64', or empty for auto-detection."
  }
}

variable "enable_resource_limits" {
  description = "Enable resource limits"
  type        = bool
  default     = true
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "100m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "200Mi"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "100Mi"
}

variable "helm_timeout" {
  description = "Helm timeout"
  type        = number
  default     = 300
}



variable "helm_cleanup_on_fail" {
  description = "Cleanup on fail"
  type        = bool
  default     = true
}

variable "helm_wait" {
  description = "Wait for deployment"
  type        = bool
  default     = true
}

variable "helm_wait_for_jobs" {
  description = "Wait for jobs to complete"
  type        = bool
  default     = true
}

variable "helm_force_update" {
  description = "Force resource update through delete/recreate if needed"
  type        = bool
  default     = true
}

variable "helm_disable_webhooks" {
  description = "Disable webhooks during Helm operations"
  type        = bool
  default     = true
}

variable "helm_skip_crds" {
  description = "Skip CRD installation"
  type        = bool
  default     = false
}

variable "helm_replace" {
  description = "Replace existing resources"
  type        = bool
  default     = false
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based scheduling"
  type        = bool
  default     = false
}

variable "enable_microk8s_mode" {
  description = "Enable MicroK8s compatibility mode"
  type        = bool
  default     = false
}

variable "service_port" {
  description = "Port for the metrics-server service"
  type        = number
  default     = 4443
}

variable "environment" {
  description = "Environment name for labeling"
  type        = string
  default     = "prod"
}
