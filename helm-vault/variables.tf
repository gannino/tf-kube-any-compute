variable "namespace" {
  type        = string
  description = "Namespace."
  default     = "vault-stack"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "name" {
  type        = string
  description = "Helm release name."
  default     = "vault"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "Name must be a valid Kubernetes resource name."
  }
}

variable "chart_name" {
  type        = string
  description = "Helm chart name."
  default     = "vault"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository URL."
  default     = "https://helm.releases.hashicorp.com"
}

variable "chart_version" {
  type        = string
  description = "Version of the Helm chart to deploy. Refer to https://artifacthub.io/packages/helm/hashicorp/vault for available versions."
  default     = "0.28.0"
}

variable "domain_name" {
  type        = string
  description = "Domain name suffix."
  default     = ".local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-\\.]*[a-zA-Z0-9])?$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "enable_ingress" {
  type        = bool
  description = "Enable Ingress for Vault UI."
  default     = true
}

variable "traefik_cert_resolver" {
  description = "Traefik certificate resolver"
  type        = string
  default     = "default"

  validation {
    condition = contains([
      "default", "wildcard", "letsencrypt", "letsencrypt-staging",
      "hurricane", "cloudflare", "route53", "digitalocean", "gandi",
      "namecheap", "godaddy", "ovh", "linode", "vultr", "hetzner"
    ], var.traefik_cert_resolver)
    error_message = "Certificate resolver must be a valid resolver name (default, wildcard, letsencrypt, letsencrypt-staging, or a DNS provider name)."
  }
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

variable "consul_address" {
  type        = string
  description = "Consul service address in hostname:port format (e.g., consul-server.consul.svc.cluster.local:8500)."
  default     = "consul-server.consul.svc.cluster.local:8500"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-\\.]*[a-zA-Z0-9])*:[0-9]+$", var.consul_address))
    error_message = "Consul address must be in hostname:port format (e.g., 'consul-server.consul.svc.cluster.local:8500')."
  }
}

variable "consul_token" {
  type        = string
  description = "Consul ACL token for Vault authentication."
  sensitive   = true
  default     = "" # Set via terraform apply -var="consul_token=your-token"
}

variable "enable_traefik_ingress" {
  description = "Enable Traefik ingress"
  type        = bool
  default     = false
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "200m"

  validation {
    condition     = can(regex("^[0-9]+(m|[0-9]*\\.?[0-9]*)$", var.cpu_limit))
    error_message = "CPU limit must be a valid Kubernetes CPU resource format (e.g., '100m', '0.5', '1')."
  }
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "128Mi"

  validation {
    condition     = can(regex("^[0-9]+(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)?$", var.memory_limit))
    error_message = "Memory limit must be a valid Kubernetes memory resource format (e.g., '128Mi', '1Gi')."
  }
}

variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "50m"

  validation {
    condition     = can(regex("^[0-9]+(m|[0-9]*\\.?[0-9]*)$", var.cpu_request))
    error_message = "CPU request must be a valid Kubernetes CPU resource format (e.g., '100m', '0.5', '1')."
  }
}

variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "64Mi"

  validation {
    condition     = can(regex("^[0-9]+(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)?$", var.memory_request))
    error_message = "Memory request must be a valid Kubernetes memory resource format (e.g., '128Mi', '1Gi')."
  }
}

variable "storage_class" {
  description = "Storage class to use for persistent volumes"
  type        = string
  default     = "" # Empty means use cluster default
}

variable "storage_size" {
  description = "Size of the persistent volume"
  type        = string
  default     = "2Gi"

  validation {
    condition     = can(regex("^[0-9]+(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)?$", var.storage_size))
    error_message = "Storage size must be a valid Kubernetes storage size format (e.g., '2Gi', '500Mi')."
  }
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

variable "vault_init_timeout" {
  description = "Timeout in seconds for Vault initialization"
  type        = number
  default     = 600

  validation {
    condition     = var.vault_init_timeout > 0 && var.vault_init_timeout <= 3600
    error_message = "Vault init timeout must be between 1 and 3600 seconds."
  }
}

variable "vault_readiness_timeout" {
  description = "Timeout in seconds for Vault container readiness"
  type        = number
  default     = 300

  validation {
    condition     = var.vault_readiness_timeout > 0 && var.vault_readiness_timeout <= 1800
    error_message = "Vault readiness timeout must be between 1 and 1800 seconds."
  }
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

# Health check configuration variables
variable "healthcheck_interval" {
  description = "Interval for health check probes"
  type        = string
  default     = "10s"

  validation {
    condition     = can(regex("^[0-9]+[smh]$", var.healthcheck_interval))
    error_message = "Health check interval must be in format like '10s', '1m', '1h'."
  }
}

variable "healthcheck_timeout" {
  description = "Timeout for health check probes"
  type        = string
  default     = "5s"

  validation {
    condition     = can(regex("^[0-9]+[smh]$", var.healthcheck_timeout))
    error_message = "Health check timeout must be in format like '5s', '30s', '1m'."
  }
}

variable "ingress_sleep_duration" {
  description = "Duration to wait before creating ingress resources"
  type        = string
  default     = "1s"

  validation {
    condition     = can(regex("^[0-9]+[smh]$", var.ingress_sleep_duration))
    error_message = "Ingress sleep duration must be in format like '1s', '5s', '1m'."
  }
}

variable "vault_port" {
  description = "Port number for Vault service"
  type        = number
  default     = 8200

  validation {
    condition     = var.vault_port > 0 && var.vault_port <= 65535
    error_message = "Vault port must be between 1 and 65535."
  }
}

variable "consul_port" {
  description = "Port number for Consul service"
  type        = number
  default     = 8500

  validation {
    condition     = var.consul_port > 0 && var.consul_port <= 65535
    error_message = "Consul port must be between 1 and 65535."
  }
}

variable "ha_replicas" {
  description = "Number of Vault HA replicas (minimum 2 for HA, recommended 3 for production)"
  type        = number
  default     = 2

  validation {
    condition     = var.ha_replicas >= 1 && var.ha_replicas <= 7
    error_message = "HA replicas must be between 1 and 7 (odd numbers recommended for consensus)."
  }
}
