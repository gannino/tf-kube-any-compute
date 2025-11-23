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
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "200Mi"
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
