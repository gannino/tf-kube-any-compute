variable "namespace" {
  type        = string
  description = "Namespace."
  default     = "consul-stack"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "name" {
  type        = string
  description = "Helm name."
  default     = "consul"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name."
  }
}
variable "chart_name" {
  type        = string
  description = "Helm name."
  default     = "consul"
}
variable "chart_repo" {
  type        = string
  description = "Helm repository name."
  default     = "https://helm.releases.hashicorp.com"
}
variable "chart_version" {
  type        = string
  description = "Helm version."
  default     = "1.8.0"
}
variable "domain_name" {
  type        = string
  description = "Domain name for the Consul deployment."
  default     = ".local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-\\.]*[a-zA-Z0-9])?$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "enable_ingress" {
  description = "Enable ingress for the Consul deployment."
  type        = bool
  default     = true
}
variable "persistent_disk_size" {
  type        = string
  description = "Persistent disk size for Consul storage in GB."
  default     = "1"
}
variable "traefik_cert_resolver" {
  type        = string
  description = "Traefik certificate resolver to use for ingress."
  default     = "default"
}

variable "cpu_arch" {
  description = "CPU architecture for node selection (amd64, arm64)"
  type        = string
  default     = "amd64"

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
  description = "Default CPU limit for containers"
  type        = string
  default     = "200m"

  validation {
    condition     = can(regex("^[0-9]+(m|[0-9]*\\.?[0-9]*)$", var.cpu_limit))
    error_message = "CPU limit must be a valid Kubernetes CPU resource format (e.g., '100m', '0.5', '1')."
  }
}

variable "memory_limit" {
  description = "Default memory limit for containers"
  type        = string
  default     = "256Mi"

  validation {
    condition     = can(regex("^[0-9]+(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)?$", var.memory_limit))
    error_message = "Memory limit must be a valid Kubernetes memory resource format (e.g., '128Mi', '1Gi')."
  }
}

variable "cpu_request" {
  description = "Default CPU request for containers"
  type        = string
  default     = "50m"

  validation {
    condition     = can(regex("^[0-9]+(m|[0-9]*\\.?[0-9]*)$", var.cpu_request))
    error_message = "CPU request must be a valid Kubernetes CPU resource format (e.g., '100m', '0.5', '1')."
  }
}

variable "memory_request" {
  description = "Default memory request for containers"
  type        = string
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)?$", var.memory_request))
    error_message = "Memory request must be a valid Kubernetes memory resource format (e.g., '128Mi', '1Gi')."
  }
}
variable "consul_image_version" {
  description = "Consul image version"
  type        = string
  default     = "1.19.1"
}
variable "consul_k8s_image_version" {
  description = "Consul K8S image version"
  type        = string
  default     = "1.4.1"
}
variable "storage_class" {
  description = "Storage class to use for Consul persistent storage."
  type        = string
  default     = "hostpath"
}

variable "helm_timeout" {
  description = "Timeout for Helm deployment in seconds"
  type        = number
  default     = 300

  validation {
    condition     = var.helm_timeout > 0 && var.helm_timeout <= 3600
    error_message = "Helm timeout must be between 1 and 3600 seconds."
  }
}

variable "helm_disable_webhooks" {
  description = "Disable webhooks for Helm release"
  type        = bool
  default     = true
}

variable "helm_skip_crds" {
  description = "Skip CRDs for Helm release"
  type        = bool
  default     = false
}

variable "helm_replace" {
  description = "Allow Helm to replace existing resources"
  type        = bool
  default     = true
}
variable "helm_force_update" {
  description = "Force resource updates if needed"
  type        = bool
  default     = true
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

# Service overrides for backward compatibility and customization
variable "service_overrides" {
  description = "Override default service configuration"
  type = object({
    helm_config = optional(object({
      chart_name       = optional(string)
      chart_repo       = optional(string)
      chart_version    = optional(string)
      timeout          = optional(number)
      disable_webhooks = optional(bool)
      skip_crds        = optional(bool)
      replace          = optional(bool)
      force_update     = optional(bool)
      cleanup_on_fail  = optional(bool)
      wait             = optional(bool)
      wait_for_jobs    = optional(bool)
    }), {})
    labels          = optional(map(string), {})
    template_values = optional(map(any), {})
  })
  default = {
    helm_config     = {}
    labels          = {}
    template_values = {}
  }
}
