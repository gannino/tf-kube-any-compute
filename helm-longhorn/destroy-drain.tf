# ============================================================================
# STORAGE DRAIN - runs FIRST during destroy, before any Longhorn teardown
# ============================================================================
# The aggressive destroy chain (webhook deletion, Helm uninstall, CR/CRD
# cleanup) is only safe AFTER every consumer PVC has been reclaimed by the
# still-running CSI stack. Consumer modules (redis, traefik, consul, ...)
# have no dependency edge on this module, so Terraform destroys them in
# parallel and may hang on a consumer PVC - e.g. a pod wedged in Terminating
# while holding kubernetes.io/pvc-protection - forever blocking that chain.
#
# This marker is created LAST in the module chain, so it is destroyed FIRST:
#
#   create:  helm_release -> helm_release_remover -> cleanup
#            -> kubectl_manifest(default_backup_target) -> storage_drain
#   destroy: storage_drain (drain runs here) -> default_backup_target
#            -> cleanup -> helm_release_remover -> helm_release
#
# Because it has no dependents, Terraform schedules its destroy immediately,
# even while consumer-module destroys hang elsewhere in the graph. The drain
# force-unwedges pods holding Longhorn PVCs, deletes the PVCs cluster-wide,
# and waits for volume/PV reclamation before the rest of the chain kills the
# CSI stack - which unblocks the parallel consumer destroys too.
#
# NOTE: this also applies to targeted destroys of this module; PVCs on
# Longhorn storage classes are deleted cluster-wide (their data is
# unrecoverable once Longhorn is removed).
resource "null_resource" "storage_drain" {
  triggers = {
    namespace       = local.module_config.namespace
    kubeconfig_path = local.kubeconfig_path
    drain_timeout   = var.destroy_drain_timeout
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      if [ -n "${self.triggers.kubeconfig_path}" ]; then
        export KUBECONFIG="${self.triggers.kubeconfig_path}"
      fi

      NS="${self.triggers.namespace}"
      TIMEOUT="${self.triggers.drain_timeout}"

      echo "========================================"
      echo "LONGHORN STORAGE DRAIN (pre-destroy)"
      echo "========================================"

      # STEP 0: Delete admission webhooks FIRST (they block BackupTarget deletion)
      echo "[drain] Deleting Longhorn admission webhooks before BackupTarget removal..."
      kubectl delete validatingwebhookconfiguration longhorn-webhook-validator --ignore-not-found=true --timeout=30s 2>/dev/null || true
      kubectl delete mutatingwebhookconfiguration longhorn-webhook-mutator --ignore-not-found=true --timeout=30s 2>/dev/null || true
      echo "[drain] Webhooks removed - BackupTarget deletion will not be blocked"

      # Discover Longhorn storage classes via provisioner (robust to renames)
      LONGHORN_SCS=$(kubectl get sc -o json 2>/dev/null | jq -r '.items[] | select(.provisioner=="driver.longhorn.io") | .metadata.name' | tr '\n' ' ')
      if [ -z "$LONGHORN_SCS" ]; then
        echo "No Longhorn storage classes found - nothing to drain."
        exit 0
      fi
      echo "Draining PVCs on storage classes: $LONGHORN_SCS"

      # Phase 1: delete consumer PVCs, force-unwedge pods holding them,
      # and wait for reclamation (bounded by TIMEOUT seconds).
      ELAPSED=0
      while [ $ELAPSED -lt $TIMEOUT ]; do
        PVC_LIST=$(kubectl get pvc -A -o json 2>/dev/null | jq -r --args '.items[] | select(.spec.storageClassName as $sc | $ARGS.positional | index($sc)) | "\(.metadata.namespace) \(.metadata.name)"' $LONGHORN_SCS)

        if [ -z "$PVC_LIST" ]; then
          echo "[drain] All Longhorn PVCs reclaimed."
          break
        fi

        echo "[drain] $ELAPSED s: $(echo "$PVC_LIST" | wc -l | tr -d ' ') PVC(s) still present:"
        echo "$PVC_LIST" | sed 's/^/  - /'

        for NSX in $(echo "$PVC_LIST" | awk '{print $1}' | sort -u); do
          # Delete PVCs in this namespace on Longhorn classes
          for SC in $LONGHORN_SCS; do
            for PVC in $(kubectl -n "$NSX" get pvc -o json 2>/dev/null | jq -r --arg sc "$SC" '.items[] | select(.spec.storageClassName==$sc) | .metadata.name'); do
              kubectl -n "$NSX" delete pvc "$PVC" --ignore-not-found=true 2>/dev/null || true
              # Force-unwedge terminating pods that still mount this PVC
              # (they hold kubernetes.io/pvc-protection forever otherwise)
              for POD in $(kubectl -n "$NSX" get pods -o json 2>/dev/null | jq -r --arg pvc "$PVC" '.items[] | select(.metadata.deletionTimestamp != null) | select(.spec.volumes[]?.persistentVolumeClaim.claimName==$pvc) | .metadata.name' | sort -u); do
                echo "[drain] Force-deleting wedged pod $NSX/$POD (holds PVC $PVC)"
                kubectl -n "$NSX" delete pod "$POD" --force --grace-period=0 --ignore-not-found=true 2>/dev/null || true
              done
            done
          done
        done

        sleep 15
        ELAPSED=$((ELAPSED + 15))
      done

      # Phase 2: wait for Longhorn volume CRs to be reclaimed (bounded by TIMEOUT)
      ELAPSED=0
      while [ $ELAPSED -lt $TIMEOUT ]; do
        VOL_COUNT=$(kubectl -n "$NS" get volumes.longhorn.io --no-headers 2>/dev/null | wc -l | tr -d ' ')
        [ "$VOL_COUNT" = "0" ] && break
        echo "[drain] $ELAPSED s: $VOL_COUNT Longhorn volume(s) still present, waiting..."
        sleep 15
        ELAPSED=$((ELAPSED + 15))
      done

      # Phase 2b: direct volume deletion if any volumes persist (webhook-safe now)
      VOL_LIST=$(kubectl -n "$NS" get volumes.longhorn.io --no-headers 2>/dev/null | awk '{print $1}' | grep -v '^$' || true)
      if [ -n "$VOL_LIST" ]; then
        echo "[drain] Deleting $VOL_LIST Longhorn volume(s) directly..."
        for VOL in $VOL_LIST; do
          kubectl -n "$NS" patch volumes.longhorn.io "$VOL" -p '{"metadata":{"finalizers":[]}}' --type=merge --ignore-not-found=true 2>/dev/null || true
          kubectl -n "$NS" delete volumes.longhorn.io "$VOL" --ignore-not-found=true --timeout=30s 2>/dev/null || true
        done
      fi

      # Phase 3: last resort - if PVs are still stuck Terminating on our
      # storage classes, strip their CSI finalizers so the objects can go;
      # the cleanup chain below handles remaining Longhorn CRs.
      for SC in $LONGHORN_SCS; do
        for PV in $(kubectl get pv -o json 2>/dev/null | jq -r --arg sc "$SC" '.items[] | select(.spec.storageClassName==$sc) | .metadata.name'); do
          PHASE=$(kubectl get pv "$PV" -o jsonpath='{.status.phase}' 2>/dev/null)
          if [ "$PHASE" != "Available" ] && [ "$PHASE" != "" ]; then
            echo "[drain] WARNING: stripping finalizers from stuck PV $PV (phase=$PHASE)"
            kubectl patch pv "$PV" --type=merge -p '{"metadata":{"finalizers":["kubernetes.io/pv-protection"]}}' 2>/dev/null || true
          fi
        done
      done

      LEFT=$(kubectl get pvc -A -o json 2>/dev/null | jq -r --args '.items[] | select(.spec.storageClassName as $sc | $ARGS.positional | index($sc)) | "\(.metadata.namespace)/\(.metadata.name)"' $LONGHORN_SCS)
      if [ -n "$LEFT" ]; then
        echo "[drain] WARNING: drain timeout reached, PVCs still present (continuing destroy - PVs may need manual cleanup):"
        echo "$LEFT" | sed 's/^/  - /'
      fi

      echo "✓ Storage drain complete"
      echo "========================================"
    EOT
  }

  # Created last => destroyed first: drain runs before the BackupTarget CR is
  # deleted (webhook-safe: no volumes reference it anymore), before the
  # cleanup provisioners wipe CRs/CRDs, and before the Helm uninstall.
  depends_on = [
    kubectl_manifest.default_backup_target,
    null_resource.crds_deployed,
  ]
}
