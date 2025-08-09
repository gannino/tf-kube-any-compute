variable "dashboard_auth" {
  description = "Basic authentication configuration for Traefik dashboard"
  default     = "traefik-dashboard-basicauth"
}

variable "label_app" {
  description = "Application label for Kubernetes resources"
  default     = "traefik"
}

variable "label_role" {
  description = "Role label for Kubernetes resources"
  default     = "ingress-controller"
}

variable "namespace" {
  description = "Kubernetes namespace where resources will be deployed"
  default     = ""
}

variable "domain_name" {
  description = "Domain name suffix for ingress rules"
  default     = ".local"
}

variable "service_name" {
  description = "Name of the Kubernetes service"
  default     = ""
}

variable "traefik_cert_resolver" {
  description = "Certificate resolver configuration for Traefik"
  default     = "default"
}

variable "traefik_dashboard_password" {
  description = "Custom password for Traefik dashboard (empty = auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}
