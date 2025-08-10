locals {
  # Module configuration
  module_config = {
    component = "policy-crds"
  }

  # Standardized labels
  common_labels = {
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/component"  = local.module_config.component
    "app.kubernetes.io/part-of"    = "infrastructure"
    "app.kubernetes.io/managed-by" = "terraform"
  }

  # Split the YAML into individual documents
  gatekeeper_manifests = split("---", data.http.gatekeeper_crds.response_body)

  # Filter for CRD manifests only and add standardized labels
  crd_manifests = [
    for manifest in local.gatekeeper_manifests :
    merge(yamldecode(manifest), {
      metadata = merge(
        yamldecode(manifest).metadata,
        {
          labels = merge(
            lookup(yamldecode(manifest).metadata, "labels", {}),
            local.common_labels
          )
        }
      )
    })
    if can(yamldecode(manifest)) &&
    lookup(yamldecode(manifest), "kind", "") == "CustomResourceDefinition"
  ]

  # Gatekeeper configuration
  gatekeeper_config = {
    version       = var.gatekeeper_version
    crd_url       = "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-${var.gatekeeper_version}/deploy/gatekeeper.yaml"
    wait_duration = var.crd_wait_duration
    api_version   = var.crd_api_version
  }
}
