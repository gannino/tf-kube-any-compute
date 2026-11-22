# Task Board

## Current Branch Status

**Active branch**: `feature/add-rook-storage` (39 commits ahead of `main`)
**Status**: Aug-17 WIP changeset landed 112226 in 8 conventional commits — `c60ed05` fix(longhorn), `c233d2f` fix(metallb), `04e5c7f` fix(host-path), `e2e00d3` fix(s3-csi), `66b134d` chore(make), `7a43222` fix(config) root wiring, test-isolation fix, docs. **PR description drafted, not yet published (held per user decision 112226).**

## Today (next session priorities)

- [ ] **Open the PR** `feature/add-rook-storage` → `main` via `gh pr create` (description drafted and delivered; awaiting user go-ahead to publish to GitHub)
- [ ] **Cluster ops (user-executed)**: fix Tailscale ACLs (tcp:16443,10250,25000,19001-19010) + patch Calico VXLAN MTU→1230 on new 3-node Pi cluster
- [ ] **MetalLB verification**: run `terraform apply -target=module.metallb` to deploy `metallb_interface=eth0` fix; verify speaker pods have METALLB_INTERFACE env var
- [ ] **Storage verification**: run `terraform apply` for storage_drain marker + hostpath reclaim_policy=Delete; verify changes
- [x] **Atomic flag decided (112226)**: keep `false` — committed as-is (`e2e00d3` module + `7a43222` root default)
- [ ] **Makefile test-exit bug**: `make test-safe`/test targets echo "✅ completed" after `terraform test` without propagating its exit code — test failures don't fail the make target (caught 112226: 5 storage-selection failures ran green in CI terms)
- [x] **Pi fleet timeout hardening**: raised `helm_timeout_xllong` 900→1200s, reassigned 14 heavy modules to xllong (grafana, traefik, consul, vault, prometheus, authelia, loki, node_red, n8n, home_assistant, openhab, homebridge, longhorn, rook_ceph)
- [x] **kubernetes provider**: validated (client_qps/client_burst not supported by this provider version)

## This Week

- [ ] **Cluster ops (user)**: fix Tailscale ACLs — allow `tcp:16443,10250,25000,19001-19010` between cluster nodes (if recovery warns port unreachable)
- [ ] **Cluster ops (user, one-time)**: patch Calico VXLAN MTU → 1230 (`kubectl patch felixconfiguration default --type merge -p '{"spec":{"vxlanMTU":1230}}'`)
- [ ] Verify metrics-server recovers after apply (probe-timeout fix + args de-dup; pod should leave CrashLoopBackOff)
- [ ] CI verification: Trivy install method + full pipeline once PR opened
- [ ] Investigate Grafana dashboard provisioning (dashboards exist on PVC but EOF errors in logs on fresh deploy)
- [ ] Verify raspberrypi2 node-exporter visibility in Grafana (Prometheus scraping confirmed)
- [ ] KubeVirt `helm_timeout=900` restore (dropped in duplicate-block merge; Pi may time out)
- [ ] Decide on moving Alertmanager to Longhorn (Grafana already migrated)

## Backlog

- [ ] Architectural (future): run 3-node HA control plane so single-node Tailscale failure can't topple the cluster
- [ ] Tracking-policy cleanup: `git rm --cached .claude/memory.md "Daily Notes"/*.md` — tracked-but-gitignored files show perpetually-modified (awaiting user decision)
- [ ] Consider renaming `feature/add-rook-storage` branch (work has expanded well beyond Rook storage)

## Done

- [080826] **COMPLETE**: Centralized helm reliability flags (`atomic`/`cleanup_on_fail`/`wait`/`wait_for_jobs`) in `local.helm_config` across all 22 modules (commit `77d8b44`)
- [080826] **COMPLETE**: Fixed metrics-server validate-bug — `fileexists()` guard on `filesha1()` in cleanup.tf via HCL2 lazy ternary (commit `77d8b44`)
- [080826] **COMPLETE**: Fixed double-default StorageClass — hostpath/longhorn/nfs now derive `set_as_default` from `local.primary_storage_class`
- [080826] **COMPLETE**: Committed `.claude/` framework sync separately as `chore(claudify)` (commit `cf91ef3`, ~87% of PR diffstat, memory.md excluded)
- [080826] **COMPLETE**: Drafted PR description for `feature/add-rook-storage` → `main` with `.claude/` explicitly described (delivered, not published)
- [080726] **COMPLETE**: Diagnosed 4/5 nodes NotReady — Tailscale-only cluster, kubelet cert SANs missing Tailscale IP + single control plane
- [080726] **COMPLETE**: Built `scripts/microk8s_tailscaled/` — setup/recovery scripts + README documenting 6 failure modes
- [080726] **COMPLETE**: Diagnosed metrics-server CrashLoopBackOff — root cause: 1s probe timeout too aggressive for ARM64/Pi TLS handshake
- [080726] **COMPLETE**: Fixed metrics-server module defaults — probe timeout/failure overrides + de-duplicated args
- [080726] **COMPLETE**: Diagnosed stuck `terraform destroy` — orphaned state lock + 4 namespaces stuck Terminating
- [080726] **COMPLETE**: Built generic `scripts/cleanup-stuck-namespace.sh` (idempotent, workspace-aware); embedded into metrics-server destroy flow
- [080726] **COMPLETE**: Diagnosed apply cascade on new cluster — Longhorn CSI down + atomic=false left stale failed releases
- [080726] **COMPLETE**: Merged duplicate `kubevirt` override blocks (kept refined Pi config, ported shadowed flags)
- [080726] **VERIFIED**: `auto_mixed_cluster_mode = true` already set — no-op
- [070526] **COMPLETE**: Fixed Trivy CI/CD installation (3 commits)
  - Root cause: Official Trivy v0.72.0 install script reports success but doesn't install binary
  - Solution: Use direct binary download as primary method (skip buggy install script)
  - Updated TRIVY_VERSION: 0.50.0 → 0.72.0
- [042026] **COMPLETE**: Fixed Grafana storage migration from HostPath to Longhorn
- [042026] **COMPLETE**: Resolved Grafana permission issues after cluster restart
- [042026] **COMPLETE**: Cleaned up 6 orphaned PVs from previous Grafana deployments
- [042026] **COMPLETE**: Verified cluster health and node-exporter status (all nodes working)
- [042026] **COMPLETE**: Updated Grafana storage class in terraform.tfvars
- [041726] **COMPLETE**: Fixed CI/CD Trivy installation (curl instead of wget, fail-fast behavior)
- [041726] **COMPLETE**: Documented n8n task runners feature (architecture, usage, troubleshooting)
- [041726] **COMPLETE**: Fixed n8n external task runner mode (broker binding, TCP health checks)
- [041426] **COMPLETE**: Fixed Traefik plugins-storage PVC issue (removed unnecessary PVC - plugins use emptyDir)
- [041426] **COMPLETE**: Fixed Authelia storage PVC (enabled persistence in Helm values)
- [041426] **COMPLETE**: Cleaned up 2 orphaned PVCs with detached Longhorn volumes
- [041426] **COMPLETE**: Cleaned up 19 Released PVs from NFS→Longhorn migration
- [041426] **VERIFIED**: All 19 PVs now Bound and actively used by services
- [041426] **DISCUSSED**: Risks of moving Loki/Grafana/Alertmanager from HostPath to Longhorn
- [041426] **COMPLETE**: README updated with comprehensive storage documentation (Longhorn, smart selection, examples)
- [041326] **COMPLETE**: CSI storage strategy review and implementation
- [041326] **MODIFIED**: locals.tf - smart primary_storage_class (Longhorn → NFS → HostPath)
- [041326] **MODIFIED**: locals.tf - new storage_classes mappings (block, shared)
- [041326] **MODIFIED**: terraform.tfvars.example - added longhorn = false
- [041326] **MODIFIED**: terraform.tfvars - set_as_default_storage_class = true
- [041326] **VERIFIED**: All services aligned with locals.tf storage configuration
- [041326] **VALIDATED**: terraform fmt + validate passed
- [041226] **PIVOT**: Abandoned S3 CSI (ARM64 incompatibility - x86_64 containers)
- [041226] **READY**: S3 CSI module configured for x86 deployment (future use)
- [032226] Fixed Rook Ceph ceph-cluster.tf template interpolation
