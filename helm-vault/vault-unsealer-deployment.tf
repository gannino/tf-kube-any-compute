resource "kubernetes_deployment" "vault_unsealer" {
  metadata {
    name      = "${var.name}-unsealer"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      app = "${var.name}-unsealer"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.name}-unsealer"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.name}-unsealer"
        }
      }

      spec {
        service_account_name = data.kubernetes_service_account.vault.metadata[0].name
        security_context {
          run_as_non_root = true
          run_as_user     = 65534
          run_as_group    = 65534
          fs_group        = 65534
        }

        container {
          name              = "vault-unsealer"
          image             = "curlimages/curl:latest"
          image_pull_policy = "Always"

          command = ["/bin/sh"]
          args    = ["-c", "while true; do /scripts/vault-unsealer.sh; sleep 30; done"]

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 65534
            run_as_group               = 65534
            capabilities {
              drop = ["ALL"]
            }
          }

          # Health check endpoint for unsealer
          liveness_probe {
            exec {
              command = ["/bin/sh", "-c", "ps aux | grep vault-unsealer.sh | grep -v grep"]
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          readiness_probe {
            exec {
              command = ["/bin/sh", "-c", "test -f /scripts/vault-unsealer.sh"]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          env {
            name  = "VAULT_SERVICE"
            value = var.name
          }

          env {
            name  = "VAULT_NAMESPACE"
            value = kubernetes_namespace.this.metadata[0].name
          }

          volume_mount {
            name       = "vault-scripts"
            mount_path = "/scripts"
            read_only  = true
          }

          volume_mount {
            name       = "sa-token"
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            read_only  = true
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }

        volume {
          name = "vault-scripts"
          config_map {
            name         = kubernetes_config_map.vault_scripts.metadata[0].name
            default_mode = "0555"
          }
        }

        volume {
          name = "sa-token"
          projected {
            sources {
              service_account_token {
                path               = "token"
                expiration_seconds = 3607
              }
              config_map {
                name = "kube-root-ca.crt"
                items {
                  key  = "ca.crt"
                  path = "ca.crt"
                }
              }
              downward_api {
                items {
                  path = "namespace"
                  field_ref {
                    field_path = "metadata.namespace"
                  }
                }
              }
            }
          }
        }

        restart_policy = "Always"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].volume[1].projected[0].sources
    ]
  }
}
