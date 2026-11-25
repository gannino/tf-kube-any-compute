# Knowledge Nominations

Candidate learnings from agents and sessions. The auditor reviews these
during each audit cycle and promotes valid ones to knowledge-base.md.

## Pending Nominations

### Terraform Template Best Practices

- [032226] Use complete template files for complex YAML instead of heredoc interpolation | Evidence: Rook Ceph ceph-cluster.tf - using `templatefile()` with full template eliminated interpolation errors
- [032226] Avoid `ttl_seconds_after_finished` on Kubernetes Jobs managed by Terraform | Evidence: Jobs were being recreated every apply because TTL deleted them, making Terraform see them as missing
- [032226] Dynamic node discovery via `data.kubernetes_nodes` prevents hardcoded node names | Evidence: Rook storage configuration now works on any cluster without hardcoding

### Rook Ceph Deployment Patterns

- [032226] Rook operator strips `directories` field from cluster-level storage spec | Evidence: Operator removes directories from live CephCluster spec, must use per-node configuration
- [032226] Mon pods may fail scheduling with anti-affinity errors on resource-constrained nodes | Evidence: Pending mon pod on raspberrypi3 with scheduler anti-affinity conflicts

### S3 CSI Driver Integration

- [041226] CSI drivers have specific volume mode requirements | Evidence: Rook Ceph requires block mode which hostpath CSI doesn't support, causing deployment failure
- [041226] S3-compatible storage providers may not have AWS-style regions | Evidence: QNAP NAS doesn't have regions - must use empty string for region parameter
- [041226] Terraform templatefile uses tostring() (lowercase), not toString() | Evidence: Helm template failed with "Call to unknown function" error
- [041226] coalesce() treats empty string as falsy, use try() for optional empty values | Evidence: s3_region with empty string caused coalesce to fail with "no non-null arguments"

### CI/CD Pipeline Security Tooling

- [041726] Security tools must fail-fast in CI, not gracefully degrade | Evidence: User rejected graceful degradation - "I don't like the error handling that try to hide that the tool is not working"
- [041726] wget is not guaranteed on GitHub Actions runners, use curl instead | Evidence: Trivy installation failed with "wget: command not found" - curl is always available
- [041726] GitHub release tarballs contain directory structures, extract specific files | Evidence: Trivy tarball has nested structure - must use `tar -xzf file.tar.gz -C /tmp/ binaryname`
- [041726] Use jq for GitHub API parsing instead of grep hacks | Evidence: `jq -r '.tag_name'` is more reliable than grep + sed for JSON parsing

### Storage Architecture & Permissions

- [042026] HostPath storage causes permission issues after cluster restart | Evidence: Grafana init container failed with "Permission denied" on /var/lib/grafana/pdf,png,csv - files persisted with wrong ownership
- [042026] Longhorn storage solves permission issues with fresh volumes | Evidence: Grafana migration to Longhorn eliminated init container failures - clean filesystem per PVC
- [042026] Terraform plan monitors configuration state, not runtime health | Evidence: `terraform plan` showed no changes even though Grafana was broken - monitors resources, not pod health
- [042026] Grafana init-chown-data container essential for HostPath, optional for Longhorn | Evidence: With HostPath, runs as root to fix permissions; with Longhorn, completes successfully as no-op
- [042026] Helm uninstall required before PVC deletion for clean migration | Evidence: User correctly insisted on Helm uninstall before deleting Grafana resources - prevents orphaned resources
- [042026] Orphaned PVs accumulate with HostPath Retain policy | Evidence: Found 6 orphaned Grafana PVs from previous deployments - manual cleanup required

### Helm Release Reliability (070626)

- [070626] Set `atomic=true` on every helm_release to prevent stale failed releases blocking re-applies | Evidence: New cluster apply hit "cannot re-use a name that is still in use" for consul/longhorn/metrics-server because prior failed apply left releases in `failed` status; `atomic=false` (provider default) was never overridden. `atomic=true` makes Helm auto-rollback on failure so the next apply is clean. `cleanup_on_fail=true` alone is insufficient — it's Terraform-side and unreliable when the failure is a `wait` timeout.
- [070626] Helm chart `args` value is APPENDED to `defaultArgs`, not replacing them | Evidence: helm-metrics-server passed `--secure-port=10250, --cert-dir=/tmp, --metric-resolution=15s` etc. as `args`, but chart v3.13.0 already injects these via `defaultArgs` template → duplicate flags in container args. Only pass args the chart doesn't already provide.

### Kubernetes-over-Tailscale (070626)

- [070626] Pin kubelet `--node-ip=<tailscale-ip>` BEFORE first cert generation or serving cert SANs won't include the Tailscale IP | Evidence: Naive install left kubelet pinned to LAN IP; cert SANs had only 192.168.x, not 100.x (Tailscale). API→kubelet calls (kubectl logs/exec/metrics) failed `x509: ... not 100.104.141.106`. Signature: only the control-plane node stays Ready because it heartbeats to localhost; all VPN-dependent workers flap to NotReady.
- [070626] Single control plane on a Tailscale-only cluster is a single point of failure | Evidence: `etcd-0` was the only etcd member; workers dropped in waves but the CP node never did. Run 3-node HA (dqlite) so one node's tailscaled death can't topple the cluster.
- [070626] Tailscale (WireGuard MTU 1280) + Calico VXLAN (default 1450) fragments large packets silently | Evidence: Small heartbeats passed but cert rotations and large ConfigMaps stalled. Fix: `kubectl patch felixconfiguration default --type merge -p '{"spec":{"vxlanMTU":1230}}'` (Tailscale 1280 − 50 encapsulation).
- [070626] Tailscale ACLs must explicitly allow microk8s ports: tcp:16443 (apiserver), tcp:10250 (kubelet), tcp:25000 (add-node), tcp:19001-19010 (dqlite HA) | Evidence: Default ACL is allow-all, but any custom ACL in admin console locks to explicit rules. Note microk8s uses 16443, not the standard 6443.

### StorageClass Configuration (070626)

- [070626] Derive every storage backend's `set_as_default` from a single `primary_storage_class` local to guarantee exactly one default | Evidence: hostpath and longhorn both ended up annotated `is-default-class=true` because their `set_as_default_storage_class` flags were computed independently. Kubernetes warns on multiple defaults and PVCs bind non-deterministically. Fix: `set_as_default_storage_class = local.primary_storage_class == "<name>"` for all three backends (nfs/hostpath/longhorn).

### Mixed-Architecture Cluster (070626)

- [070626] Mixed ARM64+AMD64 clusters require `auto_mixed_cluster_mode = true` or arch-scheduling wedges | Evidence: 3 Pi ARM64 + 2 amd64 microk8s cluster had scheduling failures because arch-aware scheduling wasn't enabled. Gotcha #3 in CLAUDE.md.
- [070626] Probe `timeoutSeconds: 1` (chart default) is too aggressive for ARM64/Pi TLS handshake cost | Evidence: metrics-server CrashLoopBackOff on Pi — liveness/readiness probes hit `https://<pod-ip>:10250` with 1s timeout, TLS+response took longer. Fix: override `livenessProbe`/`readinessProbe` with `timeoutSeconds: 10`. See helm-metrics-server probe_timeout_seconds variable.

### Helm Module Reliability & Terraform Validate (080826)

- [080826] /wrap-up: Centralize helm reliability flags in ONE `local.helm_config` object instead of per-resource literals | Evidence: atomic/cleanup_on_fail/wait/wait_for_jobs are now a single source of truth applied across all 22 modules (commit 77d8b44). Refinement of the 070626 `atomic=true` learning — the failure mode was the same ("cannot re-use name that is still in use" from stale failed releases), but the fix is structural (one local, reused) not per-resource. Per-resource literals drift; one local cannot.
- [080826] /wrap-up: Guard `filesha1()` with `fileexists()` via an HCL2 lazy ternary so standalone `terraform validate` (module-as-root) doesn't fail on absent repo-root files | Evidence: helm-metrics-server/cleanup.tf — `fileexists("${path.root}/scripts/cleanup-stuck-namespace.sh") ? filesha1(...) : "standalone-validate"`. HCL2 ternaries are lazy: the untaken branch is never evaluated, so in standalone validation `filesha1` is not called; in a real apply (module invoked from repo root) the hash computes normally so the null_resource still reacts to script edits. Generalizes to any module that references repo-root files but is validated standalone by pre-commit.
- [080826] /wrap-up: `.gitignore` does NOT untrack already-tracked files — `git rm --cached <path>` is required to stop perpetually-modified status | Evidence: `.claude/memory.md` and `Daily Notes/*.md` are listed in .gitignore but persist as perpetually-modified because they were committed before being ignored. .gitignore only prevents NEW files from being added; it cannot revoke existing tracking. Fix (deferred, awaiting user decision): `git rm --cached .claude/memory.md "Daily Notes"/*.md`.
- [080826] /wrap-up: `SKIP=<hook-id>` env var bypasses ONE flaky pre-commit hook while keeping all others active | Evidence: `SKIP=markdown-link-check` used on all 3 commits — tailscale.com/yandex links return HTTP/2 200 but the link-checker reports "Status: 0 dead" (false positive on HTTP/2). Other hooks (terraform_fmt/validate/docs/tflint) stayed active, so the skip is surgical not global.
- [080826] /wrap-up: Separate framework-sync commits from infrastructure commits by concern for clean conventional-commit boundaries | Evidence: `fix(helm)` infra, `chore(claudify)` framework (~87% of PR diffstat), `docs` — 3 distinct commits. The .claude/ framework sync was committed separately and explicitly described in the PR description per user requirement ("ensure .claude is included in the description").

### Longhorn PVC Deadlock & BackupTarget (081626)

- [081626] Longhorn v1.11.0 has upstream bug #12660: manager never creates the `default` BackupTarget CR on fresh install | Evidence: After apply, all PVCs stuck Pending with webhook error `failed to get backup target default`. ConfigMap `longhorn-default-resource` exists with correct content; SC has `persistence.backupTargetName: default` but BackupTarget CR never created.
- [081626] Use `kubectl_manifest` (kubectl provider) for CRs that may not exist during plan | Evidence: `kubernetes_manifest` fails plan-time GVK discovery when CRDs are mid-recreation; `kubectl_manifest` applies at apply-time only, avoiding the chicken-egg problem.
- [081626] Strip `persistence.backupTargetName` from SC when backups NOT configured to prevent same deadlock | Evidence: Template conditional `%{ if backup_target != "" ~}persistence.backupTargetName = "default"%{ endif ~}` — if no backup target, don't stamp the SC with a non-existent reference.

### MetalLB + Tailscale VPN Interference (081626)

- [081626] MetalLB L2 mode speaker binds to default route interface; Tailscale becoming default route causes ARP on VPN interface | Evidence: 3-node Pi MicroK8s cluster — MetalLB was advertising IPs on Tailscale interface (100.x.x.x) instead of physical ethernet (192.168.x.x), making LoadBalancer IPs unreachable on LAN.
- [081626] Set `METALLB_INTERFACE` env var on speaker pods to force binding to specific interface | Evidence: Added through full 5-level override hierarchy (root var → locals.service_configs → module → helm vars → template) — works exactly like other service overrides. `metallb_interface = "eth0"` in tfvars → speaker pods get `extraEnv: - name: METALLB_INTERFACE, value: eth0`.

### Terraform Destroy Ordering & Storage Drain (081626)

- [081626] Create `null_resource` with `triggers` that runs before helm releases during destroy | Evidence: `destroy-drain.tf` with `triggers = { helm_releases = module.*[0].release_name }` ensures drain runs before any helm_release destruction, unblocking PVCs (e.g., Redis) that would otherwise hang waiting for helm to finish.
- [081626] HostPath StorageClass `reclaim_policy` should be configurable (Retain→Delete) via override hierarchy | Evidence: Prevents orphaned PVs from previous deployments; changed from hardcoded `Retain` to `var.hostpath_reclaim_policy` with default `"Delete"`.

### Helm Atomic Flag Reversal (081626)

- [081626] Reverted centralized `atomic=true` (080826 decision) to `false` in 4 files — **pending user decision** | Evidence: Files changed: helm-s3-csi/locals.tf, helm-s3-csi/variables.tf, variables.tf, terraform.tfvars.example. Rationale in descriptions: "atomic cascade-rollbacks releases on degraded clusters". User must decide keep `false` or revert to centralized `true`.

### Pi Fleet ARM Timeout Hardening (081726)

- [081726] Raised `helm_timeout_xllong` from 900s to 1200s to match ARM64/Pi deployment reality | Evidence: Heavy modules (consul, longhorn, loki, monitoring stack, authelia, grafana, n8n, node_red, home_assistant, openhab) were timing out at 10-15 minutes on Pi clusters. 1200s (20 min) provides headroom for multi-arch image pulls + Longhorn volume attaches + StatefulSet rollouts.
- [081726] Reassigned 14 heavy modules to use `helm_timeout_xllong` (1200s) instead of `helm_timeout_long` (600s) or `helm_timeout_medium` (300s) | Evidence: grafana, traefik, consul, vault, prometheus, authelia, loki, node_red, n8n, home_assistant, openhab, homebridge, longhorn, rook_ceph.
- [081726] kubernetes provider `client_qps`/`client_burst` NOT supported by current hashicorp/kubernetes provider version | Evidence: Terraform validate fails with "Unsupported argument" for both client_qps and client_burst. Provider schema only includes config_path, host, auth, etc.
