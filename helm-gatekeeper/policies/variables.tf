variable "namespace" {
  type        = string
  description = "Namespace."
  default     = "gatekeeper-stack"
}

variable "enable_hostpath_policy" {
  description = "Enable hostpath PVC size limit policy"
  type        = bool
  default     = true
}

variable "hostpath_max_size" {
  description = "Maximum allowed size for hostpath PVCs"
  type        = string
  default     = "10Gi"
}

variable "hostpath_storage_class" {
  description = "Storage class name for hostpath policy"
  type        = string
  default     = "hostpath"
}

variable "enable_security_policies" {
  description = "Enable security-related policies (security context, privileged containers)"
  type        = bool
  default     = true
}

variable "enable_resource_policies" {
  description = "Enable resource requirement policies (CPU/memory limits)"
  type        = bool
  default     = true
}
