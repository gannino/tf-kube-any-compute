# ============================================================================
# CDI (CONTAINERIZED DATA IMPORTER) FOR KUBEVIRT
# ============================================================================

# Fetch CDI operator manifest
data "http" "cdi_operator" {
  count = var.cdi_version != null && var.cdi_version != "" ? 1 : 0
  url   = "https://github.com/kubevirt/containerized-data-importer/releases/download/${var.cdi_version}/cdi-operator.yaml"
}

# Parse CDI operator manifest
data "kubectl_file_documents" "cdi_operator" {
  count   = var.cdi_version != null && var.cdi_version != "" ? 1 : 0
  content = data.http.cdi_operator[0].response_body
}

# Apply CDI operator
resource "kubectl_manifest" "cdi_operator" {
  for_each = var.cdi_version != null && var.cdi_version != "" ? data.kubectl_file_documents.cdi_operator[0].manifests : {}

  yaml_body = each.value

  depends_on = [kubernetes_namespace.this]
}

# Wait for CDI operator to be ready
resource "null_resource" "wait_for_cdi_operator" {
  count = var.cdi_version != null && var.cdi_version != "" ? 1 : 0

  depends_on = [kubectl_manifest.cdi_operator]

  triggers = {
    kubeconfig_path = local.kubeconfig_path
  }

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG="${self.triggers.kubeconfig_path}"
      echo "Waiting for CDI operator deployment..."
      kubectl wait --for=condition=available --timeout=300s deployment/cdi-operator -n cdi || true
      sleep 10
    EOT
  }
}

# Fetch CDI CR manifest
data "http" "cdi_cr" {
  count = var.cdi_version != null && var.cdi_version != "" ? 1 : 0
  url   = "https://github.com/kubevirt/containerized-data-importer/releases/download/${var.cdi_version}/cdi-cr.yaml"
}

# Parse CDI CR manifest
data "kubectl_file_documents" "cdi_cr" {
  count   = var.cdi_version != null && var.cdi_version != "" ? 1 : 0
  content = data.http.cdi_cr[0].response_body
}

# Apply CDI CR
resource "kubectl_manifest" "cdi_cr" {
  for_each = var.cdi_version != null && var.cdi_version != "" ? data.kubectl_file_documents.cdi_cr[0].manifests : {}

  yaml_body = each.value

  depends_on = [null_resource.wait_for_cdi_operator]
}
