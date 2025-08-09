resource "kubernetes_manifest" "pvc_size_limit_template" {
  count = var.enable_hostpath_policy ? 1 : 0

  manifest = {
    "apiVersion" = "templates.gatekeeper.sh/v1beta1"
    "kind"       = "ConstraintTemplate"
    "metadata" = {
      "name" = "pvcsize"
    }
    "spec" = {
      "crd" = {
        "spec" = {
          "names" = {
            "kind" = "PvcSize"
          }
          "validation" = {
            "openAPIV3Schema" = {
              "type" = "object"
              "properties" = {
                "maxSize" = {
                  "type"        = "string"
                  "description" = "Maximum allowed storage size"
                }
                "storageClass" = {
                  "type"        = "string"
                  "description" = "Storage class to apply the limit to"
                }
              }
            }
          }
        }
      }
      "targets" = [
        {
          "target" = "admission.k8s.gatekeeper.sh"
          "rego"   = <<-EOT
            package pvcsize

            # Deny PVCs that request more storage than allowed for a specific storage class
            violation[{"msg": msg}] {
              input.review.object.kind == "PersistentVolumeClaim"
              requested_storage := input.review.object.spec.resources.requests.storage
              requested_storage_class := input.review.object.spec.storageClassName

              allowed_max_size := input.parameters.maxSize
              allowed_storage_class := input.parameters.storageClass

              # Only apply constraint to matching storage class
              requested_storage_class == allowed_storage_class

              requested_bytes := parse_quantity_to_bytes(requested_storage)
              max_bytes := parse_quantity_to_bytes(allowed_max_size)

              requested_bytes > max_bytes

              msg := sprintf(
                "PVC storage request (%s) exceeds max allowed size (%s) for storageClass %s",
                [requested_storage, allowed_max_size, requested_storage_class]
              )
            }

            # Helper function to parse Kubernetes quantity strings to bytes
            parse_quantity_to_bytes(quantity) = bytes {
              endswith(quantity, "Gi")
              size_gi := to_number(trim_suffix(quantity, "Gi"))
              bytes := size_gi * 1073741824  # 1024^3
            }

            parse_quantity_to_bytes(quantity) = bytes {
              endswith(quantity, "Mi")
              size_mi := to_number(trim_suffix(quantity, "Mi"))
              bytes := size_mi * 1048576  # 1024^2
            }

            parse_quantity_to_bytes(quantity) = bytes {
              endswith(quantity, "Ki")
              size_ki := to_number(trim_suffix(quantity, "Ki"))
              bytes := size_ki * 1024
            }

            parse_quantity_to_bytes(quantity) = bytes {
              not endswith(quantity, "Gi")
              not endswith(quantity, "Mi")
              not endswith(quantity, "Ki")
              bytes := to_number(quantity)
            }
          EOT
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "pvc_size_limit_constraint" {
  count = var.enable_hostpath_policy ? 1 : 0

  manifest = {
    "apiVersion" = "constraints.gatekeeper.sh/v1beta1"
    "kind"       = "PvcSize"
    "metadata" = {
      "name" = "pvc-size-limit-hostpath"
    }
    "spec" = {
      "match" = {
        "kinds" = [
          {
            "apiGroups" = [""]
            "kinds"     = ["PersistentVolumeClaim"]
          }
        ]
        "excludedNamespaces" = ["kube-system", "kube-public", "gatekeeper-system"]
      }
      "parameters" = {
        "maxSize"      = var.hostpath_max_size
        "storageClass" = var.hostpath_storage_class
      }
    }
  }
  depends_on = [kubernetes_manifest.pvc_size_limit_template]
}
