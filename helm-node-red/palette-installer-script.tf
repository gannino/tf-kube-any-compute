# ============================================================================
# CONFIGMAP FOR PALETTE INSTALLER SCRIPT
# ============================================================================

resource "kubernetes_config_map" "palette_installer_script" {
  count = var.enable_persistence && length(var.palette_packages) > 0 ? 1 : 0

  metadata {
    name      = "${var.name}-palette-installer-script"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "install-palette.sh" = templatefile("${path.module}/templates/install-palette.sh.tpl", {
      palette_packages = var.palette_packages
    })
  }
}
