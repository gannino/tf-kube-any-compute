variable "namespace" {
  type        = string
  description = "Ingress Gateway namespace."
  default     = "metallb-system"
}
variable "ingress_gateway_name" {
  type        = string
  description = "Ingress Gateway Helm chart name."
  default     = "metallb"
}

variable "ingress_gateway_chart_name" {
  type        = string
  description = "Ingress Gateway Helm chart name."
  default     = "metallb"
}
variable "ingress_gateway_chart_repo" {
  type        = string
  description = "Ingress Gateway Helm repository name."
  default     = "https://metallb.github.io/metallb"
}
variable "ingress_gateway_chart_version" {
  type        = string
  description = "Ingress Gateway Helm repository version."
  default     = "0.13.10"
}

variable "enable_ingress" {
  description = "Enable ingress"
  type        = bool
  default     = false
}

variable "persistent_disc_size" {
  description = "Persistent disk size"
  type        = string
  default     = "1"
}
variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = ".local"
}

variable "workspace" {
  description = "Workspace name"
  type        = string
  default     = "set-me"
}

variable "le_email" {
  description = "Let's Encrypt email"
  type        = string
  default     = ""
}

variable "address_pool" {
  description = "MetalLB address pool"
  type        = string
  default     = "192.168.169.30-192.168.169.60"
}

variable "cpu_arch" {
  description = "CPU architecture for node selection (amd64, arm64)"
  type        = string
  default     = "arm64"
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

variable "controller_replica_count" {
  description = "Number of replicas for the controller"
  type        = number
  default     = 1
}

variable "speaker_replica_count" {
  description = "Number of replicas for the speaker"
  type        = number
  default     = 1
}
