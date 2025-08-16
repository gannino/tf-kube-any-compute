variable "namespace" {
  description = "Kubernetes namespace for middleware resources"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for middleware names"
  type        = string
  default     = "auth"
}

variable "labels" {
  description = "Common labels for middleware resources"
  type        = map(string)
  default     = {}
}

variable "enable_middleware_resources" {
  description = "Enable creation of middleware resources (requires Traefik CRDs to be available)"
  type        = bool
  default     = true
}

# Basic Authentication Configuration
variable "basic_auth" {
  description = "Basic authentication middleware configuration"
  type = object({
    enabled         = bool
    secret_name     = optional(string, "")
    realm           = optional(string, "Authentication Required")
    static_password = optional(string, "")      # If set, uses this instead of random password
    username        = optional(string, "admin") # Username for basic auth
  })
  default = {
    enabled = false
  }
}

# LDAP Authentication Configuration
variable "ldap_auth" {
  description = "LDAP authentication middleware configuration"
  type = object({
    enabled       = bool
    method        = optional(string, "forwardauth") # "plugin" or "forwardauth"
    log_level     = optional(string, "INFO")
    url           = optional(string, "")
    port          = optional(number, 389)
    base_dn       = optional(string, "")
    attribute     = optional(string, "uid")
    bind_dn       = optional(string, "")
    bind_password = optional(string, "")
    search_filter = optional(string, "")
  })
  default = {
    enabled = false
  }

  validation {
    condition = !var.ldap_auth.enabled || (
      var.ldap_auth.url != "" &&
      var.ldap_auth.base_dn != ""
    )
    error_message = "When LDAP auth is enabled, url and base_dn must be provided."
  }

  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.ldap_auth.log_level)
    error_message = "LDAP log level must be one of: DEBUG, INFO, WARN, ERROR."
  }

  validation {
    condition     = var.ldap_auth.port > 0 && var.ldap_auth.port <= 65535
    error_message = "LDAP port must be between 1 and 65535."
  }

  validation {
    condition     = contains(["plugin", "forwardauth"], var.ldap_auth.method)
    error_message = "LDAP method must be either 'plugin' or 'forwardauth'."
  }
}

# Rate Limiting Configuration
variable "rate_limit" {
  description = "Rate limiting middleware configuration"
  type = object({
    enabled = bool
    average = optional(number, 100)
    burst   = optional(number, 200)
  })
  default = {
    enabled = false
  }
}

# IP Whitelist Configuration
variable "ip_whitelist" {
  description = "IP whitelist middleware configuration"
  type = object({
    enabled       = bool
    source_ranges = optional(list(string), ["127.0.0.1/32"])
  })
  default = {
    enabled = false
  }
}

# Default Authentication Configuration (basic by default, LDAP override)
variable "default_auth" {
  description = "Default authentication middleware - uses basic auth by default, switches to LDAP when ldap_override is true"
  type = object({
    enabled       = bool
    ldap_override = optional(bool, false) # Set to true to use LDAP instead of basic

    # Basic auth configuration (used when type = "basic")
    basic_config = optional(object({
      secret_name     = optional(string, "default-basic-auth")
      realm           = optional(string, "Authentication Required")
      static_password = optional(string, "")      # If set, uses this instead of random password
      username        = optional(string, "admin") # Username for basic auth
      }), {
      secret_name = "default-basic-auth"
      realm       = "Authentication Required"
      username    = "admin"
    })

    # LDAP configuration (used when type = "ldap")
    ldap_config = optional(object({
      method        = optional(string, "forwardauth") # "plugin" or "forwardauth"
      log_level     = optional(string, "INFO")
      url           = optional(string, "")
      port          = optional(number, 389)
      base_dn       = optional(string, "")
      attribute     = optional(string, "uid")
      bind_dn       = optional(string, "")
      bind_password = optional(string, "")
      search_filter = optional(string, "")
      }), {
      method    = "forwardauth"
      log_level = "INFO"
      port      = 389
      attribute = "uid"
    })
  })
  default = {
    enabled = false
  }

  validation {
    condition = !var.default_auth.enabled || !var.default_auth.ldap_override || (
      var.default_auth.ldap_config.url != "" &&
      var.default_auth.ldap_config.base_dn != ""
    )
    error_message = "When default auth LDAP override is enabled, url and base_dn must be provided."
  }
}
