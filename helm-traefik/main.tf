# ============================================================================
# HELM-TRAEFIK MODULE - STANDARDIZED RESOURCE DEPLOYMENT
# ============================================================================

# Create Traefik namespace
resource "kubernetes_namespace" "this" {
  metadata {
    annotations = merge(
      {
        name = local.module_config.namespace
      },
      local.common_labels
    )
    labels = local.common_labels
    name   = local.module_config.namespace
  }
}

# Initialize ACME files with correct permissions before Traefik starts
# This Job runs when using Longhorn storage to ensure ACME files exist with secure permissions (600)
# before Traefik pod starts, preventing the resolver from being skipped due to permission errors
resource "kubernetes_job" "acme_initializer" {
  count = var.storage_class == "longhorn" ? 1 : 0

  metadata {
    name      = "${local.module_config.name}-acme-initializer"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = merge(
      {
        "app.kubernetes.io/name" = "acme-initializer"
      },
      local.common_labels
    )
  }

  spec {
    template {
      metadata {
        labels = merge(
          {
            "app.kubernetes.io/name" = "acme-initializer"
          },
          local.common_labels
        )
      }

      spec {
        restart_policy = "OnFailure"

        # Run as root to set permissions correctly
        security_context {
          run_as_user  = 0
          run_as_group = 0
        }

        container {
          name  = "acme-initializer"
          image = "busybox:1.36"

          command = ["/bin/sh", "-c"]
          args    = [local.acme_init_script]

          volume_mount {
            name       = "certs"
            mount_path = "/certs"
          }
        }

        volume {
          name = "certs"

          persistent_volume_claim {
            claim_name = "${local.module_config.name}-certs"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim.traefik
  ]
}

# Safety check: Verify Traefik deployment has correct security context for Longhorn
# Primary fix: kubernetes_job runs before Helm to initialize ACME files
# This resource: Checks and patches deployment template, conditional rollout if needed
resource "null_resource" "traefik_security_context_patch" {
  # Run when Traefik is deployed to verify configuration
  triggers = {
    deployment_name = local.module_config.name
    namespace       = kubernetes_namespace.this.metadata[0].name
    storage_class   = var.storage_class
    helm_release    = helm_release.this.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      STORAGE_CLASS="${var.storage_class}"
      PVC_NAME="${local.module_config.name}-certs"
      DEPLOYMENT_NAME="${local.module_config.name}"
      NAMESPACE="${kubernetes_namespace.this.metadata[0].name}"

      echo "=== Traefik Security Context Safety Check ==="
      echo "Storage class: $STORAGE_CLASS"

      # Get PVC storage class
      PVC_STORAGE_CLASS=$(kubectl get pvc $PVC_NAME -n $NAMESPACE -o jsonpath='{.spec.storageClassName}' 2>/dev/null || echo "")
      echo "PVC storage class: $PVC_STORAGE_CLASS"

      if [[ "$STORAGE_CLASS" == "longhorn" || "$PVC_STORAGE_CLASS" == "longhorn" ]]; then
        echo "Longhorn storage detected"

        # Check if deployment already has fsGroup configured
        EXISTING_FSGROUP=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE \
                          -o jsonpath='{.spec.template.spec.securityContext.fsGroup}' 2>/dev/null || echo "")

        if [[ "$EXISTING_FSGROUP" == "${var.traefik_gid}" ]]; then
          echo "Deployment already has fsGroup=${var.traefik_gid} configured - no patch needed"

          # Just fix permissions on running pod as a safety measure
          POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=traefik \
                      -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null | head -1)

          if [[ -n "$POD_NAME" ]]; then
            echo "Found running pod: $POD_NAME"
            echo "Fixing ACME permissions on running pod..."
            # Fix permissions from outside the pod (as root) using kubectl exec
            kubectl exec $POD_NAME -n $NAMESPACE -- sh -c "
              chown ${var.traefik_uid}:${var.traefik_gid} /certs/*.json 2>/dev/null || echo 'chown failed'
              chmod 600 /certs/*.json 2>/dev/null || echo 'chmod failed'
              ls -la /certs/*.json 2>/dev/null || echo 'No JSON files'
            " || echo "Could not exec into pod"
          fi

        else
          echo "Deployment missing fsGroup - applying patch..."

          # Apply fsGroup patch to deployment template
          kubectl patch deployment $DEPLOYMENT_NAME \
            -n $NAMESPACE \
            --type=strategic \
            -p '{
              "spec": {
                "template": {
                  "spec": {
                    "securityContext": {
                      "fsGroup": 65532,
                      "fsGroupChangePolicy": "Always",
                      "seccompProfile": {
                        "type": "RuntimeDefault"
                      }
                    }
                  }
                }
              }
          }' || echo "Patch failed or deployment not ready"

          echo "Patch applied - terminating running pod to pick up new deployment spec..."

          # Get the running pod name
          POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=traefik \
                      -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null | head -1)

          # Terminate it with retry logic for Longhorn CSI database lock issues
          if [[ -n "$POD_NAME" ]]; then
            echo "Found running pod: $POD_NAME"

            # Wait for any pending volume operations to settle
            echo "Waiting for volume operations to settle..."
            sleep 5

            # Retry logic with exponential backoff (max 3 attempts)
            MAX_ATTEMPTS=3
            ATTEMPT=1
            DELETE_SUCCESS=false

            while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
              if kubectl delete pod $POD_NAME -n $NAMESPACE --grace-period=30 2>&1; then
                echo "Pod terminated successfully (attempt $ATTEMPT/$MAX_ATTEMPTS)"
                DELETE_SUCCESS=true
                break
              else
                echo "Delete failed (attempt $ATTEMPT/$MAX_ATTEMPTS)"
                if [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; then
                  WAIT_TIME=$((ATTEMPT * 10))
                  echo "Retrying in $WAIT_TIME s..."
                  sleep $WAIT_TIME
                fi
              fi
              ATTEMPT=$((ATTEMPT + 1))
            done

            if [[ "$DELETE_SUCCESS" == "true" ]]; then
              echo "New pod will be created automatically by deployment"
            else
              echo "Pod deletion failed after $MAX_ATTEMPTS attempts - continuing anyway"
              echo "Deployment replica set will create new pod with patched spec"
            fi
          else
            echo "No running pod found to terminate"
          fi
        fi

        echo "=== Safety check completed ==="
      else
        echo "Longhorn storage not in use - skipping fsGroup patch"
      fi
    EOT

    interpreter = ["/bin/sh", "-c"]
  }

  depends_on = [helm_release.this]
}

# Deploy Traefik Ingress Controller
resource "helm_release" "this" {
  name       = local.module_config.name
  chart      = local.module_config.chart_name
  repository = local.module_config.chart_repo
  version    = local.module_config.chart_version
  namespace  = kubernetes_namespace.this.metadata[0].name

  # Helm configuration using locals
  timeout          = local.helm_config.timeout
  disable_webhooks = local.helm_config.disable_webhooks
  skip_crds        = local.helm_config.skip_crds
  replace          = local.helm_config.replace
  force_update     = local.helm_config.force_update
  cleanup_on_fail  = local.helm_config.cleanup_on_fail
  wait             = local.helm_config.wait
  wait_for_jobs    = local.helm_config.wait_for_jobs

  values = [
    templatefile("${path.module}/templates/traefik-values.yaml.tpl", local.template_values)
  ]

  depends_on = [
    kubernetes_secret.he_dns_token,
    kubernetes_secret.cloudflare_dns_credentials,
    kubernetes_secret.route53_dns_credentials,
    kubernetes_secret.digitalocean_dns_credentials,
    kubernetes_secret.gandi_dns_credentials,
    kubernetes_secret.namecheap_dns_credentials,
    kubernetes_secret.godaddy_dns_credentials,
    kubernetes_secret.ovh_dns_credentials,
    kubernetes_secret.linode_dns_credentials,
    kubernetes_secret.vultr_dns_credentials,
    kubernetes_secret.hetzner_dns_credentials,
    kubernetes_secret.additional_dns_credentials,
    kubernetes_namespace.this,
    kubernetes_job.acme_initializer
  ]
}

# Wait for Traefik CRDs to be registered
resource "null_resource" "wait_for_traefik_crds" {
  depends_on = [helm_release.this]

  provisioner "local-exec" {
    command     = <<EOT
      echo "Waiting for Traefik CRDs to be registered..."

      # List of critical Traefik CRDs to wait for
      CRDS=(
        "ingressroutes.traefik.io"
        "ingressroutetcps.traefik.io"
        "ingressrouteudps.traefik.io"
        "middlewares.traefik.io"
        "tlsoptions.traefik.io"
        "tlsstores.traefik.io"
        "traefikservices.traefik.io"
        "serverstransports.traefik.io"
      )

      for crd in "$${CRDS[@]}"; do
        echo "Waiting for CRD: $crd"
        for i in {1..60}; do
          if kubectl get crd "$crd" >/dev/null 2>&1; then
            echo "CRD $crd is ready"
            break
          fi
          echo "Waiting for CRD $crd... ($i/60)"
          sleep 3
        done

        if ! kubectl get crd "$crd" >/dev/null 2>&1; then
          echo "Error: CRD $crd was not registered after waiting."
          exit 1
        fi
      done

      echo "All Traefik CRDs are ready!"

      # Final verification - ensure CRDs are actually usable
      echo "Verifying CRDs are functional..."
      kubectl api-resources --api-group=traefik.io >/dev/null 2>&1 || {
        echo "Error: Traefik CRDs are not properly registered in the API server"
        exit 1
      }
      echo "Traefik CRDs verification complete!"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# Wait for Traefik deployment to be ready
resource "null_resource" "wait_for_traefik_deployment" {
  depends_on = [null_resource.wait_for_traefik_crds]

  provisioner "local-exec" {
    command     = <<EOT
      echo "Waiting for Traefik deployment to be ready..."
      kubectl wait --for=condition=available --timeout=${local.module_config.deployment_wait_timeout}s deployment/${var.name} -n ${kubernetes_namespace.this.metadata[0].name}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "kubernetes_manifest" "traefik_ingress_class" {
  count = var.create_ingress_class ? 1 : 0

  manifest = {
    apiVersion = var.ingress_api_version
    kind       = "IngressClass"
    metadata = {
      name = "traefik"
      annotations = {
        "ingressclass.kubernetes.io/is-default-class" = "true"
      }
    }
    spec = {
      controller = "traefik.io/ingress-controller"
    }
  }
  depends_on = [null_resource.wait_for_traefik_deployment]
}

data "kubernetes_service" "this" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  depends_on = [helm_release.this]
}


# Deploy middleware resources - only after CRDs are available
module "middleware" {
  count  = var.enable_middleware ? 1 : 0
  source = "./middleware"

  providers = {
    kubernetes = kubernetes
    kubectl    = kubectl
    random     = random
  }

  namespace   = kubernetes_namespace.this.metadata[0].name
  name_prefix = var.name
  labels      = local.common_labels
  domain_name = var.domain_name

  # Enable middleware resources only after CRDs are ready
  enable_middleware_resources = true

  # Authentication middleware configuration
  basic_auth = var.middleware_config.basic_auth
  ldap_auth  = var.middleware_config.ldap_auth

  # Security middleware configuration
  rate_limit   = var.middleware_config.rate_limit
  ip_whitelist = var.middleware_config.ip_whitelist

  # Default authentication middleware
  default_auth = var.middleware_config.default_auth

  depends_on = [
    null_resource.wait_for_traefik_crds,
    null_resource.wait_for_traefik_deployment,
  ]
}

module "ingress" {
  count                 = var.enable_ingress && var.enable_middleware ? 1 : 0
  source                = "./ingress"
  namespace             = kubernetes_namespace.this.metadata[0].name
  domain_name           = var.domain_name
  service_name          = data.kubernetes_service.this.metadata[0].name
  traefik_cert_resolver = var.traefik_cert_resolver
  dashboard_middleware  = var.dashboard_middleware
  depends_on = [
    null_resource.wait_for_traefik_crds,
    null_resource.wait_for_traefik_deployment,
  ]
}
