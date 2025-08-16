# ============================================================================
# TRAEFIK MIDDLEWARE SUBMODULE - REUSABLE AUTHENTICATION MIDDLEWARE
# ============================================================================

# Random password for basic authentication (only when static password not provided)
resource "random_password" "basic_auth_password" {
  count   = var.basic_auth.enabled && var.basic_auth.static_password == "" ? 1 : 0
  length  = 16
  special = true
}

# Local value to determine the password to use
locals {
  basic_auth_password = var.basic_auth.enabled ? (
    var.basic_auth.static_password != "" ? var.basic_auth.static_password : random_password.basic_auth_password[0].result
  ) : ""
}

# Basic authentication secret
resource "kubernetes_secret" "basic_auth" {
  count = var.basic_auth.enabled ? 1 : 0

  metadata {
    name      = var.basic_auth.secret_name != "" ? var.basic_auth.secret_name : "${var.name_prefix}-basic-auth-secret"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    users = "${var.basic_auth.username}:${bcrypt(local.basic_auth_password, 10)}"
  }

  type = "Opaque"
}

# Basic Authentication Middleware - only create when CRDs are available
resource "kubernetes_manifest" "basic_auth" {
  count = var.basic_auth.enabled && var.enable_middleware_resources ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-basic-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      basicAuth = {
        secret = kubernetes_secret.basic_auth[0].metadata[0].name
        realm  = var.basic_auth.realm
      }
    }
  }

  depends_on = [kubernetes_secret.basic_auth]
}

# LDAP Authentication Service (ForwardAuth backend)
resource "kubernetes_deployment" "ldap_auth_service" {
  count = var.ldap_auth.enabled && var.ldap_auth.method == "forwardauth" ? 1 : 0

  metadata {
    name      = "${var.name_prefix}-ldap-auth-service"
    namespace = var.namespace
    labels    = var.labels
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "${var.name_prefix}-ldap-auth"
      }
    }
    template {
      metadata {
        labels = merge(var.labels, {
          app = "${var.name_prefix}-ldap-auth"
        })
      }
      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 65534
          run_as_group    = 65534
          fs_group        = 65534
        }
        container {
          name              = "ldap-auth"
          image             = "python:3.11-alpine"
          image_pull_policy = "Always"
          port {
            container_port = 8080
          }
          command = ["/bin/sh", "-c"]
          args = [
            "export HOME=/tmp && export PATH=/tmp/.local/bin:$PATH && pip install --user --no-warn-script-location ldap3 flask gunicorn && gunicorn --bind 0.0.0.0:8080 --workers 2 --timeout 30 ldap-auth:app"
          ]
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
            run_as_non_root            = true
            run_as_user                = 65534
            run_as_group               = 65534
            capabilities {
              drop = ["ALL"]
            }
          }
          startup_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 30
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 0
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 0
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }
          env {
            name  = "LDAP_URL"
            value = var.ldap_auth.url
          }
          env {
            name  = "LDAP_BASE_DN"
            value = var.ldap_auth.base_dn
          }
          # Only include bind credentials if specified
          dynamic "env" {
            for_each = var.ldap_auth.bind_dn != "" ? [1] : []
            content {
              name  = "LDAP_BIND_DN"
              value = var.ldap_auth.bind_dn
            }
          }
          dynamic "env" {
            for_each = var.ldap_auth.bind_password != "" ? [1] : []
            content {
              name  = "LDAP_BIND_PASSWORD"
              value = var.ldap_auth.bind_password
            }
          }
          # Include attribute (defaults to uid if not specified)
          env {
            name  = "LDAP_ATTRIBUTE"
            value = var.ldap_auth.attribute != "" ? var.ldap_auth.attribute : "uid"
          }
          # Only include port if different from default
          dynamic "env" {
            for_each = var.ldap_auth.port != 389 ? [1] : []
            content {
              name  = "LDAP_PORT"
              value = tostring(var.ldap_auth.port)
            }
          }
          # Only include search filter if specified
          dynamic "env" {
            for_each = var.ldap_auth.search_filter != "" ? [1] : []
            content {
              name  = "LDAP_SEARCH_FILTER"
              value = var.ldap_auth.search_filter
            }
          }
          volume_mount {
            name       = "ldap-auth-script"
            mount_path = "/app"
          }
          working_dir = "/app"
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
        volume {
          name = "ldap-auth-script"
          config_map {
            name = kubernetes_config_map.ldap_auth_script[0].metadata[0].name
          }
        }
      }
    }
  }
}

# LDAP Auth Script ConfigMap
resource "kubernetes_config_map" "ldap_auth_script" {
  count = var.ldap_auth.enabled && var.ldap_auth.method == "forwardauth" ? 1 : 0

  metadata {
    name      = "${var.name_prefix}-ldap-auth-script"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    "ldap-auth.py" = <<-EOF
#!/usr/bin/env python3
import os
import base64
from flask import Flask, request, jsonify
from ldap3 import Server, Connection, ALL, NTLM, SUBTREE

app = Flask(__name__)

# LDAP Configuration from environment
LDAP_URL = os.getenv('LDAP_URL', 'ldap://ldap.jumpcloud.com')
LDAP_BASE_DN = os.getenv('LDAP_BASE_DN', '')
LDAP_BIND_DN = os.getenv('LDAP_BIND_DN', '')  # Optional
LDAP_BIND_PASSWORD = os.getenv('LDAP_BIND_PASSWORD', '')  # Optional
LDAP_ATTRIBUTE = os.getenv('LDAP_ATTRIBUTE', 'uid')
LDAP_PORT = int(os.getenv('LDAP_PORT', '389'))
LDAP_SEARCH_FILTER = os.getenv('LDAP_SEARCH_FILTER', '')  # Optional

@app.route('/auth', methods=['GET', 'POST'])
def auth():
    # Get authorization header
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Basic '):
        return '', 401, {'WWW-Authenticate': 'Basic realm="LDAP Authentication"'}

    try:
        # Decode basic auth
        encoded_credentials = auth_header.split(' ')[1]
        decoded_credentials = base64.b64decode(encoded_credentials).decode('utf-8')
        username, password = decoded_credentials.split(':', 1)

        # Connect to LDAP server
        server = Server(LDAP_URL, port=LDAP_PORT, get_info=ALL)

        # Determine authentication method
        if LDAP_SEARCH_FILTER:
            # Use search filter method
            search_filter = LDAP_SEARCH_FILTER.replace('{username}', username)
            if LDAP_BIND_DN and LDAP_BIND_PASSWORD:
                # Authenticated search
                conn = Connection(server, LDAP_BIND_DN, LDAP_BIND_PASSWORD, auto_bind=True)
                conn.search(LDAP_BASE_DN, search_filter, attributes=['dn'])
                if conn.entries:
                    user_dn = str(conn.entries[0].entry_dn)
                    conn.unbind()
                    # Try to bind with user credentials
                    conn = Connection(server, user_dn, password, auto_bind=True)
                else:
                    return '', 401, {'WWW-Authenticate': 'Basic realm="LDAP Authentication"'}
            else:
                # Anonymous search (not recommended)
                conn = Connection(server, auto_bind=True)
                conn.search(LDAP_BASE_DN, search_filter, attributes=['dn'])
                if conn.entries:
                    user_dn = str(conn.entries[0].entry_dn)
                    conn.unbind()
                    # Try to bind with user credentials
                    conn = Connection(server, user_dn, password, auto_bind=True)
                else:
                    return '', 401, {'WWW-Authenticate': 'Basic realm="LDAP Authentication"'}
        else:
            # Use attribute-based method (direct DN construction)
            user_dn = f"{LDAP_ATTRIBUTE}={username},{LDAP_BASE_DN}"
            conn = Connection(server, user_dn, password, auto_bind=True)

        if conn.bind():
            # Authentication successful
            conn.unbind()
            return '', 200, {'X-Forwarded-User': username}
        else:
            # Authentication failed
            return '', 401, {'WWW-Authenticate': 'Basic realm="LDAP Authentication"'}

    except Exception as e:
        print(f"LDAP Auth Error: {e}")
        return '', 401, {'WWW-Authenticate': 'Basic realm="LDAP Authentication"'}

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)

# For Gunicorn
if __name__ != '__main__':
    # Production logging
    import logging
    logging.basicConfig(level=logging.INFO)
EOF
  }
}

# LDAP Authentication Service
resource "kubernetes_service" "ldap_auth_service" {
  count = var.ldap_auth.enabled && var.ldap_auth.method == "forwardauth" ? 1 : 0

  metadata {
    name      = "${var.name_prefix}-ldap-auth-service"
    namespace = var.namespace
    labels    = var.labels
  }

  spec {
    selector = {
      app = "${var.name_prefix}-ldap-auth"
    }
    port {
      port        = 8080
      target_port = 8080
    }
  }
}

# LDAP Authentication Middleware - Plugin Method
resource "kubernetes_manifest" "ldap_auth_plugin" {
  count = var.ldap_auth.enabled && var.ldap_auth.method == "plugin" && var.enable_middleware_resources ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-ldap-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      plugin = {
        ldapAuth = merge(
          # Always include URL and baseDN as they're required
          {
            url    = var.ldap_auth.url
            baseDN = var.ldap_auth.base_dn
          },
          # Conditionally include other parameters only if they're specified
          var.ldap_auth.attribute != "" ? { attribute = var.ldap_auth.attribute } : {},
          var.ldap_auth.bind_dn != "" ? { bindDN = var.ldap_auth.bind_dn } : {},
          var.ldap_auth.bind_password != "" ? { bindPassword = var.ldap_auth.bind_password } : {},
          var.ldap_auth.search_filter != "" ? { filter = var.ldap_auth.search_filter } : {},
          var.ldap_auth.port != 389 ? { port = var.ldap_auth.port } : {},
          var.ldap_auth.log_level != "INFO" ? { logLevel = var.ldap_auth.log_level } : {}
        )
      }
    }
  }
}

# LDAP Authentication Middleware - ForwardAuth Method
resource "kubernetes_manifest" "ldap_auth_forwardauth" {
  count = var.ldap_auth.enabled && var.ldap_auth.method == "forwardauth" && var.enable_middleware_resources ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-ldap-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      forwardAuth = {
        address = "http://${kubernetes_service.ldap_auth_service[0].metadata[0].name}.${var.namespace}.svc.cluster.local:8080/auth"
        authResponseHeaders = [
          "X-Forwarded-User"
        ]
      }
    }
  }

  depends_on = [kubernetes_service.ldap_auth_service]
}

# Rate Limiting Middleware - only create when CRDs are available
resource "kubernetes_manifest" "rate_limit" {
  count = var.rate_limit.enabled && var.enable_middleware_resources ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-rate-limit"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      rateLimit = {
        average = var.rate_limit.average
        burst   = var.rate_limit.burst
      }
    }
  }
}

# IP Whitelist Middleware - only create when CRDs are available
resource "kubernetes_manifest" "ip_whitelist" {
  count = var.ip_whitelist.enabled && var.enable_middleware_resources ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-ip-whitelist"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      ipAllowList = {
        sourceRange = var.ip_whitelist.source_ranges
      }
    }
  }
}

# Random password for default authentication (basic auth mode, only when static password not provided)
resource "random_password" "default_auth_password" {
  count   = var.default_auth.enabled && !var.default_auth.ldap_override && var.default_auth.basic_config.static_password == "" ? 1 : 0
  length  = 16
  special = true
}

# Local value to determine the default auth password to use
locals {
  default_auth_password = var.default_auth.enabled && !var.default_auth.ldap_override ? (
    var.default_auth.basic_config.static_password != "" ? var.default_auth.basic_config.static_password : random_password.default_auth_password[0].result
  ) : ""
}

# Default authentication secret (basic auth mode)
resource "kubernetes_secret" "default_auth" {
  count = var.default_auth.enabled && !var.default_auth.ldap_override ? 1 : 0

  metadata {
    name      = var.default_auth.basic_config.secret_name != "" ? var.default_auth.basic_config.secret_name : "${var.name_prefix}-default-auth-secret"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    users = "${var.default_auth.basic_config.username}:${bcrypt(local.default_auth_password, 10)}"
  }

  type = "Opaque"
}

# Default Authentication Middleware - LDAP ForwardAuth version - only create when CRDs are available
resource "kubernetes_manifest" "default_auth_ldap_forwardauth" {
  count = var.default_auth.enabled && var.default_auth.ldap_override && var.default_auth.ldap_config.method == "forwardauth" && var.enable_middleware_resources ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-default-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      forwardAuth = {
        address = "http://${var.name_prefix}-ldap-auth-service.${var.namespace}.svc.cluster.local:8080/auth"
        authResponseHeaders = [
          "X-Forwarded-User"
        ]
      }
    }
  }
}

# Default Authentication Middleware - LDAP Plugin version - only create when CRDs are available
resource "kubernetes_manifest" "default_auth_ldap_plugin" {
  count = var.default_auth.enabled && var.default_auth.ldap_override && var.default_auth.ldap_config.method == "plugin" && var.enable_middleware_resources ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-default-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      plugin = {
        ldapAuth = merge(
          # Always include URL and baseDN as they're required
          {
            url    = var.default_auth.ldap_config.url
            baseDN = var.default_auth.ldap_config.base_dn
          },
          # Conditionally include other parameters only if they're specified
          var.default_auth.ldap_config.attribute != "" ? { attribute = var.default_auth.ldap_config.attribute } : {},
          var.default_auth.ldap_config.bind_dn != "" ? { bindDN = var.default_auth.ldap_config.bind_dn } : {},
          var.default_auth.ldap_config.bind_password != "" ? { bindPassword = var.default_auth.ldap_config.bind_password } : {},
          var.default_auth.ldap_config.search_filter != "" ? { filter = var.default_auth.ldap_config.search_filter } : {},
          var.default_auth.ldap_config.port != 389 ? { port = var.default_auth.ldap_config.port } : {},
          var.default_auth.ldap_config.log_level != "INFO" ? { logLevel = var.default_auth.ldap_config.log_level } : {}
        )
      }
    }
  }
}

# Default Authentication Middleware - Basic Auth version (default) - only create when CRDs are available
resource "kubernetes_manifest" "default_auth_basic" {
  count = var.default_auth.enabled && !var.default_auth.ldap_override && var.enable_middleware_resources ? 1 : 0

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "${var.name_prefix}-default-auth"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      basicAuth = {
        secret = kubernetes_secret.default_auth[0].metadata[0].name
        realm  = var.default_auth.basic_config.realm
      }
    }
  }

  depends_on = [kubernetes_secret.default_auth]
}
