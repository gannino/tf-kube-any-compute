# Wait for CRDs to be established after Helm deployment
resource "time_sleep" "wait_for_crds" {
  depends_on = [helm_release.this]

  create_duration = "30s"
}
