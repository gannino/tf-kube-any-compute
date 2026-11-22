# ============================================================================
# DEFAULT BACKUP TARGET - explicit CR creation
# ============================================================================
# Longhorn >= 1.9 should auto-create the 'default' BackupTarget from the
# longhorn-default-resource ConfigMap on fresh install, but v1.11.0 fails to
# (upstream: longhorn/longhorn#12660). The default StorageClass references
# this target via its backupTargetName parameter, and the admission webhook
# then denies ALL volume creation: every PVC on the default StorageClass
# stays Pending. Creating the CR explicitly keeps Terraform as the source of
# truth and makes fresh installs deterministic.
#
# Uses the kubectl provider (not kubernetes_manifest) on purpose: the CRD is
# installed by the Helm release itself, so hashicorp/kubernetes schema
# discovery can fail at plan time while the release is (re)creating CRDs.
resource "kubectl_manifest" "default_backup_target" {
  count = var.backup_target != "" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "longhorn.io/v1beta2"
    kind       = "BackupTarget"
    metadata = {
      name      = "default"
      namespace = local.module_config.namespace
      labels    = local.common_labels
    }
    spec = merge(
      { backupTargetURL = var.backup_target },
      var.backup_credential_secret != "" ? { credentialSecret = var.backup_credential_secret } : {}
    )
  })

  # Create only after the Helm release is successful (it installs the CRDs).
  # Destroy ordering: this resource must be deleted while the Longhorn CRDs
  # still exist. null_resource.cleanup wipes all Longhorn CRs and CRDs via
  # kubectl during destroy; depending on it forces Terraform to destroy this
  # manifest FIRST (dependents are destroyed before their dependencies), so
  # 'kubectl delete' never hits a missing CRD.
  depends_on = [null_resource.cleanup, helm_release.this]
}
