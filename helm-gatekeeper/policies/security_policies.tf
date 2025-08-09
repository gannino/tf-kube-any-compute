# Require Security Context for Pods
resource "kubernetes_manifest" "require_security_context_template" {
  count = var.enable_security_policies ? 1 : 0

  manifest = {
    "apiVersion" = "templates.gatekeeper.sh/v1beta1"
    "kind"       = "ConstraintTemplate"
    "metadata" = {
      "name" = "requiresecuritycontext"
    }
    "spec" = {
      "crd" = {
        "spec" = {
          "names" = {
            "kind" = "RequireSecurityContext"
          }
        }
      }
      "targets" = [
        {
          "target" = "admission.k8s.gatekeeper.sh"
          "rego"   = <<-EOT
            package requiresecuritycontext

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              not input.review.object.spec.securityContext.runAsNonRoot
              msg := "Pod must specify runAsNonRoot: true in securityContext"
            }

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              container := input.review.object.spec.containers[_]
              not container.securityContext.allowPrivilegeEscalation == false
              msg := sprintf("Container %s must specify allowPrivilegeEscalation: false", [container.name])
            }

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              container := input.review.object.spec.containers[_]
              not container.securityContext.readOnlyRootFilesystem == true
              msg := sprintf("Container %s must specify readOnlyRootFilesystem: true", [container.name])
            }
          EOT
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "require_security_context_constraint" {
  count = var.enable_security_policies ? 1 : 0

  manifest = {
    "apiVersion" = "constraints.gatekeeper.sh/v1beta1"
    "kind"       = "RequireSecurityContext"
    "metadata" = {
      "name" = "require-security-context"
    }
    "spec" = {
      "match" = {
        "kinds" = [
          {
            "apiGroups" = [""]
            "kinds"     = ["Pod"]
          }
        ]
        "excludedNamespaces" = ["kube-system", "kube-public", "gatekeeper-system"]
      }
    }
  }
  depends_on = [kubernetes_manifest.require_security_context_template]
}

# Disallow Privileged Containers
resource "kubernetes_manifest" "disallow_privileged_template" {
  count = var.enable_security_policies ? 1 : 0

  manifest = {
    "apiVersion" = "templates.gatekeeper.sh/v1beta1"
    "kind"       = "ConstraintTemplate"
    "metadata" = {
      "name" = "disallowprivileged"
    }
    "spec" = {
      "crd" = {
        "spec" = {
          "names" = {
            "kind" = "DisallowPrivileged"
          }
        }
      }
      "targets" = [
        {
          "target" = "admission.k8s.gatekeeper.sh"
          "rego"   = <<-EOT
            package disallowprivileged

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              container := input.review.object.spec.containers[_]
              container.securityContext.privileged == true
              msg := sprintf("Container %s cannot run in privileged mode", [container.name])
            }

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              container := input.review.object.spec.initContainers[_]
              container.securityContext.privileged == true
              msg := sprintf("Init container %s cannot run in privileged mode", [container.name])
            }
          EOT
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "disallow_privileged_constraint" {
  count = var.enable_security_policies ? 1 : 0

  manifest = {
    "apiVersion" = "constraints.gatekeeper.sh/v1beta1"
    "kind"       = "DisallowPrivileged"
    "metadata" = {
      "name" = "disallow-privileged"
    }
    "spec" = {
      "match" = {
        "kinds" = [
          {
            "apiGroups" = [""]
            "kinds"     = ["Pod"]
          }
        ]
        "excludedNamespaces" = ["kube-system", "kube-public", "gatekeeper-system"]
      }
    }
  }
  depends_on = [kubernetes_manifest.disallow_privileged_template]
}

# Require Resource Limits
resource "kubernetes_manifest" "require_resources_template" {
  count = var.enable_resource_policies ? 1 : 0

  manifest = {
    "apiVersion" = "templates.gatekeeper.sh/v1beta1"
    "kind"       = "ConstraintTemplate"
    "metadata" = {
      "name" = "requireresources"
    }
    "spec" = {
      "crd" = {
        "spec" = {
          "names" = {
            "kind" = "RequireResources"
          }
        }
      }
      "targets" = [
        {
          "target" = "admission.k8s.gatekeeper.sh"
          "rego"   = <<-EOT
            package requireresources

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              container := input.review.object.spec.containers[_]
              not container.resources.limits.memory
              msg := sprintf("Container %s must specify memory limits", [container.name])
            }

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              container := input.review.object.spec.containers[_]
              not container.resources.limits.cpu
              msg := sprintf("Container %s must specify CPU limits", [container.name])
            }

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              container := input.review.object.spec.containers[_]
              not container.resources.requests.memory
              msg := sprintf("Container %s must specify memory requests", [container.name])
            }

            violation[{"msg": msg}] {
              input.review.object.kind == "Pod"
              container := input.review.object.spec.containers[_]
              not container.resources.requests.cpu
              msg := sprintf("Container %s must specify CPU requests", [container.name])
            }
          EOT
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "require_resources_constraint" {
  count = var.enable_resource_policies ? 1 : 0

  manifest = {
    "apiVersion" = "constraints.gatekeeper.sh/v1beta1"
    "kind"       = "RequireResources"
    "metadata" = {
      "name" = "require-resources"
    }
    "spec" = {
      "match" = {
        "kinds" = [
          {
            "apiGroups" = [""]
            "kinds"     = ["Pod"]
          }
        ]
        "excludedNamespaces" = ["kube-system", "kube-public", "gatekeeper-system"]
      }
    }
  }
  depends_on = [kubernetes_manifest.require_resources_template]
}
