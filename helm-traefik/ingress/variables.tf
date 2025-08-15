variable "dashboard_auth" {
  description = "Basic authentication configuration for Traefik dashboard"
  type        = string
  default     = "traefik-dashboard-basicauth"
}

variable "label_app" {
  description = "Application label for Kubernetes resources"
  type        = string
  default     = "traefik"
}

variable "label_role" {
  description = "Role label for Kubernetes resources"
  type        = string
  default     = "ingress-controller"
}

variable "namespace" {
  description = "Kubernetes namespace where resources will be deployed"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name suffix for ingress rules"
  type        = string
  default     = ".local"
}

variable "service_name" {
  description = "Name of the Kubernetes service"
  type        = string
  default     = ""
}

variable "traefik_cert_resolver" {
  description = "Certificate resolver configuration for Traefik"
  type        = string
  default     = "default"
}

variable "traefik_dashboard_password" {
  description = "Custom password for Traefik dashboard (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "dashboard_middleware" {
  description = "List of middleware names to apply to Traefik dashboard"
  type        = list(string)
  default     = []
}
