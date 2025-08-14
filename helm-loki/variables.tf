variable "namespace" {
  type        = string
  description = "Namespace for Loki"
  default     = "loki-system"
}

variable "name" {
  type        = string
  description = "Helm release name"
  default     = "loki"
}

variable "chart_name" {
  type        = string
  description = "Helm chart name"
  default     = "loki"
}

variable "chart_repo" {
  type        = string
  description = "Helm repository"
  default     = "https://grafana.github.io/helm-charts"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version"
  default     = "6.16.0"
}

variable "storage_class" {
  description = "Storage class for Loki"
  type        = string
  default     = "hostpath"
}

variable "storage_size" {
  description = "Storage size for Loki"
  type        = string
  default     = "10Gi"
}

variable "cpu_limit" {
  description = "CPU limit for Loki"
  type        = string
  default     = "200m"
}

variable "memory_limit" {
  description = "Memory limit for Loki"
  type        = string
  default     = "256Mi"
}

variable "cpu_request" {
  description = "CPU request for Loki"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "Memory request for Loki"
  type        = string
  default     = "64Mi"
}

variable "cpu_arch" {
  description = "CPU architecture"
  type        = string
  default     = "amd64"
}

# Helm configuration
variable "helm_timeout" {
  description = "Helm timeout"
  type        = number
  default     = 600
}

variable "helm_disable_webhooks" {
  description = "Disable webhooks"
  type        = bool
  default     = true
}

variable "helm_skip_crds" {
  description = "Skip CRDs"
  type        = bool
  default     = false
}

variable "helm_replace" {
  description = "Replace resources"
  type        = bool
  default     = false
}

variable "helm_force_update" {
  description = "Force update"
  type        = bool
  default     = true
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
  description = "Wait for jobs"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for ingress"
  type        = string
  default     = ".local"
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

variable "enable_ingress" {
  description = "Enable Traefik ingress for Loki"
  type        = bool
  default     = false
}
