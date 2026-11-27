# Stuck-namespace safety net.
#
# On `terraform destroy`, this null_resource is destroyed BEFORE the namespace
# (because it depends_on helm_release.this and kubernetes_namespace.this —
# Terraform destroys dependents first). Its destroy-time provisioner runs the
# generic cleanup helper, which clears finalizers on any resources the namespace
# controller can't process and finalizes the namespace if it's stuck Terminating.
#
# This matters here because the cluster may have many registered CRDs
# (e.g. Rook Ceph on the feature/add-rook-storage branch) that wedge the
# namespace controller — even an empty metrics-server namespace can get stuck.
#
# The script is idempotent: safe to run whether the namespace is Active,
# Terminating, or already gone.
resource "null_resource" "namespace_cleanup" {
  triggers = {
    namespace = kubernetes_namespace.this.metadata[0].name
    # fileexists() guard: the pre-commit terraform_validate hook runs this
    # module standalone (module-as-root), so path.root == this module's dir
    # and the repo-root script is absent there — filesha1 would fail validate.
    # HCL2 ternaries are lazy: the untaken branch is never evaluated, so in
    # standalone validation filesha1 is not called. In a real apply the module
    # is invoked from the repo root, path.root == repo root, and the hash is
    # computed normally so the null_resource still reacts to script edits.
    script_hash = fileexists("${path.root}/scripts/cleanup-stuck-namespace.sh") ? filesha1("${path.root}/scripts/cleanup-stuck-namespace.sh") : "standalone-validate"
  }

  depends_on = [helm_release.this, kubernetes_namespace.this]

  provisioner "local-exec" {
    when    = destroy
    command = "${path.root}/scripts/cleanup-stuck-namespace.sh ${self.triggers.namespace}"
  }
}
