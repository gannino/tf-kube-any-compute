resource "kubernetes_job" "vault_init" {
  metadata {
    name      = "${var.name}-init"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      app = "${var.name}-init"
    }
  }

  spec {
    backoff_limit = 10
    completions   = 1
    parallelism   = 1

    template {
      metadata {
        labels = {
          app = "${var.name}-init"
        }
      }

      spec {
        service_account_name = data.kubernetes_service_account.vault.metadata[0].name
        restart_policy       = "OnFailure"

        container {
          name  = "vault-init"
          image = "curlimages/curl:latest"

          command = ["/bin/sh"]
          args    = ["-c", "/scripts/vault-init.sh"]

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
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
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
      }
    }
  }

  wait_for_completion = false
  timeouts {
    create = "10m"
    update = "10m"
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].volume[1].projected[0].sources
    ]
  }
}
