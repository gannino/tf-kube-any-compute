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

# Patch Traefik deployment with fsGroup for Longhorn PVC ownership
# Traefik Helm chart sets runAsUser/runAsGroup but NOT fsGroup
# Longhorn CSI requires fsGroup to set correct volume ownership
# Script checks if Longhorn is being used before applying patch
resource "null_resource" "traefik_security_context_patch" {
  # Always run the patch when Traefik is deployed (to handle both initial install and re-installs)
  # The script internally checks if Longhorn storage is in use
  triggers = {
    deployment_name = local.module_config.name
    namespace       = kubernetes_namespace.this.metadata[0].name
    storage_class   = var.storage_class
    helm_release    = helm_release.this.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      # Check if Longhorn storage class is being used
      STORAGE_CLASS="${var.storage_class}"
      PVC_NAME="${local.module_config.name}-certs"
      NAMESPACE="${kubernetes_namespace.this.metadata[0].name}"

      echo "Checking PVC storage class..."
      PVC_STORAGE_CLASS=$(kubectl get pvc $PVC_NAME -n $NAMESPACE -o jsonpath='{.spec.storageClassName}' 2>/dev/null || echo "")

      if [[ "$STORAGE_CLASS" == "longhorn" || "$PVC_STORAGE_CLASS" == "longhorn" ]]; then
        echo "Longhorn storage detected. Applying security context patch for Traefik..."

        # Apply strategic merge patch to add fsGroup
        kubectl patch deployment ${local.module_config.name} \
          -n ${kubernetes_namespace.this.metadata[0].name} \
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
          }'

        echo "Security context patch applied successfully"

        # Restart deployment to apply new security context to pods
        echo "Restarting Traefik deployment to apply new security context..."
        kubectl rollout restart deployment ${local.module_config.name} \
          -n ${kubernetes_namespace.this.metadata[0].name}

        # Wait for rollout to complete
        echo "Waiting for rollout to complete..."
        kubectl rollout status deployment ${local.module_config.name} \
          -n ${kubernetes_namespace.this.metadata[0].name} \
          --timeout=300s

        # Fix existing acme.json file permissions (if they exist)
        echo "Fixing existing acme.json file permissions to 600..."
        POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=traefik -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
        if [[ -n "$POD_NAME" ]]; then
          kubectl exec $POD_NAME -n $NAMESPACE -- sh -c 'chmod 600 /certs/*.json 2>/dev/null || echo "No .json files to fix"' || echo "Permission fix completed"
        fi

        echo "Rollout completed successfully"
        echo "Verifying new pods have fsGroup configured..."
        kubectl get deployment ${local.module_config.name} \
          -n ${kubernetes_namespace.this.metadata[0].name} \
          -o jsonpath='{.spec.template.spec.securityContext}' | jq .
      else
        echo "Longhorn storage not in use (storage_class: $STORAGE_CLASS, pvc_storage_class: $PVC_STORAGE_CLASS)"
        echo "Skipping fsGroup patch - not needed for other storage classes"
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
    kubernetes_namespace.this
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
