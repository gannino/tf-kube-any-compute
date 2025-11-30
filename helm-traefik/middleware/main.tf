# ============================================================================
# TRAEFIK MIDDLEWARE SUBMODULE - REUSABLE AUTHENTICATION MIDDLEWARE
# ============================================================================
#
# This module provides centralized authentication middleware for Traefik:
#
# Files:
# - basic_auth.tf      - Basic HTTP authentication
# - ldap_auth.tf       - LDAP authentication (ForwardAuth & Plugin methods)
# - security.tf        - Rate limiting and IP whitelisting
# - default_auth.tf    - Default authentication (Basic or LDAP)
# - variables.tf       - Input variables
# - outputs.tf         - Module outputs
# - versions.tf        - Provider requirements
# ============================================================================
