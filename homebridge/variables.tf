variable "name" {
  description = "Helm release name for Homebridge"
  type        = string
  default     = "homebridge"
}

variable "namespace" {
  description = "Kubernetes namespace for Homebridge deployment"
  type        = string
  default     = "homebridge-system"
}

variable "cpu_arch" {
  description = "CPU architecture for node selection"
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.cpu_arch)
    error_message = "CPU architecture must be either 'amd64' or 'arm64'."
  }
}

variable "image_version" {
  description = "Homebridge container image version"
  type        = string
  default     = "latest"
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "hostpath"
}

variable "persistent_disk_size" {
  description = "Size of persistent disk for Homebridge data"
  type        = string
  default     = "2Gi"
}

variable "enable_persistence" {
  description = "Enable persistent storage for Homebridge data"
  type        = bool
  default     = true
}

variable "enable_host_network" {
  description = "Enable host network for HomeKit discovery (enabled by default for device discovery)"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable ingress functionality for external access"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for ingress resources"
  type        = string
  default     = ".local"
}

variable "traefik_cert_resolver" {
  description = "Traefik certificate resolver name"
  type        = string
  default     = "default"
}

variable "plugins" {
  description = "List of Homebridge plugins to install"
  type        = list(string)
  default = [
    "homebridge-config-ui-x"
  ]
}

variable "cpu_limit" {
  description = "CPU limit for Homebridge containers"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for Homebridge containers"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request for Homebridge containers"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request for Homebridge containers"
  type        = string
  default     = "256Mi"
}

variable "disable_arch_scheduling" {
  description = "Disable architecture-based node scheduling"
  type        = bool
  default     = false
}

variable "nfs_fs_group" {
  description = "File system group ID for NFS storage compatibility"
  type        = number
  default     = 1000
}
