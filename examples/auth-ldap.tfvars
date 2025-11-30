# ============================================================================
# AUTHENTICATION: LDAP Integration
# ============================================================================
# LDAP authentication configuration examples
# ============================================================================

base_domain   = "example.com"
platform_name = "k3s"

# Enable middleware after first deployment
middleware_overrides = {
  enabled = true
}

# JumpCloud LDAP Example
service_overrides = {
  traefik = {
    middleware_config = {
      ldap_auth = {
        enabled   = true
        method    = "forwardauth"
        url       = "ldap://ldap.jumpcloud.com"
        base_dn   = "ou=Users,o=YOUR_ORG_ID,dc=jumpcloud,dc=com"
        attribute = "uid"
      }

      # Basic auth as fallback
      basic_auth = {
        enabled = true
      }
    }
  }
}

# Active Directory Example (commented)
# service_overrides = {
#   traefik = {
#     middleware_config = {
#       ldap_auth = {
#         enabled       = true
#         method        = "forwardauth"
#         url           = "ldap://ad.company.com"
#         base_dn       = "dc=company,dc=com"
#         bind_dn       = "cn=service,dc=company,dc=com"
#         bind_password = "service-password"
#         search_filter = "(sAMAccountName={username})"
#       }
#     }
#   }
# }
