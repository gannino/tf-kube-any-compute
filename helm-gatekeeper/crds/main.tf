# Gatekeeper CRDs Module
# This module deploys Gatekeeper CRDs separately to avoid dependency issues

# Fetch Gatekeeper CRDs from the official release
data "http" "gatekeeper_crds" {
  url = local.gatekeeper_config.crd_url
}

# Apply each CRD with standardized labels
resource "kubernetes_manifest" "gatekeeper_crds" {
  for_each = {
    for idx, manifest in local.crd_manifests :
    manifest.metadata.name => manifest
  }

  manifest = each.value

  # Use server-side apply to handle provider inconsistencies
  field_manager {
    name            = "terraform"
    force_conflicts = true
  }

  # Suppress provider inconsistency errors for CRD fields
  lifecycle {
    ignore_changes = [
      manifest.spec.preserveUnknownFields,
      manifest.status
    ]
  }

  wait {
    condition {
      type   = "Established"
      status = "True"
    }
  }
}

# Wait for CRDs to be fully registered
resource "time_sleep" "wait_for_crds" {
  depends_on = [kubernetes_manifest.gatekeeper_crds]

  create_duration = local.gatekeeper_config.wait_duration
}
