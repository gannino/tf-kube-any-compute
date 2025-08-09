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
  description = "MetalLB Helm chart version."
  default     = "0.15.2" # Downgraded from 0.14.8 due to IP assignment issues
}

variable "enable_ingress" {
  default = false
}

variable "persistent_disc_size" {
  default = "1"
}
variable "domain_name" {
  default = ".local"
}

variable "workspace" {
  default = "set-me"
}

variable "le_email" {
  default = ""
}

variable "address_pool" {
  description = "IP address range for MetalLB load balancer (format: IP1-IP2)"
  type        = string
  default     = "192.168.1.30-192.168.1.60"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.address_pool))
    error_message = "Address pool must be in format 'IP1-IP2' with valid IPv4 addresses."
  }
}

variable "cpu_arch" {
  description = "CPU architecture for node selection (amd64, arm64)"
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64' or 'arm64'."
  }
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

variable "additional_ip_pools" {
  description = "Additional IP address pools for MetalLB"
  type = list(object({
    name        = string
    addresses   = list(string)
    auto_assign = optional(bool, true)
  }))
  default = []
}

variable "service_monitor_enabled" {
  description = "Enable ServiceMonitor for Prometheus Operator"
  type        = bool
  default     = false
}

variable "controller_replica_count" {
  description = "Number of replicas for the MetalLB controller (1-5 recommended)"
  type        = number
  default     = 1

  validation {
    condition     = var.controller_replica_count >= 1 && var.controller_replica_count <= 5
    error_message = "Controller replica count must be between 1 and 5."
  }
}

variable "speaker_replica_count" {
  description = "Number of replicas for the MetalLB speaker (typically matches node count)"
  type        = number
  default     = 1

  validation {
    condition     = var.speaker_replica_count >= 1 && var.speaker_replica_count <= 20
    error_message = "Speaker replica count must be between 1 and 20."
  }
}

variable "enable_bgp" {
  description = "Enable BGP mode for MetalLB (alternative to L2 mode)"
  type        = bool
  default     = false
}

variable "bgp_peers" {
  description = "BGP peer configuration for MetalLB"
  type = list(object({
    peer_address = string
    peer_asn     = number
    my_asn       = number
  }))
  default = []
}

variable "enable_frr" {
  description = "Enable FRR (Free Range Routing) for advanced BGP features"
  type        = bool
  default     = false
}

variable "load_balancer_class" {
  description = "Load balancer class name for MetalLB"
  type        = string
  default     = "metallb"
}

variable "enable_prometheus_metrics" {
  description = "Enable Prometheus metrics for MetalLB"
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Log level for MetalLB components (debug, info, warn, error)"
  type        = string
  default     = "debug"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}

variable "enable_load_balancer_class" {
  description = "Enable LoadBalancerClass for MetalLB"
  type        = bool
  default     = false
}

variable "address_pool_name" {
  description = "Name of the address pool for MetalLB"
  type        = string
  default     = "default-pool"

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.address_pool_name))
    error_message = "Address pool name must be a valid DNS label."
  }
}