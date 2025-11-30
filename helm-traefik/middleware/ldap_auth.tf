# Secret for LDAP Auth (SECRET_KEY for HMAC signing)
resource "random_password" "ldap_auth_secret_key" {
  count   = var.ldap_auth.enabled && var.ldap_auth.method == "forwardauth" ? 1 : 0
  length  = 64
  special = true
}

resource "kubernetes_secret" "ldap_auth_secret" {
  count = var.ldap_auth.enabled && var.ldap_auth.method == "forwardauth" ? 1 : 0

  metadata {
    name      = "${var.name_prefix}-ldap-auth-secret"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    secret_key = base64encode(random_password.ldap_auth_secret_key[0].result)
  }
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
        annotations = {
          "checksum/config" = sha256(kubernetes_config_map.ldap_auth_script[0].data["ldap-auth.py"])
        }
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
          image             = "python:3.13-alpine"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 8080
          }
          command = ["/bin/sh", "-c"]
          args = [
            "export HOME=/tmp && export PATH=/tmp/.local/bin:$PATH && pip install --user --no-warn-script-location ldap3 flask gunicorn && gunicorn --bind 0.0.0.0:8080 --workers 2 --timeout 30 --access-logfile - --error-logfile - --log-level info ldap-auth:app"
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
          env {
            name  = "AUTH_DOMAIN"
            value = "auth.${var.domain_name}"
          }
          env {
            name = "SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.ldap_auth_secret[0].metadata[0].name
                key  = "secret_key"
              }
            }
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
    "ldap-auth.py" = file("${path.module}/ldap-auth.py")
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
resource "kubectl_manifest" "ldap_auth_plugin" {
  count = var.ldap_auth.enabled && var.ldap_auth.method == "plugin" && var.enable_middleware_resources ? 1 : 0

  yaml_body = yamlencode({
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
  })
}

# LDAP Authentication Middleware - ForwardAuth Method
resource "kubectl_manifest" "ldap_auth_forwardauth" {
  count = var.ldap_auth.enabled && var.ldap_auth.method == "forwardauth" && var.enable_middleware_resources ? 1 : 0

  yaml_body = yamlencode({
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
  })

  depends_on = [kubernetes_service.ldap_auth_service]
}

# Public IngressRoute for login endpoint
resource "kubernetes_ingress_v1" "ldap_auth_ingress" {
  count = var.ldap_auth.enabled && var.ldap_auth.method == "forwardauth" ? 1 : 0

  metadata {
    name      = "${var.name_prefix}-ldap-auth-public"
    namespace = var.namespace
    labels    = var.labels
    annotations = merge(
      {
        "traefik.ingress.kubernetes.io/router.tls" = "true"
        "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
      },
      # Add IP whitelist middleware if configured
      var.ip_whitelist.enabled ? {
        "traefik.ingress.kubernetes.io/router.middlewares" = join(",", compact([
          var.ip_whitelist.enabled ? "${var.namespace}-${var.name_prefix}-ip-whitelist@kubernetescrd" : "",
          var.rate_limit.enabled ? "${var.namespace}-${var.name_prefix}-rate-limit@kubernetescrd" : ""
        ]))
      } : {},
      # Add rate limiter middleware if configured and no IP whitelist
      !var.ip_whitelist.enabled && var.rate_limit.enabled ? {
        "traefik.ingress.kubernetes.io/router.middlewares" = "${var.namespace}-${var.name_prefix}-rate-limit@kubernetescrd"
      } : {}
    )
  }

  spec {
    ingress_class_name = var.name_prefix

    rule {
      host = "auth.${var.domain_name}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.ldap_auth_service[0].metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
    tls {
      hosts = ["auth.${var.domain_name}"]
    }
  }

  depends_on = [kubernetes_service.ldap_auth_service]
}
